# Let's Encrypt for RouterOS / Mikrotik
**Let's Encrypt certificates for RouterOS / Mikrotik issued by ACME.SH**

![ ](https://w.keir.ru/lib/exe/fetch.php?media=external:le-acmesh-ros_640.png)

### How it works:
* Script aimed to be a PostHook for acme.sh (https://github.com/Neilpang/acme.sh)
* After acme.sh renew your certificates on Mikrotik device
* The script connects to RouterOS / Mikrotik using RSA Key (without password or user input)
* Delete previous certificate files
* Delete the previous certificate
* Upload two new files: **Certificate** and **Key**
* Import **Certificate** and **Key**
* Change **SSTP Server Settings** to use new certificate
* Delete certificate and key files form RouterOS / Mikrotik storage

### Installation on Linux-based systems

Download the repo to your system
```sh
cd $codelede
git clone https://github.com/dualmi/letsencrypt-routeros
```
Edit the settings file and fill:
```sh
nano -w $codelede/letsencrypt-routeros_acme.sh/letsencrypt-routeros.settings
```
| Variable Name | Value | Description |
| ------ | ------ | ------ |
| ROUTEROS_USER | admin | user with admin rights to connect to RouterOS |
| ROUTEROS_HOST | 192.168.1.254 | RouterOS\Mikrotik IP |
| ROUTEROS_SSH_PORT | 22 | RouterOS\Mikrotik PORT |
| ROUTEROS_PRIVATE_KEY | /root/.ssh/id_rsa | Private Key to connect to RouterOS (usualy inside $HOME/.ssh catalog if you want to use your default key) |
| DOMAIN | vpn.mydomain.com | Use domain you issued with acme.sh |
| LE_WORKING_DIR | ~/.acme.sh | #Commented by default# acme.sh home directory with certificates if you haven't use --install parameter to acme.sh |

Change permissions:
```sh
chmod a+x $codelede/letsencrypt-routeros_acme.sh/letsencrypt-routeros.sh
```
Generate a keypair for your Linux user if you haven't done it before or ROUTEROS_PRIVATE_KEY was set to non-standart location
*Make sure to leave the passphrase blank (-N "")*
```sh
source $codelede/letsencrypt-routeros_acme.sh/letsencrypt-routeros.settings
ssh-keygen -t dsa -f $ROUTEROS_PRIVATE_KEY -N ""
```
Send generated key to Mikrotik device
```sh
source $codelede/letsencrypt-routeros_acme.sh/letsencrypt-routeros.settings
scp -P $ROUTEROS_SSH_PORT $ROUTEROS_PRIVATE_KEY.pub "$ROUTEROS_USER"@"$ROUTEROS_HOST":"id_rsa.pub" 
```

### Setup RouterOS / Mikrotik side

Login to your Mikrotik and use it's terminal for next two commands. Change username if you changed it in settings.

*Check Mikrotik ssh port in /ip services ssh*

*Check Mikrotik firewall to accept on SSH port*
```sh
:put "Enable SSH"
/ip service enable ssh

:put "Add to the user DSA Public Key"
/user ssh-keys import user=admin public-key-file=id_rsa.pub
```

### acme.sh
If you getting certificate for the first time and using --issue parameter to acme.sh use something like this:
```sh
acme.sh --issue -d domain --post-hook="$codelede/letsencrypt-routeros_acme.sh/letsencrypt-routeros.sh" <...your other command line parameters...>
```
...or if you already have issued certificate you can add a post-hook in configuration file for yor domain.
Config file placement depends on how you install acme.sh but it looks like $LE_WORKING_DIR/$DOMAIN/$DOMAIN.conf where $LE_WORKING_DIR is actual variable defined by acme.sh after --install command and $DOMAIN is your domain name.
Open you domain config file and set post-hook:
```sh
Le_PostHook='$codelede/letsencrypt-routeros_acme.sh/letsencrypt-routeros.sh'
```

### Usage of the script
*To use it manually from console to upload a certificates:*
```sh
$codelede/letsencrypt-routeros_acme.sh/letsencrypt-routeros.sh
```
*Otherwise it will be used within acme.sh*

### Edit Script
You can easily edit script to execute your commands on RouterOS / Mikrotik after certificates renewal
Uncomment these strings in the «.sh» file before «exit 0» to have www-ssl and api-ssl works with Let's Encrypt SSL
```sh
$routeros /ip service set www-ssl certificate=$DOMAIN.pem_0
$routeros /ip service set api-ssl certificate=$DOMAIN.pem_0
```
---
