import sys
import os
sys.path.insert(0, os.path.abspath('.'))

import asyncio
import asyncpg
from pathlib import Path
from app.core.config import settings

MIGRATIONS_DIR = Path("../supabase/migrations").resolve()

async def apply_all():
    print(f"Reading migrations from: {MIGRATIONS_DIR}")
    files = sorted([f for f in MIGRATIONS_DIR.glob("*.sql")])
    print(f"Found {len(files)} migration files.")

    conn = await asyncpg.connect(settings.DATABASE_URL.get_secret_value(), statement_cache_size=0)
    try:
        # Create schema_migrations tracking table
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                filename VARCHAR(255) PRIMARY KEY,
                applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
            );
        """)
        
        applied_rows = await conn.fetch("SELECT filename FROM schema_migrations")
        applied_set = {r['filename'] for r in applied_rows}

        for file in files:
            if file.name in applied_set:
                print(f"  [SKIP] [{file.name}] already applied.")
                continue

            print(f"Applying [{file.name}]...")
            sql = file.read_text(encoding="utf-8")
            try:
                await conn.execute(sql)
                await conn.execute("INSERT INTO schema_migrations (filename) VALUES ($1)", file.name)
                print(f"  -> SUCCESS: [{file.name}] applied.")
            except Exception as e:
                err_msg = str(e)
                if "already exists" in err_msg or "duplicate key" in err_msg:
                    await conn.execute("INSERT INTO schema_migrations (filename) VALUES ($1) ON CONFLICT DO NOTHING", file.name)
                    print(f"  -> MARKED EXISTING: [{file.name}] ({err_msg})")
                else:
                    print(f"  !! FAILED on [{file.name}]: {e}")
                    raise e
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(apply_all())
