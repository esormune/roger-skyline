#declare port number, /etc/ssh/sshd_config
exists=$(cat /Users/esormune/hive/roger-skyline/sshdtest | grep -w "Port" | grep -v ^\#)
if [ ! -z "${exists}" ]; then
	oldport=$(cat /Users/esormune/hive/roger-skyline/sshdtest | grep -w "Port" | grep -v ^\# | \
		egrep -o '[0-9]+')
	echo "Please give port number to replace ${oldport}."
	read newport
	sed -i .bup "s/Port $oldport/Port $newport/" /Users/esormune/hive/roger-skyline/sshdtest
else
	echo "Please give port number."
	read newport
	echo "Port ${newport}" >> /Users/esormune/hive/roger-skyline/sshdtest
fi

#deny rootlogin
rlogin=$(cat /Users/esormune/hive/roger-skyline/sshdtest |  grep -w "PermitRootLogin" | grep -v ^\# | \
	grep "No")
if [ -z "${rlogin}" ]; then
	echo "PermitRootLogin No" >> /Users/esormune/hive/roger-skyline/sshdtest
	sed -i .bup 's/PermitRootLogin [Yy]es//' /Users/esormune/hive/roger-skyline/sshdtest
fi

#deny password authentication
pword=$(cat /Users/esormune/hive/roger-skyline/sshdtest |  grep -w "PasswordAuthentication" | grep -v ^\# | \
	grep "No")
if [ -z "${pword}" ]; then
	echo "PasswordAuthentication No" >> /Users/esormune/hive/roger-skyline/sshdtest
	sed -i .bup 's/#PasswordAuthentication [Yy]es//' /Users/esormune/hive/roger-skyline/sshdtest
	sed -i .bup 's/PasswordAuthentication [Yy]es//' /Users/esormune/hive/roger-skyline/sshdtest
fi