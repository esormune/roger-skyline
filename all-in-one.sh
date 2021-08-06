#run only on root
echo "Please only run on root user."
sleep 5
clear

#which setup?
echo "[1] ip setup"
echo "[2] user setup"
echo "[3] services setup"
echo "[4] ssh setup"
echo "[5] firewall setup"
echo "[6] cron setup"
echo "[7] perform all"

read input
clear


#ip setup
if [ ${input} == 1 ]; then 
echo "AFTER THIS, YOU WILL HAVE TO CHANGE YOUR NETWORKS TO HOST-ONLY FIRST AND NAT SECOND."

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
GATEWAY=$(netstat -nr | grep enp0s3 | awk '{print $2}' | sed '3d;q')

#configure /etc/network/interfaces
echo $'auto lo\niface lo inter loopback\n' > /etc/network/interfaces
echo $'auto enp0s3\niface enp0s3 inet static' >> /etc/network/interfaces
echo "address ${address}" >> /etc/network/interfaces
echo "netmask ${netmask}" >> /etc/network/interfaces

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

echo "Please restart your VM and change network settings to host-only and NAT."
fi



#user setup
if [ ${input} == 2 ]; then
#add user
echo "Please give username."
read user
sudo adduser ${user}

#add sudo privileges to user
sudo adduser ${user} sudo

#create ssh folder
mkdir /home/${user}/.ssh
touch /home/${user}/.ssh/authorized_keys

#copy id_rsa.pub from host
echo "Copying public key from host..."
echo "Please give host ip address."
read HOST_ADDR
echo "Please enter host password when prompted."
scp esormune@${HOST_ADDR}:.ssh/id_rsa.pub /home/${user}/.ssh/authorized_keys
fi





#services setup
if [ ${input} == 3 ]; then
#update system
sudo apt update -y
sudo apt upgrade -y

#update necessary tools
sudo apt install ufw portsentry fail2ban apache2 mailutils net-tools -y

#stop all unneccessary services
sudo systemctl disable console-setup.service
sudo systemctl disable keyboard-setup.service
fi




