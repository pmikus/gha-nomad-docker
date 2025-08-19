#!/bin/bash

set -exuo pipefail

source .env

function register_runner {
    echo "Registering the Runner"
    ./nomad job dispatch \
        -meta github_url="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}" \
        -meta github_pat="${GITHUB_PAT}" \
        -meta github_org="${GITHUB_ORG}" \
        -meta github_repo="${GITHUB_REPO}" \
        -meta runner_labels="nomad" \
        gha-runner
}

function nomad_run {
    echo "Run Parent Nomad Job"
    ./nomad job run \
        nomad-gha-runner/gha-runner.nomad.hcl || true
}

nomad_run
register_runner