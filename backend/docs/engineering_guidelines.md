# Backend Engineering Guidelines

## 1. Naming Standards
- Files must describe a specific business capability, not a generic technology.
- **Forbidden suffixes/names:** `utils.py`, `helper.py`, `manager.py`, `service.py`, `common.py`, `misc.py`, `ws.py`, `security.py`, `config2.py`, `handlers.py`
- **Preferred naming:** `ride_websocket.py`, `ride_timeout_scheduler.py`, `jwt_auth.py`, `ride_state_machine.py`, `ride_event_repository.py`.
- If a future responsibility (e.g., API keys, OAuth, RBAC) is added, do **not** dump it into an existing file like `jwt_auth.py` unless it strictly fits that boundary. Create a new module (e.g., `rbac_auth.py`).

## 2. File Ownership & Discoverability
- No more than 5 files should need to be opened to understand a single feature.
- Avoid dumping grounds. Every file must have a single responsibility.
- The name of a file must allow any engineer to immediately deduce its exact contents without opening it.

## 3. Architecture
- **Clean Architecture & SOLID:** Enforce Dependency Inversion and Domain Purity.
- **Future Scale:** Always assume deployment in Kubernetes with multiple pods. Do not rely on shared mutable memory or `InMemory` singleton implementations for state (e.g. PubSub or Caching).
- **No Background Sweeps in Lifespan:** Avoid running background workers that manipulate the database without proper distributed locking (e.g. Postgres advisory locks).
