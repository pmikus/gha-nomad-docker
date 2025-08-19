variable "IMAGE_REPOSITORY" {
    default = "pmikus/nomad-gha-runner"
}

group "default" {
    targets = [
      "latest",
      "gha"
    ]
}

group "all" {
    targets = [
      "latest",
      "gha"
    ]
}

target "latest" {
    dockerfile = "Dockerfile"
    tags = [
      "${IMAGE_REPOSITORY}:latest"
    ]
    platforms = [
      "linux/amd64",
      "linux/aarch64"
    ]
    args = {
        BASE_IMAGE = "ghcr.io/actions/actions-runner:latest"
    }
}

target "gha" {
    dockerfile = "Dockerfile"
    tags = [
      "${IMAGE_REPOSITORY}:2.328.0"
    ]
    platforms = [
      "linux/amd64",
      "linux/aarch64"
    ]
    args = {
        BASE_IMAGE = "ghcr.io/actions/actions-runner:2.328.0"
    }
}
