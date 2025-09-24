# Toolchain Version 2025.1

## Building the Container

**1. Build the base image:**
run `make image_base`

**2. Download webinstaller:**
run `make image_xilinx` and download the webinstaller it is requesting

**3. Configure the build:**
Use a text editor to select your desired products and part numbers in the
following files:
  - [Vitis and Vivado configuration](layer1-xilinx/install_config_1_vitis.txt)
  - [Petalinux configuration](layer1-xilinx/install_config_9_petalinux_1_all_arch.txt)

**4. Prepare the build environment:**
run `make image_xilinx` again. This will create a temp directory for the
installer files and extract/copy files into it.

**5. Provide authentication:**
copy the `generate_auth_token.sh` script to the newly created temp directory
and edit the file to include your Xilinx account credentials.

**6. Start the build:**
run `make image_xilinx` again. The build process will now begin.

**Warning:**
The build can take several hours and requires significant disk space,
potentially exceeding 200 GB. The final size depends on the products and
devices you selected in the configuration files.

## Using the Container

There are two primary ways to start the container:

**1. Start from this directory:**
to launch the container with the correct settings from the project's root
directory, run:
`make attach_xilinx`

**2. Start from another directory:**
if you want to start the container from a different directory, use the
following command, replacing `<PATH_TO_THIS_DIR>` with the absolute path to
this project folder:

`USER_ID=$(id -u) GROUP_ID=$(id -g) XILINX_VERSION=2025.1 DEBUG_DOCKER=false docker-compose -f <PATH_TO_THIS_DIR>/docker-compose.yml run --rm xilinx-3-vitis-unified`

Once the container is running, you will see a welcome message displaying the
toolchain version and the aliases available to activate the tool environments.
From there, you can use the Xilinx tools via both the command line (CLI) and
their graphical interfaces (GUI).

## Container shared resources

This container is already configured to work with Xilinx tools, including
graphical user interfaces (GUIs) and hardware manager support. It does this
by sharing key system resources listed in the
[docker compose file](docker-compose.yml)

Here is a breakdown of the resources being shared:

- **GUI Support:**
The container shares your `$DISPLAY` system variable and mounts
`/tmp/.X11-unix` so that you can run Xilinx tools with a graphical
interface.

- **Hardware Manager:**
The volume mount `/run/dbus/system_bus_socket` is necessary to use JTAG via
the Vivado Hardware Manager.

- **Workspace:**
The volume mount `${PWD}:${PWD}` allows you to start the container from any
directory on your local machine and work on your projects directly from there.
