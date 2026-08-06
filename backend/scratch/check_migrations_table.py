import sys
import os
sys.path.insert(0, os.path.abspath('.'))

import asyncio
import asyncpg
from app.core.config import settings

async def query_migrations():
    conn = await asyncpg.connect(settings.DATABASE_URL.get_secret_value(), statement_cache_size=0)
    rows = await conn.fetch("SELECT filename, applied_at FROM schema_migrations ORDER BY filename;")
    print(f"TOTAL_RECORDED_MIGRATIONS: {len(rows)}")
    for r in rows:
        print(f"  [{r['filename']}] -> Applied at: {r['applied_at']}")
    await conn.close()

if __name__ == "__main__":
    asyncio.run(query_migrations())
