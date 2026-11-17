#!/usr/bin/env bash
# Fail fast when METRICS_TOKEN is missing/expired.
# Wire into .github/workflows/metrics.yml before the metrics action:
#
#   - name: Verify METRICS_TOKEN
#     env:
#       METRICS_TOKEN: ${{ secrets.METRICS_TOKEN }}
#     run: bash .github/metrics/verify-token.sh
#
set -euo pipefail

if [ -z "${METRICS_TOKEN:-}" ]; then
  echo "::error::METRICS_TOKEN secret is empty. Create a classic PAT (public metrics need no scopes; add repo for private contributions) and set it as repository secret METRICS_TOKEN."
  exit 1
fi

code=$(curl -sS -o /tmp/metrics-token-check.json -w "%{http_code}" \
  -H "Authorization: Bearer $METRICS_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/user)

if [ "$code" != "200" ]; then
  echo "::error::METRICS_TOKEN is invalid (HTTP $code). Update Settings → Secrets → Actions → METRICS_TOKEN with a fresh classic PAT, then re-run Metrics."
  cat /tmp/metrics-token-check.json || true
  exit 1
fi

echo "METRICS_TOKEN ok for $(python3 -c 'import json; print(json.load(open("/tmp/metrics-token-check.json"))["login"])')"
