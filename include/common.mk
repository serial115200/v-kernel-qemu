# Common download function for all components
# Parameters:
#   $(1) - Download URL
#   $(2) - Target file path
#   $(3) - Expected SHA256 checksum
#   $(4) - Component name
define do_download
	@retry_count=0; \
	while [ $$retry_count -lt 3 ]; do \
		retry_count=$$((retry_count + 1)); \
		\
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
		\
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
		\
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
		mkdir -p $(2); \
		tar -xf $(1) -C $(2) --strip-components=1; \
	fi
endef

# Common build function for all components
# Parameters:
#   $(1) - Source directory
#   $(2) - Build directory
#   $(3) - Config file path
#   $(4) - Component version
#   $(5) - Component name
define do_build
	@echo "Building $(5) $(4)..."
	@mkdir -p $(2)
	@if [ -f $(3) ]; then \
		cp $(3) $(2)/.config; \
	else \
		cd $(1) && make defconfig O=$(CURDIR)/$(2); \
	fi
	@cd $(1) && make -j$(JOBS) CROSS_COMPILE=$(CROSS_COMPILE) O=$(CURDIR)/$(2)
endef

# Common menuconfig function for all components
# Parameters:
#   $(1) - Source directory
#   $(2) - Build directory
#   $(3) - Config file path
#   $(4) - Component name
define do_menuconfig
	@mkdir -p $(2)
	@if [ -f $(3) ]; then \
		cp $(3) $(2)/.config; \
	fi
	@cd $(1) && make menuconfig O=$(CURDIR)/$(2)
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
#   $(1) - Source directory
#   $(2) - Build directory
#   $(3) - Config file path
#   $(4) - Component name
define do_loadconfig
	@mkdir -p $(2)
	@if [ -f $(3) ]; then \
		cp $(3) $(2)/.config; \
		echo "Loaded $(4) config from $(3)"; \
	else \
		cd $(1) && make defconfig O=$(CURDIR)/$(2); \
		echo "Created default $(4) config"; \
	fi
endef
