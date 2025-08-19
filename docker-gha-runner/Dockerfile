ARG BASE_IMAGE
FROM ${BASE_IMAGE:-ghcr.io/actions/actions-runner:latest}

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER runner
ENTRYPOINT ["/entrypoint.sh"]