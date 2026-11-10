load("@ytt:data", "data")
load("@ytt:struct", "struct")

# The namespace of the upstream manifest, replaced by the package namespace.
upstream_namespace = "kube-system"

# The name of the Deployment, ServiceAccount, and Service of Metrics Server, and of its container.
name = "metrics-server"

# The labels selecting the Metrics Server Pods, as in the upstream Deployment.
selector = {"k8s-app": name}

# Where the certificate authority of the Kubelets is mounted (see overlays/kubelet-tls.yml).
kubelet_ca_dir = "/etc/ssl/kubelet"

# ###########
# FLAGS
# ###########

# The log levels of the package, aligned with the other Kadras packages, and their Kubernetes log verbosity.
# See: https://github.com/kubernetes/community/blob/master/contributors/devel/sig-instrumentation/logging.md
_log_verbosities = {"info": 0, "debug": 4, "trace": 6}

# The flags computed from the package values. `args` is merged on top of them.
def server_args():
  logging = data.values.observability.logging
  args = {
    "v": _log_verbosities[logging.level],
    "logging-format": logging.format,
  }

  if data.values.kubelet.insecure_tls:
    args["kubelet-insecure-tls"] = True
  end
  if data.values.kubelet.ca_cert_data:
    args["kubelet-certificate-authority"] = kubelet_ca_dir + "/ca.crt"
  end

  for name, value in struct.decode(data.values.args).items():
    args[name.lstrip("-")] = value
  end
  return args
end

def _format(value):
  if type(value) == "bool":
    return "true" if value else "false"
  end
  return str(value)
end

# Merges the given flags into the upstream ones, keeping their order. New flags are appended,
# and flags set to null are removed. Upstream flags without a value, like `--kubelet-use-node-status-port`, are kept as they are.
def _merge_args(upstream, overrides):
  flags = {}
  for arg in upstream:
    name, separator, value = arg.lstrip("-").partition("=")
    flags[name] = value if separator else None
  end
  for name, value in overrides.items():
    if value == None:
      flags.pop(name, None)
    else:
      flags[name] = _format(value)
    end
  end
  return ["--" + name if value == None else "--" + name + "=" + value for name, value in flags.items()]
end

# The `via` function of the overlay replacing the upstream container args.
def args_merger(overrides):
  return lambda left, _: _merge_args(left, overrides)
end

# The `via` function of the overlay replacing the upstream container port, so that it follows the `secure-port` flag.
def secure_port_merger(overrides):
  port = overrides.get("secure-port")
  return lambda left, _: int(port) if port != None else left
end
