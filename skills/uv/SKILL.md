---
name: uv
description: Expert guidance for correct uv usage in Python projects. Handles dependency management, environments, command execution, migration from pip/poetry/pip-tools, lockfile correctness, and uv anti-patterns.
disable-model-invocation: false
---

# uv

Use this skill when working with Python projects that use or should use **uv**.

This skill ensures instructions follow **uv-native workflows** and avoids common mistakes when mixing Python packaging tools.

Apply this skill when the user:
- mentions `uv`
- asks about Python dependency management
- asks about environment setup
- asks how to run Python commands or tests
- wants to migrate from pip / poetry / pip-tools
- needs help debugging a broken Python environment
- wants correct Python CLI tool usage

Do not apply when:
- the task is unrelated to Python tooling
- the user explicitly wants a different ecosystem (conda, poetry, pip) without discussing uv
- the question is purely about application design rather than tooling workflow

# Invocation heuristics

Prefer this skill when the user:
- mentions `uv`
- asks about Python dependency or environment management
- shows `pyproject.toml`, `uv.lock`, or `requirements.txt`
- asks how to run tests, scripts, or tools in a uv-managed repo
- is migrating from pip, poetry, or pip-tools to uv

Do not prefer this skill when:
- the user explicitly wants conda, poetry, or raw pip workflows
- the task is about app architecture rather than Python tooling

# Hard constraints

In a uv-managed workflow, never default to:
- `pip install ...`
- `python -m venv ...`
- `source .venv/bin/activate`
- `poetry add ...`
- `poetry run ...`
- `uv pip install ...` as the standard dependency workflow

Only use or mention those when the user explicitly asks for them, or when explaining migration/interoperability constraints.

If the repository already mixes workflows, call that out explicitly and recommend a single consistent path.

# Mission

Provide **correct, minimal uv-native workflows**.

The skill should:
1. enforce uv workflow invariants
2. detect mixed-tool anti-patterns
3. give minimal copy-pasteable commands
4. preserve repo structure unless migration is explicitly requested
5. prefer correctness over verbosity

Do not recommend unrelated packages, frameworks, or project architecture.

# Core uv mental model

uv is **project-centric**.

Projects are defined by:
- `pyproject.toml`
- `uv.lock`

Workflows revolve around:
- dependency resolution
- environment synchronization
- command execution within the project

uv manages environments automatically.

Manual environment management should **not be the default workflow**.

# The 5 uv invariants

Always follow these rules.

## 1. Dependency changes use uv commands

Correct:

    uv add <package>
    uv remove <package>

Avoid:

    pip install <package>
    uv pip install <package>

unless the user explicitly asks for pip compatibility.

## 2. Commands run through uv

Correct:

    uv run pytest
    uv run python script.py
    uv run python -m module

Avoid defaulting to:

    pytest
    python script.py

when the project is uv-managed.

## 3. Environments are managed automatically

Do **not** center workflows around:

    python -m venv
    source .venv/bin/activate

Activation may exist but is **not required** for normal workflows.

Prefer execution through `uv run`.

## 4. Tools use uv tool or uvx

Ephemeral execution:

    uvx <tool>

Persistent installation:

    uv tool install <tool>

Avoid recommending:

    pip install <tool>

for global CLI usage.

## 5. Do not mix packaging systems

Avoid mixing uv with:
- poetry commands
- pip install workflows
- manual dependency lists as the primary source of truth
- pip-tools compilation as the primary workflow

If a repo mixes systems, identify it and recommend one consistent workflow.

# Standard operating procedure

## Step 1 — Inspect project state

Check for:
- `pyproject.toml`
- `uv.lock`
- existing uv commands in documentation
- `requirements.txt`
- poetry or pip-tools configuration

Detect if the project is:
- uv-native
- mixed workflow
- legacy pip workflow
- poetry/pdm workflow

## Step 2 — Classify the request

Identify the task category:
- initialize uv
- manage dependencies
- run commands
- manage tools
- manage Python versions
- migration to uv
- fix broken workflow
- explain uv concepts

## Step 3 — Provide uv-native solution

Return:
- minimal commands
- short explanation when needed
- warnings if anti-patterns exist

Do not redesign the repository unless requested.

# Dependency management

Add dependencies:

    uv add <package>

Remove dependencies:

    uv remove <package>

Import existing dependency lists:

    uv add -r requirements.txt

Do not recommend manual editing of dependency lists unless explicitly requested.

# Lockfile and environment synchronization

Generate/update lockfile:

    uv lock

Synchronize environment:

    uv sync

Most normal workflows do **not require manual sync commands**.

# Command execution

Run commands inside the project environment using:

    uv run <command>

Examples:

    uv run pytest
    uv run python script.py
    uv run python -m module

# Python version management

Install Python:

    uv python install <version>

Pin project Python version:

    uv python pin <version>

# Tool execution

Temporary execution:

    uvx <tool>

Persistent installation:

    uv tool install <tool>

# Migration guidelines

1. Identify existing dependency source (`requirements.txt`, poetry config, pip workflows).
2. Establish `pyproject.toml` as the canonical project definition.
3. Import dependencies:

    uv add -r requirements.txt

4. Replace execution commands:

    pytest -> uv run pytest
    python script.py -> uv run python script.py

5. Remove conflicting documentation.

# Anti-pattern detection

Mixed installers (bad):

    uv add fastapi
    pip install sqlalchemy

pip-first workflow in uv project (bad):

    pip install requests

Correct:

    uv add requests

Manual venv workflow (bad):

    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt

Preferred:

    uv run <command>

pip compatibility misuse:

`uv pip` exists but should not be the default dependency workflow.

# Response style

- minimal commands
- concise explanations
- explicit anti-pattern detection
- no package or framework recommendations

# Completion checklist

Before finishing an answer verify:
- commands are uv-native
- no accidental pip workflow slipped in
- commands are minimal and copy-pasteable
- migration advice preserves project structure
- no unrelated packages or frameworks were introduced
