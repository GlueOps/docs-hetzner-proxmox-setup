#!/usr/bin/env bash

#ref:https://www.youtube.com/watch?v=UQaCrByk53E
wget https://cloud.debian.org/images/cloud/bookworm/20240507-1740/debian-12-genericcloud-amd64-20240507-1740.qcow2
qm create 6000 --name debian-12-cloud-init --net0 virtio,bridge=vmbr0
qm importdisk 6000 debian-12-genericcloud-amd64-20240507-1740.qcow2 local
qm set 6000 --scsihw virtio-scsi-pci --scsi0 local:6000/vm-6000-disk-0.raw
qm set 6000 --ide2 local:cloudinit
qm set 6000 --boot c --bootdisk scsi0
qm set 6000 --serial0 socket --vga serial0
