output "all_vms_map" {
  value = local.all_vms_map
}

output "origin_groups" {
  value = local.origin_groups
}

# # "all_vms_map" output variable is creating a new map called "all_vms_map" for each VM in the "all_vms_map" local variable with aggregated attributes. The JvmMs and JvmMx attributes are being looked up from the "tomcat_svc_params_map" local variable using the server_class attribute as the key.
# output "all_vms_map" {
#   value = {
#     for k, v in local.all_vms_map : k => merge(
#       v,
#       {
#         JvmMs = local.tomcat_svc_params_map[v.server_class].JvmMs,
#         JvmMx = local.tomcat_svc_params_map[v.server_class].JvmMx
#       },
#     )
#   }
#   description = "Map of all VMs with attributes aggregated from local variables: all_vms_map and tomcat_svc_params_map"
# }