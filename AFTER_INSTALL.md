---
tags: []
created: 2020-04-29T02:59:38.076Z
modified: 2020-06-30T01:47:36.093Z
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

   # 创建prometheus的ingress(通过prometheus.test.com访问)
   kk apply -f /etc/ansible/manifests/prometheus/prometheus-ingress.yaml 
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


### ingress配置及负载均衡访问
参考[ex-lb配置转发 ingress nodePort](https://github.com/Panlichen/kubeasz/blob/master/docs/op/loadballance_ingress_nodeport.md)和[Ingress配置](https://github.com/Panlichen/kubeasz/blob/master/docs/guide/ingress.md)。
主要原理是通过NodePort暴露traefik-ingress-service，然后ex-lb配置对nodePort的负载均衡访问，不至于只从一个节点访问nodeport服务，造成性能瓶颈。k8s集群内部的一个服务的ingress在部署的时候可以选择暴露一个域名（或者其他暴露方式），访问的时候直接访问这个域名，需要在访问者上修改`/etc/hosts`文件，例如
```
# for HAproxy NodePort Forwarding
10.0.0.1 traefik-ui.test.com
10.0.0.1 sn-nginx.test.com
10.0.0.1 media-nginx.test.com
10.0.0.1 prometheus.test.com
```
流量会先到达ex-lb节点，导向到对应的traefik-ingress-service，然后再根据ingress里指定的域名和后端的对应关系真正走到后端服务。



### 外部访问k8s
使用[frp](https://github.com/fatedier/frp/blob/master/README_zh.md)

在kube-master(kube-master此时充当的是frp的client)上:
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
# 其他主要内容从kube-master复制过来:
scp -r -P 36800 -i .ssh/lcpan .kube poanpan@162.105.146.121:~ 

# 编辑后.kube/config长这样:
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ...
    server: https://127.0.0.1:16643
  name: cluster1
contexts:
  ...
```