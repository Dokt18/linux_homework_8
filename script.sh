touch /etc/sysconfig/watchlog
echo '# Configuration file for my watchlog service
# Place it to /etc/sysconfig

# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log' > /etc/sysconfig/watchlog

touch /var/log/watchlog.log
echo 'ALERT' > /var/log/watchlog.log

touch /opt/watchlog.sh
echo '#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi' > /opt/watchlog.sh

chmod +x /opt/watchlog.sh

touch /etc/systemd/system/watchlog.service
echo '[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG' > /etc/systemd/system/watchlog.service

touch /etc/systemd/system/watchlog.timer
echo '[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/watchlog.timer

systemctl start watchlog.timer
systemctl start watchlog.service


sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y

echo 'SOCKET=/var/run/php-fcgi.sock' >> /etc/sysconfig/spawn-fcgi
echo 'OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"' >> /etc/sysconfig/spawn-fcgi

touch /etc/systemd/system/spawn-fcgi.service
echo '[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/spawn-fcgi.service
systemctl start spawn-fcgi

echo '# See httpd.service(8) for more information on using the httpd service.

# Modifying this file in-place is not recommended, because changes
# will be overwritten during package upgrades.  To customize the
# behaviour, run "systemctl edit httpd" to create an override unit.

# For example, to pass additional options (such as -D definitions) to
# the httpd binary at startup, create an override unit (as is done by
# systemctl edit) and enter the following:

#       [Service]
#       Environment=OPTIONS=-DMY_DEFINE

[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service
After=network.target remote-fs.target nss-lookup.target httpd-init.service
Documentation=man:httpd.service(8)

[Service]
Type=notify
Environment=LANG=C
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target' > /usr/lib/systemd/system/httpd.service

touch /etc/sysconfig/httpd-first
touch /etc/sysconfig/httpd-second
echo 'OPTIONS=-f conf/first.conf' >> /etc/sysconfig/httpd-first
echo 'OPTIONS=-f conf/second.conf' >> /etc/sysconfig/httpd-second

cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
echo 'PidFile /var/run/httpd-second.pid' >> /etc/httpd/conf/second.conf
sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/second.conf
systemctl start httpd@first
systemctl start httpd@second
