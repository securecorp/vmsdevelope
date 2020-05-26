#!/bin/sh
  
# output1=$( stat -c %a /var/lib/kube-proxy/kubeconfig )
# RESULT=$?

rm securityCheck.log 2>/dev/null
now=$(date)
echo "$now" 2>&1 | tee -a securityCheck.log

if [ -z $1 ]
then
  echo '\e[31m Specify kubelet-config.yaml path as an argument \e[39m' 2>&1 | tee -a securityCheck.log
  exit
fi

if output1=$( stat -c %a /var/lib/kube-proxy/kubeconfig ); then
  output1Num=$( expr $output1 )
  if [ $output1Num -le 644 ]
  then
    $resultPF = "PASS"
    #echo  '\e[32m[PASS] 4.1.3 Ensure that the proxy kubeconfig file permissions are set to 644 or more restrictive \e[39m' 2>&1 | tee -a securityCheck.log
  else
    $resultPF = "FAIL"
    #echo '\e[31m[FAIL] 4.1.3 kubeconfig file permissions must be 644 or more restrictive! \e[39m' 2>&1 | tee -a securityCheck.log
  fi
  echo  "[4.1.3 Ensure that the proxy kubeconfig file permissions are set to 644 or more restrictive][Result: $resultPF" 2>&1 | tee -a securityCheck.log
else
  echo '\e[31m[FAIL] 4.1.3 Error opening kubeconfig file! \e[39m' 2>&1 | tee -a securityCheck.log
fi

if output2=$( stat -c %U:%G /var/lib/kube-proxy/kubeconfig ); then
  if [ $output2 = 'root:root' ]
  then
    echo '\e[32m[PASS] 4.1.4 Ensure that the proxy kubeconfig file ownership is set to root:root \e[39m' 2>&1 | tee -a securityCheck.log
  else
    echo '\e[31m[FAIL] 4.1.4 kubeconfig file must be owned by "root:root"! \e[39m' 2>&1 | tee -a securityCheck.log
  fi
else
  echo '\e[31m[FAIL] 4.1.4 Error opening kubeconfig file! \e[39m' 2>&1 | tee -a securityCheck.log
fi

if output1=$( stat -c %a /home/kubernetes/kubelet-config.yaml ); then
  output1Num=$( expr $output1 )
  if [ $output1Num -le 644 ]
  then
    echo  '\e[32m[PASS] 4.1.9 Ensure that the kubelet configuration file has permissions set to 644 or more restrictive  \e[39m' 2>&1 | tee -a securityCheck.log
  else
    echo '\e[31m[FAIL] 4.1.9 kubelet configiguration file permissions must be 644 or more restrictive! \e[39m' 2>&1 | tee -a securityCheck.log
  fi
else
  echo '\e[31m[FAIL] 4.1.9 Error opening kubeconfig file! \e[39m' 2>&1 | tee -a securityCheck.log
fi

# include parse_yaml function
. ./parse_yaml.sh
# read yaml file
eval $(parse_yaml $1 "config_")
#eval $(parse_yaml zconfig.yml "config_")
# access yaml content
if [ -z $config_authentication_anonymous_enabled ]
then 
  echo '\e[31m[FAIL]\e[33m 4.2.1 --anonymous-auth not set!\e[39m' 2>&1 | tee -a securityCheck.log
elif [ $config_authentication_anonymous_enabled = 'false' ]
then
  echo  '\e[32m[PASS] 4.2.1 Ensure that the --anonymous-auth argument is set to false\e[39m' 2>&1 | tee -a securityCheck.log
else
  echo  '\e[31m[FAIL]\e[33m 4.2.1 --anonymous-auth must be "false"\e[39m' 2>&1 | tee -a securityCheck.log
fi


if [ -z $config_authorization_mode ]
then
  echo  '\e[31m[FAIL]\e[33m 4.2.2 --authorization-mode not set!\e[39m' 2>&1 | tee -a securityCheck.log
elif [ $config_authorization_mode = 'AlwaysAllow' ]
then
  echo  '\e[31m[FAIL]\e[33m 4.2.2 --authorization-mode must not be "AlwaysALlow"!\e[39m' 2>&1 | tee -a securityCheck.log
elif [ $config_authorization_mode = 'Webhook' ]
then
  echo  '\e[32m[PASS] 4.2.2 Ensure that the --authorization-mode argument is not set to AlwaysAllow\e[39m' 2>&1 | tee -a securityCheck.log
fi

if [ -z $config_clientCAFile ]
then
  if [ -z $config_authentication_x509_clientCAFile ]
  then
    echo '\e[31m[FAIL]\e[33m 4.2.3 --client-ca-file and --authentication-X509-clientCAFile not set!\e[39m' 2>&1 | tee -a securityCheck.log
  else
    echo  '\e[32m[PASS] 4.2.3 Ensure that the --client-ca-file argument is set as appropriate \e[39m' 2>&1 | tee -a securityCheck.log
  fi
