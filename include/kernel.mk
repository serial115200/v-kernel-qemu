# Linux kernel build configuration and rules
# =======================================

# Define paths and URLs for Linux kernel
KERNEL_SOURCE_DIR := $(SRC_DIR)/linux-$(KERNEL_VERSION)
KERNEL_BUILD_DIR := $(BUILD_DIR)/linux-$(KERNEL_VERSION)
KERNEL_CONFIG := $(CONFIGS_DIR)/linux-$(KERNEL_VERSION).config
KERNEL_ARCHIVE := $(DL_DIR)/linux-$(KERNEL_VERSION).tar.xz
KERNEL_URL := https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(KERNEL_VERSION).tar.xz

# Download Linux kernel source code
kernel-dl:
	$(call do_download,$(KERNEL_URL),$(KERNEL_ARCHIVE),$(KERNEL_SHA256),Kernel)

# Extract Linux kernel source code to source directory (for code reading)
kernel-src: kernel-dl
	$(call do_extract,$(KERNEL_ARCHIVE),$(KERNEL_SOURCE_DIR),Kernel)

# Extract Linux kernel source code to build directory
kernel-ex: kernel-dl
	$(call do_extract,$(KERNEL_ARCHIVE),$(KERNEL_BUILD_DIR),Kernel)

# Build Linux kernel
kernel: kernel-ex
	$(call do_build,$(KERNEL_BUILD_DIR),$(KERNEL_CONFIG),$(KERNEL_VERSION),Kernel)

# Configure Linux kernel using menuconfig
kernel-menu: kernel-ex
	$(call do_menuconfig,$(KERNEL_BUILD_DIR),$(KERNEL_CONFIG),Kernel)

# Save current Linux kernel configuration
kernel-save: kernel-ex
	$(call do_saveconfig,$(KERNEL_BUILD_DIR),$(KERNEL_CONFIG),Kernel)

# Clean Linux kernel build directory
kernel-clean:
	@echo "Cleaning Kernel..."
	@rm -rf $(KERNEL_BUILD_DIR)
