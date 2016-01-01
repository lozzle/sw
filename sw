function press {
  a=$((16#$1))
  b=$((16#$2))
  !(adb -d shell input tap $a $b) && echo 'canceled' && exit
  #echo $a $b
}
function pr {
  echo $1
}
function pressReplay {
  press 303 21c
  pr 'pressing replay'
}
function pressCharOk {
  press 343 2ad
  pr 'pressing char ok'
  #y 298 above
  #y 32f #below
}
function pressRewardRuneSell {
  press 303 32f
  pr 'pressing reward sell'
}
function pressRewardRuneKeep {
  press 403 32f
  pr 'pressing reward get'
}
function pressStart {
  press 593 31c
  pr 'pressing start'
}
function pressCancelEnergy {
  press 3e8 2ad
  pr 'pressing cancel energy'
}
function mainBody {
  pr '====='
  pressReplay
  pressStart
  pressCancelEnergy
  pressCharOk
}
function loopSell {
  pr 'Starting - selling runes'
  while true
  do
    sleep 0.5
    mainBody
    pressRewardRuneSell
  done
}
function loopKeep {
  pr 'Starting - keeping runes'
  while true
  do
    sleep 0.5
    mainBody
    pressRewardRuneKeep
  done
}
if [ $1 = "sell" ]; then
  loopSell
elif [ $1 = "keep" ]; then
  loopKeep
else
  echo 'Use `sw sell` or `sw keep`'
fi
