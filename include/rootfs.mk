# Root filesystem configuration and rules
# =====================================

ROOTFS_DIR := $(BUILD_DIR)/rootfs
ROOTFS_IMG := $(BUILD_DIR)/rootfs.cpio.gz


# Create root filesystem
rootfs-img: busybox
	@echo "Building root filesystem..."
	@sudo rm -rf $(ROOTFS_DIR) $(ROOTFS_IMG)
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
	@sudo mknod -m 600 $(ROOTFS_DIR)/dev/console c 5 1
	@sudo mknod -m 600 $(ROOTFS_DIR)/dev/null c 1 3

	@echo "Creating fstab..."
	@echo 'proc    /proc   proc    defaults    0 0' >  $(ROOTFS_DIR)/etc/fstab
	@echo 'sysfs   /sys    sysfs   defaults    0 0' >> $(ROOTFS_DIR)/etc/fstab
	@echo 'tmpfs   /tmp    tmpfs   defaults    0 0' >> $(ROOTFS_DIR)/etc/fstab

	@echo "Creating inittab..."
	@echo '::sysinit:/etc/init.d/rcS'           >  $(ROOTFS_DIR)/etc/inittab
	@echo '::respawn:/bin/sh'                   >> $(ROOTFS_DIR)/etc/inittab
	@echo '::ctrlaltdel:/sbin/reboot'           >> $(ROOTFS_DIR)/etc/inittab
	@echo '::shutdown:/bin/umount -a -r'        >> $(ROOTFS_DIR)/etc/inittab

	@echo "Creating rcS..."
	@echo '#!/bin/sh'                            >  $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'mount -t proc none /proc'             >> $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'mount -t sysfs none /sys'             >> $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'mount -t devtmpfs devtmpfs /dev'      >> $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'echo /sbin/mdev > /proc/sys/kernel/hotplug' >> $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'mdev -s'                              >> $(ROOTFS_DIR)/etc/init.d/rcS
	@chmod +x $(ROOTFS_DIR)/etc/init.d/rcS

	@echo "Creating initramfs image..."
	@(cd $(ROOTFS_DIR) && find . -print0 | cpio --null -H newc -ov) | gzip > $(ROOTFS_IMG)


# Clean root filesystem
rootfs-clean:
	@echo "Cleaning root filesystem..."
	@sudo rm -rf $(ROOTFS_DIR)
	@rm -f $(ROOTFS_IMG)
