#!/bin/bash

#Monta el disco y lo hace permanente

(echo n; echo e; echo 1; echo; echo; echo w;)|fdisk /dev/sdb
partprobe /dev/sdb
mkfs /dev/sdb -t ext4
mkdir /data
mkdir /data/docker
mkdir /data/users
mount /dev/sdb /data
chmod -R 755 /data



disk1=$(ls -l /dev/disk/by-uuid/ | awk -F' ' '{print $9}' | tail -2 | head -1)
disk2=$(ls -l /dev/disk/by-uuid/ | awk -F' ' '{print $9}' | tail -1)
echo "UUID=$disk1 / ext4 defaults 0 0" > fstab
echo "UUID=$disk2 /users ext4 defaults 0 0" >> fstab

