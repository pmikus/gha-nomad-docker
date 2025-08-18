job "gha-runner" {
  datacenters = [var.datacenter]
  type        = "batch"
  node_pool   = "default"

  parameterized {
    meta_required = [
      "github_url",
      "runner_token",
      "runner_labels"
    ]
  }

  group "gha-runner" {
    count = 1
    constraint {
      attribute = "$${attr.cpu.arch}"
      value     = var.constraint_arch
    }
    constraint {
      attribute = "$${node.class}"
      value     = var.constraint_class
    }
    task "gha-runner" {
      driver = "docker"
      config {
        image = "pmikus/nomad-gha-runner:2.328.0"
      }
      env {
        GITHUB_URL    = "${NOMAD_META_github_url}"
        RUNNER_TOKEN  = "${NOMAD_META_runner_token}"
        RUNNER_LABELS = "${NOMAD_META_runner_labels}"
      }
      kill_timeout = "30s"
      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}

# These variables allow the job to have overridable default values.

variable "datacenter" {
  # Set the `NOMAD_VAR_datacenter` environment variable to override the
  # default datacenter for the task.
  type    = string
  default = "dc1"
}

variable "constraint_arch" {
  # Set the `NOMAD_VAR_constraint_arch` environment variable to override the
  # default cpu architectre constraint for the task.
  type    = string
  default = "amd64"
}

variable "constraint_class" {
  # Set the `NOMAD_VAR_constraint_class` environment variable to override the
  # default node class constraint for the task.
  type    = string
  default = "builder"
}

variable "cpu" {
  # Set the `NOMAD_VAR_cpu` environment variable to override the
  # default cpu for the task.
  type    = number
  default = 8000
}

variable "memory" {
  # Set the `NOMAD_VAR_memory` environment variable to override the
  # default memory for the task.
  type    = number
  default = 8192
}