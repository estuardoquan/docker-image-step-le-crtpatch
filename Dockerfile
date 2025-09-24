FROM smallstep/step-cli:latest

USER root

# Environment variables for production
ENV STEPPATH=/var/local/step
ENV STEP_ROOT="${STEPPATH}/root_ca.crt"
ENV SITECRT="${STEPPATH}/site.crt"
ENV SITEKEY="${STEPPATH}/site.key"
ENV STEP_RENEW_PERIOD="12h"  # More frequent checks for production
ENV STEP_CA_URL="https://acme-v02.api.letsencrypt.org/directory"  # Let's Encrypt production
ENV STEP_EMAIL=""  # Required for Let's Encrypt account
ENV STEP_DOMAIN=""  # Primary domain for cert
ENV STEP_SANS=""  # Comma-separated SANs (optional)

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
