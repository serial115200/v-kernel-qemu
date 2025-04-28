# Configuration file path
CONFIG_FILE := config.conf

include include/cpu.mk
include include/deps.mk
include include/dirs.mk
include include/common.mk

include include/config.mk
include include/uboot.mk
include include/kernel.mk
include include/busybox.mk

# Include configuration and dependencies
include $(CONFIG_FILE)

.PHONY: all clean help

# Default target
.DEFAULT_GOAL := help

# Help target
help:
	@echo "Available commands:"
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
	@echo "  make clean                  - Clean build directories"
	@echo "  make distclean              - Clean everything including downloads"
	@echo ""
	@echo "Current configuration:"
	@echo "  Architecture   : $(ARCH)"
	@echo "  Cross compiler : $(CROSS_COMPILE)"
	@echo "  Build Dir      : $(BUILD_DIR)"
	@echo "  Source Dir     : $(SRC_DIR)"
	@echo "  Download Dir   : $(DL_DIR)"
	@echo "  Configs Dir    : $(CONFIGS_DIR)"
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

# Extract all components
extract: busybox-ex kernel-ex uboot-ex
	@echo "All components extracted successfully."

# Build all components
build: busybox kernel uboot
	@echo "All components built successfully."

# Clean target
clean: busybox-clean kernel-clean uboot-clean
	@rm -rf $(BUILD_DIR)

cleansrc:
	@rm -rf $(SRC_DIR)

cleanall: clean cleansrc
	@rm -rf $(DL_DIR)
