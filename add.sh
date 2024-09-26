#!/bin/bash

clustername="Lovely Amur" #завести заранее
adcmip="10.6.16.120"  # завести заранее

while IFS="," read -r t1 t2 t3 t4 t5
do

echo "[*] Get $t1 $t2 $t3 $t4 $t5"
ansible_user=$t1 
ansible_pass=$t2
hostname=$t3 #имя в adcm hostname
ansible_host=$t4   # ip 
ansible_port=$t5
#jsonadd="{\"description\":\"init\",\"config\":{\"ansible_user\":\"$ansible_user\",\"ansible_ssh_pass\":\"$ansible_pass\",\"ansible_host\":\"$ansible_host\",\"ansible_ssh_port\":\"$ansible_port\",\"ansible_become\":\"$ansible_become\",\"ansible_become_pass\":\"$ansible_pass\" }, \"attr\": {}}"

echo $jsonadd|jq
tokens=$(curl -s -X POST -H 'Content-type: application/json' -d '{"username": "admin","password": "admin"}' http://$adcmip:8000/api/v1/token/ )            
token=$(echo $tokens|awk -F"\"" '{print $4}')
#echo $token
clusters=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/cluster/ `
#echo "Cluster name: "$clusters

idcluster=`echo $clusters | jq  --arg clustername "$clustername" ' .[] |select(.name==$clustername) | .id' `
#typeid=`echo $clusters | jq  --arg clustername "$clustername" ' .[] |select(.name==$clustername) | .prototype_id' `
provids=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/provider/`
provid=`echo $provids | jq  ' .[].id' `
echo "[+] Cluster id: "$idcluster
prototype_ids=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/host/`
#echo $prototype_ids 
prototype_id=`echo $prototype_ids | jq  ' first(.[].prototype_id)' `
echo "[+] Prototype_id: "$prototype_id
echo "[+] Provider: "$provid
#add
#newhost=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"prototype_id":'$prototype_id', "provider_id": "'$provid'", "cluster_id":"'$idcluster'", "fqdn":"'$hostname'", "header": "init"}' http://$adcmip:8000/api/v1/host/`
newhost=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"cluster_id":"'$idcluster'","prototype_id":'$prototype_id',  "provider_id": "'$provid'","fqdn":"'$hostname'", "header": "init"}' http://$adcmip:8000/api/v1/host/`

#echo $newhost
idnewhost=`echo $newhost | jq  ' .id'`
echo "[+] New host id: "$idnewhost
add=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"host_id":"'$idnewhost'"}'  http://$adcmip:8000/api/v1/cluster/$idcluster/host/`
echo "[+] Host add to cluster."

#editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '$jsonadd' http://$adcmip:8000/api/v1/host/$idnewhost/config/history/`
editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"description":"init","config":{"ansible_user":"'$ansible_user'","ansible_ssh_pass":"'$ansible_pass'","ansible_host":"'$ansible_host'","ansible_ssh_port":"'$ansible_port'","ansible_become":true,"ansible_become_pass":"'$ansible_pass'" }, "attr": {}}' http://$adcmip:8000/api/v1/host/$idnewhost/config/history/`
echo $editconfigs

done < <(cat hosts.csv)