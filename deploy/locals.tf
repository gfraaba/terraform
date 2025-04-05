locals {
  script_mode = "INITIALIZE-VM"
  all_vms_map = data.terraform_remote_state.state.outputs.all_vms_map
  deploy_config_by_vm_class = {
    U = {
      certificates = {
        "cert1.pfx" = "kv_cert1_secret_name",
        "cert2.pfx" = "kv_cert2_secret_name",
        "test.cer" = ""
      },
      files = []
    },
    T = {
      certificates = {
        "cert3.pfx" = "kv_cert1_secret_name",
        "cert4.pfx" = "kv_cert2_secret_name"
      },
      files = []
    }
  }
  cert_pwds = tomap({
    "cert1.pfx" = "cert1_password",
    "cert2.pfx" = "cert2_password",
    "cert3.pfx" = "cert3_password",
    "cert4.pfx" = "cert4_password"
    }
  )

  # Certificates mapped to their respective passwords
  deploy_config_by_vm_class_final = tomap({
    for server_class, config in local.deploy_config_by_vm_class : server_class => {
      certificates = tomap({ for cert_name, secret_name in config.certificates : cert_name => local.cert_pwds[cert_name] }),
      files        = config.files
    }
  })

  # List of all certificate files and misc files with fully resloved paths
  all_cert_misc_files = toset(flatten([
    for server_class, config in local.deploy_config_by_vm_class : [
      concat(
        [for cert_name, secret_name in config.certificates : "${path.module}/../certs/${cert_name}"],
      [for file in config.files : "${path.module}/upload/misc/${file}"])
    ]
  ]))

  # Try this in 'terraform console': filemd5(flatten(fileset("${path.module}", "../upload/*"))[0])
  all_files_to_upload = toset(
    concat(
      [for script_file in fileset("${path.module}/upload/scripts", "*") : "${path.module}/upload/scripts/${script_file}"],
      (local.script_mode == "INITIALIZE-VM") ? flatten(local.all_cert_misc_files)
      : []
    )
  )

  uploaded_file_names = flatten(
    [for file in local.all_files_to_upload : split("/", file)[length(split("/", file)) - 1]]
  )

  # Output variable: merge all_vms_map with deploy_config_by_vm_class 
  all_vms_map_for_output = tomap({
    for vm_name, vm_settings in local.all_vms_map : vm_name => merge(vm_settings, local.deploy_config_by_vm_class[vm_settings.server_class])
  })

  # Update the all_vms_map with the deploy_config_by_vm_class_final
  all_vms_map_final = tomap({
    for vm_name, vm_settings in local.all_vms_map : vm_name => merge(vm_settings, local.deploy_config_by_vm_class_final[vm_settings.server_class])
  })
}