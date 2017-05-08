# Scripts

## deploy-to-bluemix
Contains necessary scripts for the toolchain to deploy the app in Bluemix.
Requirements are having a Bluemix account, deployed Cluster in Bluemix container service, and a Github account.

## install.sh
The script for Travis. It runs build and checks if the build has passed or failed.

## replace\_ip\_< os >.sh
The script for modifying the yaml files in the **core** folder and **setup.yaml**.

* Usage:

1. `replace_ip_<your-os>.sh`
  * replaces every instance of `169.47.241.213` in the yaml files inside your **core** folder  and **setup.yaml** to the IP of your cluster *(found by executing `kubectl get nodes`)*.
2. `replace_ip_<your-os>.sh <IP-ADDRESS>`
  * replaces every instance of `<IP-ADDRESS>` to the IP of your cluster *(found by executing `kubectl get nodes`)*.
  * Ex: `replace_ip_OSX.sh 169.47.241.213` replaces every `169.47.241.213` in the files mentioned above.
3. `replace_ip_<your-os>.sh <ip-to-be-replaced> <IP-ADDRESS>`
  * replaces every instance of `<ip-to-be-replaced>` to `<IP-ADDRESS>`
  * Ex: `replace_ip_OSX.sh 169.47.241.213 192.168.99.100` replaces every `169.47.241.213` to `192.168.99.100`
