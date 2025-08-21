#!/bin/bash

set -ex

function deregister_runner {
    #echo "Get Runner Deregistration Token"
    #token=$(
    #    curl -sS -X POST -H "Authorization: token ${GITHUB_PAT}" https://api.github.com/${GITHUB_URL}/actions/runners/remove-token | jq -r .token
    #)

    echo "Deregistering runner"
    ./config.sh remove --token "${token}"
}

function register_runner {
    echo "Get Runner Registration Token"
    token=$(
        curl -sS -X POST -H "Authorization: token ${GITHUB_PAT}" https://api.github.com/${GITHUB_URL}/actions/runners/registration-token | jq -r .token
    )

    echo "Configuring runner"
    CONFIGURED=false
    ./config.sh \
        --disableupdate \
        --ephemeral \
        --labels "${RUNNER_LABELS}" \
        --name "${NOMAD_ALLOC_ID}" \
        --replace \
        --token "${token}" \
        --unattended \
        --url "https://github.com/${GITHUB_URL}"
    CONFIGURED=true
}

export PATH=$PATH:/actions-runner
export RUNNER_ALLOW_RUNASROOT=1

# Register the Github Runner
register_runner

# Ensure we deregister the Github runner
trap 'deregister_runner' SIGINT SIGQUIT SIGTERM

# Launch the Github Runner
./bin/Runner.Listener run

# Deregister the Github runner
deregister_runner

exit 0