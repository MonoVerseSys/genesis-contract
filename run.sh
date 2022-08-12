#!/bin/bash


HOME="/home/ubuntu"


geth --datadir "${HOME}/work/data" init "${HOME}/genesis_r2on.json"

IP=$(hostname -I)

nohup geth --datadir "${HOME}/work/data" --networkid 11714 --nodiscover --allow-insecure-unlock --nat extip:$IP --rpc --rpcport 16812 --rpccorsdomain "*" --rpcaddr 0.0.0.0 --rpcvhosts=* --rpcapi "admin,eth,debug,miner,net,txpool,personal,web3" --ws --ws.port 8546 --ws.origins "*" --ws.addr 0.0.0.0 --ws.api "admin,eth,debug,miner,net,txpool,personal,web3" &
