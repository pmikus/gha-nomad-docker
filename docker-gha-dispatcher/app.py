import os
import requests
import subprocess
from time import sleep
from datetime import datetime


# Configuration from environment
# GitHub PAT with admin:org scope
GITHUB_PAT = os.environ["GITHUB_PAT"]
# GitHub organization name
GITHUB_ORG = os.environ["GITHUB_ORG"]
# GitHub repository name
GITHUB_REPO = os.environ["GITHUB_REPO"]
# GitHub url
# https://github.com/orgs/{GITHUB_ORG}/{GITHUB_REPO}"
GITHUB_URL = f"https://github.com/{GITHUB_ORG}/{GITHUB_REPO}"
# https://api.github.com/orgs/{GITHUB_ORG}/actions/runs?status=queued"
GITHUB_API_URL = f"https://api.github.com/repos/{GITHUB_ORG}/{GITHUB_REPO}/actions/runs?status=queued"


def trigger_runner_job():
    cmd = ["nomad", "job", "run", "/nomad-gha-runner/nomad-gha-runner.hcl"]
    print("Running Nomad job with command:", " ".join(cmd))
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print("Nomad job failed:", e.stderr)
        raise

def on_success(response: requests.Response):
    """
    This function is executed when the URL check is successful.

    :param response: The response object from the successful request.
    :type response: requests.Response
    :raises RuntimeError: If subprocess call failed.
    """
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: "
          f"Status code {response.status_code} for {response.url}"
    )
    print(str(response.content))
    #trigger_runner_job

def on_failure(response: requests.Response):
    """
    This function is executed when the URL check fails or an error occurs.

    :param response: The response object from the successful request.
    :type response: requests.Response
    :raises RuntimeError: If subprocess call failed.
    """
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Failure: "
          f"Status code {response.status_code} for {response.url}"
    )

def check_api_status(interval=10, timeout=5):
    """
    Periodically checks the status of a given URL and takes action based on
    the result.

    :param interval: The time in seconds to wait between checks.
    :param timeout: The maximum time in seconds to wait for a response.
    :type interval: int
    :type timeout: int
    :raises RequestException: If REST API get failed.
    """
    headers = {
        "Authorization": f"token {GITHUB_PAT}",
        "Accept": "application/vnd.github+json",
    }

    print(f"Starting API status checker for {GITHUB_API_URL}")
    while True:
        try:
            response = requests.get(
                GITHUB_API_URL, timeout=timeout, headers=headers
            )

            # Check for a successful status code (200-299).
            if response.status_code >= 200 and response.status_code < 300:
                on_success(response)
            else:
                on_failure(response)

        except requests.exceptions.RequestException as e:
            on_failure(f"An error occurred during the request: {e}")

        # Pause the script for the specified interval before the next check.
        sleep(interval)


if __name__ == "__main__":
    check_api_status()
