# Lerning Grafana

## dashboard

login  admin/admin

```
http://localhost:3000
```

## pull images 

```
docker pull prom/prometheus:v2.43.0
docker pull prom/node-exporter:v1.5.0
docker pull grafana/grafana:9.4.7
```

## run grafana 

localhost:3000

```
docker run -d \
  -p 3000:3000 \
  --name=grafana \
  -e "GF_SERVER_ROOT_URL=http://grafana.server.name" \
  -e "GF_SECURITY_ADMIN_PASSWORD=secret" \
  grafana/grafana
```

## Prometheus

/temp/prometheus.yml

```
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']
```

## start

localhost:9090

```
docker run -d \
    -p 9090:9090 \
    -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus
```


## Node exporter

- Go compiler => https://golang.org/dl/
- RHEL/CentOS: glibc-static package.


```
go get github.com/prometheus/node_exporter
cd ${GOPATH-$HOME/go}/src/github.com/prometheus/node_exporter
make
```

RUN WITH => ./node_exporter 

## /temp/prometheus.yml

```yml
# - targets: ['localhost:9090']
- targets: ['localhost:9090', 'ip-address:9100']
```

docker restart prometheus

localhost:3000


## microk8s

microk8s kubectl port-forward -n observability service/prometheus-operated --address 0.0.0.0 9090:9090

```
microk8s kubectl port-forward -n kube-system service/kubernetes-dashboard --address 0.0.0.0 10443:443 > /dev/null &
microk8s kubectl port-forward -n observability service/kube-prom-stack-kube-prome-prometheus --address 0.0.0.0 9090:9090 > /dev/null &
microk8s kubectl port-forward -n observability service/kube-prom-stack-grafana --address 0.0.0.0 3000:80 > /dev/null &
```

## ingress grafana

```yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ing-grafana
  labels:
    app: grafana
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: grafana.192.168.1.253.nip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kube-prom-stack-grafana
                port:
                  number: 80
```

## dashboard

https://grafana.com/grafana/dashboards/1860-node-exporter-full/

```
https://grafana.com/grafana/dashboards/1860
```

dashboard => import [ paste link ]

