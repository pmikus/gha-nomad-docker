locals {
  datacenters = join(",", var.datacenters)
  envs        = join("\n", concat([], var.envs))
}

resource "nomad_job" "nomad_job" {
  jobspec = templatefile(
    "${path.cwd}/conf/nomad/${var.job_name}.hcl.tftpl",
    {
      cpu                       = var.cpu,
      datacenters               = local.datacenters,
      envs                      = local.envs,
      image                     = var.image,
      job_name                  = var.job_name,
      memory                    = var.memory,
      type                      = var.type,
      use_vault_provider        = var.vault_secret.use_vault_provider,
      vault_kv_policy_name      = var.vault_secret.vault_kv_policy_name,
      vault_kv_path             = var.vault_secret.vault_kv_path,
      vault_kv_field_access_key = var.vault_secret.vault_kv_field_access_key,
      vault_kv_field_secret_key = var.vault_secret.vault_kv_field_secret_key
  })
  detach = false
}
