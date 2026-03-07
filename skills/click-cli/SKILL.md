---
description: Design, generate, and improve Python CLIs using the Click library. Focus on idiomatic architecture, command groups, modular layouts, CLI UX conventions, and avoiding common Click anti-patterns.
disable-model-invocation: false
---

# click-cli

Use this skill when designing or implementing Python command-line interfaces with **Click**.

This skill should add value **above baseline Click knowledge** by enforcing:
- good CLI architecture
- clear command hierarchy
- consistent argument and option design
- idiomatic Click usage
- avoidance of common Click anti-patterns

Apply this skill when the user:
- asks to create or design a Click CLI
- wants a Python CLI built with Click
- needs help structuring commands or subcommands
- wants idiomatic Click code rather than generic CLI code
- asks for help improving a Click-based command-line tool

Do not apply when:
- the task is unrelated to Python CLIs
- the user explicitly wants another CLI framework
- the question is purely about general application design rather than CLI behavior

# Invocation heuristics

Prefer this skill when the user:
- mentions `click`
- asks for command groups, subcommands, options, or arguments
- wants a CLI architecture recommendation
- is starting a new Python CLI project
- wants help fixing non-idiomatic Click code

Do not prefer this skill when:
- the user explicitly wants `argparse`, `typer`, `cement`, or another framework
- the task is general Python coding with no CLI component

# Mission

Produce **production-quality Click CLIs** that are:
1. idiomatic
2. modular
3. easy to extend
4. clear to use from the command line
5. consistent in help text and option design

Do not merely explain Click syntax unless the user explicitly asks for explanation.

# Core Click mental model

Click is best used to build CLIs around:
- a root command
- optional command groups
- small, composable subcommands
- explicit arguments and options
- predictable help output

Prefer clear command hierarchy over monolithic single-file command handlers.

# The 5 Click invariants

Always follow these rules.

## 1. Model the CLI before writing code

Define:
- root command
- subcommands
- arguments
- options
- shared context if needed

Do not jump straight into decorators without first clarifying the command structure in the answer.

## 2. Use Click-native constructs

Prefer:
- `@click.group()`
- `@click.command()`
- `@click.option()`
- `@click.argument()`
- `@click.pass_context()` when context is needed

Avoid mixing in patterns from other CLI frameworks unless explicitly requested.

## 3. Prefer `click.echo()` for user-facing output

Correct:

    click.echo("Done")

Avoid defaulting to:

    print("Done")

unless the user explicitly wants raw Python output behavior.

## 4. Prefer modular command layouts for multi-command CLIs

For anything beyond a very small CLI, prefer structure like:

    project/
      cli.py
      commands/
        init.py
        run.py
        status.py

Avoid placing every command in one large file when the CLI clearly has multiple concerns.

## 5. Design the CLI UX deliberately

Ensure:
- option names are consistent
- help text is useful
- positional arguments are used sparingly and intentionally
- subcommands are discoverable
- command names are short and predictable

# Standard operating procedure

## Step 1 — Design the CLI shape

Identify:
- root command name
- subcommands
- argument vs option boundaries
- shared/global options
- whether grouping is needed

Return a compact command tree when useful, for example:

    dataset
      ingest
      validate
      publish

## Step 2 — Recommend file layout

If the CLI is trivial, a single file may be acceptable.

If the CLI has multiple commands or domains, prefer modular layout.

## Step 3 — Generate idiomatic Click code

Use:
- typed options where appropriate
- clear help strings
- small command handlers
- `click.echo()` for output
- context objects only when they provide real value

## Step 4 — Validate the design

Before finishing, verify:
- the hierarchy is logical
- the code matches the designed command structure
- option names are consistent
- help text is present where needed
- the solution uses Click idioms rather than generic CLI habits

# Output contract

When generating or designing a Click CLI, prefer this structure in your answer:

1. CLI Architecture
2. Recommended File Layout
3. Click Implementation
4. Usage Examples

If the user asks for only code, still internally follow the same structure and provide the code cleanly.

# Anti-pattern detection

Call out these problems explicitly when they appear:
- monolithic all-in-one CLI files
- `print()` instead of `click.echo()`
- argparse-style logic mixed into Click code
- manual help formatting that Click should generate
- inconsistent option naming
- excessive positional arguments
- unnecessary global state

# Response style

- concise
- concrete
- code-first when implementation is requested
- architecture-aware
- no unnecessary framework comparisons unless relevant

# Completion checklist

Before finishing an answer verify:
- the CLI structure is clear
- Click-native decorators and patterns are used
- output uses `click.echo()` where appropriate
- the layout is modular when the CLI complexity warrants it
- the answer adds architectural guidance, not just decorator syntax
