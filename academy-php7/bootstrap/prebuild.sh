#!/usr/bin/env bash

echo "Installing all the things"
sudo yum install -y epel-release nano

# httpd
echo "Installing httpd"
sudo yum install -y httpd
sudo chkconfig httpd on
sudo service httpd start

# PHP 7.1
echo "Installing php 7.1"
sudo rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
sudo yum install -y php php-pdo php-mysql --enablerepo=remi-php71
sudo sed -i 's/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/' /etc/php.ini
sudo sed -i 's/display_errors = Off/display_errors = On/' /etc/php.ini 

# MySQL 5.6
echo "Installing mysql 5.6"
sudo rpm -Uvh http://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm
sudo yum install -y mysql mysql-server --enablerepo=mysql56-community
sudo chkconfig mysqld on
sudo service mysqld start

printf "Setting up MySQL users\n"
# Remove localhost users that confuse everything
sudo mysql -u root -e "DELETE FROM mysql.user WHERE  Host='localhost' AND User=''; DELETE FROM mysql.user WHERE  Host='localhost.localdomain' AND User='';"

# Add dbuser user and root user
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'; CREATE USER 'vagrant'; GRANT CREATE, DELETE, INSERT, SELECT, UPDATE ON *.* TO 'vagrant';FLUSH PRIVILEGES;"

# ssl
sudo service httpd stop
sudo yum install -y mod_ssl
sudo mkdir /etc/ssl/private
sudo openssl req -subj '/CN=192.168.20.20/O=Mayden/C=GB' -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
sudo cp /vagrant/bootstrap/ssl-selfsigned.conf /etc/httpd/conf.d/ssl-selfsigned.conf



# Turn off annoying caching!
printf "Setting 'EnableSendfile off' in httpd.conf (Virtual box syncing bug fix)\n"
sudo sed -i 's/#EnableSendfile off/EnableSendfile off/' /etc/httpd/conf/httpd.conf

# Restart httpd and sort out html folder symlink
sudo service httpd restart
sudo rm -rf /var/www/html
mkdir /vagrant/html
sudo ln -s /vagrant/html /var/www/html

# symlink letsencrypt cert script
sudo chmod +x /vagrant/refresh_ssl.sh
sudo ln -s /vagrant/refresh_ssl.sh ~/refresh_ssl.sh
