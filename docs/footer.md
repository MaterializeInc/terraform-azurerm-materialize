## Accessing the AKS cluster

The AKS cluster can be accessed using the `kubectl` command-line tool. To authenticate with the cluster, run the following command:

```sh
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -json aks_cluster | jq -r '.name')
```

This command retrieves the AKS cluster credentials and merges them into the `~/.kube/config` file. You can now interact with the AKS cluster using `kubectl`.

## Connecting to Materialize instances

By default, two `LoadBalancer` `Services` are created for each Materialize instance:
1. One for balancerd, listening on:
    1. Port 6875 for SQL connections to the database.
    1. Port 6876 for HTTP(S) connections to the database.
1. One for the web console, listening on:
    1. Port 8080 for HTTP(S) connections.

The IP addresses of these load balancers will be in the `terraform output` as `load_balancer_details`.

#### TLS support

TLS support is provided by using `cert-manager` and a self-signed `ClusterIssuer`.

More advanced TLS support using user-provided CAs or per-Materialize `Issuer`s are out of scope for this Terraform module. Please refer to the [cert-manager documentation](https://cert-manager.io/docs/configuration/) for detailed guidance on more advanced usage.

## Upgrade Notes

#### v0.7.0

This is an intermediate version to handle some changes that must be applied in stages.
It is recommended to upgrade to v0.8.x after upgrading to this version.

Breaking changes:
* Swap is enabled by default.
* Support for lgalloc, our legacy spill to disk mechanism, is deprecated, and will be removed in the next version.
* We now always use two node pools, one for system workloads and one for Materialize workloads.
    * Variables for configuring these node pools have been renamed, so they may be configured separately.

To avoid downtime when upgrading to future versions, you must perform a rollout at this version.
1. Ensure your `environmentd_version` is at least `v26.0.0`.
2. Update your `request_rollout` (and `force_rollout` if already at the correct `environmentd_version`).
3. Run `terraform apply`.

You must upgrade to at least v0.6.x before upgrading to v0.7.0 of this terraform code.

It is strongly recommended to have enabled swap on v0.6.x before upgrading to v0.7.0 or higher.

#### v0.6.1

We recommend upgrading to at least v0.5.10 before upgrading to v0.6.x of this terraform code.

To use swap:
1. Set `swap_enabled` to `true`.
2. Ensure your `environmentd_version` is at least `v26.0.0`.
3. Update your `request_rollout` (and `force_rollout` if already at the correct `environmentd_version`).
4. Run `terraform apply`.

This will create a new node group configured for swap, and migrate your clusterd pods there.

#### v0.6.0

This version is missing the updated helm chart.
Skip this version, go to v0.6.1.

#### v0.3.0

We now install `cert-manager` and configure a self-signed `ClusterIssuer` by default.

Due to limitations in Terraform, it cannot plan Kubernetes resources using CRDs that do not exist yet. We have worked around this for new users by only generating the certificate resources when creating Materialize instances that use them, which also cannot be created on the first run.

For existing users upgrading Materialize instances not previously configured for TLS:
1. Leave `install_cert_manager` at its default of `true`.
2. Set `use_self_signed_cluster_issuer` to `false`.
3. Run `terraform apply`. This will install cert-manager and its CRDs.
4. Set `use_self_signed_cluster_issuer` back to `true` (the default).
5. Update the `request_rollout` field of the Materialize instance.
6. Run `terraform apply`. This will generate the certificates and configure your Materialize instance to use them.
