import pytest
import time
from fastapi.testclient import TestClient
from uuid import uuid4
from main import app
from app.services.auth_service import _OTP_STORE
from app.repositories.user_repository import _USERS_MEM_DB
from app.core.rate_limit import login_rate_limiter

client = TestClient(app)

@pytest.fixture(autouse=True)
def clean_stores():
    _OTP_STORE.clear()
    _USERS_MEM_DB.clear()
    login_rate_limiter._history.clear()
    # Add default testing user with active state
    _USERS_MEM_DB["+254712345678"] = {
        "id": uuid4(),
        "phone_number": "+254712345678",
        "role": "PASSENGER",
        "status": "ACTIVE"
    }
    yield

def test_registration_flow_success_and_uniqueness():
    phone = f"+254700{uuid4().hex[:6]}"
    
    # 1. First registration succeeds
    reg_resp = client.post(
        "/auth/register",
        json={"phone_number": phone, "role": "passenger"}
    )
    assert reg_resp.status_code == 200
    assert reg_resp.json()["message"] == "Registration successful. OTP sent successfully"
    assert phone in _USERS_MEM_DB
    assert _USERS_MEM_DB[phone]["status"] == "INACTIVE"
    
    # 2. Duplicate registration fails (BR-001 Phone Uniqueness)
    dup_resp = client.post(
        "/auth/register",
        json={"phone_number": phone, "role": "passenger"}
    )
    assert dup_resp.status_code == 400
    assert "already registered" in dup_resp.json()["detail"]

def test_registration_privilege_escalation_prevented():
    phone = f"+254700{uuid4().hex[:6]}"
    
    # Registering as rider fails
    res_rider = client.post(
        "/auth/register",
        json={"phone_number": phone, "role": "rider"}
    )
    assert res_rider.status_code == 400
    assert "Only passenger self-service registration is allowed" in res_rider.json()["detail"]

    # Registering as owner fails
    res_owner = client.post(
        "/auth/register",
        json={"phone_number": phone, "role": "owner"}
    )
    assert res_owner.status_code == 400
    assert "Only passenger self-service registration is allowed" in res_owner.json()["detail"]

def test_login_otp_request_registered_only():
    phone_unregistered = f"+254700{uuid4().hex[:6]}"
    phone_registered = f"+254700{uuid4().hex[:6]}"
    
    # Pre-register user
    client.post("/auth/register", json={"phone_number": phone_registered, "role": "passenger"})

    # 1. OTP request for unregistered number fails (BR-002)
    req_fail = client.post(
        "/auth/otp/request",
        json={"phone_number": phone_unregistered}
    )
    assert req_fail.status_code == 400
    assert "not registered" in req_fail.json()["detail"]

    # 2. OTP request for registered user succeeds
    req_success = client.post(
        "/auth/otp/request",
        json={"phone_number": phone_registered}
    )
    assert req_success.status_code == 200
    assert req_success.json()["message"] == "OTP sent successfully"
    assert phone_registered in _OTP_STORE

def test_verify_correct_otp_transitions_state_to_active():
    phone = f"+254700{uuid4().hex[:6]}"
    
    # Register (status is INACTIVE)
    client.post("/auth/register", json={"phone_number": phone, "role": "passenger"})
    assert _USERS_MEM_DB[phone]["status"] == "INACTIVE"
    
    # Retrieve generated OTP from memory store
    otp = _OTP_STORE[phone]["otp"]
    
    # Verify correct OTP
    verify_resp = client.post(
        "/auth/login",
        json={"phone_number": phone, "otp": otp}
    )
    assert verify_resp.status_code == 200
    assert "access_token" in verify_resp.json()
    
    # Verify status transitioned to ACTIVE (BR-001)
    assert _USERS_MEM_DB[phone]["status"] == "ACTIVE"

