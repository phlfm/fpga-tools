#-----------------------------------------------------------------
# Makefile for building fpga/vivado Docker image
#-----------------------------------------------------------------

export USER_ID=$(shell id -u)
export GROUP_ID=$(shell id -g)

# Configure Xilinx Tool Versions
export XILINX_VERSION=2025.1
export VIVADO_BUILD_NUMBER=0530_0145
export PETA_BUILD_NUMBER=05180714
export UNIFIED_INSTALL_PACKAGE=FPGAs_AdaptiveSoCs_Unified_SDI_$(XILINX_VERSION)_$(VIVADO_BUILD_NUMBER)_Lin64
export SETUP_EXECUTABLE=temp/xsetup
export GENERATE_AUTH_SCRIPT=temp/generate_auth_token.sh
# export PETALINUX_INSTALL_PACKAGE=vivado/petalinux-v$(XILINX_VERSION)-${PETA_BUILD_NUMBER}-installer

# Optionally set to "true" to enable debug output
export DEBUG_DOCKER?=true
# Optionally set to "--progress=plain" to help debug docker build process
export PROGRESS_DEBUG?=--progress=plain

$(UNIFIED_INSTALL_PACKAGE).bin:
	@echo ""
	@echo Please download $@ from Xilinx site.
	@echo ""
	@echo The file should be put here: $(PWD)/$@
	@echo ""
	@exit 1

$(GENERATE_AUTH_SCRIPT):
	@mkdir -p temp
	@echo ""
	@echo Please...
	@echo 1. copy the layer1-xilinx/generate_auth_token.sh to ./temp
	@echo 2. fill in the email and password
	@echo 3. run make again
	@echo ""
	@exit 1

# Do NOT make the "generate_auth_script" readable to all to avoid credential leak
$(SETUP_EXECUTABLE): $(UNIFIED_INSTALL_PACKAGE).bin $(GENERATE_AUTH_SCRIPT)
	mkdir -p temp
	chmod +x $(GENERATE_AUTH_SCRIPT)
	# First extraction: unpack the self-extracting shell archive
	7z x $(UNIFIED_INSTALL_PACKAGE).bin -otemp
	# Second extraction: unpack the actual installer payload (typically a tar or 7z archive)
	7z x temp/$(UNIFIED_INSTALL_PACKAGE) -otemp
	rm temp/$(UNIFIED_INSTALL_PACKAGE)
	# Make the installer executable
	chmod a+rx $(SETUP_EXECUTABLE)
	chmod a+rx temp/installLibs.sh
	touch $(SETUP_EXECUTABLE)
	# Copy config files into the install directory
	cp layer1-xilinx/install_config_1_vitis.txt temp/
	cp layer1-xilinx/install_config_9_petalinux_1_all_arch.txt temp/
	sed -i 's|\$HOME|/home/${USER_NAME}|g' temp/install_config_9_petalinux_1_all_arch.txt

# DOCKER_BUILDKIT=1 avoids error "the --mount option requires BuildKit"
image_base: layer0-base/Dockerfile-base
	DOCKER_BUILDKIT=1 docker-compose build $(PROGRESS_DEBUG) base-u24
	touch layer0-base/Dockerfile-base

image_xilinx: $(SETUP_EXECUTABLE) layer1-xilinx/Dockerfile-xilinx-1-dependencies layer1-xilinx/Dockerfile-xilinx-2-petalinux layer1-xilinx/Dockerfile-xilinx-3-vitis-unified
	DOCKER_BUILDKIT=1 docker-compose build $(PROGRESS_DEBUG) xilinx-1-dependencies
	DOCKER_BUILDKIT=1 docker-compose build $(PROGRESS_DEBUG) xilinx-2-petalinux
	DOCKER_BUILDKIT=1 docker-compose build $(PROGRESS_DEBUG) xilinx-3-vitis-unified
	touch layer1-xilinx/Dockerfile-xilinx

# Attach to local image
attach_base:
	docker-compose run --rm base-u24

attach_xilinx:
	docker-compose run --rm xilinx-3-vitis-unified
