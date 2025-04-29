# Root filesystem configuration and rules
# =====================================

ROOTFS_DIR := $(BUILD_DIR)/rootfs
ROOTFS_IMG := $(BUILD_DIR)/rootfs.img
ROOTFS_MNT := $(BUILD_DIR)/rootfs_mnt

# Create root filesystem
rootfs-img: busybox
	@echo "Creating root filesystem..."
	@sudo umount $(ROOTFS_MNT) 2>/dev/null || true
	@sudo rm -rf $(ROOTFS_DIR)
	@sudo rm -rf $(ROOTFS_IMG)
	@sudo rm -rf $(ROOTFS_MNT)
	@mkdir -p $(ROOTFS_DIR)
	@mkdir -p $(ROOTFS_MNT)

	@mkdir -p $(ROOTFS_DIR)/bin
	@mkdir -p $(ROOTFS_DIR)/sbin
	@mkdir -p $(ROOTFS_DIR)/home
	@mkdir -p $(ROOTFS_DIR)/etc
	@mkdir -p $(ROOTFS_DIR)/lib
	@mkdir -p $(ROOTFS_DIR)/lib/modules
	@mkdir -p $(ROOTFS_DIR)/proc
	@mkdir -p $(ROOTFS_DIR)/sys
	@mkdir -p $(ROOTFS_DIR)/tmp
	@mkdir -p $(ROOTFS_DIR)/root
	@mkdir -p $(ROOTFS_DIR)/var
	@mkdir -p $(ROOTFS_DIR)/mnt
	@mkdir -p $(ROOTFS_DIR)/usr
	@mkdir -p $(ROOTFS_DIR)/dev

	@cp -arf ${BUSYBOX_BUILD_DIR}/_install/* $(ROOTFS_DIR)

	# 创建初始化脚本 /init
	@echo '#!/bin/sh' > $(ROOTFS_DIR)/init
	@echo 'mount -t proc none /proc' >> $(ROOTFS_DIR)/init
	@echo 'mount -t sysfs none /sys' >> $(ROOTFS_DIR)/init
	@echo 'mount -t devtmpfs none /dev' >> $(ROOTFS_DIR)/init
	@echo 'exec /bin/sh' >> $(ROOTFS_DIR)/init
	@chmod +x $(ROOTFS_DIR)/init

	# 复制 init 到 /sbin/init
	@mkdir -p $(ROOTFS_DIR)/sbin
	@cp $(ROOTFS_DIR)/init $(ROOTFS_DIR)/sbin/init
	@chmod +x $(ROOTFS_DIR)/sbin/init

	# 创建符号链接
	@rm -f $(ROOTFS_DIR)/linuxrc
	@ln -s $(ROOTFS_DIR)/bin/busybox $(ROOTFS_DIR)/linuxrc

	@mkdir -p $(ROOTFS_DIR)/etc
	@echo '::sysinit:/etc/init.d/rcS' > $(ROOTFS_DIR)/etc/inittab
	@echo '::askfirst:-/bin/sh' >> $(ROOTFS_DIR)/etc/inittab

	@mkdir -p $(ROOTFS_DIR)/etc/init.d
	@echo '#!/bin/sh' > $(ROOTFS_DIR)/etc/init.d/rcS
	@echo 'mount -a' >> $(ROOTFS_DIR)/etc/init.d/rcS
	@chmod +x $(ROOTFS_DIR)/etc/init.d/rcS

	# 创建 /etc/fstab
	@echo 'proc    /proc   proc    defaults    0 0' > $(ROOTFS_DIR)/etc/fstab
	@echo 'sysfs   /sys    sysfs   defaults    0 0' >> $(ROOTFS_DIR)/etc/fstab
	@echo 'tmpfs   /tmp    tmpfs   defaults    0 0' >> $(ROOTFS_DIR)/etc/fstab

	@sudo mknod $(ROOTFS_DIR)/dev/tty1 c 4 1
	@sudo mknod $(ROOTFS_DIR)/dev/tty2 c 4 2
	@sudo mknod $(ROOTFS_DIR)/dev/tty3 c 4 3
	@sudo mknod $(ROOTFS_DIR)/dev/tty4 c 4 4
	@sudo mknod $(ROOTFS_DIR)/dev/console c 5 1
	@sudo mknod $(ROOTFS_DIR)/dev/null c 1 3

	@dd if=/dev/zero of=$(ROOTFS_IMG) bs=1M count=100
	@mkfs -t ext3 $(ROOTFS_IMG)

	@mkdir -p $(ROOTFS_MNT)
	@sudo mount -t ext3 $(ROOTFS_IMG) $(ROOTFS_MNT)
	@sudo cp -arf $(ROOTFS_DIR)/* $(ROOTFS_MNT)
	@sudo umount $(ROOTFS_MNT)
	@gzip --best -c $(ROOTFS_IMG) > $(ROOTFS_IMG).gz

# Clean root filesystem
rootfs-clean:
	@echo "Cleaning root filesystem..."
	@sudo rm -rf $(ROOTFS_DIR)
	@rm -f $(ROOTFS_IMG)
	@rm -rf $(ROOTFS_MNT)
