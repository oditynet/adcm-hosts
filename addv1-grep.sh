#!/bin/bash
#TODO: prototype_id found

#bash addv1-grep.sh --edit - modify hosts
#bash addv1-grep.sh  - add new hosts


clustername="adb-t1" #завести заранее  Lovely Amur
adcmip="10.6.16.120"  # завести заранее 8000 port
edit=$1
if [[ -z $adcmip ]]; then
    echo "Correct variable hostname"
    exit 0
fi
if [[ -z $clustername ]]; then
    tokens=$(curl -s -X POST -H 'Content-type: application/json' -d '{"username": "admin","password": "admin"}' http://$adcmip:8000/api/v1/token/ )            
    token=$(echo $tokens|awk -F"\"" '{print $4}')
    #echo $token
    clusters=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/cluster/ `
    echo "Cluster name:  [list]"
    #echo $clusters|jq -r '.[].name'
    echo $clusters|grep -Po 'name":"\K[^",]*'
    echo "[!Error] Correct variable clustername in me..."
    exit 0
fi

while IFS="," read -r t1 t2 t3 t4 t5
do

echo "[*] Get $t1 *** $t3 $t4 $t5"
ansible_user=$t1 
ansible_pass=$t2
hostname=$t3 #имя в adcm hostname
ansible_host=$t4   # ip 
ansible_port=$t5
#jsonadd="{\"description\":\"init\",\"config\":{\"ansible_user\":\"$ansible_user\",\"ansible_ssh_pass\":\"$ansible_pass\",\"ansible_host\":\"$ansible_host\",\"ansible_ssh_port\":\"$ansible_port\",\"ansible_become\":\"$ansible_become\",\"ansible_become_pass\":\"$ansible_pass\" }, \"attr\": {}}"

#echo $jsonadd|jq
tokens=$(curl -s -X POST -H 'Content-type: application/json' -d '{"username": "admin","password": "admin"}' http://$adcmip:8000/api/v1/token/ )            
token=$(echo $tokens|awk -F"\"" '{print $4}')
echo $token
clusters=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/cluster/ `
echo "Cluster name: "$clusters

#idcluster=`echo $clusters | jq  --arg clustername "$clustername" ' .[] |select(.name==$clustername) | .id' `
#[1]temp_id=`echo $clusters|grep -Po 'name":"\K[^",]*'|awk 'NR==1{s=0}{s=s+1;print s,$1}'|grep $clustername|awk '{print $1}'`
idcluster=`echo $clusters|grep -Po '\[{\K[^$]*' | sed -r 's/\}\,\{/\n/'| awk -F',' '{print $1":"$3}'|tr -d '"'|awk -F ':' '{print $2" "$4}'|grep " $clustername$"|awk '{print $1}'`
#echo "temp_id="$temp_id
#[1]idcluster=`echo $clusters|grep -Po '"id":\K[^,]*'|awk 'NR==1{s=0}{s=s+1; if (s=='$temp_id')print $1}' `

#typeid=`echo $clusters | jq  --arg clustername "$clustername" ' .[] |select(.name==$clustername) | .prototype_id' `
provids=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/provider/`
#provid=`echo $provids | jq  ' .[].id' `
provid=`echo $provids|grep -Po '"id":\K[^,]*' `

echo "[+] Cluster id: "$idcluster
prototype_ids=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/host/`
#echo $prototype_ids 
#prototype_id=`echo $prototype_ids | jq  ' first(.[].prototype_id)' `
prototype_id=`echo $prototype_ids |grep -Po '"prototype_id":\K[^",]*'|head -1`
#[2]prototype_id=`echo $clusters| sed -r 's/\}\,\{/\n/'| awk -F',' '{print $3":"$2}'|tr -d '"'|grep ":$clustername:"|awk -F ':' '{print $4}'`

echo "[+] Prototype_id: "$prototype_id
echo "[+] Provider: "$provid
if [[  -z $edit ]]; then
    echo "[_]   Add new node."
    #add
    #newhost=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"prototype_id":'$prototype_id', "provider_id": "'$provid'", "cluster_id":"'$idcluster'", "fqdn":"'$hostname'", "header": "init"}' http://$adcmip:8000/api/v1/host/`
    newhost=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"cluster_id":"'$idcluster'","prototype_id":'$prototype_id',  "provider_id": "'$provid'","fqdn":"'$hostname'", "header": "init"}' http://$adcmip:8000/api/v1/host/`
    
    echo $newhost
    #idnewhost=`echo $newhost | jq  ' .id'`
    idnewhost=`echo $newhost |grep -Po '"id":\K[^,]*' `

    echo "[+] New host id: "$idnewhost
    add=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"host_id":"'$idnewhost'"}'  http://$adcmip:8000/api/v1/cluster/$idcluster/host/`
    echo "[+] Host add to cluster."
fi

#editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '$jsonadd' http://$adcmip:8000/api/v1/host/$idnewhost/config/history/`
if [[  -z $edit ]]; then
    editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"description":"init","config":{"ansible_user":"'$ansible_user'","ansible_ssh_pass":"'$ansible_pass'","ansible_host":"'$ansible_host'","ansible_ssh_port":"'$ansible_port'","ansible_become":true,"ansible_become_pass":"'$ansible_pass'" }, "attr": {}}' http://$adcmip:8000/api/v1/host/$idnewhost/config/history/`
    echo $editconfigs
else
    listhost=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/host/`
    nodecount=`echo $listhost |grep -Po '"id":\K[^",]*'`
    for i in $nodecount; do
	host_names=`curl -s -X GET -H 'Content-type: application/json' -H 'Authorization: token '$token''  http://$adcmip:8000/api/v1/host/$i/`
	host_name=`echo $host_names |grep -Po '"fqdn":"\K[^",]*'`
	if [[ "$hostname" == "$host_name" ]];then
	    editconfigs=`curl -s -X POST -H 'Content-type: application/json' -H 'Authorization: token '$token'' -d '{"description":"init","config":{"ansible_user":"'$ansible_user'","ansible_ssh_pass":"'$ansible_pass'","ansible_host":"'$ansible_host'","ansible_ssh_port":"'$ansible_port'","ansible_become":true,"ansible_become_pass":"'$ansible_pass'" }, "attr": {}}' http://$adcmip:8000/api/v1/host/$i/config/history/`
	    echo "[%] Edit host id "$i " and name "$host_name
	fi
    done

fi

done < <(cat hosts.csv)