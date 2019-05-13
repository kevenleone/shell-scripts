#!/bin/bash
IP_BLACKLIST="0.0.0.0/0"
 
containsPORT(){
    VAL=$1
    ALLOWED_PORTS=("80" "443")
    for i in "${ALLOWED_PORTS[@]}"
    do
        if [ "$i" == "$VAL" ] ; then
            echo true
        fi
    done
}
 
containsProtocol(){
    COL=$1
    ALLOWED_PROTOCOL=("tcp" "udp")
    for y in "${ALLOWED_PROTOCOL[@]}"
    do
        if [ "$y" == "$COL" ] ; then
            echo true
        fi
    done
}

rm -rfv *.csv
DATA="REGION,PORT,IP/CIDR,GROUP_ID,PROTOCOL,INSTANCES_ID"
echo "$DATA" >> security-groups-out-of-compliance.csv

for REGION in `aws ec2 describe-regions --output text | cut -f3`;  
do 
    for Groups in `aws ec2 describe-security-groups --region $REGION --output json | jq -r '.SecurityGroups | .[] | .GroupId as $GroupID | .IpPermissions[] | .FromPort as $port | .IpProtocol as $Protocol | .IpRanges[].CidrIp as $IP | ([$port,$IP,$GroupID,$Protocol] | @csv)'`
    do
        PORT=`echo "$Groups" | awk -F ","  '{print $1}' | tr --delete \"`
        IP=`echo "$Groups" | awk -F ","  '{print $2}' | tr --delete \"`
        GROUPID=`echo "$Groups" | awk -F ","  '{print $3}'`
        PROTOCOL=`echo "$Groups" | awk -F ","  '{print $4}' | tr --delete \"`
        PORT_WHITELIST=$(containsPORT "$PORT")
        PROTOCOL_WHITELIST=$(containsProtocol "$PROTOCOL")
    
        if [[ "$IP" == "$IP_BLACKLIST" && $PORT -lt 1024 && -z "$PORT_WHITELIST" && "$PROTOCOL_WHITELIST" = true ]];
        then
            INSTANCES=`aws ec2 describe-instances --region $REGION --filters "Name=instance.group-id,Values=$GROUPID" --query 'Reservations[*].Instances[*].[InstanceId]' --output text | sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}'`
            echo "\"$REGION\",$Groups,\"$INSTANCES\"" >> security-groups-out-of-compliance.csv
        fi
    done
done