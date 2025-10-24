# OpenWrt QEMU 高级配置教程

本教程将指导您如何使用现有的 OpenWrt 镜像，并配置高级功能。

## 1. 准备工作

确保已安装必要的软件包：

```bash
sudo apt-get update
sudo apt-get install -y qemu-system-arm bridge-utils uml-utilities
```

## 2. 网络配置

### 2.1 创建网络桥接

```bash
# 创建桥接接口
sudo brctl addbr br0
sudo ip addr add 192.168.1.100/24 dev br0
sudo ip link set br0 up

# 配置 NAT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i br0 -j ACCEPT
```

### 2.2 创建 TAP 接口

```bash
sudo tunctl -t tap0 -u $(whoami)
sudo ip link set tap0 up
sudo brctl addif br0 tap0
```

## 3. QEMU 启动配置

使用以下命令启动 OpenWrt，包含完整的网络、SSH、Web 和 9p 支持：

```bash
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -m 1024 \
    -kernel openwrt-armvirt-64-Image \
    -append "root=/dev/vda console=ttyAMA0" \
    -drive file=openwrt-armvirt-64-root.ext4,format=raw,id=hd0 \
    -device virtio-blk-device,drive=hd0 \
    # 网络配置
    -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
    -device virtio-net-device,netdev=net0,mac=52:54:00:12:34:56 \
    # 串口配置
    -serial mon:stdio \
    -device virtio-serial-device \
    -chardev socket,id=serial0,path=/tmp/vm.sock,server,nowait \
    -device virtserialport,chardev=serial0,name=serial0 \
    # 9p 文件系统共享
    -fsdev local,id=fsdev0,path=/path/to/shared/folder,security_model=none \
    -device virtio-9p-pci,fsdev=fsdev0,mount_tag=hostshare \
    # 端口转发
    -netdev user,id=net1,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80 \
    -device virtio-net-device,netdev=net1 \
    -nographic
```

## 4. OpenWrt 内部配置

启动后，在 OpenWrt 中执行以下配置：

### 4.1 网络配置

```bash
# 配置 LAN 接口
uci set network.lan=interface
uci set network.lan.proto=static
uci set network.lan.ipaddr=192.168.1.1
uci set network.lan.netmask=255.255.255.0
uci set network.lan.gateway=192.168.1.100
uci set network.lan.dns=8.8.8.8

# 配置防火墙
uci set firewall.@zone[0].input=ACCEPT
uci set firewall.@zone[0].output=ACCEPT
uci set firewall.@zone[0].forward=ACCEPT

# 提交更改
uci commit
/etc/init.d/network restart
/etc/init.d/firewall restart
```

### 4.2 9p 文件系统挂载

```bash
# 创建挂载点
mkdir -p /mnt/hostshare

# 挂载 9p 文件系统
mount -t 9p -o trans=virtio,version=9p2000.L hostshare /mnt/hostshare

# 设置开机自动挂载
echo 'mount -t 9p -o trans=virtio,version=9p2000.L hostshare /mnt/hostshare' >> /etc/rc.local
```

### 4.3 SSH 配置

```bash
# 安装 SSH 服务器
opkg update
opkg install openssh-server

# 配置 SSH
uci set dropbear.@dropbear[0].PasswordAuth=on
uci set dropbear.@dropbear[0].RootPasswordAuth=on
uci commit
/etc/init.d/dropbear restart
```

## 5. 访问方式

### 5.1 SSH 访问
```bash
ssh -p 2222 root@localhost
```

### 5.2 Web 界面访问
在浏览器中访问：http://localhost:8080

### 5.3 串口访问
```bash
socat - UNIX-CONNECT:/tmp/vm.sock
```

## 6. 文件共享

### 6.1 主机到虚拟机
- 将文件放在 `/path/to/shared/folder` 目录下
- 在 OpenWrt 中通过 `/mnt/hostshare` 访问

### 6.2 虚拟机到主机
- 在 OpenWrt 中将文件复制到 `/mnt/hostshare`
- 在主机上通过 `/path/to/shared/folder` 访问

## 7. 网络测试

```bash
# 在 OpenWrt 中测试网络连接
ping 8.8.8.8

# 测试端口转发
curl http://localhost:8080
```

## 8. 常见问题解决

1. 网络连接问题：
   - 检查桥接接口状态：`ip link show br0`
   - 检查 TAP 接口状态：`ip link show tap0`
   - 检查防火墙规则：`iptables -L -n -v`

2. 9p 文件系统问题：
   - 检查挂载点权限
   - 确保主机目录存在且有适当权限
   - 检查 9p 模块是否加载：`lsmod | grep 9p`

3. 端口转发问题：
   - 检查端口是否被占用：`netstat -tulpn | grep 2222`
   - 检查防火墙规则
   - 确保 OpenWrt 服务正在运行

## 9. 清理

```bash
# 停止 QEMU 后清理网络配置
sudo ip link set br0 down
sudo brctl delbr br0
sudo ip link set tap0 down
sudo tunctl -d tap0
```

## 10. 参考资料

- [OpenWrt 官方文档](https://openwrt.org/docs/start)
- [QEMU 官方文档](https://www.qemu.org/documentation/)
- [OpenWrt 开发指南](https://openwrt.org/docs/guide-developer/start)
