# Configuration

The package values cover the decisions most installations need to make: namespace, replicas, Kubelet TLS, and logs. Everything else can still be customized in two ways.

## Container flags

Metrics Server is configured via container flags. The package computes some of them from the values (log level and format, Kubelet TLS) and merges them into the upstream ones, then merges `args` on top, so its flags take precedence. The flags are written without the leading dashes, and a flag set to `null` is removed.

```yaml
args:
  metric-resolution: 30s
  kubelet-preferred-address-types: Hostname,InternalIP
```

The upstream flags are `--cert-dir=/tmp`, `--secure-port=10250`, `--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname`, `--kubelet-use-node-status-port`, and `--metric-resolution=15s`. An unknown flag prevents Metrics Server from starting. Check the [reference](https://github.com/kubernetes-sigs/metrics-server/blob/master/docs/command-line-flags.txt) of the Metrics Server version you install before adding one. A change rolls out Metrics Server.

### Metric resolution

Metrics Server scrapes the Kubelets every 15 seconds, and the autoscalers react to the latest scrape. On large clusters, a longer interval reduces the load on the Kubelets and on Metrics Server, at the cost of slower autoscaling. It must be at least 10 seconds.

```yaml
args:
  metric-resolution: 30s
```

### Kubelet addresses

Metrics Server reaches each Kubelet via the first node address of the types in `kubelet-preferred-address-types`, on the port published in the node status (`kubelet-use-node-status-port`). If the Kubelet serving certificates are issued for the node hostnames, prefer them, so that the certificates can be verified (see [kubelet-tls.md](kubelet-tls.md)).

```yaml
args:
  kubelet-preferred-address-types: Hostname,InternalDNS,InternalIP
```

To collect the metrics from a subset of the nodes only, select them by label.

```yaml
args:
  node-selector: node-role.kubernetes.io/worker=true
```

### Secure port

Metrics Server serves the Metrics API on port 10250. To change it, for example when running on the host network, set the `secure-port` flag: the container port follows it.

```yaml
args:
  secure-port: 4443
```

### TLS

The minimum TLS version and the cipher suites of the Metrics API can be restricted.

```yaml
args:
  tls-min-version: VersionTLS13
```

## ytt overlays

Any Kubernetes resource of the package can be customized with a [ytt overlay](https://carvel.dev/ytt/docs/latest/ytt-overlays/). Store it in a Secret and reference it from the PackageInstall via the `ext.packaging.carvel.dev/ytt-paths-from-secret-name.0` annotation.

```shell
kubectl create secret generic metrics-server-overlays -n kadras-system --from-file=overlays.yml
kubectl annotate packageinstall metrics-server -n kadras-system \
  ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=metrics-server-overlays
```

Metrics Server runs in a container named `metrics-server`, in the `metrics-server` Deployment.

### Resources

The upstream manifest requests 100m of CPU and 200Mi of memory, enough for clusters up to 100 nodes and 70 Pods per node. For larger clusters, add 1m of CPU and 2Mi of memory per node. See [scaling](https://github.com/kubernetes-sigs/metrics-server#scaling).

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "metrics-server"}})
---
spec:
  template:
    spec:
      containers:
        #@overlay/match by="name"
        - name: metrics-server
          resources:
            requests:
              cpu: 500m
              memory: 1Gi
            #@overlay/match missing_ok=True
            limits:
              memory: 1Gi
```

### Node placement

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "metrics-server"}})
---
spec:
  template:
    spec:
      nodeSelector:
        #@overlay/match missing_ok=True
        node-restriction.kubernetes.io/reserved-for: platform
      #@overlay/match missing_ok=True
      tolerations:
        - key: node-restriction.kubernetes.io/reserved-for
          operator: Equal
          value: platform
          effect: NoExecute
```

### Host network

On clusters where the control plane can't reach the Pod network, like some managed clusters with a custom network plugin, run Metrics Server on the host network, on a port that's free on the nodes and isn't the Kubelet one.

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": {"name": "metrics-server"}})
---
spec:
  template:
    spec:
      #@overlay/match missing_ok=True
      hostNetwork: true
```

```yaml
args:
  secure-port: 4443
```

The host network isn't allowed by the `restricted` Pod Security Standard, so it requires the `kube-system` namespace or a namespace with a less strict standard.
