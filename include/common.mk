# Common download function for all components
# Parameters:
#   $(1) - Download URL
#   $(2) - Target file path
#   $(3) - Expected SHA256 checksum
#   $(4) - Component name
define do_download
	@retry_count=0; \
	mkdir -p $(dir $(2)); \
	while [ $$retry_count -lt 3 ]; do \
		retry_count=$$((retry_count + 1)); \
		if [ -f $(2) ]; then \
			if [ -n "$(3)" ]; then \
				if echo "$(3)  $(2)" | sha256sum -c --quiet; then \
					echo "$(4) archive exists and checksum verified, skipping download..."; \
					break; \
				else \
					echo "$(4) archive exists but checksum mismatch, will retry download..."; \
					rm -f $(2); \
				fi; \
			else \
				echo "$(4) archive exists but no checksum to verify, skipping download..."; \
				break; \
			fi; \
		fi; \
		echo "Downloading $(4) source code (attempt $$retry_count/3)..."; \
		if wget -q $(1) -O $(2); then \
			if [ -n "$(3)" ]; then \
				if echo "$(3)  $(2)" | sha256sum -c --quiet; then \
					echo "$(4) download successful and checksum verified."; \
					break; \
				else \
					echo "$(4) download successful but checksum mismatch."; \
					rm -f $(2); \
				fi; \
			else \
				echo "$(4) download successful."; \
				break; \
			fi; \
		fi; \
		echo "$(4) download failed (attempt $$retry_count/3)."; \
		if [ $$retry_count -lt 3 ]; then \
			echo "Retrying in 5 seconds..."; \
			sleep 5; \
		fi; \
	done; \
	if [ $$retry_count -eq 3 ]; then \
		echo "Failed to download $(4) after 3 attempts."; \
		false; \
	fi
endef

# Common extract function for all components
# Parameters:
#   $(1) - Archive file path
#   $(2) - Target directory
#   $(3) - Component name
define do_extract
	@if [ -d $(2) ]; then \
		echo "$(3) source directory already exists, skipping extraction..."; \
	else \
		echo "Extracting $(3) source code..."; \
		mkdir -p $(dir $(2)); \
		tar -xf $(1) -C $(dir $(2)); \
		if [ ! -d $(2) ]; then \
			echo "Error: Extracted directory structure does not match expected path $(2)"; \
			false; \
		fi; \
	fi
endef

# Common build function for all components
# Parameters:
#   $(1) - Build directory
#   $(2) - Config file path
#   $(3) - Component version
#   $(4) - Component name
define do_build
	@echo "Building $(4) $(3)..."
	@mkdir -p $(1)
	@if [ -f $(1)/.config ]; then \
		echo "Using existing config in build directory"; \
	elif [ -f $(2) ]; then \
		echo "Using config from $(2)"; \
		cp $(2) $(1)/.config; \
	else \
		echo "Using default config"; \
		cd $(1) && make defconfig ARCH=$(ARCH); \
	fi
	@if [ "$(V)" = "s" ]; then \
		cd $(1) && make -j$(JOBS) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=$(ARCH) all; \
	else \
		cd $(1) && make -j$(JOBS) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=$(ARCH) all >/dev/null 2>&1; \
	fi
endef

# Common menuconfig function for all components
# Parameters:
#   $(1) - Build directory
#   $(2) - Config file path
#   $(3) - Component name
define do_menuconfig
	@mkdir -p $(1)
	@if [ -f $(2) ]; then \
		cp $(2) $(1)/.config; \
	fi
	@cd $(1) && make menuconfig
endef

# Common saveconfig function for all components
# Parameters:
#   $(1) - Build directory
#   $(2) - Config file path
#   $(3) - Component name
define do_saveconfig
	@if [ -f $(1)/.config ]; then \
		mkdir -p $(dir $(2)); \
		cp $(1)/.config $(2); \
		echo "Saved $(3) config to $(2)"; \
	else \
		echo "No $(3) config found. Please run 'make $(3)-menuconfig' first."; \
		exit 1; \
	fi
endef

# Common loadconfig function for all components
# Parameters:
#   $(1) - Build directory
#   $(2) - Config file path
#   $(3) - Component name
define do_loadconfig
	@mkdir -p $(1)
	@if [ -f $(2) ]; then \
		cp $(2) $(1)/.config; \
		echo "Loaded $(3) config from $(2)"; \
	else \
		cd $(1) && make defconfig; \
		echo "Created default $(3) config"; \
	fi
endef
