#!/bin/bash
set -e
set -o pipefail

envShouldHas() {
  if [ "$(printenv $1)" = "**None**" ]; then
    >&2 echo "Environment variable \$$1 should be declared"
    exit 1
  fi
}

log() {
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*"
}

envShouldHas S3_ENDPOINT
envShouldHas S3_BUCKET
envShouldHas S3_ACCESS_KEY_ID
envShouldHas S3_ACCESS_ACCESS_KEY

export AWS_ACCESS_KEY_ID=$S3_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

if [ ! -z "$WEBHOOK_START" ]; then
  curl -fsS -m 10 --retry 5 $WEBHOOK_START \
  && log "Starting webhook sent" \
  ||:
fi

log "Backing up..."
if [ ! -z "$ENCRYPTION_PASSWORD" ]; then
  # It's OK to use GPG's "--passphrase" as we're inside the container
  # where passphrase can also be obtained from environment variables
  tar --create --gzip $TAR_OPTS -O /data \
    | gpg -q --passphrase $ENCRYPTION_PASSWORD --symmetric --batch \
    | aws --endpoint-url ${S3_ENDPOINT} $S3_OPTS s3 cp - s3://$S3_BUCKET/$S3_PATH/$(date -u +"%Y-%m-%dT%H:%M:%SZ").sql.gz.gpg
else
  tar --create --gzip $TAR_OPTS -O /data \
    | aws --endpoint-url ${S3_ENDPOINT} $S3_OPTS s3 cp - s3://$S3_BUCKET/$S3_PATH/$(date -u +"%Y-%m-%dT%H:%M:%SZ").sql.gz || exit 2
fi

log "Success"
if [ ! -z "$WEBHOOK_SUCCESS" ]; then
  curl -fsS -m 10 --retry 5 $WEBHOOK_SUCCESS \
  && log "Success webhook sent" \
  ||:
fi
