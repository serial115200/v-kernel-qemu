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

# Extract U-Boot source code to source directory (for code reading)
uboot-src: uboot-dl
	$(call do_extract,$(UBOOT_ARCHIVE),$(UBOOT_SOURCE_DIR),U-Boot)

# Extract U-Boot source code to build directory
uboot-ex: uboot-dl
	$(call do_extract,$(UBOOT_ARCHIVE),$(UBOOT_BUILD_DIR),U-Boot)

# Build U-Boot
uboot: uboot-ex
	@echo "Building U-Boot $(UBOOT_VERSION)..."
	@if [ -f $(UBOOT_BUILD_DIR)/.config ]; then \
		echo "Using existing config in build directory"; \
	elif [ -f $(UBOOT_CONFIG) ]; then \
		echo "Using config from $(UBOOT_CONFIG)"; \
		cp $(UBOOT_CONFIG) $(UBOOT_BUILD_DIR)/.config; \
	else \
		echo "Using default config"; \
		cd $(UBOOT_BUILD_DIR) && make defconfig CROSS_COMPILE=$(CROSS_COMPILE) ARCH=x86; \
	fi
	@if [ "$(V)" = "s" ]; then \
		cd $(UBOOT_BUILD_DIR) && make -j$(JOBS) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=x86 all; \
	else \
		cd $(UBOOT_BUILD_DIR) && make -j$(JOBS) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=x86 all >/dev/null 2>&1; \
	fi

# Configure U-Boot using menuconfig
uboot-menu: uboot-ex
	$(call do_menuconfig,$(UBOOT_BUILD_DIR),$(UBOOT_CONFIG),U-Boot)

# Save current U-Boot configuration
uboot-save: uboot-ex
	$(call do_saveconfig,$(UBOOT_BUILD_DIR),$(UBOOT_CONFIG),U-Boot)

# Clean U-Boot source and build directories
uboot-clean:
	@echo "Cleaning U-Boot..."
	@rm -rf $(UBOOT_BUILD_DIR)
