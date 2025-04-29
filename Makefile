# Configuration file path
CONFIG_FILE := config.conf

# Then include other makefiles
include include/host.mk
include include/deps.mk
include include/dirs.mk
include include/common.mk

# Include user configuration first
include $(CONFIG_FILE)
include include/config.mk
include include/uboot.mk
include include/kernel.mk
include include/busybox.mk

include include/rootfs.mk

.PHONY: all clean help run

# Default target
.DEFAULT_GOAL := help

# Help target
help:
	@echo "Available commands:"
	@echo ""
	@echo "System Information:"
	@echo "  make host-info      - Display host system information"
	@echo ""
	@echo "Build commands:"
	@echo "  make all                           - Build everything"
	@echo "  make {uboot,busybox,kernel}        - Build specified component"
	@echo ""
	@echo "Build commands for uboot, busybox, kernel:"
	@echo "  make uboot-menu   - Configure uboot"
	@echo "  make uboot-show   - Show uboot configuration"
	@echo "  make uboot-save   - Save uboot configuration"
	@echo "  make uboot-load   - Load uboot configuration"
	@echo "  make uboot-dl     - Download uboot source"
	@echo "  make uboot-ex     - Extract uboot source"
	@echo "  and so on for busybox and kernel"
	@echo ""
	@echo "Cleanup commands:"
	@echo "  make clean         - Clean build directories"
	@echo "  make cleansrc      - Clean source directories"
	@echo "  make distclean     - Clean everything including downloads"
	@echo ""
	@echo "Dependency commands:"
	@echo "  make check-deps    - Check if all required packages are installed"
	@echo "  make install-deps  - Install all required packages"
	@echo ""
	@echo "Current configuration:"
	@echo "  Architecture   : $(ARCH)"
	@echo "  Cross compiler : $(CROSS_COMPILE)"
	@echo ""
	@echo "Component versions:"
	@echo "  U-Boot         : $(UBOOT_VERSION)"
	@echo "  Busybox        : $(BUSYBOX_VERSION)"
	@echo "  Linux          : $(KERNEL_VERSION)"


# Main target that depends on all required steps
all: check-deps build
	@echo "Build completed successfully."

# Download all components
download: busybox-dl kernel-dl uboot-dl
	@echo "All components downloaded successfully."

# Extract all components to build directory
extract: busybox-ex kernel-ex uboot-ex
	@echo "All components extracted successfully."

# Extract all components to source directory
src: busybox-src kernel-src uboot-src
	@echo "All components extracted successfully."

# Build all components
build: busybox kernel uboot rootfs-img
	@echo "All components built successfully."

# Clean target
clean: busybox-clean kernel-clean uboot-clean
	@rm -rf $(BUILD_DIR)

# Clean source directory
cleansrc:
	@rm -rf $(SRC_DIR)

distclean: clean cleansrc
	@rm -rf $(DL_DIR)

# Run QEMU
run: all
	@echo "Starting QEMU..."
	@qemu-system-x86_64 \
		-kernel $(KERNEL_BUILD_DIR)/arch/x86/boot/bzImage \
		-nographic \
		-append "rdinit=/sbin/init console=ttyS0" \
		-initrd $(ROOTFS_IMG)
