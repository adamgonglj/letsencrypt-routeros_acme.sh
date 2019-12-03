#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONFIG_FILE="$SCRIPT_DIR/letsencrypt-routeros.settings"

if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]] || [[ -z $4 ]] || [[ -z $5 ]]; then
        source $CONFIG_FILE
fi

if [[ -z $ROUTEROS_USER ]] || [[ -z $ROUTEROS_HOST ]] || [[ -z $ROUTEROS_SSH_PORT ]] || [[ -z $ROUTEROS_PRIVATE_KEY ]] || [[ -z $DOMAIN ]]; then
        echo "Check the config file $CONFIG_FILE. It MUST be filled with actual parameters"
        echo "Please avoid spaces"
        exit 1
fi

# acme.sh directory check
if [[ -z $LE_WORKING_DIR ]]; then
        echo "Not found installed acme.sh"
        echo "Edit $CONFIG_FILE and set up correct directory with acme.sh certificates in LE_WORKING_DIR variable"
        exit 1
fi

CERTIFICATE=$LE_WORKING_DIR/$DOMAIN/fullchain.cer
KEY=$LE_WORKING_DIR/$DOMAIN/$DOMAIN.key

#Create alias for RouterOS command
routeros="ssh -i $ROUTEROS_PRIVATE_KEY $ROUTEROS_USER@$ROUTEROS_HOST -p $ROUTEROS_SSH_PORT"

#Check connection to RouterOS
$routeros /system resource print

if [[ ! $? == 0 ]]; then
        echo -e "\nError in: $routeros"
        echo "More info: https://wiki.mikrotik.com/wiki/Use_SSH_to_execute_commands_(DSA_key_login)"
        exit 1
else
        echo -e "\nConnection to RouterOS Successful!\n" 
fi

if [ ! -r $CERTIFICATE ] && [ ! -r $KEY ]; then
        echo -e "\nFile(s) not found:\n$CERTIFICATE\n$KEY\n"
        echo -e "Please check path to files and acme.sh home dir"
        exit 1
fi

# Remove previous certificate
$routeros /certificate remove [find name=$DOMAIN.pem_0]

# Create Certificate
# Delete Certificate file if the file exist on RouterOS
$routeros /file remove $DOMAIN.pem > /dev/null
# Upload Certificate to RouterOS
scp -q -P $ROUTEROS_SSH_PORT -i "$ROUTEROS_PRIVATE_KEY" "$CERTIFICATE" "$ROUTEROS_USER"@"$ROUTEROS_HOST":"$DOMAIN.pem"
sleep 2
# Import Certificate file
$routeros /certificate import file-name=$DOMAIN.pem passphrase=\"\"
# Delete Certificate file after import
$routeros /file remove $DOMAIN.pem

# Create Key
# Delete Certificate file if the file exist on RouterOS
$routeros /file remove $KEY.key > /dev/null
# Upload Key to RouterOS
scp -q -P $ROUTEROS_SSH_PORT -i "$ROUTEROS_PRIVATE_KEY" "$KEY" "$ROUTEROS_USER"@"$ROUTEROS_HOST":"$DOMAIN.key"
sleep 2
# Import Key file
$routeros /certificate import file-name=$DOMAIN.key passphrase=\"\"
# Delete Certificate file after import
$routeros /file remove $DOMAIN.key

# Setup Certificate to SSTP Server
$routeros /interface sstp-server server set certificate=$DOMAIN.pem_0

#$routeros /ip service set www-ssl certificate=$DOMAIN.pem_0
#$routeros /ip service set api-ssl certificate=$DOMAIN.pem_0

exit 0
