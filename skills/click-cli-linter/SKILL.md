---
name: click-cli-linter
description: Audit and improve existing Python Click CLIs by identifying architecture problems, anti-patterns, and CLI UX issues, then proposing minimal, high-value fixes.
disable-model-invocation: false
---

# click-cli-linter

Use this skill when reviewing or fixing an **existing** Python CLI built with **Click**.

This skill focuses on:
- identifying structural problems
- detecting non-idiomatic Click usage
- improving CLI UX
- proposing minimal patches rather than unnecessary rewrites

Apply this skill when the user:
- asks to audit a Click CLI
- wants feedback on existing Click code
- asks why a Click CLI feels messy or hard to maintain
- wants minimal fixes for a Click-based command-line tool
- pastes Click code and asks for improvement

Do not apply when:
- the user wants a new CLI designed from scratch with no existing code
- the task is unrelated to Python CLIs
- the user explicitly wants another framework

# Invocation heuristics

Prefer this skill when the user:
- mentions existing Click code
- asks for review, linting, cleanup, or refactoring
- wants architecture feedback on a Click CLI
- wants to fix help text, options, command grouping, or code layout

Do not prefer this skill when:
- there is no existing CLI to review
- the task is purely explanatory and not evaluative
- the user is asking for a fresh implementation only

# Mission

Audit an existing Click CLI and provide:
1. the most important detected issues
2. why they matter
3. the smallest effective patch
4. an improved version when useful

Prefer **minimal, high-leverage improvements** over full rewrites.

# Core review mental model

Review the CLI across three layers:
- architecture
- Click idioms
- command-line UX

Do not nitpick style unless it affects correctness, maintainability, or usability.

# The 5 review invariants

Always follow these rules.

## 1. Prioritize real problems

Focus on:
- architecture breakdown
- non-idiomatic Click usage
- poor command discoverability
- inconsistent argument and option patterns
- output and help text problems

Do not pad the review with trivial style comments.

## 2. Prefer minimal patches

Fix the smallest thing that materially improves the CLI.

Prefer:

    print("Done")

to:

    click.echo("Done")

rather than rewriting the whole command.

## 3. Distinguish severity

Separate:
- correctness issues
- maintainability issues
- UX issues

Make it clear which problems are most important.

## 4. Preserve intent

Do not change command names, hierarchy, or behavior unnecessarily.

Improve structure and idioms while preserving what the CLI is trying to do unless the current design is clearly broken.

## 5. Stay Click-native

Recommend:
- `click.echo()`
- command groups where appropriate
- clear `@click.option()` / `@click.argument()` usage
- modularization for multi-command CLIs

Avoid recommending solutions that drift into another framework unless explicitly requested.

# Standard operating procedure

## Step 1 — Inspect the CLI

Check for:
- monolithic files
- missing command groups
- awkward command hierarchy
- lack of help text
- inconsistent option naming
- misuse of positional arguments
- `print()` instead of `click.echo()`
- argparse-style parsing habits
- unnecessary global state or implicit shared state

## Step 2 — Classify the issues

Group issues into:
- Correctness
- Maintainability
- UX

## Step 3 — Propose minimal patches

Prefer small targeted changes.

Examples:
- replace `print()` with `click.echo()`
- add `help=` text to options
- split commands into modules when the file is clearly too large
- convert a flat command set into a root group only when the CLI structure already implies subcommands

## Step 4 — Show the improved version

When useful, provide:
- a minimal diff-style patch
- or the corrected code block
- or a revised file layout for multi-command CLIs

# Output contract

When linting or reviewing a Click CLI, prefer this structure:

1. Detected Issues
2. Why They Matter
3. Minimal Patch
4. Improved Version

If the user asks for only a patch, still internally follow this structure and return the patch directly.

# Anti-patterns to flag

Call these out explicitly when present:
- `print()` instead of `click.echo()`
- mixing Click with argparse-style parsing
- manual help text formatting Click should generate
- all commands jammed into one file without need
- missing root groups for obvious multi-command CLIs
- inconsistent long-option naming
- positional arguments used for optional configuration
- hidden shared mutable state

# Response style

- concise
- specific
- patch-oriented
- severity-aware
- no unnecessary rewrite pressure

# Completion checklist

Before finishing an answer verify:
- the most important issues are identified first
- the patch is minimal and useful
- Click-native fixes are preferred
- the review preserves the CLI's intent
- the answer improves maintainability or UX in a concrete way
