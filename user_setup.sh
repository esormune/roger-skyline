#add user
echo "Please give username."
read user
sudo adduser ${user}

#add sudo privileges to user
sudo adduser ${user} sudo

#create ssh folder
mkdir /home/${user}/ssh
touch /home/${user}/ssh/authorized_keys

#copy id_rsa.pub from host
echo "Copying public key from host..."
scp esormune@${IP_ADDR}:.ssh/id_rsa.pub /home/${user}/ssh/authorized_keys