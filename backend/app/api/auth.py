from fastapi import APIRouter, Depends, HTTPException, status, Request, Header
from pydantic import BaseModel
from typing import Optional
from app.core.config import settings
from app.schemas.auth import Token, OTPRequest, OTPVerifyRequest, RegisterRequest, UserRole
from app.services.auth_service import AuthService
from app.api.dependencies import get_auth_service
from app.domain.exceptions import RuleViolationError
from app.core.rate_limit import login_rate_limiter

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/register")
async def register(
    req: RegisterRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    await login_rate_limiter.check_rate_limit(req.phone_number)
    
    # Check if user already exists
    existing_user = await auth_service.user_repo.get_user_by_phone(req.phone_number)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number is already registered"
        )
    
    # Restrict registration to passenger only (BR-003, BR-006 privilege protection)
    if req.role.upper() != UserRole.PASSENGER.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only passenger self-service registration is allowed. Rider and Owner accounts must be provisioned securely."
        )

    # Create inactive user (BR-001)
    await auth_service.user_repo.create_user(
        phone_number=req.phone_number,
        role=req.role,
        status="INACTIVE"
    )
    
    # Generate OTP (BR-001: OTP sent on registration)
    await auth_service.generate_otp(req.phone_number)
    return {"message": "Registration successful. OTP sent successfully"}

@router.post("/otp/request")
async def request_otp(
    req: OTPRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    await login_rate_limiter.check_rate_limit(req.phone_number)
    
    # Only registered users can request login OTP (BR-002)
    user = await auth_service.user_repo.get_user_by_phone(req.phone_number)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number is not registered"
        )
        
    await auth_service.generate_otp(req.phone_number)
    return {"message": "OTP sent successfully"}

@router.post("/login", response_model=Token)
async def login_verify(
    req: OTPVerifyRequest,
    auth_service: AuthService = Depends(get_auth_service)
):
    await login_rate_limiter.check_rate_limit(req.phone_number)
    try:
        return await auth_service.verify_otp_and_login(req.phone_number, req.otp)
    except RuleViolationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )

class ProvisionRequest(BaseModel):
    phone_number: str
    role: str

@router.post("/provision", status_code=201)
async def provision_user(
    req: ProvisionRequest,
    request: Request,
    x_admin_secret: Optional[str] = Header(None, alias="X-Admin-Secret"),
    auth_service: AuthService = Depends(get_auth_service)
):
    # 1. Network IP Allowlist Check
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


    # 2. Verify secure bootstrapping path using constant-time comparison
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

    # Check if user already exists
    existing = await auth_service.user_repo.get_user_by_phone(req.phone_number)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone number is already registered."
        )

    # Provision user directly into ACTIVE state
    new_user = await auth_service.user_repo.create_user(
        phone_number=req.phone_number,
        role=req.role.upper(),
        status="ACTIVE"
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
        # Check invalidation list first using SHA-256 hash
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
        
        # Invalidate the current token upon successful validation of its payload
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
