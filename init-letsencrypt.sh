#!/bin/bash

source .env
IFS=' '; set -f
domains=($DOMAINS)
subdomains=($SUBDOMAINS)
rsa_key_size=${RSA_KEY_SIZE:-4096}
data_path=$CERTS_DATA_PATH
email=$EMAIL #Adding a valid address is strongly recommended
staging=${LE_STAGING:-0} #Set to 1 if you're just testing your setup to avoid hitting request limits
force_renewal=${LE_FORCE_RENEWAL:-0} # Set to 1 if you want to obtain certificate for every domain again eventhough they exist
ask_renewal=${LE_ASK_RENEWAL:-0} # Set to 1 if you want to manually configure which domains to process

# Greet and show parameters
echo "Running the script for ${domains[@]} with subdomains ${subdomains[@]}."
echo "Certificates will be outputted to \"$data_path\" on host system."
if [ $staging != "0" ]; then echo "Running in staging mode."; fi
if [ $force_renewal != "0" ]; then echo "Running in force renewal mode. This will renew all certificates eventhough it is not needed."; fi
if [ $ask_renewal != "0" ]; then echo "Running in ask renewal mode. This will ask for renewing certificates that already exists."; fi
echo "RSA Key size for certificates is $rsa_key_size."
echo

# Copy configuration for letsencrypt if does not exists
if [ ! -e "$data_path/options-ssl-nginx.conf" ] || [ ! -e "$data_path/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path"
  cp ./build/options-ssl-nginx.conf $data_path/options-ssl-nginx.conf
  cp ./build/ssl-dhparams.pem $data_path/ssl-dhparams.pem
  echo
fi

# Select appropriate email arg
if [[ -z $email ]]; then email_arg="--register-unsafely-without-email"; else email_arg="--email $email"; fi

# Enable staging mode if needed
if [ $staging != "0" ]; then staging_arg="--staging"; fi

# Force renewal flag
if [ $force_renewal != "0" ]; then force_renewal_arg="--force-renewal"; else force_renewal_arg="--keep-until-expiring"; fi

# Create dummy certificates if no certificate exists to ensure nginx will run
echo "### Creating dummy certificates."
for domain in "${domains[@]}"; do
  if [[ ! -f "$data_path/live/$domain/fullchain.pem" || ! -f  "$data_path/live/$domain/privkey.pem" ]]; then
    echo "### Creating dummy certificate for $domain ..."
    path="/etc/letsencrypt/live/$domain"
    mkdir -p "$data_path/live/$domain"
    docker-compose run --rm --entrypoint " \
      openssl req -x509 -nodes -newkey rsa:1024 -days 1 \
        -keyout '$path/privkey.pem' \
        -out '$path/fullchain.pem' \
        -subj '/CN=localhost'" certbot
    touch "$data_path/live/$domain/.dummy"
  else
    echo "### Skipping $domain, because the certificates for it already exists."
  fi
done
echo

echo "### Ensuring containers are down..."
docker-compose down
echo "### Starting nginx..."
docker-compose up -d nginx-reverseproxy
echo

for domain in "${domains[@]}"; do
  # Check for ask renewal flag
  if [[ ! -f "$data_path/live/$domain/.dummy" && $ask_renewal != "0" ]]; then read -p "### Do you want to force renewal for $domain [y/N]: " renewal_override; fi
  # Delete dummy certificates or forced renewal certificates by user input
  if [[ -f "$data_path/live/$domain/.dummy" || ${renewal_override:-"n"} = "y" ]]; then
    echo "### Deleting certificates for $domain ..."
    rm -Rf $data_path/live/$domain && \
    rm -Rf $data_path/archive/$domain && \
    rm -Rf $data_path/renewal/$domain.conf
    echo
  fi

  # Iterate for all subdomains and add them to aliases
  echo "### Trying for domain name $domain, with subdomains ${subdomains[@]}."
  domain_args="-d $domain -d www.$domain"
  cert_name_arg="--cert-name $domain"
  for subdomain in "${subdomains[@]}"; do
    if [[ $subdomain =~ "$domain" ]]; then domain_args+=" -d $subdomain"; fi
  done

  # Get a combined certificate for domain
  docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $cert_name_arg \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --preferred-challenges=http \
    $force_renewal_arg" certbot
  echo
done

echo "### Done Stopping ..."

docker-compose stop nginx-reverseproxy
