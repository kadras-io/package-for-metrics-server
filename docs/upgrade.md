# Upgrading

Upgrade Metrics Server after reading the [release notes](https://github.com/kubernetes-sigs/metrics-server/releases) of the new version, and check its [compatibility matrix](https://github.com/kubernetes-sigs/metrics-server#compatibility-matrix) with your Kubernetes version.

```shell
kctrl package installed update -i metrics-server -v ${VERSION} -n kadras-system
```

With a single replica, the Metrics API is briefly unavailable while the new replica starts. With more replicas, it stays available (see [high-availability.md](high-availability.md)).

## Uninstalling

```shell
kctrl package installed delete -i metrics-server -n kadras-system
```

The APIService is deleted first, so that the Kubernetes API stops serving the Metrics API before Metrics Server stops. The namespace is deleted too, unless it's `kube-system`. The autoscalers stop scaling the workloads based on resource metrics until Metrics Server is installed again.
