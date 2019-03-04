#!/bin/bash
SERVER=SERVERNAME.OF.YOUR.NIGHTSCOUT.INSTANCE
SECRET=API_SECRET
DOMAIN=SUBDOMAIN.WHERE.THE.RECORDS.ARE.GENERATED                 # I Recommend nightscout.your-domain.tld
ZONE=DOMAIN
NSUPDATE=./do.nsupdate
PING=$SERVER #or use www.google.com if your server is not pingable
#PING=www.google.com
SECRETSHA1=$(echo -n $SECRET | sha1sum | awk '{print $1}')
URL="-s --header API-SECRET:"$SECRETSHA1" https://"$SERVER"/api/v1/entries/current.json"
ping -q -c5 $PING > /dev/null
if [ $? -eq 0 ];
        then
        CURRDATE=$(date '+%s')
        if [ -f lasthour.txt ];
                then LASTHOUR=$(cat lasthour.txt);
                else LASTHOUR=0;
        fi
        VALUE=$(curl $URL | sed -e 's/.*sgv\"://' | sed 's/,\".*//')
        DIRECTION=$(curl $URL | sed -e 's/.*direction\":\"//' | sed 's/\",\".*//')
        LASTVALUE=$(curl $URL | sed -e 's/.*date\"://'|cut -c -10)
        DIFF=$((CURRDATE-LASTVALUE))
        DIFF=$((DIFF/60))
        DIFFH=$((DIFF/60))
        LASTDATE=$(date -d @$LASTVALUE +%H:%M)
        if [ $DIFF -gt 10 ]; then $($NSUPDATE old.$DOMAIN $ZONE 1); else $($NSUPDATE old.$DOMAIN $ZONE 0); fi
        if [ $DIFF -lt 60 ]; then
                $($NSUPDATE timeinfo.$DOMAIN $ZONE "Vor" $DIFF "Min um" $LASTDATE)
                $($NSUPDATE direction.$DOMAIN $ZONE $DIRECTION)
                $($NSUPDATE value.$DOMAIN $ZONE $VALUE);
#                python2 nightscout.py;
        else
                if [ $DIFFH -gt $LASTHOUR ]; then
                        $($NSUPDATE timeinfo.$DOMAIN $ZONE "Vor" $DIFFH "Stunden um" $LASTDATE);
                fi
        fi
        echo $DIFFH > "lasthour.txt";
else
        echo No Connection;
fi