#ssh setup
if [ ${input} == 4 ]; then
#declare port number
exists=$(cat /etc/ssh/sshd_config | grep -w "Port" | grep -v ^\#)
if [ ! -z "${exists}" ]; then
	oldport=$(cat /etc/ssh/sshd_config | grep -w "Port" | grep -v ^\# | \
		egrep -o '[0-9]+')
	echo "Please give port number to replace ${oldport}."
	read newport
	sed -i "s/Port $oldport/Port $newport/" /etc/ssh/sshd_config
else
	echo "Please give port number."
	read newport
	echo "Port ${newport}" >> /etc/ssh/sshd_config
fi

#deny rootlogin
rlogin=$(cat /etc/ssh/sshd_config |  grep -w "PermitRootLogin" | grep -v ^\# | \
	grep "No")
if [ -z "${rlogin}" ]; then
	echo "PermitRootLogin No" >> /etc/ssh/sshd_config
	sed -i 's/PermitRootLogin [Yy]es//' /etc/ssh/sshd_config
fi

#deny password authentication
pword=$(cat /etc/ssh/sshd_config |  grep -w "PasswordAuthentication" | grep -v ^\# | \
	grep "No")
if [ -z "${pword}" ]; then
	echo "PasswordAuthentication No" >> /etc/ssh/sshd_config
	sed -i 's/#PasswordAuthentication [Yy]es//' /etc/ssh/sshd_config
	sed -i  's/PasswordAuthentication [Yy]es//' /etc/ssh/sshd_config
fi
fi



#firewall setup
if [ ${input} == 5 ]; then
#enable firewall
sudo ufw enable

#allow ssh, http, and https
echo "Enter ssh port."
read port
sudo ufw default deny incoming
sudo ufw default allow outgoing
ufw allow ${port}/tcp
ufw allow 80
ufw allow 443

##protect against DoS

#Create and update fail2ban.local
touch /etc/fail2ban/fail2ban.local

#Basic Configuration
echo "[DEFAULT]" > /etc/fail2ban/fail2ban.local
echo "loglevel = INFO" >> /etc/fail2ban/fail2ban.local
echo "logtarget = /var/log/fail2ban.log" >> /etc/fail2ban/fail2ban.local

#Create and update jail.local
touch /etc/fail2ban/jail.local

#Stop DOS attack from remote host. 
echo "[http-get-dos]" > /etc/fail2ban/jail.local
echo "enabled = true" >> /etc/fail2ban/jail.local
echo "port = http,https" >> /etc/fail2ban/jail.local
echo "filter = http-get-dos" >> /etc/fail2ban/jail.local
echo "logpath = /var/log/apache2/access.log" >> /etc/fail2ban/jail.local
echo "maxretry = 200" >> /etc/fail2ban/jail.local
echo "findtime = 200" >> /etc/fail2ban/jail.local
echo "bantime = 600" >> /etc/fail2ban/jail.local
echo "action = iptables[name=HTTP, port=http, protocol=tcp]" >> /etc/fail2ban/jail.local
#Block the failed login attempts on the SSH server.
echo "[ssh]" >> /etc/fail2ban/jail.local
echo "enabled = true" >> /etc/fail2ban/jail.local
echo "port = ${port}" >> /etc/fail2ban/jail.local
echo "filter = sshd" >> /etc/fail2ban/jail.local
echo "logpath = /var/log/auth.log" >> /etc/fail2ban/jail.local
echo "maxretry = 4" >> /etc/fail2ban/jail.local
echo "bantime = 300" >> /etc/fail2ban/jail.local

touch /etc/fail2ban/filter.d/http-get-dos.conf
# Fail2Ban configuration file 
echo "[Definition]" > /etc/fail2ban/filter.d/http-get-dos.conf
echo "failregex = ^<HOST> -.*\"(GET|POST).*" >> /etc/fail2ban/filter.d/http-get-dos.conf
echo "ignoreregex =" >> /etc/fail2ban/filter.d/http-get-dos.conf

#to unban yourseld or another ip
#sudo fail2ban-client set http-get-dos unbanip {ip_address}
##

##protect against portscans

#set advanced mode
sed -i 's/TCP_MODE="tcp"/TCP_MODE="atcp"/' /etc/default/portsentry
sed -i 's/UDP_MODE="tcp"/UDP_MODE="audp"/' /etc/default/portsentry

#set to block
sed -i 's/BLOCK_UDP="0"/BLOCK_UDP="1"/' /etc/portsentry/portsentry.conf
sed -i 's/BLOCK_TCP="0"/BLOCK_TCP="1"/' /etc/portsentry/portsentry.conf

#add offender to iptables drop
sed -i 's/KILL_ROUTE=\"\/sbin\/route add -host $TARGET$ reject\"/KILL_ROUTE=\"\/sbin\/iptables -I INPUT -s $TARGET$ -j DROP\"/' /etc/portsentry/portsentry.conf

#add offender to /etc/hosts.deny
#add to /etc/portsentry/portsentry.conf, however this is default in new version
#KILL_HOSTS_DENY="ALL: $TARGET$ : DENY"

#restart service
sudo service portsentry restart

fi




#cron setup
if [ ${input} == 6 ]; then
#make autoupdate file into /etc/autoupdate
echo "apt update -y" > /etc/autoupdate
echo "apt upgrade -y" >> /etc/autoupdate
chmod 755 /etc/autoupdate

#edit cron to run this at Sunday 4am and at reboot
echo "@reboot root /etc/autoupdate >> /var/log/update_script.log" >> /etc/crontab
echo "0 4 * * 7 root /etc/autoupdate >> /var/log/update_script.log" >> /etc/crontab

#setup mail alert when crontab has been edited
touch /etc/crontab_modfile

echo "set askcc=False;" >> ~/.mailrc

echo "ORIGMD5=\$(cat /etc/crontab_modfile)" > /etc/mailalert.sh
echo "NEWMD5=\$(md5sum /etc/crontab)" >> /etc/mailalert.sh
echo "if [[ \"\$ORIGMD5\" != \"\$NEWMD5\" ]]" >> /etc/mailalert.sh
echo " then" >> /etc/mailalert.sh
echo "  echo \"Crontab has been modified.\" | mail -s \"Crontab change\" root" >> /etc/mailalert.sh
echo "  ORIGMD5=\$NEWMD5" >> /etc/mailalert.sh
echo "fi" >> /etc/mailalert.sh
echo "echo \"\$(md5sum /etc/crontab)\" > /etc/crontab_modfile" >> /etc/mailalert.sh

chmod 755 /etc/mailalert.sh

echo "0 0 * * * root /etc/mailalert.sh" >> /etc/crontab
fi



#setup all
if [ ${input} == 7 ]; then

#ip setup 
echo "AFTER THIS, YOU WILL HAVE TO CHANGE YOUR NETWORKS TO HOST-ONLY FIRST AND NAT SECOND."

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
IP=$(ip a | grep -w inet | awk '{print $2}' |  sed -n 2p)
GATEWAY=$(netstat -nr | grep enp0s3 | awk '{print $2}' | sed '3d;q')

#configure /etc/network/interfaces
echo $'auto lo\niface lo inter loopback\n' > /etc/network/interfaces
echo $'auto enp0s3\niface enp0s3 inet static' >> /etc/network/interfaces
echo "address ${address}" >> /etc/network/interfaces
echo "netmask ${netmask}" >> /etc/network/interfaces

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




#user setup
#add user
echo "Please give username."
read user
sudo adduser ${user}

#add sudo privileges to user
sudo adduser ${user} sudo

#create ssh folder
mkdir /home/${user}/.ssh
touch /home/${user}/.ssh/authorized_keys

#copy id_rsa.pub from host
echo "Copying public key from host..."
echo "Please give host ip address."
read HOST_ADDR
echo "Please enter host password when prompted."
scp esormune@${HOST_ADDR}:.ssh/id_rsa.pub /home/${user}/.ssh/authorized_keys






#services setup
#update system
sudo apt update -y
sudo apt upgrade -y

#update necessary tools
sudo apt install ufw portsentry fail2ban apache2 mailutils net-tools -y

#stop all unneccessary services
sudo systemctl disable console-setup.service
sudo systemctl disable keyboard-setup.service





#ssh setup
#declare port number
exists=$(cat /etc/ssh/sshd_config | grep -w "Port" | grep -v ^\#)
if [ ! -z "${exists}" ]; then
	oldport=$(cat /etc/ssh/sshd_config | grep -w "Port" | grep -v ^\# | \
		egrep -o '[0-9]+')
	echo "Please give port number to replace ${oldport}."
	read newport
	sed -i "s/Port $oldport/Port $newport/" /etc/ssh/sshd_config
else
	echo "Please give port number."
	read newport
	echo "Port ${newport}" >> /etc/ssh/sshd_config
fi

#deny rootlogin
rlogin=$(cat /etc/ssh/sshd_config |  grep -w "PermitRootLogin" | grep -v ^\# | \
	grep "No")
if [ -z "${rlogin}" ]; then
	echo "PermitRootLogin No" >> /etc/ssh/sshd_config
	sed -i 's/PermitRootLogin [Yy]es//' /etc/ssh/sshd_config
fi

#deny password authentication
pword=$(cat /etc/ssh/sshd_config |  grep -w "PasswordAuthentication" | grep -v ^\# | \
	grep "No")
if [ -z "${pword}" ]; then
	echo "PasswordAuthentication No" >> /etc/ssh/sshd_config
	sed -i 's/#PasswordAuthentication [Yy]es//' /etc/ssh/sshd_config
	sed -i 's/PasswordAuthentication [Yy]es//' /etc/ssh/sshd_config
fi




#firewall setup
#enable firewall
sudo ufw enable

#allow ssh, http, and https
sudo ufw default deny incoming
sudo ufw default allow outgoing
ufw allow ${newport}/tcp
ufw allow 80
ufw allow 443

##protect against DoS

#Create and update fail2ban.local
touch /etc/fail2ban/fail2ban.local

#Basic Configuration
echo "[DEFAULT]" > /etc/fail2ban/fail2ban.local
echo "loglevel = INFO" >> /etc/fail2ban/fail2ban.local
echo "logtarget = /var/log/fail2ban.log" >> /etc/fail2ban/fail2ban.local

#Create and update jail.local
touch /etc/fail2ban/jail.local

#Stop DOS attack from remote host. 
echo "[http-get-dos]" > /etc/fail2ban/jail.local
echo "enabled = true" >> /etc/fail2ban/jail.local
echo "port = http,https" >> /etc/fail2ban/jail.local
echo "filter = http-get-dos" >> /etc/fail2ban/jail.local
echo "logpath = /var/log/apache2/access.log" >> /etc/fail2ban/jail.local
echo "maxretry = 200" >> /etc/fail2ban/jail.local
echo "findtime = 200" >> /etc/fail2ban/jail.local
echo "bantime = 600" >> /etc/fail2ban/jail.local
echo "action = iptables[name=HTTP, port=http, protocol=tcp]" >> /etc/fail2ban/jail.local
#Block the failed login attempts on the SSH server.
echo "[ssh]" >> /etc/fail2ban/jail.local
echo "enabled = true" >> /etc/fail2ban/jail.local
echo "port = ${port}" >> /etc/fail2ban/jail.local
echo "filter = sshd" >> /etc/fail2ban/jail.local
echo "logpath = /var/log/auth.log" >> /etc/fail2ban/jail.local
echo "maxretry = 4" >> /etc/fail2ban/jail.local
echo "bantime = 300" >> /etc/fail2ban/jail.local

touch /etc/fail2ban/filter.d/http-get-dos.conf
# Fail2Ban configuration file 
echo "[Definition]" > /etc/fail2ban/filter.d/http-get-dos.conf
echo "failregex = ^<HOST> -.*\"(GET|POST).*" >> /etc/fail2ban/filter.d/http-get-dos.conf
echo "ignoreregex =" >> /etc/fail2ban/filter.d/http-get-dos.conf

#to unban yourseld or another ip
#sudo fail2ban-client set http-get-dos unbanip {ip_address}
##

##protect against portscans

#set advanced mode
sed -i 's/TCP_MODE="tcp"/TCP_MODE="atcp"/' /etc/default/portsentry
sed -i 's/UDP_MODE="tcp"/UDP_MODE="audp"/' /etc/default/portsentry

#set to block
sed -i 's/BLOCK_UDP="0"/BLOCK_UDP="1"/' /etc/portsentry/portsentry.conf
sed -i 's/BLOCK_TCP="0"/BLOCK_TCP="1"/' /etc/portsentry/portsentry.conf

#add offender to iptables drop
sed -i 's/KILL_ROUTE=\"\/sbin\/route add -host $TARGET$ reject\"/KILL_ROUTE=\"\/sbin\/iptables -I INPUT -s $TARGET$ -j DROP\"/' /etc/portsentry/portsentry.conf

#add offender to /etc/hosts.deny
#add to /etc/portsentry/portsentry.conf, however this is default in new version
#KILL_HOSTS_DENY="ALL: $TARGET$ : DENY"

#restart service
sudo service portsentry restart


#cron setup
#make autoupdate file into /etc/autoupdate
echo "apt update -y" > /etc/autoupdate.sh
echo "apt upgrade -y" >> /etc/autoupdate.sh
chmod 755 /etc/autoupdate.sh

#edit cron to run this at Sunday 4am and at reboot
echo "@reboot root /etc/autoupdate >> /var/log/update_script.log" >> /etc/crontab
echo "0 4 * * 7 root /etc/autoupdate >> /var/log/update_script.log" >> /etc/crontab

#setup mail alert when crontab has been edited
touch /etc/crontab_modfile

echo "set askcc=False;" >> ~/.mailrc

echo "ORIGMD5=\$(cat /etc/crontab_modfile)" > /etc/mailalert.sh
echo "NEWMD5=\$(md5sum /etc/crontab)" >> /etc/mailalert.sh
echo "if [[ \"\$ORIGMD5\" != \"\$NEWMD5\" ]]" >> /etc/mailalert.sh
echo " then" >> /etc/mailalert.sh
echo "  echo \"Crontab has been modified.\" | mail -s \"Crontab change\" root" >> /etc/mailalert.sh
echo "  ORIGMD5=\$NEWMD5" >> /etc/mailalert.sh
echo "fi" >> /etc/mailalert.sh
echo "echo \"\$(md5sum /etc/crontab)\" > /etc/crontab_modfile" >> /etc/mailalert.sh

chmod 755 /etc/mailalert.sh

echo "0 0 * * * root /etc/mailalert.sh" >> /etc/crontab




echo "Setup complete. Please change network settings to host-only and nat from vm host, and reboot."
fi