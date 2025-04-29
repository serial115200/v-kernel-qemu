# Linux kernel build configuration and rules
# =======================================

# Define paths and URLs for Linux kernel
KERNEL_SOURCE_DIR := $(SRC_DIR)/linux-$(KERNEL_VERSION)
KERNEL_BUILD_DIR := $(BUILD_DIR)/linux-$(KERNEL_VERSION)
KERNEL_CONFIG := $(CONFIGS_DIR)/linux-$(KERNEL_VERSION).config
KERNEL_ARCHIVE := $(DL_DIR)/linux-$(KERNEL_VERSION).tar.xz

# Mirror configuration
# Available options:
#   official - Official source (cdn.kernel.org)
#   tsinghua - Tsinghua University mirror
#   ustc    - University of Science and Technology of China mirror
#   aliyun  - Alibaba Cloud mirror
KERNEL_MIRROR ?= tsinghua

# Define mirror URLs
KERNEL_MIRROR_OFFICIAL := https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(KERNEL_VERSION).tar.xz
KERNEL_MIRROR_TSINGHUA := https://mirrors.tuna.tsinghua.edu.cn/kernel/v6.x/linux-$(KERNEL_VERSION).tar.xz
KERNEL_MIRROR_USTC := https://mirrors.ustc.edu.cn/kernel/v6.x/linux-$(KERNEL_VERSION).tar.xz
KERNEL_MIRROR_ALIYUN := https://mirrors.aliyun.com/linux-kernel/v6.x/linux-$(KERNEL_VERSION).tar.xz

# Select mirror based on configuration
ifeq ($(KERNEL_MIRROR),official)
KERNEL_URL := $(KERNEL_MIRROR_OFFICIAL)
else ifeq ($(KERNEL_MIRROR),tsinghua)
KERNEL_URL := $(KERNEL_MIRROR_TSINGHUA)
else ifeq ($(KERNEL_MIRROR),ustc)
KERNEL_URL := $(KERNEL_MIRROR_USTC)
else ifeq ($(KERNEL_MIRROR),aliyun)
KERNEL_URL := $(KERNEL_MIRROR_ALIYUN)
else
$(error Invalid KERNEL_MIRROR value. Please use one of: official, tsinghua, ustc, aliyun)
endif

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
