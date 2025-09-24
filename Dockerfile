FROM smallstep/step-cli:latest

USER root

# Environment variables for production
ENV STEPPATH=/var/local/step
ENV STEP_ROOT="${STEPPATH}/root_ca.crt"
ENV SITECRT="${STEPPATH}/site.crt"
ENV SITEKEY="${STEPPATH}/site.key"
ENV STEP_RENEW_PERIOD="12h"
ENV STEP_CA_URL="https://acme-v02.api.letsencrypt.org/directory"
ENV STEP_EMAIL=""
ENV STEP_DOMAIN=""
ENV STEP_SANS=""

# Copy entrypoint script
COPY ./docker-entrypoint.sh /docker-entrypoint.sh

# Create directories with strict permissions and install dependencies
RUN mkdir -p ${STEPPATH} && \
    chown -R step:step ${STEPPATH} && \
    chmod 700 ${STEPPATH} && \
    chmod +x /docker-entrypoint.sh && \
    # Install curl for healthcheck and debugging
    apt-get update && apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR ${STEPPATH}

ENTRYPOINT ["/docker-entrypoint.sh"]

USER step

# Default command: Renew certs in daemon mode
CMD step ca renew --daemon \
    --renew-period "${STEP_RENEW_PERIOD}" \
    --ca-url "${STEP_CA_URL}" \
    --email "${STEP_EMAIL}" \
    "${SITECRT}" \
    "${SITEKEY}"
