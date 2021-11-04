#!/bin/bash

#████████████████████████████████████████████████████████████████████
#█▄─▄▄▀█▄─▄▄─█▄─█─▄█▄─▄▄─█▄─▄███─▄▄─█▄─▄▄─█▄─▄▄─█▄─▄▄▀███▄─▄─▀█▄─█─▄█
#██─██─██─▄█▀██▄▀▄███─▄█▀██─██▀█─██─██─▄▄▄██─▄█▀██─██─████─▄─▀██▄─▄██
#▀▄▄▄▄▀▀▄▄▄▄▄▀▀▀▄▀▀▀▄▄▄▄▄▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▀▀▀▄▄▄▄▄▀▄▄▄▄▀▀▀▀▄▄▄▄▀▀▀▄▄▄▀▀
#███████████████████████████████████████████████████
#█▄─▄███─▄▄─█─▄▄▄─██▀▄─██▄─▄███─█─█─▄▄─█─▄▄▄▄█─▄─▄─█
#██─██▀█─██─█─███▀██─▀─███─██▀█─▄─█─██─█▄▄▄▄─███─███
# ▄▄▄▄▄▀▄▄▄▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▀▄▀▄▄▄▄▀▄▄▄▄▄▀▀▄▄▄▀▀

#Gen DB autorization info
dir4install="/var/www/html"
name4DB="wp `date +%s`"
user4DB=$name4DB
pass4DB=`date |md5sum |cut -c '1-10'`
sleep 1
rootPass4MySQL=`date |md5sum |cut -c'1-10'`
sleep1

#Installing pkgs for apache2  && mysql
apt install apache2 -y
apt install mysql-server -y

#Apache2
rm  /var/www/html/index.html
systemctl enable apache2
systemctl start apache2

#MySQL
systemctl enable mysql
systemctl start mysql
/usr/bin/mysql -e "USE mysql;"
/usr/bin/mysql -e "UPDATE user SET Password=PASSWORD($pass4DB) WHERE user='root';"
/usr/bin/mysql -e "FLUSH PRIVILEGES;"
touch /root/.my.cnf
chmod 640 /root/.my.cnf
echo "[client]">>/root/.my.cnf
echo "user=root">>/root/.my.cnf
echo "password="$pass4DB>>/root/.my.cnf

#PHP
apt -y install php
apt -y php-mysql
apt -y php-gd
sed -i '0,/AllowOverride\ None/! {0,/AllowOverride\ None/ s/AllowOverride\ None/AllowOverride\ All/}' /etc/apache2/apache2.conf
systemctl restart apache2

#WordPress(installing)
if test -f /tmp/latest.tar.gz
then
echo "WP is already downloaded."
else
echo "Downloading WordPress"
cd /tmp/ && wget "http://wordpress.org/latest.tar.gz";
fi
/bin/tar -C $dir4install  -zxf /tmp/latest.tar.gz --strip-components=1
chown www-data: $dir4install -R

#WordPress configurations 
/bin/mv $dir4install/wp-config-sample.php $dir4install/wp-config.php
/bin/sed -i "s/database_name_here/$name4DB/g" $dir4install/wp-config.php
/bin/sed -i "s/username_here/$user4DB/g" $dir4install/wp-config.php
/bin/sed -i "s/password_here/$pass4DB/g" $dir4install/wp-config.php
cat << EOF >> $dir4install/wp-config.php
define('FS_METHOD', 'direct');
EOF
cat << EOF >> $dir4install/.htaccess

# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index.php$ – [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF
chown www-data: $dir4install -R

##### Set WordPress Salts
grep -A50 'table_prefix' $dir4install/wp-config.php > /tmp/wp-tmp-config
/bin/sed -i '/**#@/,/$p/d' $dir4install/wp-config.php
/usr/bin/lynx --dump -width 200 https://api.wordpress.org/secret-key/1.1/salt/ >> $dir4install/wp-config.php
/bin/cat /tmp/wp-tmp-config >> $dir4install/wp-config.php && rm /tmp/wp-tmp-config -f
/usr/bin/mysql -u root -e "CREATE DATABASE $name4DB"
/usr/bin/mysql -u root -e "CREATE USER '$name4DB'@'localhost' IDENTIFIED WITH mysql_native_password BY '$pass4db';"
/usr/bin/mysql -u root -e "GRANT ALL PRIVILEGES ON $name4DB.* TO '$user4DB'@'localhost';"
 
######Display generated passwords to log file.
echo "Database Name: " $name4DB
echo "Database User: " $user4DB
echo "Database Password: " $pass4DB
echo "Mysql root password: " $rootPass4MySQL
