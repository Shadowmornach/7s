import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()
db_url = os.getenv("DATABASE_URL")

async def check():
    conn = await asyncpg.connect(db_url, statement_cache_size=0)
    rows = await conn.fetch("SELECT id, phone_number, role, full_name, is_active FROM users ORDER BY created_at DESC LIMIT 5")
    print(f"Users in DB: {len(rows)}")
    for r in rows:
        print(dict(r))
    await conn.close()

asyncio.run(check())
