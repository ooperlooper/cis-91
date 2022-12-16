#! /bin/bash 

# Put this file in /etc/cron.hourly/backup

TARGET="gs://wiki-bucket"

tar_file=/tmp/dokuwiki-backup-$(date +%s).tar.gz
tar -czf $tar_file /var/www/html 2>/dev/null 
/snap/bin/gsutil cp $tar_file $TARGET
rm -f $tar_file