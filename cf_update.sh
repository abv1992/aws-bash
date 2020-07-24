
aws cloudfront list-distributions | grep distribution | cut -d'/' -f2 | cut -d'"' -f1 > /tmp/distribution.txt
cat /tmp/distribution.txt
echo "============="
#printf "%s\n" "${distributions[@]}"

echo "\n"
echo "Results"
echo "======="
#distributions=${distributions[@]}
#echo $distributions

cat /tmp/distribution.txt | while read i 
do
  previous=$(aws cloudfront get-distribution-config --id $i)
  aws cloudfront get-distribution-config --id $i > /tmp/output.txt
  check_timeout_present=$(cat /tmp/output.txt | grep OriginReadTimeout)
  if [ ! -z "$check_timeout_present" ]; then 
    jq '.DistributionConfig.Origins.Items[].CustomOriginConfig.OriginReadTimeout=59' /tmp/output.txt | jq '.DistributionConfig' > output.json  
    update=$(cat /tmp/output.txt)
    aws cloudfront update-distribution --id $i --distribution-config file://output.json --if-match $(echo "$previous" | jq -r '.ETag') >> /tmp/result.json
  else
    echo "skipping $i as it does not have Custom Origin Timeout (origin is S3)"
  fi
done

    