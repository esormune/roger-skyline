#update system
sudo apt update -y
sudo apt upgrade -y

#update necessary tools
sudo apt install sudo ufw portsentry fail2ban apache2 mailutils net-tools -y

#stop all unneccessary services
sudo systemctl disable console-setup.service
sudo systemctl disable keyboard-setup.service
