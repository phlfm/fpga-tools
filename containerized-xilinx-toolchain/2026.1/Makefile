#-----------------------------------------------------------------
# Makefile for building fpga/vivado Docker image
#-----------------------------------------------------------------

export USER_ID=$(shell id -u)
export GROUP_ID=$(shell id -g)

# Configure Xilinx Tool Versions
export XILINX_VERSION=2026.1
export VIVADO_BUILD_NUMBER=0616_1700
export UNIFIED_INSTALL_PACKAGE=FPGAs_AdaptiveSoCs_Unified_SDI_$(XILINX_VERSION)_$(VIVADO_BUILD_NUMBER)_Lin64
export SETUP_EXECUTABLE=temp/xsetup
export TEMP_FLAG=temp/flag
export GENERATE_AUTH_SCRIPT=temp/generate_auth_token.sh

# Optionally set to "true" to enable debug output
export DEBUG_DOCKER?=true
# Optionally set to "--progress=plain" to help debug docker build process
# export PROGRESS_DEBUG?=--progress=plain

export COMPOSE_FILE ?= -f compose.yml
# Container compose commands - DOCKER
# export CONTAINER_COMPOSE_BUILD ?= DOCKER_BUILDKIT=1 docker-compose $(COMPOSE_FILE) build
# export CONTAINER_COMPOSE_RUN   ?= docker-compose $(COMPOSE_FILE) run --rm
# Container compose commands - PODMAN
export CONTAINER_COMPOSE_BUILD ?= podman compose $(COMPOSE_FILE) build
export CONTAINER_COMPOSE_RUN   ?= podman compose $(COMPOSE_FILE) run --rm

$(UNIFIED_INSTALL_PACKAGE).bin:
	@echo ""
	@echo Please download $@ from Xilinx site.
	@echo ""
	@echo The file should be put here: $(PWD)/$@
	@echo ""
	@exit 1

$(TEMP_FLAG):
	@mkdir -p temp
	@echo ""
	@echo Please...
	@echo 1. copy the layer1-xilinx/generate_auth_token.sh to ./temp
	@echo 2. fill in the email and password
	@echo 3. run make again
	@echo ""
	@touch $(TEMP_FLAG)
	@exit 1

# Do NOT make the "generate_auth_script" readable to all to avoid credential leak
$(SETUP_EXECUTABLE): $(UNIFIED_INSTALL_PACKAGE).bin $(TEMP_FLAG)
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

image_base: layer0-base/Dockerfile-base
	$(CONTAINER_COMPOSE_BUILD) $(PROGRESS_DEBUG) base-u24
	touch layer0-base/Dockerfile-base

image_xilinx: $(SETUP_EXECUTABLE) layer1-xilinx/Dockerfile-xilinx-1-dependencies layer1-xilinx/Dockerfile-xilinx-3-vitis-unified
	$(CONTAINER_COMPOSE_BUILD) $(PROGRESS_DEBUG) xilinx-1-dependencies
	$(CONTAINER_COMPOSE_BUILD) $(PROGRESS_DEBUG) xilinx-3-vitis-unified
	touch layer1-xilinx/Dockerfile-xilinx

# Attach to local image
attach_base:
	$(CONTAINER_COMPOSE_RUN) base-u24

attach_xilinx:
	$(CONTAINER_COMPOSE_RUN) xilinx-3-vitis-unified
