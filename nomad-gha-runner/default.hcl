job "gha-runner" {
  datacenters = [var.datacenter]
  type        = "batch"
  node_pool   = var.node_pool
  region      = var.region
  namespace   = var.namespace
  name        = var.name

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
    ephemeral_disk {
      migrate = false
      size    = 3000
      sticky  = false
    }
    restart {
      interval = "30m"
      attempts = 0
      delay    = "15s"
      mode     = "fail"
    }
    task "gha-runner" {
      driver = "docker"
      config {
        image      = var.image
        privileged = true
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/.env"
        env         = true
        data        = <<EOT
{{- with nomadVar "nomad/jobs/" -}}
{{- range $k, $v := . }}
{{ $k }}={{ $v }}
{{- end }}
{{- end }}
EOT
      }
      env {
        RUNNER_LABELS = var.env_runner_labels
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
  # default for the task.
  type    = string
  default = "yul1"
}

variable "node_pool" {
  # Set the `NOMAD_VAR_node_pool` environment variable to override the
  # default for the task.
  type    = string
  default = "default"
}

variable "region" {
  # Set the `NOMAD_VAR_region` environment variable to override the
  # default for the task.
  type    = string
  default = "global"
}

variable "namespace" {
  # Set the `NOMAD_VAR_namespace` environment variable to override the
  # default for the task.
  type    = string
  default = "prod"
}

variable "name" {
  # Set the `NOMAD_VAR_name` environment variable to override the
  # default for the task.
  type    = string
  default = "gha"
}

variable "constraint_arch" {
  # Set the `NOMAD_VAR_constraint_arch` environment variable to override the
  # default for the task.
  type    = string
  default = "amd64"
}

variable "constraint_class" {
  # Set the `NOMAD_VAR_constraint_class` environment variable to override the
  # default for the task.
  type    = string
  default = "builder"
}

variable "cpu" {
  # Set the `NOMAD_VAR_cpu` environment variable to override the
  # default for the task.
  type    = number
  default = 24000
}

variable "image" {
  # Set the `NOMAD_VAR_image` environment variable to override the
  # default for the task.
  type    = string
  default = "pmikus/nomad-gha-runner:latest"
}

variable "memory" {
  # Set the `NOMAD_VAR_memory` environment variable to override the
  # default for the task.
  type    = number
  default = 24000
}

variable "env_runner_labels" {
  # Set the `NOMAD_VAR_env_runner_labels` environment variable to override the
  # default for the task.
  type    = string
  default = "nomad"
}