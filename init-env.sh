#!/bin/bash

echo "Initiating .env file for given container."

if [ ! -f ./.env ]; then
    echo ".env file not found initiating."
    FILEFOUND=false
else
    echo -n ".env file already initiated. You want to override? [y/N]: "
    read -r OVERRIDE
    if echo ${OVERRIDE::1} | grep -iqF "y"; then
        echo "Will rewrite the .env file with the empty one."
        FILEFOUND=false
    else
        echo "Not doing anything."
        exit
    fi
fi

FILENAME=.env
# Container specific initiate.
echo 'DOMAINS="domain subdomain"' > $FILENAME
#echo  >> $FILENAME
