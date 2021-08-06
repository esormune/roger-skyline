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
echo "[http-get-dos]" > test
echo "enabled = true" >> test
echo "port = http,https" >> test
echo "filter = http-get-dos" >> test
echo "logpath = /var/log/apache2/access.log" >> test
echo "maxretry = 200" >> test
echo "findtime = 200" >> test
echo "bantime = 600" >> test
echo "action = iptables[name=HTTP, port=http, protocol=tcp]" >> test
#Block the failed login attempts on the SSH server.
echo "[ssh]" >> test
echo "enabled = true" >> test
echo "port = ${port}" >> test
echo "filter = sshd" >> test
echo "logpath = /var/log/auth.log" >> test
echo "maxretry = 4" >> test
echo "bantime = 300" >> test

touch /etc/fail2ban/filter.d/http-get-dos.conf
# Fail2Ban configuration file 
echo "[Definition]" > test2
echo "failregex = ^<HOST> -.*\"(GET|POST).*" >>test2
echo "ignoreregex =" >>test2

#to unban yourseld or another ip
#sudo fail2ban-client set http-get-dos unbanip {ip_address}
##

##protect against portscans

#set advanced mode
sed -i .bup 's/TCP_MODE="tcp"/TCP_MODE="atcp"/' /etc/default/portsentry
sed -i .bup 's/UDP_MODE="tcp"/UDP_MODE="audp"/' /etc/default/portsentry

#set to block
sed -i .bup 's/BLOCK_UDP="0"/BLOCK_UDP="1"/' /etc/portsentry/portsentry.conf
sed -i .bup 's/BLOCK_TCP="0"/BLOCK_TCP="1"/' /etc/portsentry/portsentry.conf

#add offender to iptables drop
sed -i .bup 's/KILL_ROUTE=\"\/sbin\/route add -host $TARGET$ reject\"/KILL_ROUTE=\"\/sbin\/iptables -I INPUT -s $TARGET$ -j DROP\"/' /etc/portsentry/portsentry.conf

#add offender to /etc/hosts.deny
#add to /etc/portsentry/portsentry.conf, however this is default in new version
#KILL_HOSTS_DENY="ALL: $TARGET$ : DENY"

#restart service
sudo service portsentry restart
