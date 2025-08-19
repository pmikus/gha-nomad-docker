#!/bin/bash

set -exuo pipefail

function deregister_runner {
    echo "Get Runner Deregistration Token"
    remove_token=$(
        curl -sS -X POST -H "Authorization: token ${GITHUB_PAT}" https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners/remove-token | jq -r .token
    )

    echo "Deregistering runner"
    /actions-runner/config.sh remove --token "${remove_token}"

    echo "Removing workdir contents"
    rm -rf /home/github-runner/*
}

function register_runner {
    echo "Get Runner Registration Token"
    registration_token=$(
        curl -sS -X POST -H "Authorization: token ${GITHUB_PAT}" https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners/registration-token | jq -r .token
    )

    CONFIGURED=false
    if [ ! -f ".runner" ]; then
        /actions-runner/config.sh \
            --disableupdate \
            --ephemeral \
            --labels "${RUNNER_LABELS}" \
            --name "$(hostname)-$NOMAD_ALLOC_ID" \
            --replace \
            --token "${registration_token}" \
            --unattended \
            --url "${GITHUB_URL}" \
            --work "/home/github-runner"
    fi
    CONFIGURED=true
}

export PATH=$PATH:/actions-runner
export RUNNER_ALLOW_RUNASROOT=1

# Register the Github Runner
register_runner

# Ensure we deregister the Github runner
trap 'deregister_runner' SIGINT SIGQUIT SIGTERM

# Launch the Github Runner
./bin/Runner.Listener run --disableupdate --ephemeral

# Deregister the Github runner
deregister_runner

exit 0