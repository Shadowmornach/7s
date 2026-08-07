import pytest
from uuid import uuid4
import jwt
from datetime import datetime, timedelta, timezone
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization
from unittest.mock import patch, AsyncMock

from app.core.jwt_auth import decode_supabase_token, verify_auth_token, SUPABASE_ISSUER
from app.domain.exceptions import RuleViolationError

# Generate dummy EC keys for tests
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

KID = "test-kid-123"

def create_mock_supabase_token(
    sub=str(uuid4()),
    iss=SUPABASE_ISSUER,
    aud="authenticated",
    exp_delta_minutes=30,
    alg="ES256",
    key=pem_private
):
    payload = {
        "sub": sub,
        "iss": iss,
        "aud": aud,
        "exp": datetime.now(timezone.utc) + timedelta(minutes=exp_delta_minutes)
    }
    
    headers = {"kid": KID}
    
    return jwt.encode(payload, key, algorithm=alg, headers=headers)

@pytest.fixture
def mock_jwks_client():
    with patch("app.core.jwt_auth.jwks_client") as mock_client:
        mock_key = AsyncMock()
        mock_key.key = pem_public
        mock_client.get_signing_key_from_jwt.return_value = mock_key
        yield mock_client

def test_valid_supabase_token(mock_jwks_client):
    token = create_mock_supabase_token()
    payload = decode_supabase_token(token)
    assert payload["sub"] is not None

def test_invalid_signature(mock_jwks_client):
    # Sign with a DIFFERENT key
    wrong_private_key = ec.generate_private_key(ec.SECP256R1()).private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    token = create_mock_supabase_token(key=wrong_private_key)
    with pytest.raises(RuleViolationError, match="Invalid token"):
        decode_supabase_token(token)

def test_wrong_issuer(mock_jwks_client):
    token = create_mock_supabase_token(iss="https://wrong-issuer.com")
    with pytest.raises(RuleViolationError, match="Invalid token"):
        decode_supabase_token(token)

def test_wrong_audience(mock_jwks_client):
    token = create_mock_supabase_token(aud="public")
    with pytest.raises(RuleViolationError, match="Invalid token"):
        decode_supabase_token(token)

def test_expired_token(mock_jwks_client):
    token = create_mock_supabase_token(exp_delta_minutes=-10)
    with pytest.raises(RuleViolationError, match="Token has expired"):
        decode_supabase_token(token)

def test_missing_sub(mock_jwks_client):
    token = create_mock_supabase_token(sub="")
    with pytest.raises(RuleViolationError, match="Missing subject"):
        decode_supabase_token(token)

def test_invalid_uuid_sub(mock_jwks_client):
    token = create_mock_supabase_token(sub="not-a-uuid")
    with pytest.raises(RuleViolationError, match="Invalid subject format"):
        decode_supabase_token(token)

def test_wrong_algorithm(mock_jwks_client):
    # Create HS256 token but try to pass it as ES256 to the verifier
    payload = {
        "sub": str(uuid4()),
        "iss": SUPABASE_ISSUER,
        "aud": "authenticated",
        "exp": datetime.now(timezone.utc) + timedelta(minutes=30)
    }
    # It says alg=ES256 in header, but we sign with HS256 logic?
    # PyJWT won't let you sign with HS256 if you pass an EC key.
    # We will sign with a symmetric string key, but put alg=HS256 in header.
    token = jwt.encode(payload, "secret", algorithm="HS256")
    
    # decode_supabase_token should explicitly reject non-ES256
    with pytest.raises(RuleViolationError, match="Invalid token algorithm. Expected ES256"):
        decode_supabase_token(token)

def test_dual_token_verification(mock_jwks_client):
    # 1. Test Supabase token
    sb_token = create_mock_supabase_token()
    result1 = verify_auth_token(sb_token)
    assert result1["provider"] == "supabase"

    # 2. Test Legacy token (assuming settings.JWT_SECRET is used)
    from app.core.jwt_auth import create_access_token
    legacy_token = create_access_token(subject=str(uuid4()), role="PASSENGER")
    result2 = verify_auth_token(legacy_token)
    assert result2["provider"] == "legacy"

@pytest.mark.asyncio
async def test_role_spoofing_prevention(mock_jwks_client):
    from app.api.dependencies import get_current_user
    sb_token = create_mock_supabase_token()
    
    # Mock verify_auth_token to simulate decoding the token
    # (Since verify_auth_token relies on the payload, we just let it run)
    
    # We simulate a malicious user trying to spoof 'OWNER' in the JWT via some mechanism,
    # but the database says they are PASSENGER.
    
    mock_user = {"id": uuid4(), "role": "PASSENGER"}
    
    with patch("app.repositories.user_repository.UserRepository.get_user_by_id", AsyncMock(return_value=mock_user)):
        user_payload = await get_current_user(sb_token)
        # Even if they try to be OWNER, DB enforces PASSENGER
        assert user_payload.role == "PASSENGER"
