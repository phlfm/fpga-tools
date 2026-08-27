#-----------------------------------------------------------------
# Makefile for building fpga/vivado Docker image
#-----------------------------------------------------------------

# Set "EXTENDED_SUFFIX=_extended" to build xilinx-dependencies on top of
# another image (extending it) instead of this repo's own base-u24.
# Leave unset/empty for the standalone variant.
export EXTENDED_SUFFIX ?=

ifeq ($(strip $(EXTENDED_SUFFIX)),)
export EXTEND_BASE := false
export BASE_IMAGE  := base-u24
export USER_NAME   := $(shell id -un)
export USER_ID     := $(shell id -u)
export GROUP_ID    := $(shell id -g)
export COMPOSE_FILE ?= -f compose.yml
else
# If extending, change your base image here
export EXTEND_BASE := true
export BASE_IMAGE  := localhost/fpga_dev
export USER_NAME   := dev
export USER_ID     := 1000
export GROUP_ID    := 1000
export COMPOSE_FILE ?= -f extended_compose.yml
endif

# Marker is suffixed so toggling EXTENDED_SUFFIX always forces its own
# rebuild instead of reusing a stale marker left by the other variant.
export XILINX_MARKER := .done_image_xilinx$(EXTENDED_SUFFIX)

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

# Host directory where Vivado/Vitis gets installed. Hardcoded - if you need
# a different location, grep this repo for XILINX_INSTALL_DIR and update it
# there.
export XILINX_INSTALL_DIR := /tools/Xilinx

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

.PHONY: image_base
image_base: .done_image_base

.done_image_base: layer0-base/Dockerfile-base
	$(CONTAINER_COMPOSE_BUILD) $(PROGRESS_DEBUG) base-u24
	touch layer0-base/Dockerfile-base
	touch .done_image_base

.PHONY: image_xilinx
image_xilinx: $(XILINX_MARKER)

XILINX_MARKER_DEPS := $(SETUP_EXECUTABLE) layer1-xilinx/Dockerfile-xilinx-dependencies check_xilinx_install_dir_exists
ifeq ($(EXTEND_BASE),false)
# Not extending an external base: build on top of this repo's own base-u24.
XILINX_MARKER_DEPS += .done_image_base
endif

$(XILINX_MARKER): $(XILINX_MARKER_DEPS)
	$(CONTAINER_COMPOSE_BUILD) $(PROGRESS_DEBUG) xilinx-dependencies
	touch layer1-xilinx/Dockerfile-xilinx-dependencies
	touch $(XILINX_MARKER)

# Install Vivado/Vitis onto the host at $(XILINX_INSTALL_DIR) by running the
# installer through the xilinx-dependencies service (which always mounts
# $(XILINX_INSTALL_DIR) read-write at /tools/Xilinx - see compose.yml).
# Requires generate_auth_token.sh to be filled in (see the $(TEMP_FLAG) rule
# above).
#
# NOTE: the entrypoint's run_command() rebuilds the command by joining "$@"
# with spaces and re-wrapping it in a single `bash -c`, which mangles nested
# quoting (e.g. a self-authored "bash -c '...'" here). So this must be a
# flat list of shell words/operators (not pre-wrapped in bash -c) for the
# entrypoint's own wrapping to reconstruct correctly.
#
# The chown is mostly a safety net: with userns_mode: keep-id,
# $(XILINX_INSTALL_DIR) should already be owned by the invoking host user
# (see check_xilinx_install_dir_writable below), so this is a no-op unless
# that check was somehow bypassed.
install_vivado: image_xilinx check_xilinx_install_dir_writable
	$(CONTAINER_COMPOSE_RUN) --workdir $(PWD)/temp xilinx-dependencies \
		sudo chown $(USER_ID):$(GROUP_ID) /tools/Xilinx '&&' \
		./generate_auth_token.sh '&&' \
		./xsetup --agree XilinxEULA,3rdPartyEULA --batch Install --config ./install_config_1_vitis.txt '&&' \
		rm -f $(HOME)/.Xilinx/wi_authentication_key

# Inform (don't fix): the toolchain install directory is expected to already
# exist and be owned by the calling user. We never sudo/mkdir on the user's
# behalf here - just point them at what to run.
check_xilinx_install_dir_exists:
	@if [ ! -d "$(XILINX_INSTALL_DIR)" ]; then \
		echo ""; \
		echo "The configured Xilinx install directory does not exist:"; \
		echo "  $(XILINX_INSTALL_DIR)"; \
		echo ""; \
		echo "Please create it, e.g.:"; \
		echo "  sudo mkdir -p $(XILINX_INSTALL_DIR)"; \
		echo "  sudo chown $(USER_ID):$(GROUP_ID) $(XILINX_INSTALL_DIR)"; \
		echo ""; \
		exit 1; \
	fi

check_xilinx_install_dir_writable: check_xilinx_install_dir_exists
	@if ! touch "$(XILINX_INSTALL_DIR)/.write_test" 2>/dev/null; then \
		echo ""; \
		echo "The configured Xilinx install directory exists but is not writable"; \
		echo "by $$(id -un):"; \
		echo "  $(XILINX_INSTALL_DIR)"; \
		echo ""; \
		echo "Please fix its ownership/permissions, e.g.:"; \
		echo "  sudo chown $(USER_ID):$(GROUP_ID) $(XILINX_INSTALL_DIR)"; \
		echo "or:"; \
		echo "  sudo chmod 777 $(XILINX_INSTALL_DIR)"; \
		echo ""; \
		exit 1; \
	fi
	@rm -f "$(XILINX_INSTALL_DIR)/.write_test"
