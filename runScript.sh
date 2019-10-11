#!/bin/bash

# -------------------------------------------------------- #
# ----------------------- rsyslog ------------------------ #
# -------------------------------------------------------- #

# Install rsyslog

#sudo apt-get install npm
sudo apt-get install rsyslog


# Configure rsyslog


sudo chmod -R a+rwX /etc/rsyslog.d

sudo echo "# Input File Location
input(type=\"imfile\" ruleset=\"infiles\" Tag=\"cpusys-logger\" File=\"/home/rav/Desktop/Logger/Logs/con.log\" stateFile=\"\")

# Log Format
\$template DatadogFormat,\"f857885e2718c8b01a562a164d1b721c <%pri%>%protocol-version% %timestamp:::date-rfc3339% %HOSTNAME% %app-name% - - - %msg%\"

# Log Rules
ruleset(name=\"infiles\") {
	action(type=\"omfwd\" target=\"intake.logs.datadoghq.com\" protocol=\"tcp\" port=\"10514\" Template=\"DatadogFormat\")
}" >> /etc/rsyslog.d/datadog.conf


sudo chmod -R a+rwX /etc/rsyslog.conf
sudo echo "module(load=\"imfile\" PollingInterval=\"30\")" >> /etc/rsyslog.conf

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

# Logger Script
sudo echo "#!/bin/bash
while : 
do	

	sudo echo \{ \\\"Time\\\": \`date +%s\`\, \\\"Host\\\": \\\"\`hostname\`\\\"\, \\\"CPU\\\": \`LC_ALL=C top -bn1 | grep \"Cpu(s)\" | sed \"s/.*, *\([0-9.]*\)%* id.*/\1/\" | awk '{print 100 - \$1}'\`\, \\\"RAM\\\": \`free -m | awk '/Mem:/ { printf(\$3/\$2*100) }'\`\, \\\"HDD\\\": \`df -h / | sed 's/%//' | awk '/\// {print \$(NF-1)}'\` \} >> /var/log/cpusys-logger/Logs/cpusys.log
	sleep 5
	sudo python2 /var/log/cpusys-logger/Scripts/consolScript.py -i /var/log/cpusys-logger/Logs/cpusys.log -o /var/log/cpusys-logger/Logs/con.log
	sleep 20
done" > /var/log/cpusys-logger/Scripts/logScript.sh

# Turn Logger to Executable
sudo chmod a+x /var/log/cpusys-logger/Scripts/logScript.sh

# Grant Access to Folder
sudo chmod -R a+rwX /lib/systemd/system

# Create Logger Service
sudo echo "[Unit]
Description=cpusys-logging

[Service]
ExecStart=/var/log/cpusys-logger/Scripts/logScript.sh


[Install]
WantedBy=multi-user.target" >> /lib/systemd/system/cpusys-logging.service


# -------------------------------------------------------- #
# ------------------ File Consolidation ------------------ #
# -------------------------------------------------------- #

sudo echo "#!/usr/bin/python

import sys, getopt

def main(argv):
   inputfile = ''
   outputfile = ''
   try:
      opts, args = getopt.getopt(argv,\"hi:o:\",[\"ifile=\",\"ofile=\"])
   except getopt.GetoptError:
      sys.exit(2)

   for opt, arg in opts:
      if opt == '-h':
         sys.exit()
      elif opt in (\"-i\", \"--ifile\"):
         inputfile = arg
	 f= open(inputfile, \"r\")
	 linelist = f.readlines()
	 f.close()
      elif opt in (\"-o\", \"--ofile\"):
         outputfile = arg
	 f2= open(outputfile, \"ra+\")
	 rlist=f2.readlines()
	 num = len(rlist)

	 if(num == 0):
		#f2.write(linelist[len(linelist)-1].strip('\r\n')) 
		f2.write(linelist[len(linelist)-1]) 
	 else:	
	 	#f2.write(\",\".strip('\r\n')+linelist[len(linelist)-1].strip('\r\n')) 
		f2.write(linelist[len(linelist)-1]) 
	 f2.close()

if __name__ == \"__main__\":
   main(sys.argv[1:])" >> /var/log/cpusys-logger/Scripts/consolScript.py


sudo echo "" > /var/log/cpusys-logger/Logs/con.log

# -------------------------------------------------------- #
# --------------------- Run Services --------------------- #
# -------------------------------------------------------- #

# Run rsyslog Service
sudo systemctl start rsyslog
sudo systemctl enable rsyslog


# Run Logging Service
sudo systemctl start cpusys-logging
sudo systemctl enable cpusys-logging


echo "Done"





