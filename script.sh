#! /usr/bin/env bash

qemu-img create -f raw /var/lib/libvirt/images/maquina1.qcow2 5G
virt-resize --expand /dev/vda1 ~/bullseye-base.qcow2 /var/lib/libvirt/images/maquina1.qcow2

virsh -c qemu:///system net-define intra.xml
