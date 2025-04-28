# U-Boot build configuration and rules
# ==================================

# Define paths and URLs for U-Boot
UBOOT_SOURCE_DIR := $(SRC_DIR)/u-boot-$(UBOOT_VERSION)
UBOOT_BUILD_DIR := $(BUILD_DIR)/u-boot-$(UBOOT_VERSION)
UBOOT_CONFIG := $(CONFIGS_DIR)/u-boot-$(UBOOT_VERSION).config
UBOOT_ARCHIVE := $(DL_DIR)/u-boot-$(UBOOT_VERSION).tar.bz2
UBOOT_URL := https://ftp.denx.de/pub/u-boot/u-boot-$(UBOOT_VERSION).tar.bz2

# Download U-Boot source code
uboot-dl:
	$(call do_download,$(UBOOT_URL),$(UBOOT_ARCHIVE),$(UBOOT_SHA256),U-Boot)

# Extract U-Boot source code
uboot-ex: uboot-dl
	$(call do_extract,$(UBOOT_ARCHIVE),$(SRC_DIR),U-Boot)

# Build U-Boot
uboot: uboot-ex
	$(call do_build,$(UBOOT_SOURCE_DIR),$(UBOOT_BUILD_DIR),$(UBOOT_CONFIG),U-Boot)

# Configure U-Boot using menuconfig
uboot-menu: uboot-ex
	$(call do_menuconfig,$(UBOOT_SOURCE_DIR),$(UBOOT_BUILD_DIR),$(UBOOT_CONFIG),U-Boot)

# Save current U-Boot configuration
uboot-save: uboot-ex
	$(call do_saveconfig,$(UBOOT_BUILD_DIR),$(UBOOT_CONFIG),U-Boot)

# Load U-Boot configuration
uboot-load: uboot-ex
	$(call do_loadconfig,$(UBOOT_SOURCE_DIR),$(UBOOT_BUILD_DIR),$(UBOOT_CONFIG),U-Boot)

# Clean U-Boot build directory
uboot-clean:
	@echo "Cleaning U-Boot..."
	@rm -rf $(UBOOT_BUILD_DIR)
