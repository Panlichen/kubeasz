helm install --tls \
        --name monitor \
        --namespace monitoring \
        -f prom-settings.yaml \
        -f prom-alertsmanager.yaml \
        -f prom-alertrules.yaml \
        prometheus