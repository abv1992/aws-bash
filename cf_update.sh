
#!/bin/bash


clean() {
  if [ -f/tmp/output.txt ]; then rm -f /tmp/output.txt >/dev/null 2>&1; fi
  if [ -f /tmp/distribution.txt ]; then rm -f /tmp/distribution.txt >/dev/null 2>&1; fi
  if [ -f /output.json ]; then rm -f /output.json >/dev/null 2>&1; fi
}

read -p "[INPUT REQUIRED] Please provide the Origin Read Time out Value (FYI: Value should be between 0-60, if you want more contact AWS) : " read_time_out

aws cloudfront list-distributions | grep distribution | cut -d'/' -f2 | cut -d'"' -f1 > /tmp/distribution.txt

cat /tmp/distribution.txt | while read i 
do
  echo "Updating Distribution $i" 
  previous=$(aws cloudfront get-distribution-config --id $i)
  aws cloudfront get-distribution-config --id $i > /tmp/output.txt
  check_timeout_present=$(cat /tmp/output.txt | grep OriginReadTimeout)
  if [ ! -z "$check_timeout_present" ]; then
    quantity=$(jq '.DistributionConfig.Origins.Quantity' /tmp/output.txt | jq tonumber)
    for (( count=0; count<($quantity); count++ ))
    do
        if [[ $(jq --argjson count  $count '.DistributionConfig.Origins.Items[$count].DomainName' /tmp/output.txt) != *"s3"* ]]; then
            jq --argjson count $count --argjson read_time_out $read_time_out '.DistributionConfig.Origins.Items[$count].CustomOriginConfig.OriginReadTimeout = $read_time_out' /tmp/output.txt | jq '.DistributionConfig' > output.json  
        fi
    done
    aws cloudfront update-distribution --id $i --distribution-config file://output.json --if-match $(echo "$previous" | jq -r '.ETag') >> /tmp/result.json
  else
    echo "skipping $i as it does not have Custom Origin Timeout (origin is  just S3)"
  fi
done
clean 