#!/bin/bash

set -ex

function deregister_runner {
    echo "Get Runner Deregistration Token"
    # https://api.github.com/orgs/{GITHUB_ORG}/actions/runners/remove-token
    remove_token=$(
        curl -sS -X POST -H "Authorization: token ${GITHUB_PAT}" https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners/remove-token | jq -r .token
    )

    echo "Deregistering runner"
    ./config.sh remove --token "${remove_token}"
}

function register_runner {
    echo "Get Runner Registration Token"
    # https://api.github.com/orgs/{GITHUB_ORG}/actions/runners/registration-token
    registration_token=$(
        curl -sS -X POST -H "Authorization: token ${GITHUB_PAT}" https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners/registration-token | jq -r .token
    )

    CONFIGURED=false
    if [ ! -f ".runner" ]; then
        ./config.sh \
            --disableupdate \
            --ephemeral \
            --labels "${RUNNER_LABELS}" \
            --name "${NOMAD_ALLOC_ID}" \
            --replace \
            --token "${registration_token}" \
            --unattended \
            --url "${GITHUB_URL}"
    fi
    cat .runner
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