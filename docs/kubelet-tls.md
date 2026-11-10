# Kubelet TLS

Metrics Server collects the metrics from the Kubelets over TLS, and verifies their serving certificates. If the verification fails, Metrics Server logs `x509` errors, and the Metrics API has no data for the affected nodes.

## Cluster certificate authority

By default, Metrics Server verifies the Kubelet serving certificates with the cluster certificate authority. It requires the Kubelets to request their serving certificates from the cluster, and someone to approve them. On kubeadm clusters, enable `serverTLSBootstrap` in the Kubelet configuration, and approve the certificate signing requests, manually or with a controller like [kubelet-csr-approver](https://github.com/postfinance/kubelet-csr-approver). See [certificate management with kubeadm](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/#kubelet-serving-certs).

```shell
kubectl get csr --field-selector=spec.signerName=kubernetes.io/kubelet-serving
kubectl certificate approve <csr-name>
```

The certificates are issued for the node hostnames and IP addresses. Make sure the address types in `kubelet-preferred-address-types` are included (see [configuration.md](configuration.md#kubelet-addresses)).

## Custom certificate authority

If the Kubelet serving certificates are signed by another certificate authority, add its PEM-encoded certificates to the package values.

```yaml
kubelet:
  ca_cert_data: |
    -----BEGIN CERTIFICATE-----
    MIICvjCCAaYCCQDhcJuwMw6yZzANBgkqhkiG9w0BAQsFADAhMQswCQYDVQQGEwJE
    ...
    -----END CERTIFICATE-----
```

The certificates are stored in the `metrics-server-kubelet-ca` Secret, mounted in Metrics Server, and referenced by the `--kubelet-certificate-authority` flag.

## Self-signed certificates

On clusters where the Kubelets have self-signed serving certificates, like kind and the default kubeadm setup, the verification can be skipped. The connection is still encrypted, but the identity of the Kubelets isn't verified. Use it only for development and testing.

```yaml
kubelet:
  insecure_tls: true
```
