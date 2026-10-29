# koldun-gitops

Fleet GitOps repository for the koldun platform on the RKE2 test cluster (`c-m-jwxnbl2r`).

## Layers

Each directory is one Fleet bundle. Bundle names follow the Fleet convention
`<gitrepo>-<path>`, for example `koldun-gitops-ceph-cluster`.

| Layer | Purpose | Depends on |
|---|---|---|
| `sealed-secrets/` | sealed-secrets controller, decrypts committed ciphertext | — |
| `gateway-api/` | enables the Gateway provider on the RKE2 Traefik addon | — |
| `longhorn/` | local block storage, 1 replica, strict-local | — |
| `rook-ceph/` | Rook Ceph operator | — |
| `ceph-cluster/` | Ceph cluster, erasure-coded pools, `ceph-ec-rbd` StorageClass | `longhorn`, `rook-ceph` |
| `ceph-csi-s3/` | object store and bucket claims | `ceph-cluster` |
| `koldun/` | koldun operator chart | `ceph-csi-s3`, `gateway-api` |

## Rules

1. **Every change goes through a pull request.** Direct pushes to `main` are rejected. A change is merged only after the owner approves it.
2. **English only.** Branches, commits, pull request titles and bodies, code, manifests and documentation are written in English.
3. **Versions are pinned.** Every Helm layer sets `helm.version`. Floating versions and `latest` are not allowed.
4. **No plaintext secrets.** Only sealed-secrets ciphertext is committed. Default passwords such as `passw0rd`, `admin` or `changeme` are forbidden.
5. **Do not touch `kube-system` or `cattle-*`**, with one exception: `HelmChartConfig/rke2-traefik` that enables the Gateway provider.

## Verification

Validation scripts live in `scripts/` and write evidence to `artifacts/`.
Each layer has a check that proves the layer works, not just that it was applied.
