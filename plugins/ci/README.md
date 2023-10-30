# Kubernetes `kubectl` Helper Plugin

Leverages a local `redis` application to quickly and easily set an alias `k` for `kubectl --context <some-context> --namespace <some-namespace>`.
Much like scwrypts environments, `k` aliases are *only* shared amongst session with the same `SCWRYPTS_ENV` to prevent accidental cross-contamination.


## Getting Started

Enable the plugin in `~/.config/scwrypts/config.zsh` by adding `SCWRYPTS_PLUGIN_ENABLED__KUBECTL=1`.
Use `k` as your new `kubectl` and checkout `k --help` and `k meta --help`.
