#!/bin/bash

projectID=$1
nodePool=$2
clusterName=$3
computeZone=$4


#kubectl get psp | awk '{print $1}'
noneTrueCheckArray=(.spec.privileged .spec.hostPID .spec.hostIPC .spec.hostNetwork .spec.allowPrivilegeEscalation)

pspArray=()
while IFS= read -r line; do
  pspArray+=( "$line" )
done < <( kubectl get psp 2>/dev/null | awk '{print $1}' )

rm securityCheck.log 2>/dev/null
now=$(date)

echo "$now" 2>&1 | tee -a securityCheck.log

for (( i=1; i<${#pspArray[@]}; i++ ))
do
  echo -e '\e[33mTesting PSP '${pspArray[i]}'\e[39m' 2>&1 | tee -a securityCheck.log
  for (( j=0; j<${#noneTrueCheckArray[@]}; j++ ))
  do
    output=$(kubectl get psp ${pspArray[i]} -o=jsonpath={${noneTrueCheckArray[j]}})
    offset=1
    itemNo=$((j+offset))
    #echo ${noneTrueCheckArray[j]}
    if [ -z $output ]
    then
      echo -e '\e[32m[PASS] 5.2.'$itemNo ${pspArray[i]}${noneTrueCheckArray[j]}' is not set\e[39m' 2>&1 | tee -a securityCheck.log
    elif [ $output = 'true' ]
    then
      echo -e '\e[31m[FAIL]\e[33m 5.2.'$itemNo ${pspArray[i]}${noneTrueCheckArray[j]}' must not be "true"\e[39m' 2>&1 | tee -a securityCheck.log
    else
      echo -e '\e[32m[PASS] 5.2.'$itemNo ${pspArray[i]}${noneTrueCheckArray[j]}' does not return "true"\e[39m' 2>&1 | tee -a securityCheck.log
    fi
  done
  
  output=$(kubectl get psp ${pspArray[i]} -o=jsonpath={'.spec.runAsUser.rule'})
  output2=''
  if [ -z $output ]
  then
    echo -e '\e[31m[FAIL] '${pspArray[i]}'.spec.runAsUser.rule is not set\e[39m' 2>&1 | tee -a securityCheck.log
  elif [ $output != 'MustRunAsNonRoot' ]
  then
    output2=$(kubectl get psp ${pspArray[i]} -o=jsonpath={'.spec.runAsUser.rule.MustRunAs'})
    if [ !-z $output2 ]
    then
      if [[ $output2 != '0' ]]
      then
  echo -e '\e[32m[PASS] 5.2.6 '${pspArray[i]}'.spec.runAsUser.rule.MustRunAs must not be "0"\e[39m' 2>&1 | tee -a securityCheck.log
      else
  echo -e '\e[31m[FAIL]\e[33m 5.2.6 '${pspArray[i]}'.spec.runAsUser.rule.MustRunAs must not be "0"\e[39m' 2>&1 | tee -a securityCheck.log
      fi
    else
      echo -e '\e[31m[FAIL]\e[33m 5.2.6 '${pspArray[i]}' MustRunAsNonRoot must be set or MustRunAs must not be "0"\e[39m' 2>&1 | tee -a securityCheck.log
    fi
  else
    echo -e '\e[32m[PASS] 5.2.6 '${pspArray[i]}' spec.runAsUser.rule.MustRunAsNonRoot is set\e[39m' 2>&1 | tee -a securityCheck.log
  fi

  output=$(kubectl get psp ${pspArray[i]} -o=jsonpath={'.spec.requiredDropCapabilities'})
#   echo $output
  if [ -n "$output" ]
  then
    if [[ $output == *"NET_RAW"* ]] || [[ $output -eq *"ALL"* ]]
    then
      echo -e '\e[32m[PASS] 5.2.7 '${pspArray[i]}'.spec.requiredDropCapabilities must be "NET_RAW" or "ALL"\e[39m' 2>&1 | tee -a securityCheck.log
    else
      echo -e '\e[31m[FAIL]\e[33m 5.2.7 '${pspArray[i]}'.spec.requiredDropCapabilities must be "NET_RAW" or "ALL"\e[39m' 2>&1 | tee -a securityCheck.log
    fi
  else
    echo -e '\e[31m[FAIL]\e[33m 5.2.7 '${pspArray[i]}'.spec.requiredDropCapabilities is not set\e[39m' 2>&1 | tee -a securityCheck.log
  fi

  output=$(kubectl get psp ${pspArray[i]} -o=jsonpath={.spec.allowedCapabilities} )
#   echo $output
  if [ -z "$output" ]
  then
    echo -e '\e[32m[PASS] 5.2.8 '${pspArray[i]}' is not set\e[39m' 2>&1 | tee -a securityCheck.log
  else
    echo -e '\e[31m[FAIL]\e[33m 5.2.8 '${pspArray[i]}' must be empty \e[39m' 2>&1 | tee -a securityCheck.log
  fi
done

if [ ${#pspArray[@]} > 0 ]
then
  echo -e '\e[32m[PASS]\e[33m 5.2.9 MANUAL REVIEW REQUIRED : PSP exists \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 5.2.9 PSP not set \e[39m' 2>&1 | tee -a securityCheck.log
fi

output=$(kubectl get networkpolicy 2>/dev/null)
if [ -z "$output" ]
then
  echo -e '\e[32m[PASS]\e[33m 5.3.2 MANUAL REVIEW REQUIRED : Networkpolicy not set \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[32m[PASS]\e[33m 5.3.2 MANUAL REVIEW REQUIRED : Networkpolicy exists \e[39m' 2>&1 | tee -a securityCheck.log
fi

output=$(kubectl get all)
if [[ $output == *"NAME"* ]]
then
  echo -e '\e[32m[PASS]\e[33m 5.6.4 MANUAL REVIEW REQUIRED : Check Namespaces \e[39m' 2>&1 | tee -a securityCheck.log
fi

registryArray=()
while IFS= read -r line; do
  registryArray+=( "$line" )
done < <( gcloud services list --enabled --filter containerregistry | awk '{print $2 " " $3 " " $4}' )

answercount=0
for (( i=1; i<${#registryArray[@]}; i++ ))
do
    # echo ${registryArray[i]}
  if [ "${registryArray[i]}" = "Container Scanning API" ]
  then
    answercount++
  fi
done

# echo $answercount

if [ $answercount -ge 1 ]
then
  echo -e '\e[32m[PASS] 6.1.1 Ensure Image Vulnerability Scanning using GCR Container Analysis or a third-party provider \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.1.1 Container Scanning API not found!\e[39m' 2>&1 | tee -a securityCheck.log
fi

output=$(gsutil iam get gs://artifacts.$1.appspot.com 2>/dev/null | tr -d \":-)
if [ -z "$output" ]
then
  echo -e '\e[32m[PASS]\e[33m 6.1.2 MANUAL REVIEW REQUIRED : GCR Bucket does not exist \e[39m' 2>&1 | tee -a securityCheck.log
  echo -e '\e[32m[PASS]\e[33m 6.1.2 MANUAL REVIEW REQUIRED : GCR Bucket does not exist \e[39m' 2>&1 | tee -a securityCheck.log
elif [[ $output == *"serviceAccount"* ]]
then
  echo -e '\e[32m[PASS]\e[33m 6.1.2 MANUAL REVIEW REQUIRED : There is a member associated with GCR Bucket \e[39m' 2>&1 | tee -a securityCheck.log
  echo -e '\e[32m[PASS]\e[33m 6.1.3 MANUAL REVIEW REQUIRED : There is a member associated with GCR Bucket \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[32m[FAIL]\e[33m 6.1.2 Minimize user access to GCR \e[39m' 2>&1 | tee -a securityCheck.log
  echo -e '\e[32m[FAIL]\e[33m 6.1.3 Minimize user access to GCR \e[39m' 2>&1 | tee -a securityCheck.log
fi

output=$(gcloud container node-pools describe $2 --cluster $3 --zone $4 --format json | jq -r '.config.serviceAccount' | tr -d \":-)
if [[ $output == *"default"* ]]
then
  echo -e '\e[31m[FAIL]\e[33m 6.2.1 Default account must not be used \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[32m[PASS] 6.2.1 Default account not in use \e[39m' 2>&1 | tee -a securityCheck.log
fi

output=$(gcloud container clusters describe $3 --zone $4 --format json | jq '.databaseEncryption')
# echo $output
if [ "$output" = ' { "state": "ENCRYPTED" }' ]
then
  echo -e '\e[32m[PASS] 6.3.1 Ensure Kubernetes Secrets are encrypted using keys managed in Cloud KMS \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.3.1 Ensure Kubernetes Secrets are encrypted using keys managed in Cloud KMS \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container node-pools describe $2 --cluster $3 --zone $4 --format json | jq -r '.config.metadata' | awk 'NR==2' | tr -d \":-)
# echo gcloud container node-pools describe $2 --cluster $3 --zone $4 --format json | jq '.config.metadata'
# echo $output
answer="disablelegacyendpoints true"
# echo $answer
if [[ $output == *"$answer"* ]]
then
  echo -e '\e[32m[PASS] 6.4.1 Ensure legacy Compute Engine instance metadata APIs are Disabled\e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.4.1 Ensure legacy Compute Engine instance metadata APIs are Disabled\e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container node-pools describe $2 --cluster $3 --zone $4 --format json | jq -r '.config.imageType' | tr -d \")
if [[ $output == *"containerd"* ]]
then
  echo -e '\e[32m[PASS] 6.5.1 Ensure Container-Optimized OS (COS) is used for GKE node images \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.5.1 Ensure Container-Optimized OS (COS) is used for GKE node images \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container node-pools describe $2 --cluster $3 --zone $4 --format json | jq -r '.management' | tr -d \":)
# echo $output

answer="autoRepair true"
if [[ $output == *"$answer"* ]]
then
  echo -e '\e[32m[PASS] 6.5.2 Ensure Node Auto-Repair is enabled for GKE nodes  \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.5.2 Ensure Node Auto-Repair is enabled for GKE nodes  \e[39m' 2>&1 | tee -a securityCheck.log
fi  

answer="autoUpgrade true"
if [[ $output == *"$answer"* ]]
then
  echo -e '\e[32m[PASS] 6.5.3 Ensure Node Auto-Upgrade is enabled for GKE nodes  \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.5.3 Ensure Node Auto-Upgrade is enabled for GKE nodes  \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container clusters describe $3 --zone $4 --format json | jq '.ipAllocationPolicy.useIpAliases')
# echo $output
if [[ $output == "true" ]]
then
    echo -e '\e[32m[PASS] 6.6.2 Ensure use of VPC-native clusters   \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.6.2 Ensure use of VPC-native clusters   \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container clusters describe $3 --zone $4 --format json | jq -r '.masterAuthorizedNetworksConfig' | tr -d \":)
# echo $output
answer="enabled true"
if [[ $output == *"$answer"* ]]
then
  echo -e '\e[32m[PASS] 6.6.3 Ensure Master Authorized Networks is Enabled \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.6.3 Ensure Master Authorized Networks is Enabled \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container clusters describe $3 --zone $4 --format json | jq '.privateClusterConfig.enablePrivateEndpoint')
if [[ $output == "true" ]]
then
    echo -e '\e[32m[PASS] 6.6.4 Ensure clusters are created with Private Endpoint Enabled and Public Access Disabled \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.6.4 Ensure clusters are created with Private Endpoint Enabled and Public Access Disabled \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container clusters describe $3 --zone $4 --format json | jq '.privateClusterConfig.enablePrivateNodes')
if [[ $output == "true" ]]
then
    echo -e '\e[32m[PASS] 6.6.5 Ensure clusters are created with Private Nodes  \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.6.5 Ensure clusters are created with Private Nodes  \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container clusters describe $3 --zone $4 --format json | jq '.loggingService' | tr -d \")
if [[ $output == "logging.googleapis.com/kubernetes" ]]
then
    echo -e '\e[32m[PASS] 6.7.1 [1/2] Ensure Stackdriver Kubernetes Logging and Monitoring is Enabled \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.7.1 [1/2] Ensure Stackdriver Kubernetes Logging and Monitoring is Enabled \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container clusters describe $3 --zone $4 --format json | jq '.monitoringService' | tr -d \")
if [[ $output == "monitoring.googleapis.com/kubernetes" ]]
then
    echo -e '\e[32m[PASS] 6.7.1 [2/2] Ensure Stackdriver Kubernetes Logging and Monitoring is Enabled \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.7.1 [2/2] Ensure Stackdriver Kubernetes Logging and Monitoring is Enabled \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container clusters describe $3 --zone $4 --format json | jq '.masterAuth.password and .masterAuth.username' | tr -d \")
if [[ $output == "false" ]]
then
    echo -e '\e[32m[PASS] 6.8.1 Ensure Basic Authentication using static passwords is Disabled \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.8.1 Ensure Basic Authentication using static passwords is Disabled \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container clusters describe $3 --zone $4 --format json | jq -r '.masterAuth.clientKey' | tr -d \")
if [[ $output == *"null"* ]]
then
    echo -e '\e[32m[PASS] 6.8.2 Ensure authentication using Client Certificates is Disabled  \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.8.2 Ensure authentication using Client Certificates is Disabled  \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container clusters describe $3 --zone $4 --format json | jq -r '.legacyAbac' | tr -d \")
# echo $output
if [[ -z $output ]] || [[ $output == "{}" ]] || [[ $output == *"null"* ]]
then
    echo -e '\e[32m[PASS] 6.8.4 Ensure Legacy Authorization (ABAC) is Disabled  \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.8.4 Ensure Legacy Authorization (ABAC) is Disabled  \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container clusters describe $3 --zone $4 --format json | jq '.addonsConfig.kubernetesDashboard' | tr -d \":)
# echo $output
answer="disabled true"
if [[ $output == *"$answer"* ]]
then
  echo -e '\e[32m[PASS] 6.10.1 Ensure Kubernetes Web UI is Disabled  \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.10.1 Ensure Kubernetes Web UI is Disabled  \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container clusters describe $3 --zone $4 --format json | jq '.enableKubernetesAlpha' | tr -d \":)
# echo $output
if [[ $output == "true" ]]
then
  echo -e '\e[32m[PASS] 6.10.2 Ensure that Alpha clusters are not used for production workloads   \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.10.2 Ensure that Alpha clusters are not used for production workloads   \e[39m' 2>&1 | tee -a securityCheck.log
fi  

output=$(gcloud container clusters describe $3 --zone $4  --format json | jq '.binaryAuthorization' | tr -d \":)
# echo $output
answer="enabled true"
if [[ $output == *"$answer"* ]]
then
  echo -e '\e[32m[PASS] 6.10.5 Ensure use of Binary Authorization   \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo -e '\e[31m[FAIL]\e[33m 6.10.5 Ensure use of Binary Authorization   \e[39m' 2>&1 | tee -a securityCheck.log
fi  

