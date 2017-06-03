#!/bin/bash
read -r nick chan BOT_NICK msg 
timeout=20
maxLines=4
export BC_LINE_LENGTH=400

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#BOT_NICK="$(grep -P "BOT_NICK=.*" ${DIR}/bot.sh | cut -d '=' -f 2- | tr -d '"')"

function say { 
  echo "PRIVMSG $chan :$1"
}
function sayMulti {
  lines=0;
  while read -r line; do
    lines=`expr $lines + 1`;
    if [ $lines -gt $maxLines ]; then say "Cut off at line limit $maxLines"; break; fi
    say "$line"
  done <<< "$1"
}

priv=1

if [ "$chan" = "$BOT_NICK" ] ; then chan="$nick";priv=0 ; fi

isBot="`if grep -qiP "bot$" <<< "$nick"; then echo -n "yes"; fi`"

printUnlessBot() {
  if [ -z "$isBot" ]; then cat; fi
}

run() {
  echo "$1" 1>&2
  str="$(echo "time=`date +%s`; nanos=`date +%N`; `<<<"$1" sed $'s/define/\\\ndefine/g'`" | ~/bin/bc -l bc_startup 2> >(tr '\n' ';' | printUnlessBot))"
  if [ -n "$str" -o -z "$isBot" ]; then sayMulti "$nick: $str"; fi
}

safeRun() {
  run "$1" &
  pid=$!
  ( sleep $timeout && ps -p $pid && kill -9 $pid && say "$nick: Killed (timeout $timeout secs)" && echo "Killed $1" 1>&2 ) > ${BOT_NICK}.io &
}
name="m[aeiou]ths?(bot)?"

runCmd() {
  case "`<<<"$1" tr '[:upper:]' '[:lower:]'`" in
    "") say "See !math help" ;;
    help) 
      say "math <program>: Pipe program into bc (see \`man bc\` for syntax)"
      say "math_restart: kill the bot (automatically restarted every minute)" 
      say "For more information, see infoobot mathbot" 
      ;;
    restart) screen -r mathbot -X kill ;;
    *) say "$nick: Unrecognized command $1" ;;
  esac
}


if grep -qiP "^$name[:,]* " <<<"$msg" ; then
  safeRun "`echo -n "$msg" | cut -d ' ' -f 2-`"

elif grep -qiP "^${name}_[a-zA-Z]" <<<"$msg"; then
  runCmd `cut -d '_' -f 2- <<<"$msg" | cut -d ' ' -f 1`

elif grep -qiP "^!${name} " <<<"$msg"; then
  runCmd "`cut -d ' ' -f 2- <<<"$msg"`"

elif grep -qiP "^!${name}" <<<"$msg"; then
  runCmd ""

elif grep -qiP "^!help$" <<<"$msg"; then
  say "See math_help"

elif grep -qiP "mathbot\+\+" <<<"$msg"; then
  case `head -c 1 /dev/urandom | hexdump -v -e '/1 "%u"' | cat - <(echo "%21") | bc` in
    0) say ":)" ;;
    1) say ":D" ;;
    2) say "Thanks!" ;;
    3) say "Yay!" ;;
    4) say "I live to serve." ;;
    5) say "Thanks, $nick" ;;
    6) say "Anytime." ;;
    *) ;;
  esac
fi


