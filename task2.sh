#!/bin/bash
#Task 2
#Configure httpd as a forward proxy with authentication. 
mkdir /var/www/html/forward
cat << EOF > /etc/httpd/conf.d/forward-proxy.conf
<VirtualHost *:80>
        ServerName forward.viktar.kaliada

        DocumentRoot "/var/www/html/forward"
        ProxyRequests On
        ProxyVia On
        RequestHeader unset Authorization
        LogLevel alert rewrite:trace6
<Proxy *>
    AuthType Basic
    AuthBasicProvider file
    AuthName "Password Required for Proxy"
    AuthUserFile "/var/www/html/forward/.htpasswd"
    Require valid-user
    Allow from all
    Order deny,allow
</Proxy>
</VirtualHost>           
EOF
echo "Qwerty1*" | htpasswd -i -c /var/www/html/forward/.htpasswd Viktar_Kaliada
systemctl restart httpd
#Configure httpd as a reverse proxy
systemctl stop httpd
rm -f /etc/httpd/conf.d/forward-proxy.conf
cat << EOF > /etc/httpd/conf.d/reverse-proxy.conf
<VirtualHost *:80>
        ServerName reverse.viktar.kaliada
       
        ProxyRequests Off
        ProxyPass /cern http://info.cern.ch/
        ProxyPassReverse /cern/ http://info.cern.ch/

        LogLevel alert rewrite:trace6
</VirtualHost>           
EOF
systemctl start httpd
#Configure connection to Tomcat
rm -f /etc/httpd/conf.d/reverse-proxy.conf
yum -y install tomcat-webapps tomcat-admin-webapps
cat << EOF > /etc/httpd/conf.d/forward-proxy.conf
<VirtualHost *:80>
        ServerName forward.viktar.kaliada

        DocumentRoot "/var/www/html/forward"
        ProxyRequests On
        ProxyVia On
        RequestHeader unset Authorization
        LogLevel alert rewrite:trace6


<Proxy *>
    AuthType Basic
    AuthBasicProvider file
    AuthName "Password Required for Proxy"
    AuthUserFile "/var/www/html/forward/.htpasswd"
    Require valid-user
    Allow from all
    Order deny,allow
</Proxy>
</VirtualHost>           
EOF
chmod 640 /usr/share/tomcat/conf/tomcat-users.xml
chown root:tomcat /usr/share/tomcat/conf/tomcat-users.xml
cat << EOF > /usr/share/tomcat/conf/tomcat-users.xml
<?xml version='1.0' encoding='utf-8'?>
<tomcat-users>
<user username="admin" password="Qwerty1*" roles="manager-gui,admin-gui"/>
</tomcat-users>
EOF
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload
cat << EOF > /etc/httpd/conf.d/proxy.conf
<proxy balancer://appset>
        BalancerMember http://localhost
        ProxySet lbmethod=bytraffic
</proxy>

ProxyPass "/app" "balancer://appset/"
ProxyPassReverse "/app" "balancer://appset/"
EOF
echo "Qwerty1*" | htpasswd -i -c /etc/httpd/.htpasswd admin
cat << EOF > /etc/httpd/conf.d/lbmanager.conf
<location "/balancer-manager">
        SetHandler balancer-manager
        AuthType "basic"
        AuthName "balancer-manager"
        AuthUserFile /etc/httpd/.htpasswd
        Require valid-user
</location>
EOF
systemctl restart httpd
