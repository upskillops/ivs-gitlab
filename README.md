# GitLab on Kubernetes (chart 10.5.0 / GitLab 19.5.0)

| Path | Purpose |
|---|---|
| `gitlab/` | Upstream GitLab Helm chart 10.5.0, pulled with `helm pull gitlab/gitlab --untar` |
| `gitlab-deps/` | Small chart with PostgreSQL 17, Valkey 8 (Redis) and MinIO (S3). Chart 10.x no longer bundles them. |
| `values.yaml` | Shared GitLab values for every cloud: external DB/Redis/S3, registry, Envoy Gateway, cert-manager |
| `values-eks.yaml` | EKS: AWS NLB annotations (gp3 is the default in `values.yaml`) |
| `values-oci.yaml` | OCI OKE: public OCI load balancer on a reserved IP, `oci-bv-pv` storage, small sizing |
| `values-local.yaml` | Local kubeadm cluster: Longhorn, Istio ingress, single replicas |
| `gitlab-deps/values-<cloud>.yaml` | Storage class and disk sizes for the dependencies |
| `oci/storageclass.yaml` | `oci-bv-pv` StorageClass (paravirtualized, required with in-transit encryption); applied by `deploy.sh oci` |
| `local/istio-routing.yaml` | Istio Gateway and VirtualServices for the local cluster |
| `deploy.sh` | `./deploy.sh eks`, `./deploy.sh oci` or `./deploy.sh local` |

Everything goes into the `gitlab-ivs` namespace (override with `NAMESPACE=...`).

## EKS

Prerequisites:
- a `gp3` StorageClass (EBS CSI driver)
- the AWS Load Balancer Controller (provisions the NLB for Envoy Gateway)

1. In `values.yaml`, set `global.hosts.domain` and `certmanager-issuer.email`.
   If cert-manager is already installed, also set `installCertmanager: false`.
2. Run `./deploy.sh eks` (uses `values.yaml` + `values-eks.yaml`).
3. Point DNS for `gitlab.<domain>`, `registry.<domain>` and `kas.<domain>` at the NLB:
   `kubectl get svc -n gitlab-ivs | grep envoy`

Graviton (arm64) nodes work as-is: the GitLab CNG, postgres, valkey and minio images are multi-arch.

### Production: RDS, ElastiCache and S3

Skip `gitlab-deps`, then:
- Set `global.psql.host` and `global.redis.host` to your endpoints, and create the
  `gitlab-postgresql-password` and `gitlab-redis-password` secrets.
- Create the `gitlab-object-storage` secret (key `connection`):
  ```yaml
  provider: AWS
  region: us-east-1
  use_iam_profile: true   # IRSA / instance role
  ```
- Create the `gitlab-registry-storage` secret (key `config`):
  ```yaml
  s3_v2:
    bucket: <registry-bucket>
    region: us-east-1
  ```
- Bucket names must be globally unique on S3, so rename the buckets under `global.appConfig`.

## OCI (OKE)

Infrastructure comes from the `oke-private` Terraform (`envs/uat.tfvars`): it creates the public LB subnet,
the `lb_public` NSG (22/80/443) and a reserved public IP named `gitlab`. Put those three values from
`terraform output` into `values-oci.yaml`, then:

```bash
export KUBECONFIG=~/.kube/oke-uat.config      # via the jump host SOCKS tunnel, or run on the jump host
./deploy.sh oci
```

The hostnames use nip.io on the reserved IP (`gitlab.<ip>.nip.io`), so no DNS records are needed.
For a real domain, change `global.hosts.domain` and point `gitlab`, `registry` and `kas` at the IP.

## Local cluster (upskillops)

```bash
./deploy.sh local
```

- URL: https://gitlab-ivs.upskillops.in. TLS is terminated at the Istio ingress gateway with the wildcard cert.
  There is no public DNS record yet. Either add one (like `gitlab.upskillops.in`), or add this line to `/etc/hosts`:
  `192.168.0.140 gitlab-ivs.upskillops.in registry-ivs.upskillops.in`
- Git over SSH is not exposed (the Istio gateway only serves 80/443), so clone over HTTPS.
- KAS and gitlab-exporter are disabled to save resources.

## Login

User `root`. Get the password with:

```bash
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab-ivs -o jsonpath='{.data.password}' | base64 -d; echo
```

## Notes

- With Helm 4, `deploy.sh` uses `--wait=legacy`. Helm 4's default hook watcher hung on GitLab's shared-secrets hook Job.
- The `gitlab-deps` secrets use `helm.sh/resource-policy: keep` and are reused on upgrade.
  The `longhorn-gitlab` StorageClass has `Retain`, so PVs are left behind after an uninstall.

## Uninstall

```bash
helm uninstall gitlab -n gitlab-ivs
helm uninstall gitlab-deps -n gitlab-ivs
kubectl delete -f local/istio-routing.yaml
kubectl delete namespace gitlab-ivs   # also deletes the PVCs; Retain PVs must be removed by hand
```
