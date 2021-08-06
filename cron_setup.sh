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

echo "ORIGMD5=\$(cat /etc/crontab_modfile)" > /etc/mailalert
echo "NEWMD5=\$(md5sum /etc/crontab)" >> /etc/mailalert
echo "if [[ \"\$ORIGMD5\" != \"\$NEWMD5\" ]]" >> /etc/mailalert
echo " then" >> /etc/mailalert
echo "  echo \"Crontab has been modified.\" | mail -s \"Crontab change\" root" >> /etc/mailalert
echo "  ORIGMD5=\$NEWMD5" >> /etc/mailalert
echo "fi" >> /etc/mailalert
echo "echo \"\$(md5sum /etc/crontab)\" > /etc/crontab_modfile" >> /etc/mailalert

chmod 755 /etc/mailalert

echo "0 0 * * * root /etc/mailalert" >> /etc/crontab