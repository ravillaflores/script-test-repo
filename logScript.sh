#!/bin/bash

echo "creating cpusys..."
MKSYS=$'sudo mkdir ~/Desktop/cpusys'
${MKSYS//[$'\t\r\n']}
echo "creating Script..."
sudo mkdir ~/Desktop/cpusys/Script
MKSCRIPT=$'sudo mkdir ~/Desktop/cpusys/Script'
${MKSCRIPT//[$'\t\r\n']}
echo "creating log file..."
sudo mkdir ~/Desktop/cpusys/Script/Logs

while : 
do	

	sudo echo \{ \"Time\": `date +%s`\, \"Host\": \"`hostname`\"\,   \"CPU\": `LC_ALL=C top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'`\, \"RAM\": `free -m | awk '/Mem:/ { printf($3/$2*100) }'`\, \"HDD\": `df -h / | sed 's/%//' | awk '/\// {print $(NF-1)}'` \} >> ~/Desktop/cpusys/Script/Logs/cpusys.log

	sleep 60
done
