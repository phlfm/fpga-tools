#!/bin/bash -e

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

XILINX_VERSION=${XILINX_VERSION}

# Have to set HOME even if the su manual states that HOME is reset
export HOME=/home/${USER_NAME}
export PWD=$(pwd)

BASH_PROFILE=${HOME}/.bash_profile
BASHRC=${HOME}/.bashrc
BASHRC_DONE=${HOME}/.bashrc_done
ACTIVATE_VIVADO=${HOME}/activate_vivado.sh
ACTIVATE_VITIS=${HOME}/activate_vitis.sh
ACTIVATE_PETALINUX=${HOME}/activate_petalinux.sh

# PROFILE=${HOME}/.profile

SETTINGS_PETALINUX="/tools/Xilinx/${XILINX_VERSION}/Petalinux/tool/settings.sh"
SETTINGS_VIVADO="/tools/Xilinx/${XILINX_VERSION}/Vivado/settings64.sh"
SETTINGS_VITIS="/tools/Xilinx/${XILINX_VERSION}/Vitis/settings64.sh"

function setup_vivado() {
    echo "#!/usr/bin/env bash" > ${ACTIVATE_VIVADO}
    echo "echo sourcing ${ACTIVATE_VIVADO} ..." >> ${ACTIVATE_VIVADO}
    # Needed for vivado on docker
    echo "# Reference: https://support.xilinx.com/s/question/0D54U00005Sgst2SAB/failed-batch-mode-execution-in-linux-docker-running-under-windows-host?language=en_US" >> ${ACTIVATE_VIVADO}
    echo "# Reference: https://support.xilinx.com/s/article/000034450?language=en_US" >> ${ACTIVATE_VIVADO}
    echo "export LD_PRELOAD=/lib/x86_64-linux-gnu/libudev.so.1" >> ${ACTIVATE_VIVADO}
    echo "source ${SETTINGS_VIVADO}" >> ${ACTIVATE_VIVADO}
}

function setup_vitis() {
    echo "#!/usr/bin/env bash" > ${ACTIVATE_VITIS}
    echo "echo sourcing ${ACTIVATE_VITIS} ..." >> ${ACTIVATE_VITIS}
    # TODO: apparently now the container has /bin/xlsclients...
    # local XLSCLIENTS="/bin/xlsclients"
    # echo "#!/usr/bin/env bash" >> ${XLSCLIENTS}
    # echo "echo empty file to fix 'ERROR: xlsclients is not available on the system'" >> ${XLSCLIENTS}
    # echo "echo Reference: https://support.xilinx.com/s/question/0D52E00006hpYLESA2/xsct-commandline-with-no-xvfb?language=en_US" >> ${XLSCLIENTS}
    # chmod +x ${XLSCLIENTS}
    echo "source ${SETTINGS_VITIS}" >> ${ACTIVATE_VITIS}
}

function setup_petalinux() {
    echo "#!/usr/bin/env bash" > ${ACTIVATE_PETALINUX}
    echo "echo sourcing ${ACTIVATE_PETALINUX} ..." >> ${ACTIVATE_PETALINUX}
    echo "source ${SETTINGS_PETALINUX}" >> ${ACTIVATE_PETALINUX}
}

function configure_user() {
    touch ${BASHRC}
    if [ ! -f ${BASHRC_DONE} ]; then
        # BACHRC_DONE avoids adding this many times to bashrc
        echo "if [ \"\${DEBUG_DOCKER}\" == \"true\" ]; then echo 'Running .bashrc ...'; fi" >> ${BASHRC}
        echo "alias activate_petalinux='source ${ACTIVATE_PETALINUX}'" >> ${BASHRC}
        echo "alias activate_vivado='source ${ACTIVATE_VIVADO}'" >> ${BASHRC}
        echo "alias activate_vitis='source ${ACTIVATE_VITIS}'" >> ${BASHRC}
        echo "echo " >> ${BASHRC}
        echo "echo '*--------------------------------------------------------*'" >> ${BASHRC}
        echo "echo '| Available environments:               VERSION ${XILINX_VERSION}   |'" >> ${BASHRC}
        echo "echo '|                                                        |'" >> ${BASHRC}
        echo "echo '|    - activate_petalinux                                |'" >> ${BASHRC}
        echo "echo '|    - activate_vivado                                   |'" >> ${BASHRC}
        echo "echo '|    - activate_vitis                                    |'" >> ${BASHRC}
        echo "echo '|                                                        |'" >> ${BASHRC}
        echo "echo '*--------------------------------------------------------*'" >> ${BASHRC}
        echo "echo " >> ${BASHRC}
        echo "" >> ${BASHRC}
        echo "FILE_TO_ACTIVATE='${HOME}/activate_\${ACTIVATE_ENV}.sh'" >> ${BASHRC}
        echo "FILE_TO_ACTIVATE=\$(eval echo \$FILE_TO_ACTIVATE)" >> ${BASHRC}
        echo "if [ -f \${FILE_TO_ACTIVATE} ]; then" >> ${BASHRC}
        echo "    source \${FILE_TO_ACTIVATE}" >> ${BASHRC}
        echo "fi" >> ${BASHRC}
        touch ${BASHRC_DONE}
    fi

    # Remove notice about sudo
    touch ${HOME}/.sudo_as_admin_successful

    # Needed for Petalinux config window
    if [ -n "$(command -v xrdb)" ]; then
        echo "echo 'XTerm.VT100.geometry: 230x60' | xrdb -merge -" >> ${BASHRC}
    fi
    chown -R ${USER_ID}:${GROUP_ID} ${BASHRC}

    # Remove user password for sudo.
    echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

    # Create Xilinx user configuration directory
    mkdir -p ${HOME}/.Xilinx/${XILINX_VERSION}/XilinxTclStore
    chmod 777 -R ${HOME}/.Xilinx

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

configure_user
setup_vivado
setup_vitis
setup_petalinux
source_functions
run_command "${*}"
