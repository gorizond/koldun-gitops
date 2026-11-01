# koldun-gitops

Fleet GitOps for the koldun platform.

`longhorn/` — Longhorn 1.13.0: one replica, strict-local data, retention on delete.

`rook-ceph/` — Rook Ceph operator 1.21.1. The Ceph cluster and pools come next.

`ceph-cluster/` — Ceph cluster: four OSDs on Longhorn PVCs, erasure coded `ceph-ec-rbd`, dashboard over HTTP.

`ceph-s3/` — Ceph object store (RGW), the bucket class and the koldun bucket claim.

`csi-s3/` — S3 CSI driver (GeeseFS) exposing buckets as the `csi-s3` volume class. Mount options include
`--no-systemd`: the driver's systemd path runs GeeseFS on the host, where cluster DNS names do not resolve.
Model CRs must pass the same flag in `spec.pv.csiOptions`.

`nats/` — NATS 1.2.8, single node with JetStream on a 10Gi PVC, holding the KV buckets of the
koldun conversation reconciler; consumers use `nats://nats.nats.svc:4222`.

Rules: pull request only, owner approval before merge, English only, pinned Helm versions, no plaintext secrets.

## Layer structure

Fleet applies each top-level directory as one bundle, chained with `dependsOn`:

`longhorn` → `rook-ceph` → `ceph-cluster` → `ceph-s3` → `csi-s3`

The S3 stack deviates from the single `ceph-csi-s3/` directory in the original plan:

- `ceph-s3/` carries only raw manifests — `CephObjectStore`, the bucket storage class, the
  `ObjectBucketClaim` and the credential sync Job — and has no Helm release.
- `csi-s3/` carries the S3 CSI driver Helm chart, pinned on its own, and depends on `ceph-s3`.

The split keeps raw manifests and the Helm chart in separate bundles so each is versioned
independently: the driver chart moves at a different cadence than Rook and its CRs.

`nats/` is an additional layer beyond the plan: NATS JetStream (chart 1.2.8) hosts the `conversations`
KV bucket required by the operator and the dispatcher. It has no dependency on the storage layers.
