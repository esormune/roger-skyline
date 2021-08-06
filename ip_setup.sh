#make sure you have host-only adapter first and NAT second
echo "MAKE SURE YOU HAVE HOST-ONLY ADAPTER AND NAT APPLIED."

#get ip address & netmask
echo "Please enter IP address."
read address
echo "Please enter netmask in 0.0.0.0 form."
read netmask
echo "Please enter netmask in number form."
read netnumber

#install net-tools
apt install net-tools

#get assigned ip and gateway for network access
IP=$(ip a | grep -w inet | awk '{print $2}' |  sed -n 3p)
GATEWAY=$(netstat -nr | grep enp0s8 | awk '{print $2}' | sed '3d;q')

#configure /etc/networks/interfaces
echo $'auto lo\niface lo inter loopback\n' > /etc/networks/interfaces
echo $'auto enp0s8\niface enp0s8 inet static' >> /etc/networks/interfaces
echo "address ${address}" >> /etc/networks/interfaces
echo "netmask ${netmask}" >> /etc/networks/interfaces

#configure /etc/netplan/00-installer-config.yaml
echo "network:" > /etc/netplan/00-installer-config.yaml
echo "  ethernets:" >> /etc/netplan/00-installer-config.yaml
echo "    enp0s3:" >> /etc/netplan/00-installer-config.yaml
echo "      addresses:" >> /etc/netplan/00-installer-config.yaml
echo "       - ${address}/${netnumber}" >> /etc/netplan/00-installer-config.yaml
echo "      nameservers:" >> /etc/netplan/00-installer-config.yaml
echo "         addresses: [8.8.8.8,8.8.4.4]" >> /etc/netplan/00-installer-config.yaml
echo "      dhcp4: false" >> /etc/netplan/00-installer-config.yaml
echo "      dhcp6: false" >> /etc/netplan/00-installer-config.yaml
echo "    enp0s8:" >> /etc/netplan/00-installer-config.yaml
echo "      addresses:" >> /etc/netplan/00-installer-config.yaml
echo "       - ${IP}" >> /etc/netplan/00-installer-config.yaml
echo "      nameservers:" >> /etc/netplan/00-installer-config.yaml
echo "         addresses: [8.8.8.8,8.8.4.4]" >> /etc/netplan/00-installer-config.yaml
echo "      gateway4: ${GATEWAY}" >> /etc/netplan/00-installer-config.yaml
echo "      dhcp4: false" >> /etc/netplan/00-installer-config.yaml
echo "      dhcp6: false" >> /etc/netplan/00-installer-config.yaml
echo "  version: 2" >> /etc/netplan/00-installer-config.yaml