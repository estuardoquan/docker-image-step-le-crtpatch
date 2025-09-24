FROM smallstep/step-cli

USER root

ENV STEPPATH=/var/local/step
ENV STEP_RENEW_PERIOD="1m"
ENV STEP_DOMAIN="balraug.com"
ENV STEP_SAN="*.balraug.com"
ENV STEP_EMAIL="estuardo.quan@gmail.com"
ENV STEP_LE_ACME=https://acme-staging-v02.api.letsencrypt.org/directory

ENV SITECRT="${STEPPATH}/site.crt"
ENV SITEKEY="${STEPPATH}/site.key"

RUN mkdir -p ${STEPPATH} && \
    chown -R step:step ${STEPPATH}

WORKDIR ${STEPPATH}

USER step

CMD step ca certificate ${STEP_DOMAIN} ${SITECRT} ${SITEKEY} \
    --acme ${STEP_LE_ACME}
