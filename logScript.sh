#!/bin/bash


sudo mkdir ~/Desktop/cpusys
sudo mkdir ~/Desktop/cpusys/Script
sudo mkdir ~/Desktop/cpusys/Script/Logs

while : 
do	

	echo \{ \"Time\": `date +%s`\, \"Host\": \"`hostname`\"\,   \"CPU\": `LC_ALL=C top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'`\, \"RAM\": `free -m | awk '/Mem:/ { printf($3/$2*100) }'`\, \"HDD\": `df -h / | sed 's/%//' | awk '/\// {print $(NF-1)}'` \} >> /home/rav/Desktop/Logger2/Logs/cpusys.log

	sleep 60
done

