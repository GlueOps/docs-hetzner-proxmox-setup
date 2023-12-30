# docs-hetzner-proxmox-setup
Worth a watch:
https://www.youtube.com/watch?v=1pE-XbqPQi4
A lot of this script is based on: https://gist.github.com/gushmazuko/9208438b7be6ac4e6476529385047bbb but modifications were made based on the video and/or issues I came across


- Login to server via SSH using rescue mode.



```bash
ISO_VERSION=$(curl -s 'http://download.proxmox.com/iso/' | grep -oP 'proxmox-ve_(\d+.\d+-\d).iso' | sort -V | tail -n1)
ISO_URL="http://download.proxmox.com/iso/$ISO_VERSION"
curl $ISO_URL -o /tmp/proxmox-ve.iso

# This INTERFACE should be whatever has the public IP assigned to it. Some of the guides i came across expect it to be eth0 but in my case it was eth2
INTERFACE_PORT=$(ip -br addr | grep 'UP' | grep -v '127.0.0.1' | grep -v '::1/128' | awk '{print $1}')
echo $INTERFACE_PORT

INTERFACE_NAME=$(udevadm info -q property /sys/class/net/$INTERFACE_PORT | grep "ID_NET_NAME_PATH=" | cut -d'=' -f2)
IP_CIDR=$(ip addr show $INTERFACE_PORT | grep "inet\b" | awk '{print $2}')
GATEWAY=$(ip route | grep default | awk '{print $3}')
IP_ADDRESS=$(echo "$IP_CIDR" | cut -d'/' -f1)
CIDR=$(echo "$IP_CIDR" | cut -d'/' -f2)

PRIMARY_DISK=$(lsblk -dn -o NAME,SIZE,TYPE -e 1,7,11,14,15 | sed -n 1p | awk '{print $1}')
SECONDARY_DISK=$(lsblk -dn -o NAME,SIZE,TYPE -e 1,7,11,14,15 | sed -n 2p | awk '{print $1}')

qemu-system-x86_64 -daemonize -k en-us -m 4096 \
-drive file=/dev/$PRIMARY_DISK,format=raw,media=disk,if=virtio \
-drive file=/dev/$SECONDARY_DISK,format=raw,media=disk,if=virtio \
-cdrom /tmp/proxmox-ve.iso -boot d -vnc :0,password -monitor telnet:127.0.0.1:4444,server,nowait

VNC_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
echo "change vnc password $VNC_PASSWORD" | nc -q 1 127.0.0.1 4444
echo "Password for VNC is: $VNC_PASSWORD and IP is: $IP_ADDRESS"

```


# After installing proxmox:

```bash
# Stop QEMU
printf "quit\n" | nc 127.0.0.1 4444

qemu-system-x86_64 -daemonize -k en-us -m 4096 \
-drive file=/dev/$PRIMARY_DISK,format=raw,media=disk,if=virtio \
-drive file=/dev/$SECONDARY_DISK,format=raw,media=disk,if=virtio \
-vnc :0,password -monitor telnet:127.0.0.1:4444,server,nowait \
-net user,hostfwd=tcp::2222-:22 -net nic

VNC_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
echo "change vnc password $VNC_PASSWORD" | nc -q 1 127.0.0.1 4444
echo "Password for VNC is: $VNC_PASSWORD and IP is: $IP_ADDRESS"
```

- Reconnect in VNC and update the `/etc/network/interfaces` so that it uses the correct interface. 
- It should match the output of this file:

```bash
cat > /tmp/proxmox_network_config << EOF
auto lo
iface lo inet loopback

iface $INTERFACE_NAME inet manual

auto vmbr0
iface vmbr0 inet static
  address $IP_ADDRESS/$CIDR
  gateway $GATEWAY
  bridge_ports $INTERFACE_NAME
  bridge_stp off
  bridge_fd 0
EOF
```

After getting the changes made on the proxmox host tell it to shutdown (from the rescue environment) and then reboot into proxmox:

```bash
printf "system_powerdown\n" | nc 127.0.0.1 4444
shutdown -r now
```

After the reboot, your Proxmox VE system should be up and running. You can access the Proxmox VE interface at https://<YourIPAddress>:8006.


- Run updates:
```bash
apt-get update && apt-get upgrade
apt-get update && apt-get dist-upgrade
apt install dnsmasq
systemctl disable --now dnsmasq
sudo reboot
```

Setup a vnet and then you are all set:
https://pve.proxmox.com/wiki/Setup_Simple_Zone_With_SNAT_and_DHCP
https://www.youtube.com/watch?v=UZ9mfxNMyHw
