locals {
  path = "/root/parent/child/lastNode"
}

output "fileName_from_path" {
  value = basename(local.path)
}

output "fileName_from_path_using_regex" {
  value = regex("([^/]+)$", local.path)[0]
}

output "fileName_from_path_using_regex2" {
  value = regex("[^/]+$", local.path)
}