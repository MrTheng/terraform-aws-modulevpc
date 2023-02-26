#!/bin/sh
sudo su 
yum update -y 
yum install -y httpd.x86_64
systemctl start httpd.service
systemcrl enable httpd.service

echo "<html><h1>Welcome to my Instance</h2></html>" > /var/www/html/index.html

