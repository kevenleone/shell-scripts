#!/bin/bash
rm -rfv *.csv
DATA="BUCKET_NAME,CreationDate,SSEAlgorithm,KMSMasterKeyID,OWNER"
echo "$DATA" >> ec2-encrypted.csv
echo "$DATA" >> ec2-unencrypted.csv

for BUCKETS in `aws s3api list-buckets --output json | jq -r '.Buckets | .[] | .Name as $Name | .CreationDate as $Date | ([$Name, $Date] | @csv)'`
do
    BUCKET=`echo "$BUCKETS" | awk -F ","  '{print $1}' | tr --delete \"`
    BUCKET_DATA=`echo "$BUCKETS" | awk -F ","  '{print $2}' | tr --delete \"`
    OWNERS=`aws s3api get-bucket-tagging --bucket $BUCKET | jq '.TagSet | .[] | select(.Key| sub( "^[\\\s\\\p{Cc}]+"; "" ) | sub( "[\\\s\\\p{Cc}]+$"; "" ) | test("^owner$";"ix")) | .Value'`
    Encrypt=`aws s3api get-bucket-encryption --bucket $BUCKET | jq -r '.ServerSideEncryptionConfiguration | .Rules | .[] | .ApplyServerSideEncryptionByDefault | .KMSMasterKeyID as $KeyID | .SSEAlgorithm as $Algorith | ([$KeyID, $Algorith] | @csv)'`
    KMSMasterKeyID=`echo "$Encrypt" | awk -F ","  '{print $1}' | tr --delete \"`
    SSEAlgorithm=`echo "$Encrypt" | awk -F ","  '{print $2}' | tr --delete \"`
    DATA="$BUCKET,$BUCKET_DATA,$SSEAlgorithm,$KMSMasterKeyID,$OWNERS"
    if [ -z "$SSEAlgorithm" ]
    then   
        echo "$DATA" >> ec2-unencrypted.csv
    else
        echo "$DATA" >> ec2-encrypted.csv
    fi
done    
