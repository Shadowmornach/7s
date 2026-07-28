class SecurityHeadersMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        async def send_with_security_headers(message):
            if message["type"] == "http.response.start":
                headers = list(message.get("headers", []))
                
                security_headers = [
                    (b"x-content-type-options", b"nosniff"),
                    (b"x-frame-options", b"DENY"),
                    (b"referrer-policy", b"strict-origin-when-cross-origin"),
                    (b"x-xss-protection", b"1; mode=block"),
                ]
                
                existing_keys = {k.lower() for k, v in headers}
                for key, val in security_headers:
                    if key not in existing_keys:
                        headers.append((key, val))
                
                message["headers"] = headers

            await send(message)

        await self.app(scope, receive, send_with_security_headers)
