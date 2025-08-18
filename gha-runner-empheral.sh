#!/bin/bash

set -exuo pipefail

source .env

# ./nomad job run nomad-gha-runner/gha-runner.nomad.hcl || true

runner_token=$(
    curl -sS -X POST -H "Authorization: token $GITHUB_PAT" https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners/registration-token | jq -r .token
)

./nomad job dispatch \
    -meta github_url="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}" \
    -meta runner_token="${runner_token}" \
    -meta runner_labels="nomad" \
    gha-runner
