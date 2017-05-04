#!/bin/bash
kubectl get nodes
IP_ADDR=$(kubectl get nodes | grep Ready | awk '{print $1}' | head -1)

if [ -z $1 ]
then
    defaultIP=$(cat core/* | grep 169.47.241.213)
    if [[ -z $defaultIP ]]
    then
        echo "169.47.241.213 not found in yaml files. Please use ./scripts/replace_ip_<your-os>.sh <IP-in-the-yaml-files-you-want-to-replace>"
    else
        echo "Replacing 169.47.241.213 to $IP_ADDR in core/*.yaml and setup.yaml"
        for filename in core/*.yaml
        do
            sed -i '' s#169\.47\.241\.213#$IP_ADDR# $filename
        done

        sed -i '' s#169\.47\.241\.213#$IP_ADDR# setup.yaml
    fi
else
    ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
    then
      OIFS=$IFS
      IFS='.'
      ip=($ip)
      IFS=$OIFS
      [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
          && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
      stat=$?
      if [ $stat -eq 0 ]
      then
          prevIP=$(cat core/* | grep $1)
          if [[ -z $prevIP ]]
          then
              echo "$1 not found in yaml files. Please check your yaml files."
          else

              echo "Replacing $1 to $IP_ADDR in core/*.yaml and setup.yaml"
              for filename in core/*.yaml
              do
                  sed -i '' s#$1#$IP_ADDR# $filename
              done
              sed -i '' s#$1#$IP_ADDR# setup.yaml
          fi
      else
          echo "Invalid IP"
      fi
    else
      echo "Invalid IP format"
    fi
fi
