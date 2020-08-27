ps -efww|grep -w 'frpc'|grep -v grep|cut -c 9-15|xargs kill -9                
nohup /etc/ansible/frp-121/frpc -c /etc/ansible/frp-121/frpc.ini 2>&1 >/etc/ansible/frp-121/runfrp.err & 