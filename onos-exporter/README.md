<!--
SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>

SPDX-License-Identifier: Apache-2.0
-->

# onos-exporter
The exporter for ONOS SD-RAN (µONOS Architecture) to scrape, format, and export KPIs to TSDB databases (e.g., Prometheus).

## Overview
The onos-exporter realizes the collection of KPIs from multiple ONOS SD-RAN components via gRPC interfaces, properly label them according to their namespace and subsystem, and turn them available to be pulled (or pushed to) TSDBs. Currently the implementation supports Prometheus.
It also contain in its chart definitions the dependencies to enable the collection of logs from sd-ran pods.

## Enable 

To enable logging in sdran components, in the onos-exporter chart values.yaml file enable the following components:
In the chart dependencies, fluent-bit realizes the collection of logs from kubernetes pods and stores them into opensearch database.

```yaml
import:
...
  fluent-bit:
    enabled: true
  opensearch:
    enabled: true
```

Important: opensearch requires to set `sysctl -w vm.max_map_count=262144` (and restart the docker service), otherwise the pods stay in a crashloop state.

Associated with the monitoring of sdran components is the onos-exporter component, the exporter for ONOS SD-RAN (µONOS Architecture) to scrape, format, and export onos KPIs to TSDB databases (e.g., Prometheus). Currently the implementation supports Prometheus. In order to enable onos-exporter, as shown below, make sure the prometheus-stack is enabled too in the onos-exporter chart values.yaml file.

```yaml
import:
...
  prometheus-stack:
    enabled: true
```

The onos-exporter component supports scraping of metrics from onos-topo, onos-e2t, onos-uenib, onos-kpimon and onos-pci.

## Deploy onos-exporter

Given the deployment of sd-ran components already in place in the sdran namespace, onos-exporter can be deployed using the following helm command:

```text
helm -n sdran install onos-exporter sdran/onos-exporter --set import.fluent-bit.enabled=true --set import.prometheus-stack.enabled=true --set import.opensearch.enabled=true
```

To remove onos-exporter deployment using helm run the following command.
```text
helm -n sdran uninstall onos-exporter
```


## Visualize metrics in Grafana

After deployed, the services and pods related to logging and monitoring will be accessible by making a port-forward rule to the grafana service on port 3000.

```bash
kubectl -n sdran port-forward svc/onos-exporter-grafana 3000:80
```

Open a browser and access `localhost:3000`. The credentials to access grafana are: 
```txt
username: admin 
password: prom-operator
```

To look at the grafana dashboard for the sdran component logs and KPIs, check in the left menu of grafana the option dashboards and select the submenu Manage (or just access in the browser the address http://localhost:3000/dashboards).

In the menu that shows, look for the dashboard named `Kubernetes / SD-RAN KPIs` to check the KPIs of the sd-ran components (e.g., kpimon, pci, topo, uenib and e2t).

Similarly, other dashboards can be found in the left menu of grafana, showing for instance each pod workload in the dashboad `Kubernetes / Compute Resources / Workload`.


## Visualize onos-exporter prometheus metrics

To look at the onos-exporter metrics, it's possible to access the onos-exporter directly or visualize the metrics in grafana.

To access the metrics directly have a port-forward kubectl command for onos-exporter service:

```bash
kubectl -n sdran port-forward svc/onos-exporter 9861
```

The example above shows the case when onos-exporter is deployed separately, in case it is deployed via RiaB, list the services (kubectl -n sdran get svc) in order to check what is the name of the grafana service to have the port-forward definition.

Then access the address `localhost:9861/metrics` in the browser. The exporter shows golang related metrics too.

To access the metrics using grafana, proceed with the access to grafana. After accessing grafana go to the Explore item on the left menu, on the openned window select the Prometheus data source, and type the name of the metrics to see its visualization and click on the Run query button.


## Visualize logs in opensearch dashboards

Make a port-forward to opensearch-dashboards service on port 5601.

```bash
kubectl -n sdran port-forward svc/onos-exporter-opensearch-dashboards 5601
```

Open a browser and access `localhost:5601`. The credentials to access opensearch dashboards are: 
```txt
username: admin 
password: admin
```

In there, to access the logs, there is the need to set the index pattern, `fluentbit-*`, and explore the index using the Lucene query syntax.
