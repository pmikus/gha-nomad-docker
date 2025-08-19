variable "IMAGE_REPOSITORY" {
    default = "pmikus/docker-gha-dispatcher"
}

group "default" {
    targets = [
      "latest"
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
        BASE_IMAGE = "ghcr.io/astral-sh/uv:python3.13-trixie-slim"
    }
}
