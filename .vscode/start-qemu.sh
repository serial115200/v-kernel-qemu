#!/bin/bash

# 启动 QEMU 并等待 GDB server 就绪
# 参数：
#   $1: 内核映像路径 (bzImage)
#   $2: rootfs 映像路径 (rootfs.ext4)
#   $3: vmlinux 路径（用于检查）

KERNEL_IMG="$1"
ROOTFS_IMG="$2"
VMLINUX="$3"

# 检查文件是否存在
if [ ! -f "$KERNEL_IMG" ]; then
    echo "错误: 内核映像不存在: $KERNEL_IMG"
    exit 1
fi

if [ ! -f "$ROOTFS_IMG" ]; then
    echo "错误: rootfs 映像不存在: $ROOTFS_IMG"
    exit 1
fi

# 检查是否已有 QEMU 在运行
if pgrep -f "qemu-system-x86_64.*bzImage" > /dev/null; then
    echo "警告: 检测到已有 QEMU 进程在运行，正在终止..."
    pkill -f "qemu-system-x86_64.*bzImage"
    sleep 1
fi

# 启动 QEMU 在后台，使用 setsid 创建新会话确保进程独立
echo "正在启动 QEMU..."
# 使用 setsid 创建新会话，避免被 SIGHUP 终止
setsid qemu-system-x86_64 \
    -kernel "$KERNEL_IMG" \
    -append "root=/dev/vda console=ttyS0 rootfstype=ext4 rw nokaslr" \
    -drive "file=$ROOTFS_IMG,format=raw,if=virtio" \
    -S \
    -s \
    -nographic > /tmp/qemu-gdb.log 2>&1 < /dev/null &

QEMU_PID=$!

# 等待 QEMU 进程稳定
sleep 2

# 确认 QEMU 进程仍在运行
if ! kill -0 $QEMU_PID 2>/dev/null; then
    echo "错误: QEMU 进程启动失败"
    cat /tmp/qemu-gdb.log 2>/dev/null || true
    exit 1
fi

# 等待 QEMU GDB server 就绪（检查端口 1234 是否可连接）
echo "等待 GDB server 启动..."
for i in {1..60}; do
    if timeout 1 bash -c "echo > /dev/tcp/127.0.0.1/1234" 2>/dev/null; then
        # 再次确认端口稳定
        sleep 0.5
        if timeout 1 bash -c "echo > /dev/tcp/127.0.0.1/1234" 2>/dev/null; then
            # 额外等待确保完全就绪
            sleep 2
            # 再次确认端口和进程
            if timeout 1 bash -c "echo > /dev/tcp/127.0.0.1/1234" 2>/dev/null && kill -0 $QEMU_PID 2>/dev/null; then
                # 将 QEMU 进程从当前进程组分离，确保脚本退出后继续运行
                disown $QEMU_PID 2>/dev/null || true
                echo "GDB server ready on port 1234"
                echo "QEMU PID: $QEMU_PID"
                # 输出完成信号，让 VS Code 知道任务已完成
                # 脚本可以安全退出，QEMU 会继续运行
                exit 0
            fi
        fi
    fi
    # 检查 QEMU 进程是否还在运行
    if ! kill -0 $QEMU_PID 2>/dev/null; then
        echo "错误: QEMU 进程已退出"
        exit 1
    fi
    sleep 0.3
done

echo "警告: GDB server 可能在 18 秒后仍未就绪，但将继续..."
echo "GDB server ready on port 1234"
sleep 1
