#!/bin/bash

source .env
IFS=' '; set -f
echo "Running the script for $DOMAINS."
domains=($DOMAINS)
rsa_key_size=${RSA_KEY_SIZE:-4096}
data_path=$CERTS_DATA_PATH
email=$EMAIL #Adding a valid address is strongly recommended
staging=${LE_STAGING:-0} #Set to 1 if you're just testing your setup to avoid hitting request limits
force_renewal=${LE_FORCE_RENEWAL:-0} # Set to 1 if you want to obtain certificate for every domain again eventhough they exist
ask_renewal=${LE_ASK_RENEWAL:-0} # Set to 1 if you want to manually configure which domains to process

if [ ! -e "$data_path/options-ssl-nginx.conf" ] || [ ! -e "$data_path/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path"
  cp ./build/options-ssl-nginx.conf $data_path/options-ssl-nginx.conf
  cp ./build/ssl-dhparams.pem $data_path/ssl-dhparams.pem
  echo
fi

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

# Force renewal flag
if [ $force_renewal != "0" ]; then force_renewal_arg="--force-renewal"; else force_renewal_arg="--keep-until-expiring"; fi

for domain in "${domains[@]}"; do
  if [[ ! -f "$data_path/live/$domain/fullchain.pem" || ! -f  "$data_path/live/$domain/privkey.pem" ]]; then
    echo "### Creating dummy certificate for $domain ..."
    path="/etc/letsencrypt/live/$domain"
    mkdir -p "$data_path/live/$domain"
    docker-compose run --rm --entrypoint "\
      openssl req -x509 -nodes -newkey rsa:1024 -days 1\
        -keyout '$path/privkey.pem' \
        -out '$path/fullchain.pem' \
        -subj '/CN=localhost'" certbot
    touch "$data_path/live/$domain/.dummy"
  else
    echo "### Skipping $domain, because the certificates for it already exists."
  fi
  echo
done

echo "### Starting nginx ..."
docker-compose up -d nginx-reverseproxy
echo

for domain in "${domains[@]}"; do
  if [[ ! -f "$data_path/live/$domain/.dummy" && $ask_renewal != "0" ]]; then read -p "### Do you want to force renewal for $domain [y/N]: " renewal_override; fi
  if [[ -f "$data_path/live/$domain/.dummy" || ${renewal_override:-"n"} = "y" ]]; then
    echo "### Deleting certificates for $domain ..."
    docker-compose run --rm --entrypoint "\
      rm -Rf /etc/letsencrypt/live/$domain && \
      rm -Rf /etc/letsencrypt/archive/$domain && \
      rm -Rf /etc/letsencrypt/renewal/$domain.conf" certbot
    echo
  fi

  echo "### Will try to check certificate validity."
  echo "### Trying for domain/subdomain name $domain"
  domain_args=""
  domain_args="-d $domain"
  docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    $force_renewal_arg" certbot
  echo
done

echo "### Done Stopping ..."

docker-compose stop nginx-reverseproxy
