# High Availability

By default, the package runs 1 replica of Metrics Server. While it's unavailable, for example during a node drain or an upgrade, the Metrics API is unavailable too: the autoscalers keep the current number of replicas and resources, and `kubectl top` fails.

To keep the Metrics API available, run more replicas.

```yaml
replicas: 2
```

With more than one replica, the package follows the upstream [high-availability](https://github.com/kubernetes-sigs/metrics-server#high-availability) setup:

* each replica runs on a different node, so the cluster needs at least as many schedulable nodes as replicas;
* the replicas are replaced one at a time during the upgrades;
* a PodDisruptionBudget keeps at least one replica available during the node drains.

All the replicas scrape all the Kubelets, and serve the same metrics. To load balance the requests among them, enable the `--enable-aggregator-routing=true` flag of the Kubernetes API server, where you can configure it.

## Priority

Metrics Server runs with the `system-cluster-critical` [priority class](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/), as upstream, since the autoscalers depend on it. When deployed to a namespace other than `kube-system`, the package creates the `critical-pods` ResourceQuota, which allows this priority class in that namespace, on clusters that only allow it in `kube-system` by default.

## Resources

Tune the resources with a ytt overlay, as described in [configuration.md](configuration.md#resources).
