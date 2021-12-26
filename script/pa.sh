#!/bin/zsh


find_root() {
  local path=$(pwd)
  while ! test -f "$path/.pa" ; do
    if [ $path = "/" ] ; then
      pa 
      exit 1
    fi
  done
}