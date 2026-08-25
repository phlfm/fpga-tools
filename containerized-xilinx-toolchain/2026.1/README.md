# Toolchain Version 2025.1

## Building the Container

**Note on Vivado/Vitis installation:**
Running the Xilinx `xsetup` installer inside the docker/podman build can fail
with disk space errors even with hundreds of GB free, even after configuring
all the temp directories, overlay and cache locations, etc. plus the commit
stage takes hours and hours, plus the 2 hour wait for the toolchain download
and install.
To avoid all of this, Vivado/Vitis is installed directly on the host at
`/tools/Xilinx` - not by running `xsetup` on the bare host, but through the
`xilinx-dependencies` container itself (via `make install_vivado`), with
`/tools/Xilinx` bind-mounted read-write to `/tools/Xilinx` inside the
container. This writes the install straight through to host disk (never
touching the container's build layer) while guaranteeing the installer runs
against the exact same OS/libraries the runtime container has. The image
itself only ever contains the OS and the required libraries; at runtime the
host's `/tools/Xilinx` is bind-mounted back in, read-write, at
`/tools/Xilinx` (see [compose.yml](compose.yml)).

The host install directory is hardcoded to `/tools/Xilinx` (see
`XILINX_INSTALL_DIR` in the [Makefile](Makefile)). If you need it somewhere
else, grep the repo for `XILINX_INSTALL_DIR` and update it there.

**1. Build the base image:**
run `make image_base`

**2. Download webinstaller:**
run `make image_xilinx` and download the webinstaller it is requesting

**3. Configure the build:**
Use a text editor to select your desired products and part numbers in the
following files:
  - [Vitis and Vivado configuration](layer1-xilinx/install_config_1_vitis.txt)

**4. Prepare the build environment:**
run `make image_xilinx` again. This will create a temp directory for the
installer files and extract/copy files into it.

**5. Provide authentication:**
copy the `generate_auth_token.sh` script to the newly created temp directory
and edit the file to include your Xilinx account credentials.

**6. Build the image:**
run `make image_xilinx` again. This builds the `xilinx-dependencies` image,
which only installs the OS and required libraries - it does not install
Vivado/Vitis.

**7. Install Vivado/Vitis onto the host:**
run `make install_vivado`. This runs the installer through the
`xilinx-dependencies` image with `/tools/Xilinx` mounted read-write at
`/tools/Xilinx`, so Vivado/Vitis ends up installed on the host, not in the
image.

**Warning:**
The install can still take a while and require significant disk space,
potentially exceeding 200 GB, depending on the products and devices you
selected in the configuration file.

**Note on the install directory:**
The Makefile does not create or `chown` the install directory for you - it
only checks it and tells you what to run. Before `make image_xilinx` /
`make install_vivado` / `make attach_xilinx` will proceed, the directory
`/tools/Xilinx` (hardcoded as `XILINX_INSTALL_DIR` in the
[Makefile](Makefile)) must already exist, and for `make install_vivado`
specifically it must also be writable by your user, e.g.:
```
sudo mkdir -p /tools/Xilinx
sudo chown $(id -u):$(id -g) /tools/Xilinx
```

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
`USER_ID=$(id -u) GROUP_ID=$(id -g) XILINX_VERSION=2026.1 DEBUG_DOCKER=false docker-compose -f <PATH_TO_THIS_DIR>/compose.yml run --rm xilinx-dependencies`

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

- **Vivado/Vitis Toolchain:**
The volume mount `/tools/Xilinx:/tools/Xilinx` makes the host-installed
toolchain available inside the container without it needing to be installed
in the image itself. It's mounted read-write so that `make install_vivado`
can also write the toolchain onto the host through this same mount.
