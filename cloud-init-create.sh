#!/bin/bash
###########################################################
# Script de backup criado por Welligton Alves - SRE eulabs #
###########################################################

echo -e '=====Informe o ID que deseja utilizar no template:====='
echo -e 'Exemplo: 9000'
read ID;

echo -e '=====Informe o link da imagem que deseja utilizar no template:====='
echo -e 'Exemplo de uma imagem Debian: https://cloud.debian.org/images/cloud/bookworm/20230802-1460/debian-12-generic-amd64-20230802-1460.qcow2'
read IMAGE;

echo -e '=====Informe nome da imagem com extensão:====='
echo -e 'Exemplo: debian-12-generic-amd64-20230802-1460.qcow2'
read OS;

echo -e '=====Informe nome de usuário para a imagem:====='
echo -e 'Exemplo: debian ou ubuntu'
read USERNAME;

echo -e '=====Informe nome do template:====='
echo -e 'Exemplo: debian-cloud'
read NOMETEMPLATE;

# Diretório para baixar a imagem temporariamente
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

# Baixando a imagem
echo -e 'Baixando imagem'

wget $IMAGE

# Instalando qemu agent na imagem
echo -e 'Instalando qemu agent na imagem'

virt-customize --install qemu-guest-agent -a $OS

sleep 5

# Criando VM e template
echo -e 'Criando VM e template'

qm create $ID --memory 2048 --cores 2 --name $NOMETEMPLATE --net0 virtio,bridge=vmbr0

qm importdisk $ID $OS local-lvm

qm set $ID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$ID-disk-0

qm set $ID --ide2 local-lvm:cloudinit

qm set $ID --boot c --bootdisk scsi0

qm set $ID --serial0 socket --vga serial0

qm set $ID --machine q35

qm set $ID --ciuser $USERNAME

qm template $ID

cd /tmp

sleep 5
echo -e 'Removendo a imagem que foi baixada para criação do template'

rm $OS

exit
