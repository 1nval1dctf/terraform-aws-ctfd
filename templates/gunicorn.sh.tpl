#!/bin/sh

export DATABASE_URL=${DATABASE_URL}
export REDIS_URL=${REDIS_URL}
export SECRET_KEY="${SECRET_KEY}"
export UPLOAD_PROVIDER="s3"
export AWS_S3_BUCKET=${CHALLENGE_BUCKET}
export LOG_FOLDER=${LOG_DIR}

# Start CTFd
echo "Starting CTFd"
exec gunicorn 'CTFd:create_app()' \
--bind '0.0.0.0:8080' \
--workers ${WORKERS} \
--worker-tmp-dir "${WORKER_TEMP_DIR}" \
--worker-class "${WORKER_CLASS}" \
--worker-connections ${WORKER_CONNECTIONS} \
--access-logfile "${ACCESS_LOG}" \
--error-logfile "${ERROR_LOG}"
