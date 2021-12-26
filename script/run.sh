#!/bin/zsh

name=$1
first=1
last=99999

if [ -z "$name" ]; then
  echo "Usage $0 <app-name> [<first|last>] [<last>]"
  exit 0
fi


if [ $# = 2 ]; then
  last=$2
elif [ $# = 3 ]; then
  first=$2
  last=$3
fi

mkdir -p "test/$name/act"


accepted=0
failed=0
max_time=0
total_time=0
first_fail=""

for i in $(seq $first $last); do 

  input="test/$name/in/$i.in"
  
  if ! test -f $input ; then 
    break
  fi 

  { time exe/$name < $input > test/$name/act/$i.out ; } 2> tmp.txt


  act=$(cat test/$name/act/$i.out)
  exp=$(cat test/$name/out/$i.out)
  lines=$(echo $act | wc -l)
  command_suffix="diff --no-index test/$name/act/$i.out test/$name/out/$i.out"
  exec_time=$(cat tmp.txt)
  exec_time=${exec_time##*cpu }
  exec_time=${exec_time% total}

  total_time=$(( total_time + exec_time ))
  max_time=$(( max_time > exec_time ? max_time : exec_time ))

  echo "############"
  echo "git --no-pager diff --no-index r.sh run.sh | head -n 3"
  git --no-pager diff --no-index r.sh run.sh | head -n 3
  echo "git --no-pager $command_suffix"
  git --no-pager $command_suffix
  echo "############"

  if git --no-pager $command_suffix > /dev/null; then
    accepted=$(( accepted + 1 ))
    if [ "1" = lines ]; then 
      echo "$i OK $exec_time $act $exp"
    else 
      echo "$i OK $exec_time"
    fi
  else 
    failed=$(( failed + 1 ))
    if [ -z "$first_fail" ]; then first_fail=$i; fi
    echo "---------------------------------------------------------"
    echo "   fail - test case $i": $input
    echo " exe/$name < $input > test/$name/act/$i.out"
    echo "---------------------------------------------------------"
    if [ "1" = lines ]; then 
      echo "$i, act: $act, exp: $exp"
    else 
      echo "$i, to see difference RUN: git $command_suffix"
    fi
  fi

  rm tmp.txt
done

all=$(( accepted + failed ))

if [ -z "$first_fail" ]; then 
  echo ""
  echo ""
  echo "##########################################################"
  echo "#   S U C C E S"
  echo "# $all tests executed"
  echo "# avg_time: $(( total_time / accepted ))"
  echo "# max_time: $max_time"
  echo "##########################################################"
else 
  echo ""
  echo ""
  echo "##########################################################"
  echo "#   F A I L"
  echo "# $failed of $all tests failed"
  echo "# first failed test: $first_fail" 
  echo "# "
  echo -n "# avg_time: " ; printf "%g\n" "$(( total_time / i ))"
  echo -n "# max_time: " ; printf "%g\n" "$max_time"
  echo "##########################################################"
fi

