#!/bin/bash

echo "Begin Installation..."
echo "Installing cpusys-logger..."
# -------------------------------------------------------- #
# ----------------------- Logger ------------------------- #
# -------------------------------------------------------- #

echo "Creating Folders..."
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

echo "Generating Key Pair..."


echo "Writing Script Files..."
# Logger Script
sudo echo "#!/bin/bash
while : 
do	
	sudo echo \{ \\\"Time\\\": \`date +%s\`\, \\\"Host\\\": \\\"\`hostname\`\\\"\, \\\"CPU\\\": \`LC_ALL=C top -bn1 | grep \"Cpu(s)\" | sed \"s/.*, *\([0-9.]*\)%* id.*/\1/\" | awk '{print 100 - \$1}'\`\, \\\"RAM\\\": \`free -m | awk '/Mem:/ { printf(\$3/\$2*100) }'\`\, \\\"HDD\\\": \`df -h / | sed 's/%//' | awk '/\// {print \$(NF-1)}'\` \} >> /var/log/cpusys-logger/Logs/cpusys.log
	sudo echo \{ \\\"Time\\\": \`date +%s\`\, \\\"Host\\\": \\\"\`hostname\`\\\"\, \\\"CPU\\\": \`LC_ALL=C top -bn1 | grep \"Cpu(s)\" | sed \"s/.*, *\([0-9.]*\)%* id.*/\1/\" | awk '{print 100 - \$1}'\`\, \\\"RAM\\\": \`free -m | awk '/Mem:/ { printf(\$3/\$2*100) }'\`\, \\\"HDD\\\": \`df -h / | sed 's/%//' | awk '/\// {print \$(NF-1)}'\` \} | ssh -o StrictHostKeyChecking=no -i '~/Desktop/Logger2/SampleKeyPai.pem' ubuntu@ec2-18-140-236-240.ap-southeast-1.compute.amazonaws.com -t 'bash -l -c \"sudo cat >> /var/log/cpusys-logger/Logs/con.log | bash ;bash\"'
	sleep 25
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


sudo echo "" > /var/log/cpusys-logger/Logs/con.log
sudo echo "" > /var/log/cpusys-logger/Logs/cpusys.log

# Grant Access to Modify Log Files
sudo chmod -R a+rwX /var/log/cpusys-logger/Logs/cpusys.log
sudo chmod -R a+rwX var/log/cpusys-logger/Logs/con.log

# -------------------------------------------------------- #
# --------------------- Run Services --------------------- #
# -------------------------------------------------------- #

echo "Stopping rsyslog Service..."
# Run rsyslog Service
sudo systemctl stop rsyslog

echo "Running cpusys-logger Service..."
# Run Logging Service
sudo systemctl start cpusys-logging
sudo systemctl enable cpusys-logging


echo "Finished Installation..."