else
  echo  '\e[32m[PASS] 4.2.3 Ensure that the --client-ca-file argument is set as appropriate \e[39m' 2>&1 | tee -a securityCheck.log
fi

if [ -z $config_read_only_port ]
then
  echo  '\e[31m[FAIL]\e[33m 4.2.4 --read-only-port not set!\e[39m' 2>&1 | tee -a securityCheck.log
elif [ $config_read_only_port = '0' ]
then
  echo  '\e[32m[PASS] 4.2.4 Ensure that the --read-only-port argument is set to 0\e[39m' 2>&1 | tee -a securityCheck.log
elif [ $config_read_only_port != '0' ]
then
  echo  '\e[31m[FAIL]\e[33m 4.2.4 --read-only-port must not be "0"\e[39m' 2>&1 | tee -a securityCheck.log
fi


if [ -z $config_streaming_connection_idle_timeout ]
then
  echo  '\e[31m[FAIL]\e[33m 4.2.5 --streaming-connection-idle-timeout not set!\e[39m' 2>&1 | tee -a securityCheck.log
elif [ $config_streaming_connection_idle_timeout != 0 ]
then
  echo  '\e[32m[PASS] 4.2.5 Ensure that the --streaming-connection-idle-timeout argument is not set to 0 \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo  '\e[31m[FAIL]\e[33m 4.2.5 --streaming-connection-idle-timeout must not be "0" \e[39m' 2>&1 | tee -a securityCheck.log
fi


if [ -z $config_protect_kernel_defaults ]
then
  echo  '\e[31m[FAIL]\e[33m 4.2.6 --protect-kernel-defaults not set!\e[39m' 2>&1 | tee -a securityCheck.log
elif [ $config_protect_kernel_defaults = 'true' ]
then
  echo  '\e[32m[PASS] 4.2.6 Ensure that the --protect-kernel-defaults argument is set to true \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo  '\e[31m[FAIL]\e[33m 4.2.6 --protect-kernel-defaults must be "true"\e[39m' 2>&1 | tee -a securityCheck.log
fi


if [ -z $config_make_iptables_util_chains ]
then
  echo  '\e[31m[FAIL]\e[33m 4.2.7 --make-iptables-util-chains not set!\e[39m' 2>&1 | tee -a securityCheck.log
elif [ $config_make_iptables_util_chains = 'true' ]
then
  echo  '\e[32m[PASS] 4.2.7 Ensure that the --make-iptables-util-chains argument is set to true \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo  '\e[32m[FAIL] 4.2.7 --make-iptables-util-chains must be "true"\e[39m' 2>&1 | tee -a securityCheck.log
fi


if [ -z $config_hostname_override ]
then
  echo  '\e[32m[PASS] 4.2.8 Ensure that the --hostname-override argument is not set \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo  '\e[31m[FAIL]\e[33m 4.2.8 --hostname-override must not be set!\e[39m' 2>&1 | tee -a securityCheck.log
fi


if [ -z $config_event_qps ] 
then
  echo  '\e[31m[FAIL]\e[33m 4.2.9 --event-qps not set!\e[39m' 2>&1 | tee -a securityCheck.log
else
  echo  '\e[32m[PASS] 4.2.9 nsure that the --event-qps argument is set to 0 or a level which appropriate event capture \e[39m' 2>&1 | tee -a securityCheck.log
fi


if [ ! -z $config_tls_cert_file ]  || [ ! -z $config_tls_private_key_file ]
then
  echo  '\e[32m[PASS] 4.2.10 Ensure that the --tls-cert-file and --tls-private-key-file arguments are set as appropriate \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo  '\e[31m[FAIL]\e[33m 4.2.10 --tls-cert-file and/or --tls-private-key-file not set!\e[39m' 2>&1 | tee -a securityCheck.log
fi


if [ -z $config_rotate_certificates ]
then
  echo  '\e[31m[FAIL]\e[33m 4.2.11 --rotate-certificates not set!\e[39m' 2>&1 | tee -a securityCheck.log
elif [ $config_rotate_certificates != 'false' ]
then
  echo  '\e[32m[PASS] 4.2.11 Ensure that the --rotate-certificates argument is not set to false \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo  '\e[31m[FAIL]\e[33m 4.2.11 --rotate-certificates must not be "false"\e[39m' 2>&1 | tee -a securityCheck.log
fi


if [ -z $config_featureGates_RotateKubeletServerCertificate ]
then
  echo  '\e[31m[FAIL]\e[33m 4.2.12 RotateKubeletServerCertificate not set!\e[39m' 2>&1 | tee -a securityCheck.log
elif [ $config_featureGates_RotateKubeletServerCertificate = 'true' ]
then
  echo  '\e[32m[PASS] 4.2.12 Ensure that the RotateKubeletServerCertificate argument is set to true \e[39m' 2>&1 | tee -a securityCheck.log
else
  echo  '\e[31m[FAIL]\e[33m 4.2.12 RotateKubeletServerCertificate must be "true"\e[39m' 2>&1 | tee -a securityCheck.log
fi
