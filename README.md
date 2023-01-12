# Metrics Server

<a href="https://slsa.dev/spec/v0.1/levels"><img src="https://slsa.dev/images/gh-badge-level3.svg" alt="The SLSA Level 3 badge"></a>

This project provides a [Carvel package](https://carvel.dev/kapp-controller/docs/latest/packaging) for [Metrics Server](https://github.com/kubernetes-sigs/metrics-server), a scalable and efficient source of container resource metrics for Kubernetes built-in autoscaling pipelines.

## Prerequisites

* Kubernetes 1.24+
* Carvel [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) CLI.
* Carvel [kapp-controller](https://carvel.dev/kapp-controller) deployed in your Kubernetes cluster. You can install it with Carvel [`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

  ```shell
  kapp deploy -a kapp-controller -y \
    -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml
  ```

## Installation

First, add the [Kadras package repository](https://github.com/kadras-io/kadras-packages) to your Kubernetes cluster.

  ```shell
  kubectl create namespace kadras-packages
  kctrl package repository add -r kadras-repo \
    --url ghcr.io/kadras-io/kadras-packages \
    -n kadras-packages
  ```

Then, install the Metrics Server package.

  ```shell
  kctrl package install -i metrics-server \
    -p metrics-server.packages.kadras.io \
    -v 0.6.2+kadras.1 \
    -n kadras-packages
  ```

### Verification

You can verify the list of installed Carvel packages and their status.

  ```shell
  kctrl package installed list -n kadras-packages
  ```

### Version

You can get the list of Metrics Server versions available in the Kadras package repository.

  ```shell
  kctrl package available list -p metrics-server.packages.kadras.io -n kadras-packages
  ```

## Configuration

The Metrics Server package has the following configurable properties.

| Value | Required/Optional | Description |
|-------|-------------------|-------------|
| `metricsServer.createNamespace` | Optional | Whether to create namespace specified for metrics-server. Default value is `true`. |
| `metricsServer.namespace` | Optional | The namespace value used by older templates, will be overwriten if top level namespace is present, kept for backward compatibility. Default value is `null`. |
| `metricsServer.config.securePort` | Optional | TThe HTTPS secure port used by metrics-server. Default: `4443`. |
| `metricsServer.config.updateStrategy` | Optional | TThe update strategy of the metrics-server deployment. Default: `RollingUpdate` |
| `metricsServer.config.probe.failureThreshold` | Optional | Probe failureThreshold of metrics-server deployment. Default: `3`. |
| `metricsServer.config.probe.periodSeconds` | Optional | Probe period of metrics-server deployment. Default: `10` . |
| `metricsServer.config.apiServiceInsecureTLS`| Optional | Whether to enable insecure TLS for metrics-server api service. Default: `True`. |

You can define your configuration in a `values.yml` file.

  ```yaml
  metricsServer:
    config:
      securePort: 4443
  ```

Then, reference it from the `kctrl` command when installing or upgrading the package.

  ```shell
  kctrl package install -i metrics-server \
    -p metrics-server.packages.kadras.io \
    -v 0.6.2+kadras.1 \
    -n kadras-packages \
    --values-file values.yml
  ```

## Upgrading

You can upgrade an existing package to a newer version using `kctrl`.

  ```shell
  kctrl package installed update -i metrics-server \
    -v <new-version> \
    -n kadras-packages
  ```

You can also update an existing package with a newer `values.yml` file.

  ```shell
  kctrl package installed update -i metrics-server \
    -n kadras-packages \
    --values-file values.yml
  ```

## Other

The recommended way of installing the Metrics Server package is via the [Kadras package repository](https://github.com/kadras-io/kadras-packages). If you prefer not using the repository, you can install the package by creating the necessary Carvel `PackageMetadata` and `Package` resources directly using [`kapp`](https://carvel.dev/kapp/docs/latest/install) or `kubectl`.

  ```shell
  kubectl create namespace kadras-packages
  kapp deploy -a metrics-server-package -n kadras-packages -y \
    -f https://github.com/kadras-io/package-for-metrics-server/releases/latest/download/metadata.yml \
    -f https://github.com/kadras-io/package-for-metrics-server/releases/latest/download/package.yml
  ```

## Support and Documentation

For support and documentation specific to Metrics Server, check out [https://github.com/kubernetes-sigs/metrics-server](https://github.com/kubernetes-sigs/metrics-server).

## References

This package is based on the original Metrics Server package used in [Tanzu Community Edition](https://github.com/vmware-tanzu/community-edition) before its retirement.

## Supply Chain Security

This project is compliant with level 3 of the [SLSA Framework](https://slsa.dev).

<img src="https://slsa.dev/images/SLSA-Badge-full-level3.svg" alt="The SLSA Level 3 badge" width=200>
