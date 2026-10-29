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