def test_verify_incorrect_otp_increments_attempts_and_locks():
    phone = f"+254700{uuid4().hex[:6]}"
    
    # Register user
    client.post("/auth/register", json={"phone_number": phone, "role": "passenger"})
    
    # Verify attempts counter starts at 0
    assert _OTP_STORE[phone]["attempts"] == 0
    
    # 1. First incorrect attempt
    resp1 = client.post("/auth/login", json={"phone_number": phone, "otp": "000000"})
    assert resp1.status_code == 401
    assert _OTP_STORE[phone]["attempts"] == 1
    
    # 2. Second incorrect attempt
    resp2 = client.post("/auth/login", json={"phone_number": phone, "otp": "000000"})
    assert resp2.status_code == 401
    assert _OTP_STORE[phone]["attempts"] == 2
    
    # 3. Third incorrect attempt
    resp3 = client.post("/auth/login", json={"phone_number": phone, "otp": "000000"})
    assert resp3.status_code == 401
    assert _OTP_STORE[phone]["attempts"] == 3
    
    # 4. Fourth attempt triggers max retries limit (evicts and locks OTP)
    resp4 = client.post("/auth/login", json={"phone_number": phone, "otp": "000000"})
    assert resp4.status_code == 401
    assert "Max verification attempts exceeded" in resp4.json()["detail"]
    assert phone not in _OTP_STORE

def test_otp_expiry_enforced():
    phone = f"+254700{uuid4().hex[:6]}"
    client.post("/auth/register", json={"phone_number": phone, "role": "passenger"})
    
    # Force expiration time in the past
    _OTP_STORE[phone]["expires_at"] = time.time() - 10
    
    resp = client.post("/auth/login", json={"phone_number": phone, "otp": _OTP_STORE[phone]["otp"]})
    assert resp.status_code == 401
    assert "expired" in resp.json()["detail"]
    assert phone not in _OTP_STORE

def test_otp_is_single_use():
    phone = f"+254700{uuid4().hex[:6]}"
    client.post("/auth/register", json={"phone_number": phone, "role": "passenger"})
    otp = _OTP_STORE[phone]["otp"]
    
    # First verify succeeds
    resp1 = client.post("/auth/login", json={"phone_number": phone, "otp": otp})
    assert resp1.status_code == 200
    
    # Second verify with same OTP fails (evicted on success)
    resp2 = client.post("/auth/login", json={"phone_number": phone, "otp": otp})
    assert resp2.status_code == 401
    assert phone not in _OTP_STORE

def test_provision_user_restricted_and_permitted():
    phone = f"+254700{uuid4().hex[:6]}"
    
    # 1. Access without valid X-Admin-Secret is rejected
    res_no_sec = client.post(
        "/auth/provision",
        json={"phone_number": phone, "role": "owner"}
    )
    assert res_no_sec.status_code == 403

    # 2. Access with valid X-Admin-Secret is allowed
    from app.core.config import settings
    sec_key = settings.PROVISIONING_SECRET.get_secret_value()
    
    res_success = client.post(
        "/auth/provision",
        json={"phone_number": phone, "role": "owner"},
        headers={"X-Admin-Secret": sec_key}
    )
    assert res_success.status_code == 201
    assert res_success.json()["message"] == "User provisioned successfully"
    assert phone in _USERS_MEM_DB
    assert _USERS_MEM_DB[phone]["role"] == "OWNER"
    assert _USERS_MEM_DB[phone]["status"] == "ACTIVE"

def test_provision_user_network_ip_restriction():
    phone = f"+254700{uuid4().hex[:6]}"
    from app.core.config import settings
    sec_key = settings.PROVISIONING_SECRET.get_secret_value()

    # Request from unauthorized client IP should be rejected (403)
    res = client.post(
        "/auth/provision",
        json={"phone_number": phone, "role": "owner"},
        headers={"X-Admin-Secret": sec_key, "X-Forwarded-For": "192.168.1.100"}
    )
    assert res.status_code == 403
    assert res.json()["detail"] == "Forbidden: Admin network IP restriction."




def test_refresh_token_endpoint():

    from app.core.jwt_auth import create_refresh_token
    token = create_refresh_token(subject="test-user-id", role="PASSENGER")
    
    # Successful refresh (1st time)
    resp = client.post(
        "/auth/refresh",
        json={"refresh_token": token}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data

    # Reusing the same refresh token must fail (rotation validation)
    resp_reuse = client.post(
        "/auth/refresh",
        json={"refresh_token": token}
    )
    assert resp_reuse.status_code == 401
    assert "already been used" in resp_reuse.json()["detail"]

    # Failed refresh (expired or invalid token type)
    resp_fail = client.post(
        "/auth/refresh",
        json={"refresh_token": "invalidtoken"}
    )
    assert resp_fail.status_code == 401

