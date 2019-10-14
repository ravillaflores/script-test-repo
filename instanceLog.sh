#!/bin/bash


echo "Begin Installation..."
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


# Get KeyPair.pem file and put in folder /var/log/cpusys-logger/Scripts (name it KeyPair.pem)
# This is only a sample key pair for testing, add here the keypair
sudo echo "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAjFfH+5qNfhkNZ9xOLEvnTr5wMVl1HhPvhLjffRJKa0PaH2kl7dAUAcmAulLb
W1NulZdqJdLu5GC8lPYJ+qEE+A5sKIWGUHIDSUiUjxjTSRQhR8dxWa/K2EQoe2U8XyMYNfDGpDXE
X33rcyE+aXJlHnXcvUXlAq+Zcg2KiViQOAWxdSyhfebLJzebI7564yeBuZmiWwS/eBT6dlHvonvg
aUCMMGNlo7g4GN6sTIF5UGYPxqAsblXoyzWBu+Fq1iMVaeijUU0PuW+AneIhmHhSHBeof1cvxrex
ajsfDy4ZAtYzUYzeIooGl2pcX1H6AlbH/oopC5q9HQrd6ilQGBwzOwIDAQABAoIBAALaNeJTPdT2
RWN7Asu7rzPWgwk9vDekSBX2e/RaztBnTKOey3qN5Bo1MjyXOoYcp/66WRnzs49IuAx/A6zoYOV5
xZD9RcGUz6RJqVtPMdwmYJbI4vDjtce3eusnH5b/a5qNDjyAK0GVmZd5cX9LJ+r6kkX2ibUIRKIg
zFQGTMgWrcl9xQNAg1iuK/5jwUcEDsApeY3MlXCdWF7P6V57a/6w3g+v5tfilan9BptCBIhn9cNN
QLDKxnSr2Arqe7BgkqyUe1sm9WazXee7Gqg+PmUqGoYc04akNssajObEEvFjwKUZLSNfM2ochSfE
0ra1zSbiRqL210laKMCvlqRJOGECgYEA0lfe7aQAXDKYOO6bhU3/c/OeWOXILuWw7UzrwL5ADImR
ds1UiAWNpZpqLIlvgtsjvAdvHMasTTorIP2KkU0nAjlkB0NKM194z8ACqR+1ytDiy3OI8xeVvmwz
iYZRDfMt9gdHpAfWagCMnBbfc7IDM1vEJSEFMWQTCArSmQK7xsUCgYEAqs40nuXoPYZlmK6me5Wr
LHteINpNn7eGdOpOUQatIR0FCoSBsdbH30K+L8FppICyJogHjJI9WxirrqCj/qevYWHhpJTen0y/
ORy3ze41VjTQ+8FcJPRfLMf1Ifdg8WkVyEYTmI64dSFB1Pv1gcp2M6Om+OpM2VTAFF1Z62JHsf8C
gYBX+FoKx0lDRgG15czzPoC07NFv2oITYwrQ5BfBH5BH7g0BQ7SzwqbP+Lmo8L3LW30heXZ18X1E
OyyoeoFGbZ7/5iK4iuLwg2BSerpiIxnzvdLsReCj0lxVLImNXbhufiLdv4OtzX1WDe7ApSxFBdEi
3KE26g1y76ip92TGi4cfBQKBgH7HN3+JnmusSdSeLawlVzxZBXDVGDCohABbuW2iyvZ9F7TKzYk2
pnwsigXgRY14iMLYzOGl2iy3jxa63X6y8BYUFOuYI/WRfY3ipvsPCD/ITCXRS5eSWuJeOLDRcP8+
xJA2k2z04izuVnLD4WJI6JtDqTewkQHvSfLTp15zQEv5AoGBAMdXaaUNeHD2Vw/JNNHaoUtHr5k1
6h60779CdrmDfYf/+Psm2nyOY8gzGC7r47klMkrwtIieZGjVi9Ze5+OqOKC5ff9vGjAHIs9wbBzu
tGj5DTwCbDa9TQdOfbFEX6vFdj9vk3eSPei28A4rzsq6M2dWWtpAAnhS9tWoC5WRdQCW
-----END RSA PRIVATE KEY-----" > /var/log/cpusys-logger/Scripts/keyPair.pem

sudo chmod 400 /var/log/cpusys-logger/Scripts/keyPair.pem

echo "Writing Logger Script..."
# Logger Script
sudo echo "#!/bin/bash
while : 
do	
	sudo echo \{ \\\"Time\\\": \`date +%s\`\, \\\"Host\\\": \\\"\`hostname\`\\\"\, \\\"CPU\\\": \`LC_ALL=C top -bn1 | grep \"Cpu(s)\" | sed \"s/.*, *\([0-9.]*\)%* id.*/\1/\" | awk '{print 100 - \$1}'\`\, \\\"RAM\\\": \`free -m | awk '/Mem:/ { printf(\$3/\$2*100) }'\`\, \\\"HDD\\\": \`df -h / | sed 's/%//' | awk '/\// {print \$(NF-1)}'\` \} | ssh -o StrictHostKeyChecking=no -i '/var/log/cpusys-logger/Scripts/keyPair.pem' ubuntu@ec2-18-140-236-240.ap-southeast-1.compute.amazonaws.com -t 'bash -l -c \"sudo cat >> /var/log/cpusys-logger/Logs/con.log | bash ;bash\"'
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


sudo echo "" > /var/log/cpusys-logger/Logs/con.log
sudo echo "" > /var/log/cpusys-logger/Logs/cpusys.log

# Grant Access to Modify Log Files
sudo chmod -R a+rwX /var/log/cpusys-logger/Logs/cpusys.log
sudo chmod -R a+rwX /var/log/cpusys-logger/Logs/con.log

# -------------------------------------------------------- #
# --------------------- Run Services --------------------- #
# -------------------------------------------------------- #


echo "Running CPUsys-Logger Service..."
# Run Logging Service
sudo systemctl start cpusys-logging
sudo systemctl enable cpusys-logging


echo "Installation Finished..."





