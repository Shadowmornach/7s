import pytest
from fastapi.testclient import TestClient
from uuid import uuid4
from main import app
from app.repositories.user_repository import _USERS_MEM_DB
from app.core.rate_limit import login_rate_limiter

client = TestClient(app)

@pytest.fixture(autouse=True)
def clean_stores():
    _USERS_MEM_DB.clear()
    login_rate_limiter._history.clear()
    yield

def test_email_registration_flow_success_and_uniqueness():
    email = f"user_{uuid4().hex[:6]}@example.com"
    password = "SecurePassword123!"
    
    # 1. First registration succeeds
    reg_resp = client.post(
        "/auth/register",
        json={"email": email, "password": password}
    )
    assert reg_resp.status_code == 200
    assert "access_token" in reg_resp.json()
    assert "refresh_token" in reg_resp.json()
    
    # 2. Duplicate registration fails
    dup_resp = client.post(
        "/auth/register",
        json={"email": email, "password": password}
    )
    assert dup_resp.status_code == 400
    assert "already registered" in dup_resp.json()["detail"]

def test_email_login_success():
    email = f"user_{uuid4().hex[:6]}@example.com"
    password = "SecurePassword123!"
    
    # Register user
    client.post("/auth/register", json={"email": email, "password": password})
    
    # Login succeeds
    login_resp = client.post("/auth/login", json={"email": email, "password": password})
    assert login_resp.status_code == 200
    assert "access_token" in login_resp.json()

def test_google_login_flow():
    token_resp = client.post("/auth/google", json={"id_token": "dev-google-token-12345"})
    assert token_resp.status_code == 200
    assert "access_token" in token_resp.json()

def test_refresh_token_endpoint():
    from app.core.jwt_auth import create_refresh_token
    token = create_refresh_token(subject="test-user-id", role="PASSENGER")
    
    # Successful refresh
    resp = client.post(
        "/auth/refresh",
        json={"refresh_token": token}
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data

    # Reusing the same refresh token fails
    resp_reuse = client.post(
        "/auth/refresh",
        json={"refresh_token": token}
    )
    assert resp_reuse.status_code == 401

def test_duplicate_email_signup_exact_error_message():
    email = f"dup_{uuid4().hex[:6]}@example.com"
    client.post("/auth/register", json={"email": email, "password": "Password123!"})
    
    dup_resp = client.post("/auth/register", json={"email": email, "password": "Password123!"})
    assert dup_resp.status_code == 400
    assert dup_resp.json()["detail"] == "This email is already registered. Please sign in instead."

def test_forgot_password_generic_response_non_existent_email():
    resp = client.post("/auth/forgot-password/request", json={"email": "nonexistent_7s_test@example.com"})
    assert resp.status_code == 200
    assert resp.json()["message"] == "If an account exists for this email, a code has been sent."

def test_forgot_password_otp_flow_success():
    from app.services.auth_service import _PASSWORD_RESET_STORE
    email = f"reset_{uuid4().hex[:6]}@example.com"
    client.post("/auth/register", json={"email": email, "password": "OldPassword123!"})
    
    # 1. Request OTP
    req_resp = client.post("/auth/forgot-password/request", json={"email": email})
    assert req_resp.status_code == 200
    assert req_resp.json()["message"] == "If an account exists for this email, a code has been sent."
    
    # Inspect generated OTP from test store (raw_otp_dev)
    otp_code = _PASSWORD_RESET_STORE[email]["raw_otp_dev"]
    assert len(otp_code) == 6
    assert "otp_code_hash" in _PASSWORD_RESET_STORE[email]
    
    # 2. Verify OTP
    verify_resp = client.post("/auth/forgot-password/verify-otp", json={"email": email, "otp": otp_code})
    assert verify_resp.status_code == 200
    assert verify_resp.json()["message"] == "OTP verified successfully"
    
    # 3. Reset password
    reset_resp = client.post("/auth/forgot-password/reset", json={"email": email, "otp": otp_code, "new_password": "NewPassword123!"})
    assert reset_resp.status_code == 200
    
    # 4. Login with new password succeeds
    login_resp = client.post("/auth/login", json={"email": email, "password": "NewPassword123!"})
    assert login_resp.status_code == 200
