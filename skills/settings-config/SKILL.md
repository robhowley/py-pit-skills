---
description: Production-ready configuration management for Python backend projects using pydantic-settings. Use this skill when the user needs to add environment variable management, introduce pydantic-settings, replace scattered os.getenv usage, add a settings module, or set up .env support in a FastAPI service or Python backend.
disable-model-invocation: false
---

# Skill: settings-config

## Core position

This skill creates **clean, production-ready application configuration
management** using **pydantic-settings**.

It enforces disciplined configuration patterns that prevent common
problems such as:

-   configuration drift
-   unclear env var naming
-   environment-specific branching
-   accidental secrets in code

The skill favors **minimal, explicit configuration surfaces** and
ensures configuration is:

-   typed
-   validated
-   environment-driven
-   testable

------------------------------------------------------------------------

## Goals

Produce a configuration system that:

1.  Centralizes configuration in a **single settings module**
2.  Uses **typed settings via pydantic**
3.  Reads configuration from **environment variables**
4.  Allows `.env` usage in local development
5.  Avoids configuration logic scattered across the codebase

------------------------------------------------------------------------

## Step 0 — Inspect the existing project first

Before generating anything:

1.  Check whether a `config.py` or `settings.py` already exists. If it
    does, extend it rather than creating a parallel one.
2.  Note the existing package layout. If the project was scaffolded with
    `fastapi-init`, config lives at `{pkg_name}/core/config.py` — use
    that path, not `app/config.py`.
3.  Check whether an `env_prefix` is already in use anywhere
    (`env_prefix=`, `os.getenv("XYZ_`, existing `.env` keys). If one
    exists, adopt it.
4.  Check whether `.env` loading is already part of the project
    convention (for example a real `.env` file used locally, documented
    setup instructions, or an explicit user request). If so, adopt
    `env_file=".env"` in the config.

    Do not assume that the presence of `.env.example` alone means `.env`
    should be automatically loaded at runtime.
5.  Only create new files if no config module is present.

------------------------------------------------------------------------

## Standard structure

Create a dedicated settings module.

Typical layout (adapt to the actual package structure found in Step 0):

    project/
      {pkg_name}/
        core/
          config.py     ← preferred location for fastapi-init projects
      .env
      .env.example

Example implementation:

``` python
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "service"
    debug: bool = False
    database_url: str

    model_config = SettingsConfigDict(
        env_prefix="APP_",
        extra="ignore",
    )


settings = Settings()
```

Usage:

``` python
from {pkg_name}.core.config import settings

print(settings.database_url)
```

------------------------------------------------------------------------

## Environment variable pattern

Environment variables should follow a **consistent prefix convention**.

Example:

    APP_DATABASE_URL=postgresql://...
    APP_DEBUG=true

The prefix prevents collisions with other services or system variables.

------------------------------------------------------------------------

## .env files (optional, local dev)

Environment variables are the canonical configuration source. `.env`
support is an optional local-development convenience layer.

To enable it, add `env_file` to the config:

``` python
model_config = SettingsConfigDict(
    env_prefix="APP_",
    env_file=".env",
    extra="ignore",
)
```

Example `.env`:

    APP_DATABASE_URL=postgresql://localhost/service
    APP_DEBUG=true

When `.env` is in use, commit a `.env.example` to the repo showing
required variables. The `.env` file itself must be in `.gitignore` — it
may contain secrets and should never be committed.

`extra="ignore"` is intentional here (unlike `extra="forbid"` in
request schemas). Environment variables from the shell, Docker, or CI
will be present alongside app config — rejecting unknown keys would
break deployment.

------------------------------------------------------------------------

## Anti-patterns to remove

Replace patterns like:

``` python
import os
DATABASE_URL = os.getenv("DATABASE_URL")
```

or scattered config usage across modules.

All configuration should flow through the **settings object**.

------------------------------------------------------------------------

## Three subtle rules (important)

These rules are what distinguish this skill from generic AI
configuration scaffolding.

### Rule 1 --- No runtime environment branching

Avoid code such as:

``` python
if ENV == "production":
    ...
```

Configuration differences should come from **environment variables**,
not logic in the settings module.

The settings layer should remain **purely declarative**.

### Rule 2 --- Canonical environment prefix

If the repository already uses a prefix pattern (for example
`MY_SERVICE_`), the settings model must adopt it.

If no prefix exists, create one derived from the package name.

Consistency is more important than any specific prefix choice.

### Rule 3 --- Single settings instantiation

Instantiate settings **once** and import the instance everywhere.

Correct:

``` python
settings = Settings()
```

Incorrect:

``` python
Settings()
Settings()
Settings()
```

Multiple instantiations can lead to:

-   inconsistent configuration reads
-   test instability
-   hidden environment reloads

------------------------------------------------------------------------

## Output checklist

The skill should produce:

-   `config.py` with `BaseSettings`
-   a `Settings` class
-   a single `settings` instance
-   consistent env var prefix
-   removal of `os.getenv` usage
-   documentation comment describing required variables
-   `.env.example` committed *(if using .env)*
-   `.env` in `.gitignore` *(if using .env)*

------------------------------------------------------------------------

## Summary

A good configuration system is:

-   **typed**
-   **centralized**
-   **environment-driven**
-   **boring and predictable**

This skill enforces those properties so configuration never becomes a
source of production bugs.
