#!/bin/bash
cd `dirname $0`

BOT_NICK="mathbot"
KEY="$(cat ./config.txt)"

nanos=1000000000
interval=$(( $nanos * 50 / 100 ))
declare -i prevdate
prevdate=0

function send {
    while read -r line; do
      newdate=`date +%s%N`
      if [ $prevdate -gt $newdate ]; then sleep `bc -l <<< "($prevdate - $newdate) / $nanos"`; newdate=`date +%s%N`; fi
      prevdate=$newdate+$interval
      echo "-> $1"
      echo "$line" >> ${BOT_NICK}.io
    done <<< "$1"
}

rm ${BOT_NICK}.io
mkfifo ${BOT_NICK}.io
tail -f ${BOT_NICK}.io | openssl s_client -connect irc.cat.pdx.edu:6697 | while [ -z "$started" ] || read -r irc ; do
    if [ -z "$started" ] ; then
        send "NICK $BOT_NICK" 
        send "USER 0 0 0 :$BOT_NICK"
        send "JOIN #robots $KEY"
        send "JOIN #numberwang"
        started="yes"
        read -r irc
    fi
    if $(<<<"$irc" cut -d ' ' -f 1 | grep -qP "PING") ; then
        send "PONG"
    elif $(<<<"$irc" cut -d ' ' -f 2 | grep -qP "PRIVMSG") ; then 
#:nick!user@host.cat.pdx.edu PRIVMSG #bots :This is what an IRC protocol PRIVMSG looks like!
        nick="$(<<<"$irc" cut -d ':' -f 2- | cut -d '!' -f 1)"
        chan="$(<<<"$irc" cut -d ' ' -f 3)"
        if [ "$chan" = "$BOT_NICK" ] ; then chan="$nick" ; fi 
        msg="$(<<<"$irc" cut -d ' ' -f 4- | cut -c 2- | tr -d "\r\n")"
        echo "$(date) | $chan <$nick>: $msg"
        var="$(echo "$nick" "$chan" "$BOT_NICK" "$msg" | ./commands.sh)"
        if [ ! -z "$var" ] ; then
            send "$var"
        fi
    
    fi
done
