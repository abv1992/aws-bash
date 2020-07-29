

clean() {
  if [ -f/tmp/output.txt ]; then rm -f /tmp/output.txt >/dev/null 2>&1; fi
  if [ -f /tmp/distribution.txt ]; then rm -f /tmp/distribution.txt >/dev/null 2>&1; fi
  output.json
  if [ -f /output.json ]; then rm -f /output.json >/dev/null 2>&1; fi
}

aws cloudfront list-distributions | grep distribution | cut -d'/' -f2 | cut -d'"' -f1 > /tmp/distribution.txt
#cat /tmp/distribution.txt
#echo "============="
#printf "%s\n" "${distributions[@]}"

#echo "\n"
#:echo "Results"
#echo "======="

cat /tmp/distribution.txt | while read i 
do
  echo $i
  previous=$(aws cloudfront get-distribution-config --id $i)
  aws cloudfront get-distribution-config --id $i > /tmp/output.txt
  check_timeout_present=$(cat /tmp/output.txt | grep OriginReadTimeout)
  if [ ! -z "$check_timeout_present" ]; then
    #jq '.DistributionConfig.Origins.Items[].DomainName' /tmp/output.txt > /tmp/domain_if_S3.txt
    quantity=$(jq '.DistributionConfig.Origins.Quantity' /tmp/output.txt | jq tonumber)
    echo $quantity
    for (( count=0; count<($quantity); count++ ))
    do
        if [[ $(jq --argjson count  $count '.DistributionConfig.Origins.Items[$count].DomainName' /tmp/output.txt) != *"s3"* ]]; then
            jq --argjson count $count '.DistributionConfig.Origins.Items[$count].CustomOriginConfig.OriginReadTimeout = 60' /tmp/output.txt | jq '.DistributionConfig' > output.json  
        fi
    done
    aws cloudfront update-distribution --id $i --distribution-config file://output.json --if-match $(echo "$previous" | jq -r '.ETag') >> /tmp/result.json
  else
    echo "skipping $i as it does not have Custom Origin Timeout (origin is  just S3)"
  fi
done
clean

    