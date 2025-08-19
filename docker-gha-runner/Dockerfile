ARG BASE_IMAGE
FROM ${BASE_IMAGE:-python:3.12-slim-trixie}

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER runner
ENTRYPOINT ["/entrypoint.sh"]