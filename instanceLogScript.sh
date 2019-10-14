#!/bin/bash
#!/bin/bash

# -------------------------------------------------------- #
# ----------------------- rsyslog ------------------------ #
# -------------------------------------------------------- #

# Install rsyslog

#sudo apt-get install npm
sudo apt-get remove -y rsyslog
sudo apt-get purge -y rsyslog
sudo add-apt-repository -y ppa:adiscon/v8-devel
sudo apt-get update -y
sudo apt-get install -y rsyslog
sudo apt install -y python-minimal


# -------------------------------------------------------- #
# ----------------------- Logger ------------------------- #
# -------------------------------------------------------- #

# Create Directory inside /var/log
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

# Grant Access to modify
sudo chmod -R a+rwX /var/log/
sudo chmod -R a+rwX /var/log/cpusys-logger
sudo chmod -R a+rwX /var/log/cpusys-logger/Logs
sudo chmod -R a+rwX /var/log/cpusys-logger/Scripts

# Logger Script
sudo echo "#!/bin/bash
while : 
do	
	sudo echo \{ \\\"Time\\\": \`date +%s\`\, \\\"Host\\\": \\\"\`hostname\`\\\"\, \\\"CPU\\\": \`LC_ALL=C top -bn1 | grep \"Cpu(s)\" | sed \"s/.*, *\([0-9.]*\)%* id.*/\1/\" | awk '{print 100 - \$1}'\`\, \\\"RAM\\\": \`free -m | awk '/Mem:/ { printf(\$3/\$2*100) }'\`\, \\\"HDD\\\": \`df -h / | sed 's/%//' | awk '/\// {print \$(NF-1)}'\` \} >> /var/log/cpusys-logger/Logs/cpusys.log
	sudo echo \{ \\\"Time\\\": \`date +%s\`\, \\\"Host\\\": \\\"\`hostname\`\\\"\, \\\"CPU\\\": \`LC_ALL=C top -bn1 | grep \"Cpu(s)\" | sed \"s/.*, *\([0-9.]*\)%* id.*/\1/\" | awk '{print 100 - \$1}'\`\, \\\"RAM\\\": \`free -m | awk '/Mem:/ { printf(\$3/\$2*100) }'\`\, \\\"HDD\\\": \`df -h / | sed 's/%//' | awk '/\// {print \$(NF-1)}'\` \} | ssh -o StrictHostKeyChecking=no -i '~/Desktop/Logger2/SampleKeyPai.pem' ubuntu@ec2-18-140-236-240.ap-southeast-1.compute.amazonaws.com -t 'bash -l -c \"sudo cat >> /var/log/cpusys-logger/Logs/con.log | bash ;bash\"'
	sleep 25
done" > /var/log/cpusys-logger/Scripts/instanceScript.sh



# Turn Logger to Executable
sudo chmod a+x /var/log/cpusys-logger/Scripts/instanceScript.sh

# Grant Access to Log Service
sudo chmod -R a+rwX /lib/systemd/system
sudo chmod -R a+rwX /lib/systemd/system

# Create Logger Service
sudo echo "[Unit]
Description=cpusys-logging

[Service]
ExecStart=/var/log/cpusys-logger/Scripts/instanceScript.sh


[Install]
WantedBy=multi-user.target" > /lib/systemd/system/cpusys-logging.service

sudo echo "" > /var/log/cpusys-logger/Logs/cpusys.log

# Grant Access to Modify Log Files
sudo chmod -R a+rwX /var/log/cpusys-logger/Logs/cpusys.log

# Run Logging Service
sudo systemctl start cpusys-logging
sudo systemctl enable cpusys-logging


echo "Done"




