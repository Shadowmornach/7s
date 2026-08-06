import sys
import os
sys.path.insert(0, os.path.abspath('.'))

import asyncio
import asyncpg
from app.core.config import settings

async def check():
    conn = await asyncpg.connect(settings.DATABASE_URL.get_secret_value(), statement_cache_size=0)
    rows = await conn.fetch("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
    tables = sorted([r['table_name'] for r in rows])
    print("EXISTING_TABLES_COUNT:", len(tables))
    print("EXISTING_TABLES:", tables)
    await conn.close()

if __name__ == "__main__":
    asyncio.run(check())
