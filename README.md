# Metrics Server

![Test Workflow](https://github.com/kadras-io/package-for-metrics-server/actions/workflows/test.yml/badge.svg)
![Release Workflow](https://github.com/kadras-io/package-for-metrics-server/actions/workflows/release.yml/badge.svg)
[![The SLSA Level 3 badge](https://slsa.dev/images/gh-badge-level3.svg)](https://slsa.dev/spec/v1.0/levels)
[![The Apache 2.0 license badge](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Follow us on Bluesky](https://img.shields.io/static/v1?label=Bluesky&message=Follow&color=1DA1F2)](https://bsky.app/profile/kadras.bsky.social)

A Carvel package for [Metrics Server](https://github.com/kubernetes-sigs/metrics-server), a scalable and efficient source of container resource metrics for Kubernetes built-in autoscaling pipelines. It collects CPU and memory usage from the Kubelets, and serves them via the Metrics API to the Horizontal and Vertical Pod Autoscalers and to `kubectl top`.

## ✨&nbsp; What's Included

* **Metrics API**. Metrics Server, registered in the Kubernetes API as `metrics.k8s.io`, configurable via its flags. It verifies the Kubelet serving certificates with the cluster certificate authority, or a custom one.
* **High availability**. Optionally, multiple replicas spread across nodes and protected by a PodDisruptionBudget.
* **Observability**. Structured logs with configurable level.
* **Security**. Metrics Server complies with the `restricted` [Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/), enforced on its namespace when created by the package, and mounts the service account token only where needed. Optionally, Kyverno verifies the signature of the Metrics Server image.

## 🚀&nbsp; Getting Started

### Prerequisites

* Kubernetes 1.35+, with the [aggregation layer](https://kubernetes.io/docs/tasks/extend-kubernetes/configure-aggregation-layer/) enabled and the Kubelet [webhook authentication and authorization](https://kubernetes.io/docs/reference/access-authn-authz/kubelet-authn-authz/) enabled. See the upstream [requirements](https://github.com/kubernetes-sigs/metrics-server#requirements).
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) CLI.
* Carvel [kapp-controller](https://carvel.dev/kapp-controller) deployed in your Kubernetes cluster. You can install it with Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

```shell
kapp deploy -a kapp-controller -y \
  -f https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yml
```

### Dependencies

Metrics Server has no required dependencies. To authenticate with private registries, install [secretgen-controller](https://github.com/kadras-io/package-for-secretgen-controller) from the [Kadras package repository](https://github.com/kadras-io/kadras-packages). To verify the Metrics Server image, install [Kyverno](https://github.com/kadras-io/package-for-kyverno) 1.19 or later.

### Installation

Add the Kadras [package repository](https://github.com/kadras-io/kadras-packages) to your Kubernetes cluster:

```shell
kctrl package repository add -r kadras-packages \
  --url ghcr.io/kadras-io/kadras-packages \
  -n kadras-system --create-namespace
```

<details><summary>Installation without package repository</summary>
The recommended way of installing the Metrics Server package is via the Kadras <a href="https://github.com/kadras-io/kadras-packages">package repository</a>. If you prefer not using the repository, you can add the package definition directly using <a href="https://carvel.dev/kapp/docs/latest/install"><code>kapp</code></a> or <code>kubectl</code>.

```shell
kubectl create namespace kadras-system
kapp deploy -a metrics-server-package -n kadras-system -y \
  -f https://github.com/kadras-io/package-for-metrics-server/releases/latest/download/metadata.yml \
  -f https://github.com/kadras-io/package-for-metrics-server/releases/latest/download/package.yml
```
</details>

Install the Metrics Server package:

```shell
kctrl package install -i metrics-server \
  -p metrics-server.packages.kadras.io \
  -v ${VERSION} \
  -n kadras-system
```

> **Note**
> You can find the `${VERSION}` value by retrieving the list of package versions available in the Kadras package repository installed on your cluster.
> 
> ```shell
> kctrl package available list -p metrics-server.packages.kadras.io -n kadras-system
> ```

> **Note**
> On clusters where the Kubelets have self-signed serving certificates, like kind and the default kubeadm setup, Metrics Server can't verify them. Set `kubelet.insecure_tls: true`, or have the Kubelet certificates signed by the cluster certificate authority. See [kubelet-tls.md](docs/kubelet-tls.md).

Verify the installed packages and their status:

```shell
kctrl package installed list -n kadras-system
```

### Try It Out

After the first scrapes of the Kubelets, check the resource usage of the nodes and Pods:

```shell
kubectl top nodes
kubectl top pods -A
```

## 📙&nbsp; Documentation

Documentation, tutorials and examples for this package are available in the [docs](docs) folder.
For documentation specific to Metrics Server, check out [github.com/kubernetes-sigs/metrics-server](https://github.com/kubernetes-sigs/metrics-server).

Features:

* [High availability](docs/high-availability.md)
* [Observability](docs/observability.md)
* [Security](docs/security.md)

Operations:

* [Configuration and ytt overlays](docs/configuration.md)
* [Kubelet TLS](docs/kubelet-tls.md)
* [Upgrading and uninstalling](docs/upgrade.md)
* [Verifying the release](docs/verify-release.md)

## 🎯&nbsp; Configuration

The Metrics Server package can be customized via a `values.yml` file.

```yaml
replicas: 2
args:
  metric-resolution: 30s
kubelet:
  insecure_tls: true
```

Reference the `values.yml` file from the `kctrl` command when installing or upgrading the package.

```shell
kctrl package install -i metrics-server \
  -p metrics-server.packages.kadras.io \
  -v ${VERSION} \
  -n kadras-system \
  --values-file values.yml
```

The flags of Metrics Server can be customized beyond the values, as well as any resource via ytt overlays. See [configuration.md](docs/configuration.md).

### Values

The Metrics Server package has the following configurable properties.

<details><summary>Configurable properties</summary>

<!-- values-table:start -->

| Config | Default | Description |
|--------|---------|-------------|
| `namespace` | `"kube-system"` | The namespace in which to deploy Metrics Server. It's created by the package, unless it's `kube-system`. |
| `replicas` | `1` | The number of Metrics Server replicas. With more than one, each replica runs on a different node, and a PodDisruptionBudget keeps at least one available. |
| `args` | `{}` | Container flags, merged on top of the ones computed by the package. Set a flag to null to remove it. See https://github.com/kubernetes-sigs/metrics-server/blob/master/docs/command-line-flags.txt. |
| `kubelet.insecure_tls` | `false` | Whether to skip the verification of the Kubelet serving certificates. Only for clusters where they are self-signed, like kind and the default kubeadm setup. |
| `kubelet.ca_cert_data` | `""` | PEM-encoded certificates of the certificate authority that signed the Kubelet serving certificates, when it's not the cluster one. |
| `observability.logging.level` | `"info"` | The log level: `info` for the essential messages, `debug` and `trace` for increasingly detailed ones. For a specific verbosity, set the `v` flag via `args`. |
| `observability.logging.format` | `"json"` | The format of the logs. |
| `policies.enabled` | `false` | Whether to include the Kyverno policies that validate and secure the package installation. They require Kyverno 1.19 or later. |

<!-- values-table:end -->

</details>

## 🛠️&nbsp; Development

The development environment is defined with [devenv](https://devenv.sh). Enter it with `devenv shell`, or automatically with [direnv](https://direnv.net) after running `direnv allow`. Run `task --list` to see all the available tasks.

```shell
# Run the unit tests, which render the package and check the result without a cluster.
task test:config

# Create a local kind cluster and run the integration tests on it.
task cluster:setup
task test:integration

# Deploy the package from the local sources to the current cluster.
task dev

# Update the table of configurable values in this README after changing the values schema.
task docs:values
```

The unit tests are described in [test/unit/README.md](test/unit/README.md).

## 🛡️&nbsp; Security

The security process for reporting vulnerabilities is described in [SECURITY.md](SECURITY.md).

## 🖊️&nbsp; License

This project is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE) for more information.
