import os
import requests
import subprocess
from time import sleep
from datetime import datetime


# Configuration from environment
# GitHub PAT with admin:org scope
GH_PAT = os.environ["GITHUB_PAT"]
# GitHub URL
GH_URL = os.environ["GITHUB_URL"]


def trigger_runner_job(response):
    if
    try:
        subprocess.run(
            ["nomad", "job", "run", "default.hcl"],
            env=os.environ | {
                "NOMAD_VAR_node_pool": "default",
                "NOMAD_VAR_region": "global",
                "NOMAD_VAR_namespace": "prod",
                "NOMAD_VAR_name": "gha-17120745847",
                "NOMAD_VAR_constraint_arch": "amd64",
                "NOMAD_VAR_constraint_class": "builder",
                "NOMAD_VAR_image": "pmikus/nomad-gha-runner:latest",
                "NOMAD_VAR_cpu": "24000",
                "NOMAD_VAR_memory": "24000",
                "NOMAD_VAR_env_runner_labels": "nomad"
            },
            check=True
        )
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
    print(response.json())
    trigger_runner_job(str(response.content))

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
        "Authorization": f"token {GH_PAT}",
        "Accept": "application/vnd.github+json",
    }

    print(f"Starting API status checker...")
    while True:
        try:
            response = requests.get(
                f"https://api.github.com/{GH_URL}/actions/runs?status=queued",
                timeout=timeout,
                headers=headers
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
