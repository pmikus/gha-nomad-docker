locals {
  datacenters = join(",", var.datacenters)
}

resource "nomad_job" "gha-dispatcher" {
  jobspec = templatefile(
    "${path.cwd}/nomad-${var.job_name}.hcl.tftpl",
    {
      cpu         = var.cpu,
      datacenters = local.datacenters,
      image       = var.image,
      job_name    = var.job_name,
      memory      = var.memory,
      namespace   = var.namespace,
      node_pool   = var.node_pool,
      region      = var.region,
      type        = var.type
  })
  detach = false
}
