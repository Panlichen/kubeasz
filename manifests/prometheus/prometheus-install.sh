helm install \
        --namespace monitoring \
        --set kubeStateMetrics.nodeSelector=kubernetes.io/hostname: 10.0.0.252 \
        -f prom-settings.yaml \
        -f prom-alertsmanager.yaml \
        -f prom-alertrules.yaml \
        prometheus