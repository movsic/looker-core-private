sudo apt-get update && \
sudo apt-get install certbot python3-certbot-nginx -y && \
sudo certbot --nginx -d private.lookerapp.com --register-unsafely-without-email --agree-tos