#!/bin/bash
#Task 1
#Configuring hybrid multi-process multi-threaded httpd server (i.e., worker)
yum -y install httpd
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --reload
sed -i 's/LoadModule\ mpm_prefork_module\ modules\/mod_mpm_prefork.so/#LoadModule\ mpm_prefork_module\ modules\/mod_mpm_prefork.so/' /etc/httpd/conf.modules.d/00-mpm.conf
sed -i 's/#LoadModule\ mpm_worker_module\ modules\/mod_mpm_worker.so/LoadModule\ mpm_worker_module\ modules\/mod_mpm_worker.so/' /etc/httpd/conf.modules.d/00-mpm.conf
mkdir /var/www/html/worker
cat << EOF > /var/www/html/worker/index.html
<h2>Hello from worker module httpd</h2>
<hr />
<p>Created by Viktar Kaliada</p>
EOF
cat << EOF > /etc/httpd/conf.d/vhosts.conf
<VirtualHost *:80>
        ServerName worker.viktar.kaliada

        DocumentRoot "/var/www/html/worker"

        LogLevel alert rewrite:trace6

</VirtualHost>

<IfModule worker.c>
    StartServers           2
    MaxRequestWorkers      50
    MinSpareThreads        5
    MaxSpareThreads        50
    ThreadsPerChild        5
    ServerLimit            11
    MaxConnectionsPerChild 0 
</IfModule>
EOF
systemctl start httpd
httpd -V
yum -y install pstree
pstree apache
ab -n 100000 -c 5 http://worker.viktar.kaliada/
systemctl stop httpd
#Configuring non-threaded httpd server (i.e., prefork).
sed -i 's/#LoadModule\ mpm_prefork_module\ modules\/mod_mpm_prefork.so/LoadModule\ mpm_prefork_module\ modules\/mod_mpm_prefork.so/' /etc/httpd/conf.modules.d/00-mpm.conf
sed -i 's/LoadModule\ mpm_worker_module\ modules\/mod_mpm_worker.so/#LoadModule\ mpm_worker_module\ modules\/mod_mpm_worker.so/' /etc/httpd/conf.modules.d/00-mpm.conf
mkdir /var/www/html/prefork
cat << EOF > /var/www/html/prefork/index.html
<h2>Hello from prefork module httpd</h2>
<hr />
<p>Created by Viktar Kaliada</p>
EOF
cat << EOF > /etc/httpd/conf.d/vhosts.conf
<VirtualHost *:80>
        ServerName prefork.viktar.kaliada

        DocumentRoot "/var/www/html/prefork"

        LogLevel alert rewrite:trace6

</VirtualHost>

<IfModule prefork.c>
       ServerLimit            25
       StartServers           5
       MinSpareServers        3
       MaxSpareServers        7
       MaxRequestWorkers      25
       MaxConnectionsPerChild 500
</IfModule>
EOF
systemctl start httpd
pstree apache
ab -n 100000 -c 5 http://worker.viktar.kaliada/
systemctl stop httpd

