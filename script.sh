#! /usr/bin/env bash

echo "################################"
echo "1. Crea una imagen nueva"
echo "################################"

#virsh -c qemu:///system vol-create-as default maquina1.qcow2 5G --format raw
## este comando no lo puedo ejecutar sin sudo, el siguiente si

qemu-img create -f qcow2 -b bullseye-base.qcow2 maquina1.qcow2 5G
virt-resize --expand /dev/vda1 bullseye-base.qcow2 maquina1.qcow2

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
			 --disk maquina1.qcow2 \
			 --os-variant debian10 \
			 --memory 1024 \
			 --vcpus 1 \
             --network network=intra \
             --autostart \
             --import \
             --noautoconsole
sleep 20
IPm1=$(virsh -c qemu:///system domifaddr maquina1 | egrep -o '(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}')
ssh -i ~/.ssh/clave-ecdsa -o "StrictHostKeyChecking no" debian@$IPm1 'sudo hostnamectl set-hostname maquina1'

echo "################################"
echo "4. Crea un volumen adicional de 1 GiB"
echo "################################"

virsh -c qemu:///system vol-create-as default vol.raw 1G --format raw

echo "################################"
echo "5. crea un sistema de ficheros XFS en el volumen y móntalo en el directorio /var/www/html"
echo "################################"

virsh -c qemu:///system  attach-disk maquina1 \
--source /var/lib/libvirt/images/vol.raw \
--target vdb \
--persistent

# añado la el disco a fstab a también para que sea persistente tras reinicios
ssh -i ~/.ssh/clave-ecdsa debian@$IPm1 'sudo mkdir -p /var/www/html && sudo mkfs.xfs /dev/vdb && sudo mount /dev/vdb /var/www/html'
ssh -i ~/.ssh/clave-ecdsa debian@$IPm1 "sudo -- bash -c 'echo "/dev/vdb        /var/www/html   xfs     defaults        0       0" >> /etc/fstab'"

echo "################################"
echo "6. Instala el servidor web apache2"
echo "################################"

ssh -i ~/.ssh/clave-ecdsa debian@$IPm1 'sudo apt update &>/dev/null && sudo apt install apache2 -y  &>/dev/null'
scp -i ~/.ssh/clave-ecdsa index.html debian@$IPm1:/home/debian/index.html
ssh -i ~/.ssh/clave-ecdsa debian@$IPm1 'sudo mv index.html /var/www/html/index.html'


echo "################################"
echo "7. Comprobación del servidor Apache2"
echo "################################"

echo "La dirección IP del servidor es http://$IPm1"
read -p "Pulsa [INTRO] una vez has comprobado que funciona el servidor"

echo "################################"
echo "8. Instala LXC"
echo "################################"
