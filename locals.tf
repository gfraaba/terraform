locals {

  custom_domain = "mycompany.com"
  origin_groups_basic = {
    app1 = {
      subdomain = "subdomain"
    }
  }
  origin_groups_ext = { 
    for k, v in local.origin_groups_basic : "${replace(format("%s.%s.%s", k, v.subdomain, local.custom_domain), ".", "_")}" => merge(v, { domain = local.custom_domain })
    # for k, v in local.origin_groups_basic : "${k}.${v.subdomain}" => merge(v, { domain = local.custom_domain })
  }
  origin_groups = merge({
      for k, v in local.origin_groups_ext : "${k}-east" => v
    },
    {
      for k, v in local.origin_groups_ext : "${k}-west" => v
    }
  )

  vm_settings_common = {
    os_type                = "Windows",
    data_disk_size_gb      = 100,
    data_disk_drive_letter = "F",
    vm_name_prefix         = "vm",
  }

  vm_settings_by_server_class = {
    U = {
      vm_size  = "Standard_F2s_v2",
      vm_count = 2,
    },
    T = {
      vm_size  = "Standard_F8s_v2",
      vm_count = 2,
    }
  }

  tomcat_svc_params_map = {
    U = {
      "JvmMs" = 1024,
      "JvmMx" = 6144,
    },
    T = {
      "JvmMs" = 2048,
      "JvmMx" = 12288,
    },
  }

  all_vms_list = flatten([
    for server_class, settings in local.vm_settings_by_server_class : [
      for i in range(settings.vm_count) : {
        vm_name = "${local.vm_settings_common.vm_name_prefix}${format("%03d", (server_class == "U" ? i + 1 : i + 101))}"
        vm_settings = merge(
          { for k, v in local.vm_settings_common : k => v if k != "vm_name_prefix" },
          { for k, v in settings : k => v if k != "vm_count" },
          { for k, v in local.tomcat_svc_params_map[server_class] : k => v },
          { server_class = server_class }
        )
      }
    ]
  ])

  # TODO: Provide a detailed explanation (preferably a dedicated ReadMe.md file for documentation) of the idea/logic in designing these various local variables in a modular way and then computing unique VM names and then aggregating or merging the attributes spread across various local map variables using attributes of one map to look up values in another map. And also explain why we used the flatten function to convert a list of lists into a single list while computing unique VM names conditionally based on the server class and then eventually used the tomap function to convert a list of objects into a map of objects with the unique VM names as keys.

  all_vms_map = tomap({
    for vm in local.all_vms_list : vm.vm_name => merge(vm.vm_settings, { vm_name = vm.vm_name })
  })
}