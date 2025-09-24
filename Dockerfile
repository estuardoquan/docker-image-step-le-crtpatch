FROM smallstep/step-cli

USER root

ENV STEPPATH=/var/local/step
ENV STEP_RENEW_PERIOD="1m"
ENV STEP_DOMAIN="balraug.com"
ENV STEP_SANS="*.balraug.com"
ENV STEP_EMAIL="estuardo.quan@gmail.com"

ENV SITECRT="${STEPPATH}/site.crt"
ENV SITEKEY="${STEPPATH}/site.key"

RUN mkdir -p ${STEPPATH} && \
    chown -R step:step ${STEPPATH}

WORKDIR ${STEPPATH}

ENTRYPOINT ["/docker-entrypoint.sh"]

USER step

CMD step ca certificate ${STEP_DOMAIN} ${SITECRT} ${SITEKEY} \
    --acme https://acme-staging-v02.api.letsencrypt.org/directory\
    --email ${STEP_EMAIL} \
    --sans localhost \
    --sans ${STEP_SANS}

