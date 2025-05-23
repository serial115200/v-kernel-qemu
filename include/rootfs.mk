# Root filesystem configuration and rules
# =====================================

ROOTFS_DIR := $(BUILD_DIR)/rootfs
ROOTFS_MOUNT := $(BUILD_DIR)/rootfs-mount
ROOTFS_IMG_CPIO := $(BUILD_DIR)/rootfs.cpio.gz
ROOTFS_IMG_EXT4 := $(BUILD_DIR)/rootfs.ext4

# Create root filesystem
rootfs: busybox
	@echo "Building root filesystem..."
	@sudo rm -rf $(ROOTFS_DIR)
	@mkdir -p $(ROOTFS_DIR)/bin
	@mkdir -p $(ROOTFS_DIR)/sbin
	@mkdir -p $(ROOTFS_DIR)/dev
	@mkdir -p $(ROOTFS_DIR)/usr
	@mkdir -p $(ROOTFS_DIR)/etc/init.d
	@mkdir -p $(ROOTFS_DIR)/proc
	@mkdir -p $(ROOTFS_DIR)/sys
	@mkdir -p $(ROOTFS_DIR)/tmp

	@echo "Installing Busybox..."
	@make CONFIG_PREFIX=$(abspath $(ROOTFS_DIR)) -C $(BUSYBOX_BUILD_DIR) install V=1


	@echo "Creating init symlink..."
	@ln -sf ../bin/busybox $(ROOTFS_DIR)/sbin/init

	@echo "Creating necessary devices..."
	@sudo mknod -m 622 $(ROOTFS_DIR)/dev/console c 5 1
	@sudo mknod -m 666 $(ROOTFS_DIR)/dev/null c 1 3
	@sudo mknod -m 666 $(ROOTFS_DIR)/dev/ttyS0 c 4 64

	@echo "Creating fstab..."
	@echo 'proc    /proc   proc    defaults    0 0' >  $(ROOTFS_DIR)/etc/fstab
	@echo 'sysfs   /sys    sysfs   defaults    0 0' >> $(ROOTFS_DIR)/etc/fstab
	@echo 'tmpfs   /tmp    tmpfs   defaults    0 0' >> $(ROOTFS_DIR)/etc/fstab

	@echo "Creating inittab..."
	@echo '::sysinit:/etc/init.d/rcS'           >  $(ROOTFS_DIR)/etc/inittab
	@echo '::respawn:/bin/cttyhack /bin/sh -l'  >> $(ROOTFS_DIR)/etc/inittab
	@echo '::ctrlaltdel:/sbin/reboot'           >> $(ROOTFS_DIR)/etc/inittab
	@echo '::shutdown:/bin/umount -a -r'        >> $(ROOTFS_DIR)/etc/inittab

	@echo "Creating rcS..."
	@echo '#!/bin/sh'                                >  $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'mount -t proc proc /proc'                 >> $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'mount -t sysfs sysfs /sys'                >> $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'echo /sbin/mdev > /proc/sys/kernel/hotplug' >> $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'mdev -s'                                  >> $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'chmod 666 /dev/ttyS0'                     >> $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'chmod 622 /dev/console 2>/dev/null'       >> $(ROOTFS_DIR)/etc/init.d/rcS

	@chmod +x $(ROOTFS_DIR)/etc/init.d/rcS
	@sudo find $(ROOTFS_DIR) -exec chown root:root {} \; 2>/dev/null

rootfs-cpio: rootfs
	@echo "Creating initramfs image..."
	@sudo rm -rf $(ROOTFS_IMG_CPIO)
	@(cd $(ROOTFS_DIR) && find . -print0 | cpio --null -H newc -ov) | gzip > $(ROOTFS_IMG_CPIO)

rootfs-ext4: rootfs
	@echo "Creating ext4 image..."
	@sudo rm -rf $(ROOTFS_IMG_EXT4)
	@sudo rm -rf $(ROOTFS_MOUNT)
	@sudo mkdir -p $(ROOTFS_MOUNT)
	@dd if=/dev/zero of=$(ROOTFS_IMG_EXT4) bs=1M count=512
	@sudo mkfs.ext4 $(ROOTFS_IMG_EXT4)
	@sudo mount $(ROOTFS_IMG_EXT4) $(ROOTFS_MOUNT)
	@sudo cp -a $(ROOTFS_DIR)/* $(ROOTFS_MOUNT)
	@sudo umount $(ROOTFS_MOUNT)

# Clean root filesystem
rootfs-clean:
	@echo "Cleaning root filesystem..."
	@sudo rm -rf $(ROOTFS_DIR)
	@sudo rm -f $(ROOTFS_IMG_CPIO)
	@sudo rm -f $(ROOTFS_IMG_EXT4)
