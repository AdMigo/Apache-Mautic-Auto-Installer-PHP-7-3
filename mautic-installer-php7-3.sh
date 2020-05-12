#!/bin/bash

#Variables
pass='mautic-database-password'
db_name='your-mautic-database-name'
db_user='your-mautic-database-username'
web_root='/var/www/html'
domain='my-mautic'
email='admin@my.mautic'
timezone='America/New_York'

### Set default parameters

sitesEnabled='/etc/apache2/sites-enabled/'
sitesAvailable='/etc/apache2/sites-available/'
sitesAvailabledomain=$sitesAvailable$domain.conf
export DEBIAN_FRONTEND=noninteractive
#####

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Please use sudo"
		exit 1;
fi

#Ensure it only works on ubuntu and install apps for specific versions
if [  -n "$(uname -a | grep Ubuntu)" ]; then
        echo `lsb_release -d | grep -oh Ubuntu.*`

        echo "Updating the repository."
        add-apt-repository -y ppa:certbot/certbot
		apt install software-properties-common
		add-apt-repository ppa:ondrej/php
        apt-get update
        echo "Installing LAMP packages"
        apt-get --assume-yes install apache2 mysql-server php7.3 php7.3-cli libapache2-mod-php7.3 php7.3-mysql unzip python-certbot-apache
        apt-get --assume-yes install php7.3-zip php7.3-xml php7.3-imap php7.3-opcache php7.3-apcu php7.3-memcached php7.3-mbstring php7.3-curl php-amqplib php7.3-mbstring php7.3-bcmath php7.3-intl


        x=`lsb_release -rs`
        if (($(echo "$x < 18.04" | bc -l) ));then
                echo "old version"
                apt-get --assume-yes install php-mcrypt
        fi
else
        echo "This script is only compatible and tested on Ubuntu"
        exit 1
fi
cd /etc/apache2/mods-enabled/
sed -e 's/\s*DirectoryIndex.*$/\tDirectoryIndex index\.php index\.html index\.cgi index\.pl index\.xhtml index\.htm/' \
    dir.conf > /tmp/dir.conf && mv /tmp/dir.conf dir.conf
systemctl restart apache2

while true; do
    read -p "Do you wish to secure your mysql installation? Y/N: " yn
    case $yn in
        [Yy]* ) mysql_secure_installation; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

mysql -e "DROP DATABASE IF EXISTS ${db_name};"
mysql -e "CREATE DATABASE ${db_name} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -e "DROP USER IF EXISTS ${db_user}@localhost;"
mysql -e "CREATE USER ${db_user}@localhost IDENTIFIED BY '${pass}';"
mysql -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

cd

curl -s https://api.github.com/repos/mautic/mautic/releases/latest \
| grep "browser_download_url.*zip" \
| cut -d : -f 2,3 \
| tr -d \" \
| tail -1 | wget -O mautic.zip -qi -

unzip -o mautic.zip -d $web_root
rm mautic.zip

apacheUser=$(ps -ef | egrep '(httpd|apache2|apache)' | grep -v root | head -n1 | awk '{print $1}')
# Set permissions for apache
cd $web_root
chown -R $USER:$apacheUser .
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod -R g+w app/cache/
chmod -R g+w app/logs/
chmod -R g+w app/config/
chmod -R g+w media/files/
chmod -R g+w media/images/
chmod -R g+w translations/

### check if domain already exists
if [ -e $sitesAvailabledomain ]; then
    echo -e "This domain already exists.\nRemoving...."

    ### disable website
    a2dissite $domain

    ### restart Apache
    /etc/init.d/apache2 reload

    ### Delete virtual host rules files
    rm $sitesAvailabledomain
    ### show the finished message
    echo -e "Complete!\nVirtual Host $domain has been removed."
fi

### create virtual host rules file
if ! echo "
<VirtualHost *:80>
    ServerAdmin $email
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot $web_root
    <Directory />
        AllowOverride All
    </Directory>
    <Directory $web_root>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride all
        Require all granted
    </Directory>
    ErrorLog /var/log/apache2/$domain-error.log
    LogLevel error
    CustomLog /var/log/apache2/$domain-access.log combined
</VirtualHost>" > $sitesAvailabledomain
then
    echo -e $"There is an ERROR creating $domain file"
    exit;
else
    echo -e $"\nNew Virtual Host Created\n"
fi

### enable website
a2ensite $domain

ini=$(sudo find /etc/ -name php.ini | grep 'apache2')
sed 's#^;*date\.timezone[[:space:]]=.*$#date.timezone = "'"$timezone"'"#' $ini > /tmp/timezone.conf && mv /tmp/timezone.conf $ini

### restart Apache
/etc/init.d/apache2 reload

#Setup SSL for https
certbot -d $domain --non-interactive --redirect --keep-until-expiring --agree-tos --apache -m $email

### show the finished message
echo -e $"Complete! \nYou now have a new Virtual Host \nYour new host is: https://$domain \nAnd its located at $web_root"
