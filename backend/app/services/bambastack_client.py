import logging
from typing import Optional, Dict, Any

import httpx

from app.core.config import settings

logger = logging.getLogger("7s.bambastack")


class BambaStackException(Exception):
    """Infrastructure failure communicating with the BambaStack payment gateway."""
    pass


class BambaStackClient:
    """
    Pure infrastructure adapter for BambaStack M-Pesa Payment Gateway.
    Handles HTTP requests, authentication headers, and response parsing.
    Strictly devoid of business logic and database access.

    API contract source of truth: BambaStack_7s_delivery_Collection.json
    Base URL: configured via BAMBASTACK_BASE_URL environment variable
    Auth: Bearer token using BAMBASTACK_API_KEY
    """

    def __init__(self):
        self.base_url = settings.BAMBASTACK_BASE_URL.rstrip("/") if settings.BAMBASTACK_BASE_URL else ""
        self.timeout = settings.BAMBASTACK_TIMEOUT_SECONDS

    def _ensure_configured(self) -> None:
        """Verifies that required BambaStack configuration values are present."""
        if not settings.BAMBASTACK_API_KEY:
            raise BambaStackException("BambaStack API key is not configured on this server.")
        if not self.base_url:
            raise BambaStackException("BambaStack base URL is not configured on this server.")

    def _get_auth_headers(self) -> Dict[str, str]:
        """Returns authorization headers with the Bearer API key. Never logs the key."""
        self._ensure_configured()
        api_key = settings.BAMBASTACK_API_KEY.get_secret_value()
        return {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }

    async def check_status(self) -> Dict[str, Any]:
        """
        GET /api/external/v1/onboarding/status
        Verifies API key validity and channel readiness.
        Returns dict with 'is_channel_ready' field.
        """
        self._ensure_configured()
        url = f"{self.base_url}/api/external/v1/onboarding/status"
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(url, headers=self._get_auth_headers())
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            logger.error(f"BambaStack status check HTTP error: {e.response.status_code}")
            raise BambaStackException(f"BambaStack status check failed: HTTP {e.response.status_code}") from e
        except httpx.TimeoutException as e:
            logger.error("BambaStack status check timed out.")
            raise BambaStackException("BambaStack status check timed out.") from e
        except Exception as e:
            logger.error("BambaStack status check connection error.")
            raise BambaStackException("Failed to connect to BambaStack for status check.") from e

    async def send_stk_push(
        self,
        phone: str,
        amount: int,
        reference: str,
        description: str,
    ) -> Dict[str, Any]:
        """
        POST /api/external/v1/payments/stk-push

        Initiates an M-Pesa STK push prompt to the customer's phone.

        Args:
            phone: Customer phone number (07xx or 254xx format).
            amount: KES amount (integer, 1–150,000).
            reference: Unique order/payment identifier (must be unique per BambaStack contract;
                       duplicate references return HTTP 409).
            description: Human-readable transaction description.

        Returns:
            Dict containing at minimum: transaction_id, checkout_request_id
            (HTTP 202 on success per BambaStack contract).

        Raises:
            BambaStackException on infrastructure or provider errors.
        """
        self._ensure_configured()
        url = f"{self.base_url}/api/external/v1/payments/stk-push"
        payload = {
            "phone": phone,
            "amount": amount,
            "reference": reference,
            "description": description,
        }
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(url, json=payload, headers=self._get_auth_headers())
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            status_code = e.response.status_code
            # Log status without leaking auth headers
            logger.error(f"BambaStack STK Push HTTP error: {status_code}")
            if status_code == 409:
                raise BambaStackException(f"BambaStack rejected STK Push: duplicate reference '{reference}'.") from e
            error_body = e.response.text
            raise BambaStackException(f"BambaStack rejected STK Push: HTTP {status_code} — {error_body}") from e
        except httpx.TimeoutException as e:
            logger.error("BambaStack STK Push timed out.")
            raise BambaStackException("BambaStack STK Push request timed out.") from e
        except Exception as e:
            logger.error("BambaStack STK Push connection error.")
            raise BambaStackException("Failed to connect to BambaStack for STK Push.") from e

    async def get_payment_status(self, reference: str) -> Dict[str, Any]:
        """
        GET /api/external/v1/payments/{reference}

        Checks payment status by its unique reference.

        Returns dict with at minimum a 'status' field.
        BambaStack statuses: pending, paid, failed, cancelled.
        """
        self._ensure_configured()
        url = f"{self.base_url}/api/external/v1/payments/{reference}"
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(url, headers=self._get_auth_headers())
            response.raise_for_status()
            return response.json()
        except httpx.HTTPStatusError as e:
            logger.error(f"BambaStack payment status HTTP error: {e.response.status_code}")
            raise BambaStackException(f"BambaStack payment status check failed: HTTP {e.response.status_code}") from e
        except httpx.TimeoutException as e:
            logger.error("BambaStack payment status check timed out.")
            raise BambaStackException("BambaStack payment status check timed out.") from e
        except Exception as e:
            logger.error("BambaStack payment status connection error.")
            raise BambaStackException("Failed to connect to BambaStack for payment status.") from e


bambastack_client = BambaStackClient()
