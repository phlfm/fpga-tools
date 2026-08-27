# Toolchain Version 2026.1

## Strategy

Vivado/Vitis is installed on the host, not inside the container image.

Running the Xilinx `xsetup` installer inside a docker/podman build fails with
disk space errors even with 500+ GB free, and takes over 2 hours to reach
that failure. That makes the image impossible to debug and iterate on.

So the image only contains the OS and required libraries. Vivado/Vitis is
installed and run from `/tools/Xilinx` on the host, using the
`xilinx-dependencies` container only to guarantee the installer/tools run
against the exact OS/libs they expect (see [compose.yml](compose.yml)).

This is not the ideal setup - Vivado inside the container would be
preferable - but it is not currently viable given the above.

## Building the Container

Install dir is hardcoded to `/tools/Xilinx` (`XILINX_INSTALL_DIR` in the
[Makefile](Makefile)). Change it there if you need a different path.

`/tools/Xilinx` must exist before `make image_xilinx`, `make install_vivado`,
or `make attach_xilinx`, and must be writable by your user for
`make install_vivado`:
```
sudo mkdir -p /tools/Xilinx
sudo chown $(id -u):$(id -g) /tools/Xilinx
```

**1.** `make image_base` - builds the base image.

**2.** `make image_xilinx` - prompts you to download the Xilinx webinstaller.

**3.** Edit
[install_config_1_vitis.txt](layer1-xilinx/install_config_1_vitis.txt) to
select the products/devices you want.

**4.** `make image_xilinx` - extracts the installer into `temp/`.

**5.** Copy `generate_auth_token.sh` into `temp/` and fill in your Xilinx
credentials.

**6.** `make image_xilinx` - builds the `xilinx-dependencies` image (OS +
libs only, no Vivado/Vitis).

**7.** `make install_vivado` - installs Vivado/Vitis onto the host at
`/tools/Xilinx`, running the installer through the `xilinx-dependencies`
container with `/tools/Xilinx` mounted read-write.

Step 7 can take a while and use 200+ GB, depending on the products/devices
selected.

## Using the Container

- From this directory: `make attach_xilinx`
- From another directory, replacing `<PATH_TO_THIS_DIR>`:
`USER_ID=$(id -u) GROUP_ID=$(id -g) XILINX_VERSION=2026.1 DEBUG_DOCKER=false podman compose -f <PATH_TO_THIS_DIR>/compose.yml run --rm xilinx-dependencies`

On start you'll see the toolchain version and the `activate_*` aliases
available for the tool environments (CLI and GUI).

## Extended Variant

`EXTENDED_SUFFIX=_extended` builds `xilinx-dependencies` on top of
`localhost/fpga_dev` (AI CLIs + HDL sim tools, from `~/work/containers`)
instead of this repo's own `base-u24`, so one container has Vivado/Vitis,
the FPGA sim tools, and the AI CLIs.

Prerequisites:
- `localhost/fpga_dev` already built (see
  `~/work/containers/environment_fpga_run.composefile`).
- Its baked-in `dev` user is UID/GID 1000:1000; your host user must match.

Usage: prefix any target with `EXTENDED_SUFFIX=_extended`, e.g.
`EXTENDED_SUFFIX=_extended make image_xilinx` and
`EXTENDED_SUFFIX=_extended make attach_xilinx`. This uses
[extended_compose.yml](extended_compose.yml) and its own build marker, so it
won't collide with or force a rebuild of the standalone variant.

## Shared Resources

See [compose.yml](compose.yml).

- `$DISPLAY` + `/tmp/.X11-unix` - GUI support.
- `/run/dbus/system_bus_socket` - JTAG / Vivado Hardware Manager.
- `${PWD}:${PWD}` - workspace; run the container from any directory.
- `/tools/Xilinx:/tools/Xilinx` - host-installed toolchain, mounted
read-write so `make install_vivado` can also write through it.
