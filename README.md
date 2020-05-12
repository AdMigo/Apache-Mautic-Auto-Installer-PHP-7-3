# Apache-Mautic-Auto-Installer-PHP-7-3
Mautic Auto Installation Script with PHP 7.3

Original Script: https://github.com/frazras/Mautic-Installer

Edited version of @frazras Mautic Auto Installation script which implements the usage of PHP 7.3 and all PHP 7.3 extension required for Successful Mautic installation and usage. 

I had originally used this script to Install Mautic at Version 2.15.1, but after requiring same site cookie security I was required to install PHP 7.3. For some reason Digital Ocean had not updated the PHP package to 7.3, so I edited the script to include 7.3.
 
Script Installs the Latest version of Mautic - *as of this Repo Creation: (2.16.2)

I use Mautic with Cloudflare, it is recommended not to use Mautic with Cloudflare if you require user IP Address tracking, I do not for this particular use case. If for some reason you do not want to use Cloudflare you can simply disregard my CF Instructions and install the script with Let’s Encrypt cert’s. 

Cloudflare DNSing

1. Add Domain A Record to Cloudflare with DNS ONLY
2. Switch Cloudflare to Development Mode
3. Turn OFF HTTPS upgrades
4. Turn OFF HTTPS Rewrites 

Script Instructions:
1. Create Digital Ocean Ubuntu 18.04 Server
2. Launch Server Terminal with SSH Key
3. Edit mautic-installer-php7-3.sh bash script with new database details, your domain name, and email.
4. Drag and Drop the mautic-installer-php7-3.sh file into the /root/ directory of the Server SFTP In your terminal app or simple git clone this repo
5. run the following Command: chmod +x /root/mautic-installer-php7-3.sh
6. Run ./mautic-installer-php7-3.sh
7. Complete Installer SQL Security Prompts.
8. After Install you may go re-enable the Cloudflare settings which were set to OFF, turn off Dev mode, and set SSL to Full Strict for end-end encryption. 

If you encounter and error about site being offline after performing the install or after adding google analytics simply run the following commands:

1. chown -R www-data /var/www/html/mautic/ 

2. systemctl restart apache2.service or /etc/init.d/apache2 restart
