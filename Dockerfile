FROM alpine:latest
LABEL maintainer="Dmitry Nourell <hi@imcatwhocode.dev>"

RUN apk update && apk --no-cache add dumb-init gnupg curl bash aws-cli

RUN curl -fsSL https://github.com/odise/go-cron/releases/download/v0.0.7/go-cron-linux.gz > go-cron-linux.gz
RUN echo "d614f811d468a77a57923ebff5643c58c6e10b939358da56024d4098e811a7ee  go-cron-linux.gz" | sha256sum -c
RUN zcat go-cron-linux.gz > /usr/local/bin/go-cron && chmod +x /usr/local/bin/go-cron
RUN rm go-cron-linux.gz

ENV S3_ENDPOINT "**None**"
ENV S3_REGION "us-west-1"
ENV S3_BUCKET "**None**"
ENV S3_PATH "backup"
ENV S3_KEY_ID "**None**"
ENV S3_ACCESS_KEY "**None**"
ENV S3_OPTS ""
ENV TAR_OPTS ""

ENV SCHEDULE "**None**"

ENV ENCRYPTION_PASSWORD ""

ENV WEBHOOK_START ""
ENV WEBHOOK_SUCCESS ""

ADD entrypoint.sh .
ADD backup.sh .

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["sh", "entrypoint.sh"]
