#!/bin/bash

NGINX_CONF="/etc/nginx/sites-available/flaskapp"

# Detect public IP
AUTO_IP=$(curl -s https://checkip.amazonaws.com)

echo "🌐 Detected public IP: $AUTO_IP"
read -p "Do you want to use a domain name instead of IP? (y/n): " USE_DOMAIN

if [[ "$USE_DOMAIN" =~ ^[Yy]$ ]]; then
  read -p "Enter your domain name (must point to this server): " DOMAIN_NAME
  SERVER_NAME="$DOMAIN_NAME"
else
  SERVER_NAME="$AUTO_IP"
fi

# Escape for sed
ESCAPED_NAME=$(printf '%s\n' "$SERVER_NAME" | sed 's/[.[\*^$/]/\\&/g')

# Check nginx config file
if [ ! -f "$NGINX_CONF" ]; then
  echo "❌ Nginx config file not found at $NGINX_CONF"
  exit 1
fi

# Update server_name line
sudo sed -i "s/^\s*server_name\s\+.*;/    server_name $ESCAPED_NAME;/" "$NGINX_CONF"
echo "✅ Updated server_name to: $SERVER_NAME"

# Allow HTTP through firewall (if ufw exists)
if command -v ufw >/dev/null 2>&1; then
  echo "🌐 Ensuring port 80 is open..."
  sudo ufw allow 80/tcp
fi

# Test and reload nginx
echo "🔁 Testing and reloading Nginx..."
if sudo nginx -t; then
  sudo systemctl reload nginx
  echo "✅ Nginx reloaded successfully."
else
  echo "❌ Nginx config test failed. Check the syntax."
  exit 1
fi

# Show current Nginx status
echo "📄 Current Nginx config for $SERVER_NAME:"
grep server_name "$NGINX_CONF"

# If using domain, set up SSL with Certbot
if [[ "$USE_DOMAIN" =~ ^[Yy]$ ]]; then
  echo "🔐 Attempting to install Certbot and configure SSL for $SERVER_NAME"
  sudo apt-get update
  sudo apt-get install -y certbot python3-certbot-nginx

  echo "📄 Running Certbot for $SERVER_NAME..."
  sudo certbot --nginx -d "$SERVER_NAME"

  echo "✅ SSL setup complete. You can now access https://$SERVER_NAME"
fi