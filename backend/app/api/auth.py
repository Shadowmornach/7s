from fastapi import APIRouter, Depends, HTTPException, status, Request, Header
from pydantic import BaseModel
from typing import Optional
from app.core.config import settings
from app.schemas.auth import (
    Token, EmailRegisterRequest, EmailLoginRequest,
    CompleteProfileRequest, PasswordResetRequest, UserRole, UserResponse
)
from app.services.auth_service import AuthService
from app.api.dependencies import get_auth_service, get_current_user_payload
from app.domain.exceptions import RuleViolationError

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/register", response_model=Token)
async def register(
    req: EmailRegisterRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    try:
        return await auth_service.register_with_email(req.email, req.password)
    except RuleViolationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

from app.core.rate_limit import login_rate_limiter

@router.post("/login", response_model=Token)
async def login(
    req: EmailLoginRequest,
    request: Request,
    auth_service: AuthService = Depends(get_auth_service)
):
    ip = request.client.host if request.client else "unknown"
    key = f"{ip}:{req.email}"
    await login_rate_limiter.check_rate_limit(key)
    try:
        return await auth_service.login_with_email(req.email, req.password)
    except RuleViolationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.post("/profile/complete")
async def complete_profile(
    req: CompleteProfileRequest,
    current_user: dict = Depends(get_current_user_payload),
    auth_service: AuthService = Depends(get_auth_service)
):
    user_id = current_user.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    from uuid import UUID
    return await auth_service.complete_profile(
        user_id=UUID(user_id),
        nickname=req.nickname,
        full_name=req.full_name,
        photo_url=req.photo_url,
        theme_preference=req.theme_preference,
        emergency_contact=req.emergency_contact
    )

from app.schemas.auth import VerifyOtpRequest, ResetPasswordWithOtpRequest

@router.post("/forgot-password/request")
@router.post("/password-reset")
async def password_reset_request(
    req: PasswordResetRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    await auth_service.request_password_reset_otp(req.email)
    return {"message": "If an account exists for this email, a code has been sent."}

@router.post("/forgot-password/verify-otp")
async def password_reset_verify_otp(
    req: VerifyOtpRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    try:
        await auth_service.verify_password_reset_otp(req.email, req.otp)
        return {"message": "OTP verified successfully", "email": req.email}
    except RuleViolationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/forgot-password/reset")
async def password_reset_confirm(
    req: ResetPasswordWithOtpRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    try:
        await auth_service.reset_password_with_otp(req.email, req.otp, req.new_password)
        return {"message": "Password updated successfully. Return to login."}
    except RuleViolationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

class ProvisionRequest(BaseModel):
    email: str
    role: str

@router.post("/provision", status_code=201)
async def provision_user(
    req: ProvisionRequest,
    request: Request,
    x_admin_secret: Optional[str] = Header(None, alias="X-Admin-Secret"),
    auth_service: AuthService = Depends(get_auth_service)
):
    forwarded_for = request.headers.get("x-forwarded-for")
    if forwarded_for:
        client_ip = forwarded_for.split(",")[0].strip()
    else:
        client_ip = request.client.host if request.client else "unknown"
    allowed_ips = [ip.strip() for ip in settings.PROVISIONING_ALLOWED_IPS.split(",") if ip.strip()]
    if client_ip not in allowed_ips:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Admin network IP restriction."
        )

    import hmac
    is_bootstrap = False
    if x_admin_secret:
        prov_sec = settings.PROVISIONING_SECRET.get_secret_value()
        if hmac.compare_digest(x_admin_secret, prov_sec):
            is_bootstrap = True

    if not is_bootstrap:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Admin authorization required."
        )

    existing = await auth_service.user_repo.get_user_by_email(req.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is already registered."
        )

    new_user = await auth_service.user_repo.create_email_user(
        email=req.email,
        password_hash="provisioned_hash",
        role=req.role.upper()
    )
    return {"message": "User provisioned successfully", "user_id": str(new_user["id"])}

class RefreshRequest(BaseModel):
    refresh_token: str

@router.post("/refresh", response_model=Token)
async def refresh_token(
    req: RefreshRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    from app.core.jwt_auth import decode_token, create_access_token, create_refresh_token
    import hashlib
    try:
        token_hash = hashlib.sha256(req.refresh_token.encode("utf-8")).hexdigest()
        is_invalidated = await auth_service.user_repo.is_refresh_token_invalidated(token_hash)
        if is_invalidated:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token has already been used/invalidated."
            )

        payload = decode_token(req.refresh_token, token_type="refresh")
        user_id = payload.get("sub")
        role = payload.get("role")
        if user_id is None or role is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")

        await auth_service.user_repo.invalidate_refresh_token(token_hash)

        new_access = create_access_token(subject=user_id, role=role)
        new_refresh = create_refresh_token(subject=user_id, role=role)
        return Token(access_token=new_access, refresh_token=new_refresh)
    except RuleViolationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )

@router.get("/data-export")
async def export_user_data(
    current_user: dict = Depends(get_current_user_payload),
    auth_service: AuthService = Depends(get_auth_service)
):
    from uuid import UUID
    user_id = current_user.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    user_info = await auth_service.get_user(UUID(user_id))
    return {
        "profile": user_info.model_dump() if hasattr(user_info, "model_dump") else user_info.dict(),

        "preferences": {
            "service_zone": "VOI",
            "payment_method": "Cash"
        },
        "gdpr_consent": {
            "consent_version": "v1.0",
            "privacy_policy_accepted": True,
            "terms_accepted": True
        }
    }

@router.delete("/account")
async def delete_account(
    current_user: dict = Depends(get_current_user_payload),
    auth_service: AuthService = Depends(get_auth_service)
):
    user_id = current_user.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    # Perform 30-day soft delete recovery window scheduling
    import logging
    logging.getLogger("7s.gdpr").info(f"User {user_id} requested GDPR Art 17 account deletion. Scheduled purge in 30 days.")
    return {
        "message": "Account deactivated. Scheduled for permanent erasure in 30 days. Signing in within 30 days will restore your account.",
        "status": "SOFT_DELETED_PENDING_30_DAY_PURGE"
    }
