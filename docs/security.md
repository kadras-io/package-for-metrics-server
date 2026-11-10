# Security

## Pod Security Standards

Metrics Server complies with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/): it runs as non-root, with a read-only root filesystem, no privilege escalation, no capabilities, and the `RuntimeDefault` seccomp profile. When the package creates its namespace, the standard is enforced on it. The `kube-system` namespace is left as it is, since it hosts other system components.

## Service account tokens

The service account token isn't auto-mounted. Metrics Server mounts a projected token instead, which expires after an hour and is rotated by the kubelet.

## Permissions

Metrics Server can read the nodes and the Pods, and their metrics from the Kubelets (`nodes/metrics`). It delegates the authentication and authorization of the requests to the Metrics API to the Kubernetes API server (`system:auth-delegator`), and reads the configuration of the API server authentication in `kube-system` (`extension-apiserver-authentication-reader`), wherever it's deployed.

The `system:aggregated-metrics-reader` ClusterRole aggregates the permission to read the Metrics API to the built-in `view`, `edit`, and `admin` ClusterRoles.

## TLS

Metrics Server verifies the Kubelet serving certificates with the cluster certificate authority, or a custom one. See [kubelet-tls.md](kubelet-tls.md).

The Kubernetes API server reaches Metrics Server via the APIService, without verifying its certificate (`insecureSkipTLSVerify`), since Metrics Server generates a self-signed one at startup, as upstream. To verify it, issue a certificate for the `metrics-server.<namespace>.svc` name, for example with [cert-manager](https://cert-manager.io), mount it in Metrics Server via the `tls-cert-file` and `tls-private-key-file` flags, and set its certificate authority in the APIService `caBundle`, with a ytt overlay (see [configuration.md](configuration.md#ytt-overlays)). The package keeps the `caBundle` set on the cluster, for example by the cert-manager CA injector.

```yaml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "APIService"})
---
metadata:
  #@overlay/match missing_ok=True
  annotations:
    #@overlay/match missing_ok=True
    cert-manager.io/inject-ca-from: kube-system/metrics-server
spec:
  insecureSkipTLSVerify: false
```

## Network traffic

Metrics Server needs the following traffic. Allow it if the cluster restricts the network traffic:

* from the Kubernetes API server to Metrics Server, on its secure port (10250);
* from Metrics Server to the Kubelets of all the nodes, on their port (usually 10250);
* from Metrics Server to the Kubernetes API server.

## Kyverno policies

The package can include a Kyverno policy verifying that the Metrics Server image is signed by the Kubernetes image promoter, with [Cosign keyless signatures](https://kubernetes.io/docs/tasks/administer-cluster/verify-signed-artifacts/) recorded in the Rekor transparency log. It requires Kyverno 1.19 or later, and access to the Rekor and Sigstore services. The policy is created before Metrics Server, so that it applies to its Pods.

```yaml
policies:
  enabled: true
```
