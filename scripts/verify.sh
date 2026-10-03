#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
moon check --target js --deny-warn
moon test --target js --deny-warn
moon build --target js --deny-warn
python3 scripts/verify_cli.py
