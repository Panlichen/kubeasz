kubectl label nodes 10.0.0.252 AcceptType=SysTool
kubectl taint nodes 10.0.0.252 AcceptType=SysTool:NoSchedule