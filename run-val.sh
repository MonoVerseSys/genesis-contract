#!/bin/bash

SHORT=a:,n:,h
LONG=address:,node:,help
OPTS=$(getopt -a -n entropy --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

while :
do
  case "$1" in
    -a | --address )
      address="$2"
      shift 2
      ;;
    -n | --node )
      node="$2"
      shift 2
      ;;
    -h | --help)
      "This is node reset command"
      exit 2
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      ;;
  esac
done

echo $address, $node




HOME="/home/ubuntu"


geth --datadir "${HOME}/work/data" init "${HOME}/genesis_r2on.json"

geth account import --datadir "${HOME}/work/data" "${HOME}/priv.txt"


nohup geth --datadir "${HOME}/work/data" --syncmode 'full' --port 30303 --bootnodes $node --networkid 11714  --unlock $address  --password "${HOME}/password.txt" --mine &


