#!/bin/bash
set -euo pipefail

# Set recommended umask of "u=,g=w,o=rwx" (0027)
umask 0027

: ${JAVA_OPTS:=}

: ${ELASTICSEARCH_ENABLED:=false}
: ${APPLICATION_MODE:=}

JAVA_OPTS="${JAVA_OPTS}"

ARGS="$@"

# Start Bitbucket without Elasticsearch
if [ "${ELASTICSEARCH_ENABLED}" == "false" ] || [ "${APPLICATION_MODE}" == "mirror" ]; then
    ARGS="--no-search ${ARGS}"
fi

# Start Bitbucket as the correct user.
if [ "${UID}" -eq 0 ]; then
    echo "User is currently root. Will change directory ownership to ${RUN_USER}:${RUN_GROUP}, then downgrade permission to ${RUN_USER}"
    PERMISSIONS_SIGNATURE=$(stat -c "%u:%U:%a" "${BITBUCKET_HOME}")
    EXPECTED_PERMISSIONS=$(id -u ${RUN_USER}):${RUN_USER}:700
    if [ "${PERMISSIONS_SIGNATURE}" != "${EXPECTED_PERMISSIONS}" ]; then
        echo "Updating permissions for BITBUCKET_HOME"
        mkdir -p "${BITBUCKET_HOME}/lib" &&
            chmod -R 700 "${BITBUCKET_HOME}" &&
            chown -R "${RUN_USER}:${RUN_GROUP}" "${BITBUCKET_HOME}"
    fi
    # Now drop privileges
    exec su -s /bin/bash "${RUN_USER}" -c "${BITBUCKET_INSTALL}/bin/start-bitbucket.sh ${ARGS}"
else
    exec "${BITBUCKET_INSTALL}/bin/start-bitbucket.sh" ${ARGS}
fi
