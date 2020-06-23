---
note:
    createdAt: 2020-04-29T02:59:38.076Z
    modifiedAt: 2020-04-30T03:25:09.342Z
    tags: []
---
~~### 安装之后需要给252加taint~~

  ~~`/etc/ansible/label-taint-252.sh`~~

[TOC]

### 拉取业务镜像
```bash
/home1/root/DeathStarBench/tools/pull-docker-image.sh
```

### 部署ex-lb

安装之前需要看看/etc/ansible/roles/ex-lb/defaults/main.yml和/etc/ansible/roles/ex-lb/templates/haproxy.cfg.j2的配置

```bash
ansible-playbook /etc/ansible/roles/ex-lb/ex-lb.yml
kubectl create -f /etc/ansible/manifests/ingress/traefik/traefik-ui.ing.yaml
```
### 安装结束之后需要手动装的插件
  
#### helm
  ```bash
  ansible-playbook /etc/ansible/roles/helm/helm.yml
  kk apply -f /etc/ansible/roles/helm/tasks/tiller.yaml
  ```
    
#### prometheus + grafana
   ```bash
   cd /etc/ansible/manifests/prometheus
   /etc/ansible/manifests/prometheus/prometheus-install.sh
   /etc/ansible/manifests/prometheus/grafana-install.sh
   ```
#### hubble
   ```bash
   cd /home1/root/DeathStarBench/deploy-hubble/install/kubernetes/
   # only when change config
   /home1/root/DeathStarBench/deploy-hubble/install/kubernetes/gen-yaml.sh
   
   kk apply -f /home1/root/DeathStarBench/deploy-hubble/install/kubernetes/install-hubble.yaml
   ```
   



#### Deploy jaeger

Refer to [here](https://www.jaegertracing.io/docs/1.17/operator/).

##### Deploy jaeger operator:

```
kubectl apply -f /home1/root/DeathStarBench/deploy-jaeger/crds/jaegertracing.io_jaegers_crd.yaml
kubectl apply -f /home1/root/DeathStarBench/deploy-jaeger
```

Configurations:

1. Customize the `operator.yaml`, setting the env var `WATCH_NAMESPACES` to have an empty value, so that it can watch for instances across all namespaces.

The operator creates a Kubernetes [`ingress`](https://kubernetes.io/docs/concepts/services-networking/ingress/) route, which is the Kubernetes’ standard for exposing a service to the outside world. Once Ingress is enabled, the address for the Jaeger UI can be found by querying the Ingress object:

```
kubectl get ingress
```



##### Deploy jaeger instances

###### All-in-one, in memory

```
kubectl apply -f /home1/root/DeathStarBench/deploy-jaeger/crds/jaeger-all-in-one-inmemory.yaml
```

###### Configurations

- [Auto-injecting Jaeger Agent Sidecars](https://www.jaegertracing.io/docs/1.17/operator/#auto-injecting-jaeger-agent-sidecars)
- [Deployment Strategies](https://www.jaegertracing.io/docs/1.17/operator/#deployment-strategies)
- [Storage options](https://www.jaegertracing.io/docs/1.17/operator/#storage-options)

### 外部访问k8s
使用[frp](https://github.com/fatedier/frp/blob/master/README_zh.md)

在master(master此时充当的是frp的client)上:
```bash
nohup /etc/ansible/frp/frpc -c /etc/ansible/frp/frpc.ini 2>&1 >/etc/ansible/frp/runfrp.err & 
# 最好放到/etc/rc.local里开机启动
```

在frp的server上
```bash
nohup /home/poanpan/frp/frps -c /home/poanpan/frp/frps.ini 2>&1 >/home/poanpan/frp/runfrp.err &
# 最好放到/etc/rc.local里开机启动
# frps.ini的内容也很简单:
[common]
bind_port = 13680
```

接下来在frp的server上,编辑.kube/config:
```bash
# 其他主要内容从master复制过来
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ...
    server: https://127.0.0.1:16643
  name: cluster1
contexts:
  ...
```