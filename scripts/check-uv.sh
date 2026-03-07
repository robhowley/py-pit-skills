#!/usr/bin/env bash
if ! command -v uv &>/dev/null; then
  echo "ERROR: 'uv' is not installed or not in PATH. Install it with: curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
  exit 1
fi
