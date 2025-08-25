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
# Organisation
ORG = "fdio"

headers = {
    "Authorization": f"token {GH_PAT}",
    "Accept": "application/vnd.github+json",
}


def parse_labels(labels, namespace="acme"):
    """
    This function parses labels from github runner.

    :param labels: The response object from the successful request.
    :param namespace: Custom namespace for labels.
    :type labels: list
    :type namespace: string
    """
    parsed = {}
    for label in labels:
        if label.startswith(namespace + "_"):
            _, kv = label.split(namespace + "_", 1)
            if "_" in kv:
                key, value = kv.split("_", 1)
                parsed[key] = value
    return parsed


def trigger_runner_job(response):
    """
    This function is executed to trigger Nomad Job.

    :param response: The response object from the successful request.
    :type response: requests.Response
    :raises RuntimeError: If subprocess call failed.
    """
    runs = response.json().get("workflow_runs", [])
    if not runs:
        return

    for run in runs:
        run_id = run["id"]
        jobs_url = f"https://api.github.com/{GH_URL}/actions/runs/{run_id}/jobs"
        jobs_response = requests.get(url=jobs_url, headers=headers)
        jobs_response.raise_for_status()
        jobs = jobs_response.json().get("jobs", [])

        labels = []
        for job in jobs:
            if "labels" in job:
                labels.extend(job["labels"])

        print(f"Workflow: {run_id} | {set(labels)}")

        labels = parse_labels(labels)

        if "nomad" not in labels:
            pass

        constraint_arch = labels.get("arch", "amd64")
        constraint_class = labels.get("class", "builder")
        namespace = labels.get("namespace", "prod")
        print(f"A: {constraint_arch} | C: {constraint_class} | N: {namespace}")

        try:
            with open("default.hcl", "r+") as f:
                content = f.read()
                f.seek(0)
                f.truncate()
                f.write(content.replace('"gha-runner"', f"gha-{run_id}"))
            subprocess.run(
                ["nomad", "job", "run", "default.hcl"],
                env={
                    "NOMAD_ADDR": "http://10.30.51.24:4646",
                    "NOMAD_VAR_node_pool": "default",
                    "NOMAD_VAR_region": "global",
                    "NOMAD_VAR_namespace": namespace,
                    "NOMAD_VAR_name": f"gha-{run_id}",
                    "NOMAD_VAR_constraint_arch": constraint_arch,
                    "NOMAD_VAR_constraint_class": constraint_class,
                    "NOMAD_VAR_image": "pmikus/nomad-gha-runner:latest",
                    "NOMAD_VAR_cpu": "24000",
                    "NOMAD_VAR_memory": "24000",
                    "NOMAD_VAR_env_runner_labels": ",".join(labels)
                },
                check=True
            )
        except subprocess.CalledProcessError as e:
            print("Nomad job failed:", e.stderr)
            pass

def on_success(response: requests.Response):
    """
    This function is executed when the URL check is successful.

    :param response: The response object from the successful request.
    :type response: requests.Response
    """
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: "
          f"Status code {response.status_code} for {response.url}"
    )
    trigger_runner_job(response)

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

def check_api_status(interval=30):
    """
    Periodically checks the status of a given URL and takes action based on
    the result.

    :param interval: The time in seconds to wait between checks.
    :type interval: int
    :raises RequestException: If REST API get failed.
    """
    print(f"Starting API status checker...")
    while True:
        try:
            url = f"https://api.github.com/{GH_URL}/actions/runs"
            params = {"status": "queued"}
            response = requests.get(url=url, headers=headers, params=params)
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
