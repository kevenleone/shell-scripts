#!/bin/bash
rm -rfv *.csv
DATA="REGION,INSTANCE,OWNER,NAME,KEY_NAME,PUBLIC_IP,PRIVATE_IP"
echo "$DATA" >> machines-with-owner.csv
echo "$DATA" >> machines-without-owner.csv
for REGION in `aws ec2 describe-regions --output text | cut -f3`;  
do 
    for INSTANCE_DETAILS in `aws ec2 describe-instances --output json  --region $REGION | jq -r '.Reservations | .[] | .Instances[] | .InstanceId as $i | .KeyName as $k | .NetworkInterfaces[] | .Association.PublicIp as $p |  ([$i, $p, .PrivateIpAddress,$k] | @csv)'`; 
    do
        INSTANCE_ID=`echo "$INSTANCE_DETAILS" | awk -F "," '{print $1}' | tr --delete \\\"`
        PUBLIC_IP=`echo "$INSTANCE_DETAILS" | awk -F ","   '{print $2}'`
        PRIVATE_IP=`echo "$INSTANCE_DETAILS" | awk -F ","  '{print $3}'`
        KEY_NAME=`echo "$INSTANCE_DETAILS" | awk -F ","    '{print $4}'`
        
        OWNER=`aws ec2 describe-instances --query 'Reservations[*].Instances[*].Tags[*]' --region $REGION --instance-id $INSTANCE_ID | jq '.[] | .[] | .[] | select(.Key| sub( "^[\\\\\\s\\\\\\p{Cc}]+"; "" ) | sub( "[\\\\\\s\\\\\\p{Cc}]+$"; "" ) | test("^owner$";"ix")) | .Value' | head -n 1`;
        NAME=`aws  ec2 describe-instances --query 'Reservations[*].Instances[*].Tags[*]' --region $REGION --instance-id $INSTANCE_ID | jq '.[] | .[] | .[] | select(.Key| sub( "^[\\\\\\s\\\\\\p{Cc}]+"; "" ) | sub( "[\\\\\\s\\\\\\p{Cc}]+$"; "" ) | test("^name$";"ix"))  | .Value' | head -n 1`;
        DATA="$REGION,$INSTANCE_ID,$OWNER,$NAME,$KEY_NAME,$PUBLIC_IP,$PRIVATE_IP"

        if [ -z $OWNER ] 
        then
            echo "$DATA" >> machines-without-owner.csv
        else 
            echo "$DATA" >> machines-with-owner.csv
        fi
    done
done