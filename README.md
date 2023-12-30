# docs-hetzner-proxmox-setup

Worth a watch:
https://www.youtube.com/watch?v=1pE-XbqPQi4

Additional resources:
https://gist.github.com/gushmazuko/9208438b7be6ac4e6476529385047bbb


- Visit hetzner ROBOT console and activate rescue mode and then restart and login using rescue mode.



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

