#! /bin/bash
for ip in $(cat /etc/ansible/ip-hosts-sub)
do
    for image in $(cat /etc/ansible/lab-images-p1)
    do
        ssh $ip "hostname && echo $image"
        ssh $ip "docker pull $image" &
    done
    echo "======================="
    echo "***********************"
    echo "======================="
done

for image in $(cat /etc/ansible/lab-images-master)
do
    echo "pulling $image"
    ssh 10.0.0.11 "docker pull $image" &
done