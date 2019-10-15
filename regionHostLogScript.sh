#!/bin/bash


echo "Begin Installation..."
# -------------------------------------------------------- #
# ----------------------- rsyslog ------------------------ #
# -------------------------------------------------------- #

echo "Installing Dependencies..."
# Install rsyslog
#sudo apt-get install npm
sudo apt-get remove -y rsyslog
sudo apt-get purge -y rsyslog
sudo add-apt-repository -y ppa:adiscon/v8-devel
sudo apt-get update -y
sudo apt-get install -y rsyslog
sudo apt install -y python-minimal

echo "Configuring Rsyslog..."
# Configure rsyslog
sudo chmod -R a+rwX /etc/rsyslog.d


echo "Creating Datadog Config File..."
sudo echo "# Input File Location
input(type=\"imfile\" ruleset=\"infiles\" Tag=\"cpusys-logger\" File=\"/var/log/cpusys-logger/Logs/con.log\")

# Log Format
\$template DatadogFormat,\"e48c1d17f8923604339ba68438b4bf5c <%pri%>%protocol-version% %timestamp:::date-rfc3339% %HOSTNAME% %app-name% - - - %msg%\"

# Log Rules
ruleset(name=\"infiles\") {
	action(type=\"omfwd\" target=\"intake.logs.datadoghq.com\" protocol=\"tcp\" port=\"10514\" Template=\"DatadogFormat\")
}" > /etc/rsyslog.d/datadog.conf

echo "Patching Rsyslog Config File..."
# Grant Access to File
sudo chmod -R a+rwX /etc/rsyslog.conf

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

#\$ModLoad imfile
#\$InputFilePollInterval 10
#\$PrivDropToGroup adm
#\$WorkDirectory /var/spool/rsyslog

module(load=\"imfile\" PollingInterval=\"30\")

#\$ModLoad immark  # provides --MARK-- message capability
#\$MarkMessagePeriod 20

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

# -------------------------------------------------------- #
# ----------------------- Logger ------------------------- #
# -------------------------------------------------------- #

echo "Installing CPUsys-Logger..."
echo "Creating Directories..."
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

echo "Writing Logger Script..."
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

# Grant Access to Log Service
sudo chmod -R a+rwX /lib/systemd/system
sudo chmod -R a+rwX /lib/systemd/system

echo "Creating CPUsys-Logger Service..."
# Create Logger Service
sudo echo "[Unit]
Description=cpusys-logging

[Service]
ExecStart=/var/log/cpusys-logger/Scripts/logScript.sh


[Install]
WantedBy=multi-user.target" > /lib/systemd/system/cpusys-logging.service


# -------------------------------------------------------- #
# ------------------ File Consolidation ------------------ #
# -------------------------------------------------------- #


echo "Creating File Consolidation Script..."
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
sudo echo "" > /var/log/cpusys-logger/Logs/cpusys.log

# Grant Access to Modify Log Files
sudo chmod -R a+rwX /var/log/cpusys-logger/Logs/cpusys.log
sudo chmod -R a+rwX var/log/cpusys-logger/Logs/con.log

# -------------------------------------------------------- #
# --------------------- Run Services --------------------- #
# -------------------------------------------------------- #

echo "Running Rsyslog Service..."
# Run rsyslog Service
sudo systemctl start rsyslog
sudo systemctl enable rsyslog
sudo systemctl restart rsyslog


echo "Running CPUsys-Logger Service..."
# Run Logging Service
sudo systemctl start cpusys-logging
sudo systemctl enable cpusys-logging


echo "Installation Finished..."





