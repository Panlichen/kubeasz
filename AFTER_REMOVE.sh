#! /bin/bash
for ip in $(cat /etc/ansible/ip-hosts-sub)
do
    ssh $ip "hostname ; ifconfig cilium_host down ; ifconfig cilium_net down ; ifconfig cilium_vxlan down ; ifconfig tunl0 down ; ifconfig docker0 down; ifconfig mynet0 down; iptables -F"
    ssh $ip "hostname ; ip r s" # show route table
    echo $ip
    echo "======================="
    echo "***********************"
    echo "======================="
done

# rm -rf ~/.kube/