#!/bin/bash

set -exuo pipefail

source .env

function deregister_runner {
    echo "Get Runner Deregistration Token"
    runner_token=$(
        curl -sS -X POST -H "Authorization: token $GITHUB_PAT" https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners/remove-token | jq -r .token
    )

    echo "Deregistering the Runner"
    ./config.sh remove --token "${runner_token}"
}

function register_runner {
    echo "Get Runner Registration Token"
    runner_token=$(
        curl -sS -X POST -H "Authorization: token $GITHUB_PAT" https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners/registration-token | jq -r .token
    )

    echo "Registering the Runner"
    nomad job dispatch \
        -meta github_url="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}" \
        -meta runner_token="${runner_token}" \
        -meta runner_labels="nomad" \
        gha-runner
}

function nomad_run {
    echo "Run Parent Nomad Job"
    nomad job run \
        nomad-gha-runner/gha-runner.nomad.hcl || true
}

register_runner