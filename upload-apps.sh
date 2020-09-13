#!/bin/bash
limit=${1:-0}
NC='\033[0m'
Red='\033[0;31m'
Green='\033[0;32m'
Cyan='\033[0;36m'

# Script forked from vicelversa.

# Script variables, please plug-in your configuration here:
login='reuss'
pass='password1'
host='localhost'
port='21'
remote_dir='/home/user/apps/'
local_dir='/APPS/'

# Start SFTP downloads, lock script
echo -e "${Cyan}Starting SFTP downloads${NC}"
base_name="$(basename "apps")"
lock_file="/tmp/$base_name.lock"
trap "rm -f $lock_file" SIGINT SIGTERM
if [ -e "$lock_file" ]
then
    echo -e "${Red}$base_name is running already.${NC}"
    exit
else
    touch "$lock_file"
    lftp -p "$port" -u "$login","$pass" ftp://"$host" << EOF
    set dns:fatal-timeout never
    set ssl:verify-certificate no
    set ssl:priority +TLS1.2
    set net:reconnect-interval-base 5
    set ftp:list-options -a
    set sftp:auto-confirm yes
    set ftp:use-feat false
    set ftp:ssl-allow true
    set ftp:ssl-auth TLS
    set ftp:ssl-protect-data true
    set ftp:ssl-protect-list true
    set mirror:exclude-regex ^.*file_id\.jpg.*$\|^.*\.jpeg.*$\|^.*\[.*$
    set mirror:order "*.sfv *.nfo Sample/"
    set net:socket-buffer 0
	set net:limit-total-rate $limit
    mirror -R -c -v --Remove-source-dirs "$remote_dir" "$local_dir"
EOF

# - OPTIONAL -
# This will put the lftp process in the background and script will wait for downloads to finish.
# To use, add queue in front of the above mirror command and uncomment the 2 lines below.
# You may re-attach to the lftp session by running lftp -c attach PID
#
#echo "Download in progress, waiting for job to finish..."
#while pgrep lftp > /dev/null; do sleep 1; done

# Remove script lock
rm -f "$lock_file"
trap - SIGINT SIGTERM
fi

echo -e "${Green}Downloads complete!${NC}"
echo -e "${Cyan}Starting post-processing...${NC}"

# Check for incomplete downloads
if [ $(find "$remote_dir" -name "*.lftp" | wc -l) -gt 0 ]; then
        echo -e "${Red}Incomplete lftp transfers found in downloading directory. Aborting...${NC}"
    exit
else
:
fi


echo -e "${Green}Operation complete.${NC}"
exit
