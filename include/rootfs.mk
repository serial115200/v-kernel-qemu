# Root filesystem build configuration and rules
# ==========================================

# Define paths for root filesystem
ROOTFS_DIR := $(BUILD_DIR)/rootfs
ROOTFS_IMAGE := $(BUILD_DIR)/rootfs.img

# Create root filesystem
rootfs: busybox
	@echo "Creating root filesystem..."
	@mkdir -p $(ROOTFS_DIR)
	@mkdir -p $(ROOTFS_DIR)/{bin,dev,etc,proc,sys}

	# Copy Busybox binaries
	@cp -a $(BUSYBOX_BUILD_DIR)/_install/* $(ROOTFS_DIR)/
	@ln -sf /bin/busybox $(ROOTFS_DIR)/init

	# Create device nodes
	@sudo mknod $(ROOTFS_DIR)/dev/console c 5 1
	@sudo mknod $(ROOTFS_DIR)/dev/null c 1 3

	# Create init script
	@echo '#!/bin/sh' > $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'mount -t proc proc /proc' >> $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'mount -t sysfs sysfs /sys' >> $(ROOTFS_DIR)/etc/init.d/rcS
	@chmod +x $(ROOTFS_DIR)/etc/init.d/rcS

	# Create inittab
	@echo '::sysinit:/etc/init.d/rcS' > $(ROOTFS_DIR)/etc/inittab
	@echo '::respawn:-/bin/sh' >> $(ROOTFS_DIR)/etc/inittab

	# Set permissions
	@sudo chown -R root:root $(ROOTFS_DIR)

# Create root filesystem image
rootfs-img: rootfs
	@echo "Creating root filesystem image..."
	@dd if=/dev/zero of=$(ROOTFS_IMAGE) bs=1M count=64
	@mkfs.ext4 $(ROOTFS_IMAGE)
	@mkdir -p $(BUILD_DIR)/rootfs-mount
	@sudo mount $(ROOTFS_IMAGE) $(BUILD_DIR)/rootfs-mount
	@sudo cp -a $(ROOTFS_DIR)/* $(BUILD_DIR)/rootfs-mount/
	@sudo umount $(BUILD_DIR)/rootfs-mount
	@rm -rf $(BUILD_DIR)/rootfs-mount

# Clean root filesystem
rootfs-clean:
	@echo "Cleaning root filesystem..."
	@sudo rm -rf $(ROOTFS_DIR)
	@rm -f $(ROOTFS_IMAGE)
