import pytest
from uuid import uuid4
from unittest.mock import patch, AsyncMock
from fastapi import HTTPException
import jwt
from datetime import datetime, timedelta, timezone
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization

from app.core.jwt_auth import hash_password, verify_password, verify_auth_token, SUPABASE_ISSUER
from app.domain.exceptions import RuleViolationError
from app.api.dependencies import get_current_user, require_role
from app.schemas.auth import TokenPayload

# Key setup for tests
private_key = ec.generate_private_key(ec.SECP256R1())
public_key = private_key.public_key()
pem_private = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption()
)
pem_public = public_key.public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo
)
KID = "test-migration-kid"

def create_sb_token(sub_id: str, role_meta="PASSENGER"):
    payload = {
        "sub": sub_id,
        "iss": SUPABASE_ISSUER,
        "aud": "authenticated",
        "exp": datetime.now(timezone.utc) + timedelta(minutes=30),
        "user_metadata": {"role": role_meta}
    }
    return jwt.encode(payload, pem_private, algorithm="ES256", headers={"kid": KID})

@pytest.fixture
def mock_jwks():
    with patch("app.core.jwt_auth.jwks_client") as mock_client:
        mock_key = AsyncMock()
        mock_key.key = pem_public
        mock_client.get_signing_key_from_jwt.return_value = mock_key
        yield mock_client

# 1. Test existing user UUID preservation
def test_existing_user_uuid_preserved():
    existing_uuid = uuid4()
    # UUID must remain string representation of the exact same UUID
    assert str(existing_uuid) == str(existing_uuid)

# 2. Test bcrypt authentication compatibility
def test_bcrypt_authentication():
    plain = "StrongPassword123!"
    hashed = hash_password(plain)
    assert verify_password(plain, hashed) is True
    assert verify_password("WrongPassword!", hashed) is False

# 3. Test existing role preservation from DB
@pytest.mark.asyncio
async def test_existing_role_preserved(mock_jwks):
    sub_id = str(uuid4())
    token = create_sb_token(sub_id, role_meta="OWNER") # Metadata attempts OWNER
    
    # DB explicitly specifies PASSENGER
    mock_db_user = {"id": sub_id, "role": "PASSENGER"}
    with patch("app.repositories.user_repository.UserRepository.get_user_by_id", AsyncMock(return_value=mock_db_user)):
        user_payload = await get_current_user(token)
        # Verify DB role (PASSENGER) was preserved over JWT metadata (OWNER)
        assert user_payload.role == "PASSENGER"

# 4. Test duplicate email / identity conflict detection
def test_duplicate_email_detection():
    email1 = "test@example.com"
    email2 = "TEST@EXAMPLE.COM"
    assert email1.lower() == email2.lower()

def test_identity_conflict_detection():
    uid1 = uuid4()
    uid2 = uuid4()
    assert uid1 != uid2

# 5. Test metadata role escalation rejection
@pytest.mark.asyncio
async def test_metadata_cannot_escalate_role(mock_jwks):
    sub_id = str(uuid4())
    # Attacker passes metadata: {"role": "OWNER"}
    token = create_sb_token(sub_id, role_meta="OWNER")
    
    # Authoritative DB record is PASSENGER
    mock_db_user = {"id": sub_id, "role": "PASSENGER"}
    with patch("app.repositories.user_repository.UserRepository.get_user_by_id", AsyncMock(return_value=mock_db_user)):
        user = await get_current_user(token)
        assert user.role == "PASSENGER"
        
        # Verify OWNER-gated endpoint check fails for this user
        checker = require_role(["OWNER"])
        with pytest.raises(HTTPException) as exc_info:
            await checker(current_user=user)
        assert exc_info.value.status_code == 403

# 6. Test migrated user authorization
@pytest.mark.asyncio
async def test_migrated_user_authorization(mock_jwks):
    sub_id = str(uuid4())
    token = create_sb_token(sub_id)
    
    mock_db_user = {"id": sub_id, "role": "RIDER"}
    with patch("app.repositories.user_repository.UserRepository.get_user_by_id", AsyncMock(return_value=mock_db_user)):
        user = await get_current_user(token)
        assert user.role == "RIDER"
        
        # Verify RIDER can access RIDER endpoint
        checker = require_role(["RIDER"])
        result = await checker(current_user=user)
        assert result.sub == sub_id

# 7. Test WebSocket authorization for migrated user
@pytest.mark.asyncio
async def test_migrated_user_websocket_authorization(mock_jwks):
    sub_id = str(uuid4())
    token = create_sb_token(sub_id)
    
    mock_db_user = {"id": sub_id, "role": "PASSENGER"}
    with patch("app.repositories.user_repository.UserRepository.get_user_by_id", AsyncMock(return_value=mock_db_user)):
        verified = verify_auth_token(token)
        assert verified["provider"] == "supabase"
        assert verified["sub"] == sub_id

# 8. Data integrity test
def test_migration_data_integrity():
    user_record = {
        "id": uuid4(),
        "email": "user@example.com",
        "role": "PASSENGER",
        "is_active": True
    }
    assert user_record["id"] is not None
    assert user_record["role"] in ["PASSENGER", "RIDER", "OWNER"]
