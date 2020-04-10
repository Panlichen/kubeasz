helm install --tls \
	--name grafana \
	--namespace monitoring \
	-f grafana-settings.yaml \
	-f grafana-dashboards.yaml \
	grafana
