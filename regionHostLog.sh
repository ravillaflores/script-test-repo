#!/bin/bash


sudo echo "Begin Installation..."

sudo echo "Installing rsyslog"
# -------------------------------------------------------- #
# ----------------------- rsyslog ------------------------ #
# -------------------------------------------------------- #

# Install rsyslog

sudo echo "Installing Dependecies..."
#sudo apt-get install npm
sudo apt-get remove -y rsyslog
sudo apt-get purge -y rsyslog
sudo add-apt-repository -y ppa:adiscon/v8-stable
sudo apt-get update -y
sudo apt-get install -y rsyslog
sudo systemctl stop syslog.socket rsyslog.service
sudo apt install -y python-minimal
sudo apt install -y python-boto3

sudo echo "Configuring rsyslog..."
# Configure rsyslog
sudo chmod -R a+rwX /etc/rsyslog.d

sudo echo "Creating Datadog Config..."
sudo echo "# Input File Location
input(type=\"imfile\" ruleset=\"infiles\" Tag=\"cpusys-logger\" File=\"/var/log/cpusys-logger/Logs/con.log\" PersistStateInterval=\"0\")

# Log Format
\$template DatadogFormat,\"18ba51aa66a64c1fa6dde59feb8145ce <%pri%>%protocol-version% %timestamp:::date-rfc3339% %HOSTNAME% %app-name% - - - %msg%\"

# Log Rules
ruleset(name=\"infiles\") {
	action(type=\"omfwd\" target=\"intake.logs.datadoghq.com\" protocol=\"tcp\" port=\"10514\" Template=\"DatadogFormat\")
}" > /etc/rsyslog.d/datadog.conf

sudo echo "Accessing Config File..."
# Grant Access to File
sudo chmod -R a+rwX /etc/rsyslog.conf


sudo echo "Patching Config File..."
# Edit Rsyslog Config File
sudo echo "#  /etc/rsyslog.conf	Configuration file for rsyslog.
#
#			For more information see
#			/usr/share/doc/rsyslog-doc/html/rsyslog_conf.html
#
#  Default logging rules can be found in /etc/rsyslog.d/50-default.conf


#################
#### MODULES ####
#################

\$ModLoad imuxsock # provides support for local system logging
\$ModLoad imklog   # provides kernel logging support (previously done by rklogd)

module(load=\"imfile\" PollingInterval=\"30\")

\$ModLoad immark  # provides --MARK-- message capability
\$MarkMessagePeriod 20

# provides UDP syslog reception
#\$ModLoad imudp
#\$UDPServerRun 514

# provides TCP syslog reception
#\$ModLoad imtcp
#\$InputTCPServerRun 514


###########################
#### GLOBAL DIRECTIVES ####
###########################

#
# Use traditional timestamp format.
# To enable high precision timestamps, comment out the following line.
#
\$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat

# Filter duplicated messages
\$RepeatedMsgReduction on

#
# Set the default permissions for all log files.
#
\$FileOwner syslog
\$FileGroup adm
\$FileCreateMode 0640
\$DirCreateMode 0755
\$Umask 0022
\$PrivDropToUser syslog
\$PrivDropToGroup syslog

#
# Where to place spool files
#
\$WorkDirectory /var/spool/rsyslog

#
# Include all config files in /etc/rsyslog.d/
#
\$IncludeConfig /etc/rsyslog.d/*.conf" > /etc/rsyslog.conf

sudo echo "Installing cpusys-logger..."
# -------------------------------------------------------- #
# ----------------------- Logger ------------------------- #
# -------------------------------------------------------- #

sudo echo "Creating Folders..."
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

echo "Writing Script Files..."
# DataDog Source Folder Change
sudo echo "#!/bin/bash

echo \"\$1 this is the param\"
sudo echo \"Changing Datadog Config...\"
sudo echo \"# Input File Location
input(type=\\\"imfile\\\" ruleset=\\\"infiles\\\" Tag=\\\"cpusys-logger\\\" File=\\\"\$1\\\" PersistStateInterval=\\\"0\\\")

# Log Format
\\\$template DatadogFormat,\\\"18ba51aa66a64c1fa6dde59feb8145ce <%pri%>%protocol-version% %timestamp:::date-rfc3339% %HOSTNAME% %app-name% - - - %msg%\\\"

# Log Rules
ruleset(name=\\\"infiles\\\") {
	action(type=\\\"omfwd\\\" target=\\\"intake.logs.datadoghq.com\\\" protocol=\\\"tcp\\\" port=\\\"10514\\\" Template=\\\"DatadogFormat\\\")
}\" > /etc/rsyslog.d/datadog.conf

" > /var/log/cpusys-logger/Scripts/dd-refactor.sh

sudo chmod a+x /var/log/cpusys-logger/Scripts/dd-refactor.sh

# Logger Script
sudo echo "#!/bin/bash

	ec2_avail_zone=\`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone\`
	ec2_region=\"\`echo \"\$ec2_avail_zone\" | sed 's/[a-z]$//'\`\"
	ec2_instance_id=\`curl -s http://169.254.169.254/latest/meta-data/instance-id\`
	ec2_name=\$(aws ec2 describe-tags --region \$ec2_region --filters \"Name=resource-id,Values=\$ec2_instance_id\" \"Name=key,Values=Name\" --output text | cut -f5)

while : 
do	
	pathFolder=/var/log/cpusys-logger/Logs
	varDate=\`date +%y-%m-%d\`
	varFile=\"sys-\$varDate.log\"
	filePath=\`find \$pathFolder -type f -name \"\$varFile\"\`


	if [ -f \"\$filePath\" ]; then
		echo \"\$filePath exists\"
	else
		newFilePath=\$pathFolder\\/\$varFile
		echo \"\$newFilePath does not exist, creating file\"
		echo "" >> \$newFilePath
		sudo chmod -R a+rwX \$newFilePath
		. /var/log/cpusys-logger/Scripts/dd-refactor.sh \$newFilePath
		sudo systemctl restart rsyslog
	fi

	date_diff=2
	varDateRM=\`date --date=\"\$varDate -\$date_diff days\" +%y-%m-%d\`
	varFileRM=\"sys-\$varDateRM.log\"
	filePathRM=\`find \$pathFolder -type f -name \"\$varFileRM\"\`

	
	if [ -f \"\$filePathRM\" ]; then
		echo \"\$filePathRM exists, deleting file...\"
		sudo rm -f \$filePathRM
		echo \"\$filePathRM is deleted.\"
	else
		echo \"\$filePathRM does not exists\"
	fi



	sudo echo \{ \\\"Time\\\": \`date +%s\`\, \\\"Host\\\": \\\"\`\$ec2_name\`\\\"\, \\\"CPU\\\": \`LC_ALL=C top -bn1 | grep \"Cpu(s)\" | sed \"s/.*, *\([0-9.]*\)%* id.*/\1/\" | awk '{print 100 - \$1}'\`\, \\\"RAM\\\": \`free -m | awk '/Mem:/ { printf(\$3/\$2*100) }'\`\, \\\"HDD\\\": \`df -h / | sed 's/%//' | awk '/\// {print \$(NF-1)}'\` \} >> \$newFilePath
	
	sleep 30

	
done" > /var/log/cpusys-logger/Scripts/logScript.sh


echo "Creating Service..."
# Turn Logger to Executable
sudo chmod a+x /var/log/cpusys-logger/Scripts/logScript.sh

# Grant Access to Log Service
sudo chmod -R a+rwX /lib/systemd/system
sudo chmod -R a+rwX /lib/systemd/system

echo "Initializing Service..."
# Create Logger Service
sudo echo "[Unit]
Description=cpusys-logging

[Service]
ExecStart=/var/log/cpusys-logger/Scripts/logScript.sh


[Install]
WantedBy=multi-user.target" > /lib/systemd/system/cpusys-logging.service


echo "Writing Consolidation Script Service..."
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


# Grant Access to Modify Log Files
sudo chmod -R a+rwX /var/spool/rsyslog

# -------------------------------------------------------- #
# --------------------- Run Services --------------------- #
# -------------------------------------------------------- #

echo "Running rsyslog Service..."
# Run rsyslog Service
sudo systemctl start rsyslog
sudo systemctl enable rsyslog
sudo systemctl restart rsyslog

echo "Running cpusys-logger Service..."
# Run Logging Service
sudo systemctl start cpusys-logging
sudo systemctl enable cpusys-logging


echo "Done"





