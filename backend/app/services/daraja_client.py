import base64
import time
import logging
import httpx
from datetime import datetime
from typing import Optional

from app.core.config import settings
from app.schemas.payments import STKPushResponse

logger = logging.getLogger("7s.daraja")

class DarajaException(Exception):
    """Base exception for infrastructure failures communicating with Daraja."""
    pass

class DarajaClient:
    """
    Pure infrastructure adapter for Safaricom Daraja API.
    Handles authentication, network requests, and payload formatting.
    Strictly devoid of business logic and database access.
    """
    _oauth_token: Optional[str] = None
    _token_expiry: float = 0.0

    def __init__(self):
        if settings.DARAJA_ENVIRONMENT == "sandbox":
            self.base_url = "https://sandbox.safaricom.co.ke"
        else:
            self.base_url = "https://api.safaricom.co.ke"
            
        self.timeout = settings.DARAJA_TIMEOUT_SECONDS
        self.shortcode = settings.DARAJA_SHORTCODE
        self.callback_url = settings.DARAJA_CALLBACK_BASE_URL
        
        # Ensure URLs are well-formed without trailing slashes (safely guarded against None)
        if self.callback_url and self.callback_url.endswith("/"):
            self.callback_url = self.callback_url[:-1]

    def _ensure_configured(self):
        """Verifies that all required Daraja API configuration values are present."""
        if not (
            settings.DARAJA_CONSUMER_KEY and 
            settings.DARAJA_CONSUMER_SECRET and 
            settings.DARAJA_SHORTCODE and 
            settings.DARAJA_PASSKEY and 
            settings.DARAJA_CALLBACK_BASE_URL
        ):
            raise DarajaException("Daraja STK Push credentials are not configured on this server.")

    def _generate_password(self, timestamp: str) -> str:
        """Generates the base64 encoded password required for STK Push."""
        self._ensure_configured()
        passkey = settings.DARAJA_PASSKEY.get_secret_value() if settings.DARAJA_PASSKEY else ""
        data_to_encode = f"{self.shortcode}{passkey}{timestamp}"
        encoded_string = base64.b64encode(data_to_encode.encode("utf-8")).decode("utf-8")
        return encoded_string

    async def _get_auth_token(self) -> str:
        """
        Retrieves an OAuth token. Caches the token in memory until it expires.
        Daraja tokens are typically valid for 3599 seconds. We refresh 60 seconds early.
        """
        self._ensure_configured()
        current_time = time.time()
        
        # Return cached token if valid
        if self._oauth_token and current_time < self._token_expiry:
            return self._oauth_token

        key = settings.DARAJA_CONSUMER_KEY.get_secret_value() if settings.DARAJA_CONSUMER_KEY else ""
        secret = settings.DARAJA_CONSUMER_SECRET.get_secret_value() if settings.DARAJA_CONSUMER_SECRET else ""
        auth_string = f"{key}:{secret}"
        encoded_auth = base64.b64encode(auth_string.encode("utf-8")).decode("utf-8")

        headers = {
            "Authorization": f"Basic {encoded_auth}",
            "Cache-Control": "no-cache"
        }

        url = f"{self.base_url}/oauth/v1/generate?grant_type=client_credentials"

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(url, headers=headers)
                
            response.raise_for_status()
            data = response.json()
            
            self._oauth_token = data.get("access_token")
            # Cache it, subtracting 60 seconds from the expiry buffer just to be safe
            expires_in = int(data.get("expires_in", 3599))
            self._token_expiry = current_time + expires_in - 60
            
            return self._oauth_token or ""
            
        except httpx.HTTPStatusError as e:
            # We purposely do not log the full request headers to prevent secret leakage
            logger.error(f"Daraja OAuth HTTP error: {e.response.status_code}")
            raise DarajaException("Failed to authenticate with Daraja.") from e
        except Exception as e:
            logger.error("Daraja OAuth connection error.")
            raise DarajaException("Failed to connect to Daraja OAuth.") from e

    async def send_stk_push(self, amount: float, phone_number: str, reference: str, description: str) -> STKPushResponse:
        """
        Initiates an STK Push prompt to the passenger's phone.
        
        Args:
            amount: The final amount to charge.
            phone_number: The MSISDN to push to (must be formatted 2547...).
            reference: AccountReference (often the Ride ID or receipt string).
            description: TransactionDesc presented to the user.
            
        Returns:
            STKPushResponse mapping the synchronous acknowledgment.
        """
        self._ensure_configured()
        token = await self._get_auth_token()
        
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        password = self._generate_password(timestamp)
        
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "BusinessShortCode": self.shortcode,
            "Password": password,
            "Timestamp": timestamp,
            "TransactionType": "CustomerPayBillOnline",
            "Amount": int(amount),
            "PartyA": phone_number,
            "PartyB": self.shortcode,
            "PhoneNumber": phone_number,
            "CallBackURL": f"{self.callback_url}/api/v1/payments/callback" + (f"?token={settings.DARAJA_WEBHOOK_SECRET.get_secret_value()}" if settings.DARAJA_WEBHOOK_SECRET else ""),
            "AccountReference": reference,
            "TransactionDesc": description
        }
        
        url = f"{self.base_url}/mpesa/stkpush/v1/processrequest"
        
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(url, json=payload, headers=headers)
            
            response.raise_for_status()
            data = response.json()
            
            return STKPushResponse(**data)
            
        except httpx.HTTPStatusError as e:
            logger.error(f"Daraja STK Push HTTP error: {e.response.status_code}")
            error_detail = e.response.text
            raise DarajaException(f"Daraja rejected STK Push: {error_detail}") from e
        except Exception as e:
            logger.error("Daraja STK connection error.")
            raise DarajaException("Failed to send STK request to Daraja.") from e

    async def query_stk_status(self, checkout_request_id: str) -> dict:
        """
        Queries Daraja for the status of an STK push transaction (BR-010 timeout fallback).
        """
        self._ensure_configured()
        token = await self._get_auth_token()
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        password = self._generate_password(timestamp)
        
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "BusinessShortCode": self.shortcode,
            "Password": password,
            "Timestamp": timestamp,
            "CheckoutRequestID": checkout_request_id
        }
        
        url = f"{self.base_url}/mpesa/stkpushquery/v1/query"
        
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(url, json=payload, headers=headers)
            
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            logger.error(f"Daraja STK Query HTTP error: {e.response.status_code}")
            raise DarajaException(f"Daraja STK Query failed: {e.response.text}") from e
        except Exception as e:
            logger.error("Daraja STK Query connection error.")
            raise DarajaException("Failed to query STK status from Daraja.") from e

daraja_client = DarajaClient()
