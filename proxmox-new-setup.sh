#Populate variables to generate /etc/hosts and /etc/network/interfaces files
INTERFACE_PORT=$(ip -br addr | grep 'UP' | grep -v '127.0.0.1' | grep -v '::1/128' | awk '{print $1}')
echo $INTERFACE_PORT


INTERFACE_NAME=$(udevadm info -q property /sys/class/net/$INTERFACE_PORT | grep "ID_NET_NAME_PATH=" | cut -d'=' -f2)
IP_CIDR=$(ip addr show $INTERFACE_PORT | grep "inet\b" | awk '{print $2}')
GATEWAY=$(ip route | grep default | awk '{print $3}')
IP_ADDRESS=$(echo "$IP_CIDR" | cut -d'/' -f1)
CIDR=$(echo "$IP_CIDR" | cut -d'/' -f2)

#Configure the network /ect/network/interfaces and create backup of old one
cat > ~/interfaces << EOF
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

source /etc/network/interfaces.d/*

EOF

# #Reboot the system for changes to take effect
# reboot now

#Add Repository 
echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list

#Add repository Key
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg 

# # verify
# sha512sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg 

#OUTPUT of command should be
# 7da6fe34168adc6e479327ba517796d4702fa2f8b4f0a9833f5ea6e6b48f6507a6da403a274fe201595edc86a84463d50383d07f64bdde2e3658108db7d6dc87 /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

#Update system
apt update && apt full-upgrade -y

#Install Proxmox kernel and reboot
apt install proxmox-default-kernel -y
reboot now #Note reboot was left out maybe the cause of the kernel panic - must test in hetzner

# Set debconf selections for Postfix
echo "postfix postfix/main_mailer_type select Local only" | debconf-set-selections
echo "postfix postfix/mailname string ''" | debconf-set-selections

# Install proxmox packages
apt install -y proxmox-ve postfix open-iscsi chrony

#Reomove the debian kernel and update grub
apt remove linux-image-amd64 'linux-image-6.1*' -y
update-grub

#remove OS Prober
apt remove os-prober -y

#If you are not using a license key remove the enterprise repository
rm /etc/apt/sources.list.d/pve-enterprise.list

#Update the system
apt update && apt dist-upgrade -y

#Setup a software defined network
apt install libpve-network-perl frr-pythontools dnsmasq -y
systemctl disable --now dnsmasq

#move the interfaces and back up the old
mv /etc/network/interfaces /etc/network/interfaces.old
mv ~/interfaces /etc/network/interfaces.new

#Reboot to finalize all the changes
sysctl -w kernel.panic=10
reboot now

# #Additional security measures
# Enable 2FA on the proxmox web interface
# select root@pam in upper right corner > TFA > Add

# #connect to the proxmox web interface
# https://your_ip:8006
