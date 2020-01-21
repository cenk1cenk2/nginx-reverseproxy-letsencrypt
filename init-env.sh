#!/bin/bash

echo "init-env.sh@bash: v2.0, 20190321"
## Variables
# Write down the data required in .env file here for initiation.
ENVFILENAME=.env
ENVFILECONTENTS=(
  "# SPLIT DOMAINS AND SUBDOMAINS WITH SPACE IN BETWEEN"
  "DOMAINS=\"\""
  "# EMAIL ADDRESS FOR LETSENCRYPT CERTIFICATES"
  "EMAIL="
  "# Add the directory for certificates that is shared among nginx and le"
  "CERTS_DATA_PATH="
  "# RSA Key Size Requested (Default: 4096)"
  "RSA_KEY_SIZE="
  "# Set to 1 if you're just testing your setup to avoid hitting request limits"
  "LE_STAGING=0"
  "# Set to 1 if you want to obtain certificate for every domain again eventhough they exist"
  "LE_FORCE_RENEWAL=0"
  "# Set to 1 if you want to manually configure which domains to process with user prompt"
  "LE_ASK_RENEWAL=0"
  )

## Script
echo "Initiating ${ENVFILENAME} file."; if [[ ! -f ${ENVFILENAME} ]] || ( echo -n ".env file already initiated. You want to override? [ y/N ]: " && read -r OVERRIDE && echo ${OVERRIDE::1} | grep -iqF "y" ); then echo "Will rewrite the .env file with the default one."; > ${ENVFILENAME} && for i in "${ENVFILECONTENTS[@]}"; do echo $i >> ${ENVFILENAME}; done; echo "Opening enviroment file in nano editor."; nano ${ENVFILENAME}; echo "All done."; else echo "File already exists with no overwrite permissiong given."; echo "Not doing anything."; fi

