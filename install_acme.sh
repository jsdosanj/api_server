#!/bin/bash

echo "Installing acme.sh"
systemctl reload nginx.service
curl https://get.acme.sh | sh -s email=rangers@omnigroup.com
echo "Please configure nginx so that Acme.sh can pull the proper certificates into nginx"

# Setup acme.sh
# Set the notification level:  Default value is 2.
#0: disabled, no notification will be sent.
#1: send notification only when there is an error. No news is good news.
#2: send notification when a cert is successfully renewed, or there is an error
#3: send notification when a cert is skipped, renewed, or error. You will receive notification every night with this level.
acme.sh --set-notify  [--notify-hook mail]
acme.sh --set-notify  [--notify-level 2]
acme.sh --set-notify  [--notify-mode 0]
export MAIL_FROM="rangers@omnigroup.com" # or "Xxx Xxx <xxx@xxx.com>", currently works only with sendmail
export MAIL_TO="rangers@omnigroup.com"   # your account e-mail will be used as default if available


acme.sh --issue --standalone -d "$HOSTNAME"

acme.sh --install-cert -d $HOSTNAME \
--key-file       /path/to/keyfile/in/nginx/key.pem  \
--fullchain-file /path/to/fullchain/nginx/cert.pem \
--reloadcmd     "service nginx force-reload"