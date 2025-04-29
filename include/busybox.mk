# Busybox build configuration and rules
# ====================================

# Define paths and URLs for Busybox
BUSYBOX_SOURCE_DIR := $(SRC_DIR)/busybox-$(BUSYBOX_VERSION)
BUSYBOX_BUILD_DIR := $(BUILD_DIR)/busybox-$(BUSYBOX_VERSION)
BUSYBOX_CONFIG := $(CONFIGS_DIR)/busybox-$(BUSYBOX_VERSION).config
BUSYBOX_ARCHIVE := $(DL_DIR)/busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_URL := https://busybox.net/downloads/busybox-$(BUSYBOX_VERSION).tar.bz2

# Download Busybox source code
busybox-dl:
	$(call do_download,$(BUSYBOX_URL),$(BUSYBOX_ARCHIVE),$(BUSYBOX_SHA256),Busybox)

# Extract Busybox source code to source directory (for code reading)
busybox-src: busybox-dl
	$(call do_extract,$(BUSYBOX_ARCHIVE),$(BUSYBOX_SOURCE_DIR),Busybox)

# Extract Busybox source code to build directory
busybox-ex: busybox-dl
	$(call do_extract,$(BUSYBOX_ARCHIVE),$(BUSYBOX_BUILD_DIR),Busybox)

# Build Busybox
busybox: busybox-ex
	$(call do_build,$(BUSYBOX_BUILD_DIR),$(BUSYBOX_CONFIG),$(BUSYBOX_VERSION),Busybox)

# Configure Busybox using menuconfig
busybox-menu: busybox-ex
	$(call do_menuconfig,$(BUSYBOX_BUILD_DIR),$(BUSYBOX_CONFIG),Busybox)

# Save current Busybox configuration
busybox-save: busybox-ex
	$(call do_saveconfig,$(BUSYBOX_BUILD_DIR),$(BUSYBOX_CONFIG),Busybox)

# Clean Busybox build directory
busybox-clean:
	@echo "Cleaning Busybox..."
	@rm -rf $(BUSYBOX_BUILD_DIR)
