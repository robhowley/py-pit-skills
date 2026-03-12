---
description: Write disciplined backend tests for FastAPI services with pytest. Use
  this skill when adding tests to a Python/FastAPI service, setting up SQLAlchemy
  test fixtures, wiring TestClient with DI overrides, mocking external clients, or
  improving test maintainability. Covers fixture design, factory patterns, SQLite
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

------------------------------------------------------------------------

## Core testing stance

Prefer **simple local tests with minimal infrastructure**.

Rules:

-   Prefer **`TestClient`** for FastAPI endpoint tests whenever possible
-   Use **async clients only when the test genuinely requires async
    behavior**
-   Default test databases to **SQLite via SQLAlchemy fixtures**
-   Do **not introduce Docker databases** unless the repository already
    uses them for testing
-   External clients must be **mocked**, not called
-   **No test classes** — top-level `test_*` functions only; fixtures handle all setup

Tests must run reliably with a simple:

    pytest

No external services should be required.

------------------------------------------------------------------------

## Project structure

Tests should live in a `tests/` directory.

Example layout:

    tests/
      conftest.py
      test_health.py
      test_users.py
      factories/
        user_factory.py

Guidelines:

-   `conftest.py` holds shared fixtures
-   test files mirror application modules when possible
-   factory fixtures may live in `tests/factories/` or `conftest.py`

------------------------------------------------------------------------

## Fixture discipline

Shared setup belongs in **pytest fixtures**, not duplicated code.

Rules:

-   Use `@pytest.fixture` for reusable setup
-   Inspect existing fixtures **before creating new ones**
-   Prefer **composing fixtures** instead of duplicating setup logic
-   Keep fixture responsibilities narrow and clearly named

Example:

``` python
@pytest.fixture
def client(app):
    return TestClient(app)
```

Avoid inline setup repeated across tests.

------------------------------------------------------------------------

## Fixture scope

Choose fixture scope based on what the fixture creates and how expensive it is.

-   `scope="session"` — for things that are expensive to create and safe to share (e.g., the SQLAlchemy engine, schema creation)
-   `scope="function"` (default) — for anything that holds mutable state or must be isolated per test (e.g., sessions, clients, mocks)

A common pattern: session-scoped engine, function-scoped session with rollback.

``` python
@pytest.fixture(scope="session")
def engine():
    eng = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(eng)
    yield eng
    Base.metadata.drop_all(eng)


@pytest.fixture
def db_session(engine) -> Session:
    connection = engine.connect()
    transaction = connection.begin()
    TestSession = sessionmaker(bind=connection)
    session = TestSession()
    yield session
    session.close()
    transaction.rollback()
    connection.close()
```

The rollback in teardown means tests never bleed into each other even when they write data.

------------------------------------------------------------------------

## Factory fixtures

Use **factory fixtures** when tests require variations of objects.

Factories are appropriate for:

-   sample data
-   request payloads
-   ORM objects
-   mocked clients
-   service configurations

Factories are **not limited to data**. They may also produce configured
mocks or dependency variants.

Example:

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

Factory fixtures prevent duplicated setup across tests.

------------------------------------------------------------------------

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

Tests should control behavior explicitly rather than relying on fixture
branching.

------------------------------------------------------------------------

## SQLAlchemy test database

Tests should default to a **SQLite in-memory database** with
transaction-per-test isolation.

The three-fixture pattern:

1.  Session-scoped engine — schema created once for the whole run
2.  Function-scoped `db_session` — wraps each test in a transaction that rolls back
3.  `client` fixture — overrides the FastAPI DB dependency with the test session

See the **Fixture scope** section above for the engine/session implementation.

Avoid introducing containerized databases for tests unless that pattern
already exists in the repository.

------------------------------------------------------------------------

## FastAPI dependency overrides

Use **`app.dependency_overrides`** to swap FastAPI dependencies in tests.
Do not patch internals directly.

This is the correct pattern for replacing database sessions, auth providers,
or any injected dependency:

``` python
@pytest.fixture
def client(db_session):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
```

Always clear `dependency_overrides` in teardown so overrides don't leak
between tests.

------------------------------------------------------------------------

## FastAPI testing

Prefer `TestClient` for endpoint tests.

Example:

``` python
def test_health_endpoint(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
```

Use async clients only when necessary.

------------------------------------------------------------------------

## External client mocking

External services must be mocked.

Rules:

-   use `MagicMock(spec=ClientType)` or `create_autospec`
-   do not make real network calls in unit tests
-   assert the application's behavior, not the external service behavior

Example:

``` python
client = MagicMock(spec=PaymentClient)
client.charge.return_value = {"status": "ok"}
```

Shared mock setups should be implemented as **fixtures or factory
fixtures**.

------------------------------------------------------------------------

## Parametrization

Use pytest parametrization when only inputs vary.

Example:

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

Avoid duplicating identical test logic.

------------------------------------------------------------------------

## Avoid redundant coverage

Tests should verify **distinct behaviors**.

Avoid:

-   repeating the same assertions across multiple tests
-   testing framework behavior
-   duplicating coverage across layers without reason

Each test should justify its existence by covering a **unique behavior
or edge case**.

------------------------------------------------------------------------

## Deterministic time

Tests should not depend on the system clock.

Guidelines:

-   freeze or control time in tests
-   use tools such as `freezegun` when testing time-based behavior

Example:

``` python
from freezegun import freeze_time

@freeze_time("2025-01-01")
def test_token_expiry():
    ...
```

Time-dependent tests should always be deterministic.

------------------------------------------------------------------------

## Stable test data

Avoid uncontrolled randomness in tests.

Rules:

-   do not rely on random values for test behavior
-   prefer explicit, stable inputs
-   if randomness is necessary, seed it

Bad:

``` python
email = f"user-{uuid4()}@example.com"
```

Better:

``` python
email = "user@example.com"
```

Deterministic test data makes failures reproducible.

------------------------------------------------------------------------

## Test design principles

Tests should optimize for **human readability**.

Guidelines:

-   avoid excessive branching logic
-   avoid clever abstractions
-   prefer explicit inputs
-   keep tests easy to scan

Tests are read far more often than they are written.

------------------------------------------------------------------------

## Python hygiene in tests

Follow normal Python best practices even in test code.

Rules:

-   avoid mutable default arguments
-   keep fixtures small and focused
-   prefer explicit object construction over clever shortcuts

Readable tests are more valuable than minimal tests.
