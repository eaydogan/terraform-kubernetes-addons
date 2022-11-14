locals {

  cockroachdb = merge(
    {
      enabled = false
      version = "v2.8.0"
    },
    var.cockroachdb
  )

}


resource "kubectl_manifest" "cockroachdb_deployment" {
  count   = local.cockroachdb.enabled ? 1 : 0
  yaml_body = <<-YAML
  apiVersion: crdb.cockroachlabs.com/v1alpha1
  kind: CrdbCluster
  metadata:
    # this translates to the name of the statefulset that is created
    name: cockroachdb
  spec:
    clientTLSSecret: cockroachdb.client.root
    nodeTLSSecret: cockroachdb.node  
    dataStore:
      pvc:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: "60Gi"
          volumeMode: Filesystem
    resources:
      requests:
        # This is intentionally low to make it work on local k3d clusters.
        cpu: 500m
        memory: 2Gi
      limits:
        cpu: 2
        memory: 8Gi
    tlsEnabled: true
  # You can set either a version of the db or a specific image name
  # cockroachDBVersion: v22.1.2
    image:
      name: cockroachdb/cockroach:v22.1.2
    # nodes refers to the number of crdb pods that are created
    # via the statefulset
    nodes: 3
    additionalLabels:
      crdb: is-cool
    # affinity is a new API field that is behind a feature gate that is
    # disabled by default.  To enable please see the operator.yaml file.
  
    # The affinity field will accept any podSpec affinity rule.
    # affinity:
    #   podAntiAffinity:
    #      preferredDuringSchedulingIgnoredDuringExecution:
    #      - weight: 100
    #        podAffinityTerm:
    #          labelSelector:
    #            matchExpressions:
    #            - key: app.kubernetes.io/instance
    #              operator: In
    #              values:
    #              - cockroachdb
    #          topologyKey: kubernetes.io/hostname
  
    # nodeSelectors used to match against
    # nodeSelector:
    #   worker-pool-name: crdb-workers
  YAML

  depends_on = [
    kubectl_manifest.cockroach-operator
  ]
}


