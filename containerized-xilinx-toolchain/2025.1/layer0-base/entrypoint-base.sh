#!/bin/bash -e

# Docker entry-point script to:
# 1. add local user inside the container
# 2. sudo into the newly created user

set -m # Enable job control

if [ "${DEBUG_DOCKER}" == "true" ]; then
    set -x
    env
    echo "USER_NAME: ${USER_NAME}"
    echo "HOME: ${HOME}"
    echo "PWD: ${PWD}"
fi

USER_ID=${USER_ID:-9001}
USER_NAME=${USER_NAME:-dev}
GROUP_ID=${GROUP_ID:-9001}

# Have to set HOME even if the su manual states that HOME is reset
export HOME=/home/${USER_NAME}
export PWD=$(pwd)

BASHRC=${HOME}/.bashrc

function create_user() {
    # Create user inside container.
    /usr/sbin/groupadd --gid ${GROUP_ID} ${USER_NAME}
    /usr/sbin/useradd --shell /bin/bash -u ${USER_ID} -g ${GROUP_ID} --groups sudo -m ${USER_NAME} > /dev/null 2>&1

    echo "if [ \"\${DEBUG_DOCKER}\" == \"true\" ]; then echo 'Running .bashrc ...'; fi" >> ${BASHRC}

    # Remove notice about sudo
    touch ${HOME}/.sudo_as_admin_successful

    chown -R ${USER_ID}:${GROUP_ID} ${BASHRC}

    # Remove user password for sudo.
    echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

}

function run_command {
    EXEC="exec sudo -u ${USER_NAME} -E"
    if [ "${DEBUG_DOCKER}" == "true" ]; then
        echo "Running command as ${USER_NAME}: ${*}"
    fi
    if [ -n "${*}" ]; then
        ${EXEC} bash -c "${*}"
    else
        ${EXEC} bash -i
    fi
}

function run_command {
    CMD=(sudo -u "${USER_NAME}" -E)

    # If arguments are provided, run them as a command
    # Otherwise, start an interactive shell
    if [ -n "${*}" ]; then
        CMD+=("bash" "-c" "${*}")
    else
        CMD+=("bash" "-i")
    fi

    # Echo the full command when debugging is enabled
    if [ "${DEBUG_DOCKER}" == "true" ]; then
        echo "Running command as ${USER_NAME}: ${CMD[*]}"
    fi

    # Replace current shell with the target command
    exec "${CMD[@]}"
}

# Source all dynamic entrypoint scripts
# Instead of having all functionality in one script the different
function source_functions() {
    ENTRYPOINT_DIR=/etc/entrypoint
    if [ -d "${ENTRYPOINT_DIR}" ]; then
       FUNCS=$(ls /etc/entrypoint/*.sh)
       for ENTRY in ${FUNCS}; do
          if [ "${DEBUG_DOCKER}" == "true" ]; then
              echo "Entrypoint source: ${ENTRY}"
          fi
          source ${ENTRY}
       done
    fi
}

create_user
source_functions
run_command "${*}"
