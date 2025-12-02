#!/bin/bash
set -xe

# Update & install nginx
apt-get update -y
apt-get install -y nginx

# Simple index page
cat >/var/www/html/index.html <<EOF
<html>
  <head><title>Custom Image Base</title></head>
  <body>
    <h1>Hello from the base VM (to be imaged)!</h1>
  </body>
</html>
EOF

systemctl enable nginx
systemctl restart nginx
