#! /usr/bin/env bash

echo "################################"
echo "1. Crea una imagen nueva"
echo "################################"

virsh -c qemu:///system vol-create-as default maquina1.qcow2 5G --format raw

virt-resize --expand /dev/vda1 /home/roberto/bullseye-base.qcow2 /var/lib/libvirt/images/maquina1.qcow2

echo "################################"
echo "2. Crea una red interna"
echo "################################"

virsh -c qemu:///system net-define intra.xml
virsh -c qemu:///system net-start intra
virsh -c qemu:///system net-autostart intra

echo "################################"
echo "3. Crea una máquina virtual (maquina1)"
echo "################################"

virt-install --connect qemu:///system \
			 --virt-type kvm \
			 --name maquina1 \
			 --disk /var/lib/libvirt/images/maquina1.qcow2 \
			 --os-variant debian10 \
			 --memory 1024 \
			 --vcpus 1 \
             --network network=intra \
             --autostart \
             --import \
             --noautoconsole
sleep 20
IPm1=$(virsh domifaddr maquina1 | egrep -o '(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}')
ssh -i /home/roberto/clave-ecdsa -o "StrictHostKeyChecking no" debian@$IPm1 'sudo hostnamectl set-hostname maquina1'

echo "################################"
echo "4. Crea un volumen adicional de 1 GiB"
echo "################################"

virsh -c qemu:///system vol-create-as default vol.raw 1G --format raw

echo "################################"
echo" crea un sistema de ficheros XFS en el volumen y móntalo en el directorio /var/www/html"
echo "################################"

