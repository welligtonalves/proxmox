#!/bin/bash 

echo -e '=====Informe o ID que deseja utilizar no template:======='
echo -e 'Exmeplo: 9000'

read ID;


echo -e '=====Informe o link da imagem que deseja utilizar no template:======='
echo -e 'Exmeplo de uma imagem debian: https://cloud.debian.org/images/cloud/bookworm/20230802-1460/debian-12-generic-amd64-20230802-1460.qcow2'

read IMAGE;

echo -e '=====Inform nome da imgem com extesao:====='
echo -e 'Exemplo: debian-12-generic-amd64-20230802-1460.qcow2'

read OS;

echo -e '=====Inform nome de usuario para imagem:====='
echo -e 'Exemplo: debian ou ubuntu'

read USERNAME;

echo -e '=====Inform nome do template:====='
echo -e 'Exemplo: debian-cloud'

read NOMETEMPLATE;

#Diretorio para baixar a imagem temporariamente 

cd /tmp

sleep 5

# Verifica se o pacote está instalado
if dpkg -l | grep -q libguestfs-tools; then
    echo -e "O pacote libguestfs-tools está instalado."
else
    echo -e "O pacote libguestfs-tools não está instalado. Instalando..."
# Atualiza a lista de pacotes
    sudo apt update
# Instala o pacote
    sudo apt install libguestfs-tools -y

# Verifica se a instalação foi bem-sucedida
    if [ $? -eq 0 ]; then
        echo -e "O pacote libguestfs-tools foi instalado com sucesso."
    else
        echo -e "Falha na instalação do pacote libguestfs-tools."
    fi
fi

sleep 5

#Baixando image
echo -e 'Baixando image'

wget $IMAGE

#Instalando quemu agent na imagem
echo -e 'Instalando quemu agent na imagem'

virt-customize --install qemu-guest-agent -a $OS

sleep 5

#Criando VM e template
echo -e 'Criando VM e template'

qm create $ID  --memory 2048 --core 2 --name $NOMETEMPLATE --net0 virtio,bridge=vmbr0

qm importdisk $ID $OS local-lvm

qm set $ID  --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$ID-disk-0

qm set $ID  --ide2 local-lvm:cloudinit

qm set $ID  --boot c --bootdisk scsi0

qm set $ID  --serial0 socket --vga serial0

qm set $ID --machine q35

qm set $ID --ciuser $USERNAME

qm template $ID

cd /tmp

sleep 5
echo -e 'Removendo imagem que foi baixada para criacao do template'

rm $OS

exit
