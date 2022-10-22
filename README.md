# Metrics Server

This project provides a [Carvel package](https://carvel.dev/kapp-controller/docs/latest/packaging) for [Metrics Server](https://github.com/kubernetes-sigs/metrics-server), a scalable and efficient source of container resource metrics for Kubernetes built-in autoscaling pipelines.

## Components

* Metrics Server

## Prerequisites

* Install the [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl) CLI to manage Carvel packages in a convenient way.
* Ensure [kapp-controller](https://carvel.dev/kapp-controller) is deployed in your Kubernetes cluster. You can do that with Carvel
[`kapp`](https://carvel.dev/kapp/docs/latest/install) (recommended choice) or `kubectl`.

```shell
kapp deploy -a kapp-controller -y \
  -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml
```

## Installation

You can install the Metrics Server package directly or rely on the [Kadras package repository](https://github.com/arktonix/carvel-packages)
(recommended choice).

Follow the [instructions](https://github.com/arktonix/carvel-packages) to add the Kadras package repository to your Kubernetes cluster.

If you don't want to use the Kadras package repository, you can create the necessary `PackageMetadata` and
`Package` resources for the Metrics Server package directly.

```shell
kubectl create namespace carvel-packages
kapp deploy -a metrics-server-package -n carvel-packages -y \
    -f https://github.com/arktonix/package-for-metrics-server/releases/latest/download/metadata.yml \
    -f https://github.com/arktonix/package-for-metrics-server/releases/latest/download/package.yml
```

Either way, you can then install the Metrics Server package using [`kctrl`](https://carvel.dev/kapp-controller/docs/latest/install/#installing-kapp-controller-cli-kctrl).

```shell
kctrl package install -i metrics-server \
    -p metrics-server.packages.kadras.io \
    -v 0.6.1 \
    -n carvel-packages
```

You can retrieve the list of available versions with the following command.

```shell
kctrl package available list -p metrics-server.packages.kadras.io
```

You can check the list of installed packages and their status as follows.

```shell
kctrl package installed list -n carvel-packages
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
    -v 0.6.1 \
    -n carvel-packages \
    --values-file values.yml
```

## Documentation

For documentation specific to Metrics Server, check out [https://github.com/kubernetes-sigs/metrics-server](https://github.com/kubernetes-sigs/metrics-server).

## References

This package is based on the original Metrics Server package used in [Tanzu Community Edition](https://github.com/vmware-tanzu/community-edition) before its retirement.

## Supply Chain Security

This project is compliant with level 2 of the [SLSA Framework](https://slsa.dev).

<img src="https://slsa.dev/images/SLSA-Badge-full-level2.svg" alt="The SLSA Level 2 badge" width=200>
