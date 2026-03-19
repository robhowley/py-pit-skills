---
name: pytest-service
description: Write disciplined backend tests for FastAPI services with pytest. Use
  this skill when adding tests to a Python/FastAPI service, setting up async SQLAlchemy
  test fixtures, wiring AsyncClient with DI overrides, mocking external clients, or
  improving test maintainability. Covers fixture design, factory patterns, async SQLite
  in-memory databases, app.dependency_overrides, and avoiding fragile or redundant
  tests.
disable-model-invocation: false
---

# Skill: pytest-service

## Core position

This skill establishes **clean, reliable backend testing using pytest**.

The goal is to produce tests that are:

-   fast
-   deterministic
-   easy to read
-   easy to extend
-   free of infrastructure dependencies

Tests should **optimize for scanability and maintainability**, not
clever abstractions.

## Core testing stance

Prefer **simple local tests with minimal infrastructure**.

Rules:

-   Use **`httpx.AsyncClient`** with `ASGITransport` for FastAPI endpoint tests
-   All test functions are **`async def`**; `asyncio_mode = "auto"` eliminates per-test markers
-   Use **`pytest_asyncio` fixtures** for async setup/teardown
-   Default test databases to **async SQLite via SQLAlchemy async fixtures**
-   Do **not introduce Docker databases** unless the repository already uses them for testing
-   External clients must be **mocked**, not called
-   **No test classes** — top-level `test_*` functions only; fixtures handle all setup
-   Each test covers a **distinct behavior** — no redundant assertions across tests
-   Avoid mutable default arguments in fixtures and helpers
-   Dev deps assumed: `pytest`, `pytest-asyncio`, `httpx`

Tests must run reliably with a simple `pytest`. No external services required.

## Project structure

Tests should live in a `tests/` directory.

    tests/
      conftest.py
      test_health.py
      test_users.py
      factories/
        user_factory.py

-   `conftest.py` holds shared fixtures
-   test files mirror application modules when possible
-   factory fixtures may live in `tests/factories/` or `conftest.py`

## Fixture discipline

Shared setup belongs in **pytest fixtures**, not duplicated code.

-   Use `@pytest.fixture` for reusable setup
-   Inspect existing fixtures **before creating new ones**
-   Prefer **composing fixtures** instead of duplicating setup logic
-   Keep fixture responsibilities narrow and clearly named

Avoid inline setup repeated across tests.

## Fixture scope

Choose fixture scope based on what the fixture creates and how expensive it is.

-   `scope="session"` — for things that are expensive to create and safe to share (e.g., the SQLAlchemy engine, schema creation)
-   `scope="function"` (default) — for anything that holds mutable state or must be isolated per test (e.g., sessions, clients, mocks)

A common pattern: session-scoped async engine, function-scoped async session with rollback.

``` python
@pytest_asyncio.fixture(scope="session")
async def engine():
    eng = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield eng
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await eng.dispose()


@pytest_asyncio.fixture
async def db_session(engine) -> AsyncSession:
    async with engine.connect() as conn:
        async with conn.begin() as trans:
            session = async_sessionmaker(bind=conn, expire_on_commit=False)()
            yield session
            await session.close()
            await trans.rollback()
```

The rollback in teardown means tests never bleed into each other even when they write data. `expire_on_commit=False` prevents lazy-load errors after commit in async sessions.

## Factory fixtures

Use **factory fixtures** when tests require variations of objects. Factories are appropriate for sample data, request payloads, ORM objects, mocked clients, and service configurations — not just data.

``` python
@pytest.fixture
def user_payload_factory():
    def _factory(**overrides):
        payload = {
            "email": "test@example.com",
            "name": "Test User",
        }
        payload.update(overrides)
        return payload

    return _factory
```

## Avoid branching logic in fixtures

Fixtures should configure objects, not contain decision trees.

Bad:

``` python
if status == "ok":
    client.charge.return_value = ...
elif status == "declined":
    ...
```

Good:

``` python
@pytest.fixture
def payment_client_factory():
    def _factory(charge_response=None):
        charge_response = charge_response or {"status": "ok"}

        client = MagicMock(spec=PaymentClient)
        client.charge.return_value = charge_response
        return client

    return _factory
```

Tests should control behavior explicitly rather than relying on fixture branching.

## FastAPI dependency overrides

Use **`app.dependency_overrides`** to swap FastAPI dependencies in tests. Do not patch internals directly.

``` python
@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncClient:
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c
    app.dependency_overrides.clear()
```

Always clear `dependency_overrides` in teardown so overrides don't leak between tests.

## FastAPI testing

Use `httpx.AsyncClient` with `ASGITransport` for endpoint tests.

``` python
async def test_health_endpoint(client: AsyncClient):
    response = await client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
```

## External client mocking

External services must be mocked.

-   use `MagicMock(spec=ClientType)` or `create_autospec`
-   do not make real network calls in unit tests
-   assert the application's behavior, not the external service behavior

Shared mock setups should be implemented as **fixtures or factory fixtures**.

## Parametrization

Use pytest parametrization when only inputs vary.

``` python
@pytest.mark.parametrize(
    "email",
    [
        "user@example.com",
        "admin@example.com",
    ],
)
def test_email_validation(email):
    ...
```

## Deterministic time and data

Tests should not depend on the system clock or random values. Freeze time with `freezegun`; use explicit, stable inputs rather than `uuid4()` or `random`.

``` python
@freeze_time("2025-01-01")
def test_token_expiry():
    ...
```
