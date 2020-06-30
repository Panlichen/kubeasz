ps -efww|grep -w 'frpc'|grep -v grep|cut -c 9-15|xargs kill -9                
nohup /etc/ansible/frp/frpc -c /etc/ansible/frp/frpc.ini 2>&1 >/etc/ansible/frp/runfrp.err & 