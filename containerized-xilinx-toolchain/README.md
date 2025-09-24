# Containerized Xilinx Toolchain

A docker container for Xilinx toolchain (Vivado, petalinux and Vitis AI).

Everything here assumes you are on a Linux system with a working docker
installation and `make` is available.

The container should work to make FPGA builds with Windows WSL2 but maybe not
for JTAG/USB connection to the FPGA as this needs additional configurations and
driver installations on the Windows side of things.

## Adding support to other toolchain versions

Unfortunately, this is **NOT** trivial. Between different versions a lot of
adjustments are needed, such as:

- changes to required packages
- sometimes fixes are needed to the activation procedure
- change of the ubuntu base version might break something

There's a lot of trial and error involved and could take a few days to a few
weeks to have the environment fully functioning for a new version, specially
considering that the build process takes many hours for the newer (2021+)
toolchain versions.
