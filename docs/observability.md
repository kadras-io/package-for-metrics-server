# Observability

## Logs

```yaml
observability:
  logging:
    level: info
    format: json
```

* `level` is one of `info`, `debug`, `trace`. They map to the [log verbosity](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-instrumentation/logging.md#what-method-to-use) 0, 4, and 6 of the Kubernetes components. `info` logs the essential messages, `debug` also the operational ones, like the scrapes of each Kubelet. For a specific verbosity, set the `v` flag via `args` (see [configuration.md](configuration.md)):

```yaml
args:
  v: 2
```

* `format` is one of `text` and `json`.

## Metrics

Metrics Server exposes its own metrics in the Prometheus format on its secure port (`/metrics`), like the duration of the Kubelet scrapes and the number of metrics stored. The endpoint requires authentication and authorization, delegated to the Kubernetes API: grant the scraper the permission to read it.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: metrics-server-metrics-reader
rules:
  - nonResourceURLs: ["/metrics"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: metrics-server-metrics-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: metrics-server-metrics-reader
subjects:
  - kind: ServiceAccount
    name: prometheus
    namespace: monitoring
```

If you use the Prometheus Operator, create a ServiceMonitor that authenticates with the token of the Prometheus service account. Metrics Server serves a self-signed certificate.

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  endpoints:
    - port: https
      scheme: https
      bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
      tlsConfig:
        insecureSkipVerify: true
```

Metrics Server is meant only for autoscaling. To monitor the resource usage of the workloads, collect the metrics from the Kubelets directly (`/metrics/resource` and `/metrics/cadvisor`). See [use cases](https://github.com/kubernetes-sigs/metrics-server#use-cases).
