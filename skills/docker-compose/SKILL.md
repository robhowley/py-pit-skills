# Skill: docker-compose

## Core position

This skill produces a **local-development Docker Compose setup** that reflects the project as-is. It does not introduce backing services the repo doesn't already use, and it does not create a second Docker pattern if one already exists.

---

## Trigger

Use this skill when the user wants to:
- Containerize an existing Python project
- Add Docker Compose to a project
- Add a Dockerfile to a project
- "Dockerize" a service

---

## Variables

- `{pkg_name}` — snake_case package name (matches the project directory and Python package)
- `{PKG_NAME}` — SCREAMING_SNAKE_CASE env prefix (e.g. `my_service` → `MY_SERVICE`)

---

## Step 1 — Inspect the repo

Inspect before asking. Work through each check in order and record findings.

**1. Check for existing Docker artifacts**

Look for `Dockerfile`, `docker-compose.yml`, `docker-compose.yaml`, `.dockerignore`. If any are present, extend them — do not create a competing setup. Note what was found.

**2. Check for repo tooling**

- `uv.lock` present → uv-native project; use uv base image in Dockerfile
- No `uv.lock` → pip-based project; use `python:3.12-slim` with `pip install`

**3. Check for service signals**

Inspect `pyproject.toml` dependencies and any settings/config files for:
- `sqlalchemy` + a non-sqlite database URL pattern, or `psycopg`, `psycopg2`, `asyncpg` in deps → Postgres
- `redis` in deps → Redis
- No signals → **app-only** (do not add Postgres as a default)

If Postgres is signaled, also note which driver is already present (`psycopg2-binary`, `psycopg[binary]`, `asyncpg`, etc.) — this determines what to add in Step 6.

**4. Check for an existing health endpoint**

Grep routes for `/health`, `/healthz`, `/ping`, `/api/v1/health`, or similar. Record the exact path if found.

**5. Present inference summary**

Tell the user what was found and what will be generated. Ask for confirmation only if something is genuinely ambiguous (e.g., multiple config files with conflicting signals, or an existing `Dockerfile` that may need replacement vs. extension).

---

## Step 2 — Generate `Dockerfile`

Multi-stage build. Base image depends on repo tooling detected in Step 1.

**If `uv.lock` is present:**

```dockerfile
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
COPY {pkg_name}/ ./{pkg_name}/
RUN uv sync --frozen --no-dev

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/{pkg_name} /app/{pkg_name}
ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 8000
{HEALTHCHECK}
CMD ["/app/.venv/bin/uvicorn", "{pkg_name}.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**If no `uv.lock`:**

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY pyproject.toml ./
RUN pip install --no-cache-dir build && python -m build --wheel
RUN pip install --no-cache-dir dist/*.whl

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=builder /usr/local/bin /usr/local/bin
COPY {pkg_name}/ ./{pkg_name}/
EXPOSE 8000
{HEALTHCHECK}
CMD ["uvicorn", "{pkg_name}.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**HEALTHCHECK selection:**

- If a health endpoint was detected in Step 1:
  ```dockerfile
  HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000{detected_path}')"
  ```
- If no health endpoint exists, use a process-level check and note that a health endpoint should be added:
  ```dockerfile
  HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD python -c "import sys; sys.exit(0)"
  ```
  > Note: No health route was found. Consider adding a `/health` endpoint; the HEALTHCHECK currently uses a process-level fallback.

---

## Step 3 — Generate `docker-compose.yml`

Always include the `app` service. Add `db` (Postgres) and/or `cache` (Redis) only based on signals found in Step 1.

```yaml
# Local development only — not a production deployment target
services:
  app:
    build: .
    ports:
      - "8000:8000"
    env_file: .env.compose
    depends_on:
      db:                          # only if postgres signaled
        condition: service_healthy
      cache:                       # only if redis signaled
        condition: service_healthy
    restart: unless-stopped

  db:                              # only if postgres signaled
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: {pkg_name}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  cache:                           # only if redis signaled
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:                   # only if postgres signaled
```

---

## Step 4 — Generate `.env.compose`

Environment variables for the running containers. Uses the pydantic-settings env prefix convention from `core/config.py`.

```
# docker compose environment — do not commit real secrets
{PKG_NAME}_DATABASE_URL=postgresql+psycopg2://postgres:postgres@db:5432/{pkg_name}  # only if postgres signaled
{PKG_NAME}_REDIS_URL=redis://cache:6379/0                                            # only if redis signaled
{PKG_NAME}_DEBUG=false
```

Also create `.env.compose.example` with the same content — this file IS committed to version control as a template.

Add `.env.compose` to `.gitignore`:

```
echo ".env.compose" >> .gitignore
```

---

## Step 5 — Generate `.dockerignore`

Skip if `.dockerignore` already exists and covers these patterns.

```
.venv/
__pycache__/
*.pyc
*.pyo
.pytest_cache/
.ruff_cache/
*.egg-info/
dist/
.env*
!.env.compose.example
```

---

## Step 6 — Update dependencies if needed

**Postgres driver** — only if Postgres was signaled and no postgres driver is already present in `pyproject.toml`:

Inspect the existing stack first:
- Async stack (uses `asyncpg` elsewhere, or `AsyncSession`) → add `asyncpg`
- Sync stack with modern psycopg → add `psycopg[binary]`
- Sync stack with legacy psycopg2 → add `psycopg2-binary`
- Do not introduce a second driver if one already exists

Follow the repo's dependency management workflow:
- `uv.lock` present → `uv add <driver>`
- No `uv.lock` → `pip install <driver>` and update `pyproject.toml` manually

**Redis** — only if Redis was signaled and `redis` is not already in deps:
- `uv.lock` present → `uv add redis`
- No `uv.lock` → `pip install redis`

---

## Step 7 — Verify

```bash
docker compose up --build -d
docker compose ps          # all services healthy
curl http://localhost:8000{detected_health_path_or_omit_if_none}
docker compose down
```

If no health endpoint exists, omit the `curl` line and note that one should be added before moving to production.

---

## Hard constraints

1. Always use multi-stage builds — never ship builder layers to production
2. Never embed real credentials in `docker-compose.yml` — always use `env_file`
3. Always include a `HEALTHCHECK` in the Dockerfile and `healthcheck:` on backing services
4. Use `depends_on: condition: service_healthy` — not plain `depends_on`
5. Add `.env.compose` to `.gitignore`; provide `.env.compose.example` as a committed template
6. Never introduce a backing service (Postgres, Redis) unless the repo or user request shows it is needed — no signals → app-only
7. If Docker artifacts already exist, extend them; do not create a parallel competing setup
8. Match the project's existing dependency management workflow — do not assume uv if `uv.lock` is absent
9. Do not invent or hardcode a health endpoint path — detect from existing routes or use a process-level check

---

## Completion checklist

- [ ] `Dockerfile` present, multi-stage, appropriate base image for repo tooling
- [ ] `docker-compose.yml` scoped to inferred services only; no uninferred backing services added
- [ ] `HEALTHCHECK` uses detected path or process-level fallback — no invented path
- [ ] `.env.compose` present, `.gitignore` updated, `.env.compose.example` committed
- [ ] No existing Docker artifacts replaced without user confirmation
- [ ] No new backing services introduced without repo evidence or explicit user request
- [ ] No hardcoded credentials in `docker-compose.yml`
- [ ] `docker compose up --build` succeeds
