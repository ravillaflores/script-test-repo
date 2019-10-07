#!/bin/bash



if [ -d "/var/log/cpusys-logger" ] 
then
	if [ -d "/var/log/cpusys-logger/Logs" ] 
	then
		echo ""
	else
		sudo mkdir /var/log/cpusys-logger/Logs
	fi
else
	sudo mkdir /var/log/cpusys-logger
	sudo mkdir /var/log/cpusys-logger/Logs
	sudo mkdir /var/log/cpusys-logger/Scripts
fi


echo -e "
while : 
do	

	echo \{ \"Time\": `date +%s`\, \"Host\": \"`hostname`\"\, \"CPU\": `LC_ALL=C top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'`\, \"RAM\": `free -m | awk '/Mem:/ { printf($3/$2*100) }'`\, \"HDD\": `df -h / | sed 's/%//' | awk '/\// {print $(NF-1)}'` \} >> sudo /var/log/cpusys-logger/Logs/cpusys.log

	sleep 60
done " >> sudo /var/log/cpusys-logger/Scripts/logScript.sh


sudo chmod +x /var/log/cpusys-logger/Scripts/logScript.sh


