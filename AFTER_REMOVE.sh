#! /bin/bash
for ip in $(cat ip-hosts-no252)
do
    ssh $ip "hostname ; ifconfig cilium_host down ; ifconfig cilium_net down ; ifconfig cilium_vxlan down ; ifconfig tunl0 down ; ifconfig docker0 down; ifconfig mynet0 down; iptables -F"
    ssh $ip "hostname ; ip r s"
    echo $ip
    echo "======================="
    echo "***********************"
    echo "======================="
done