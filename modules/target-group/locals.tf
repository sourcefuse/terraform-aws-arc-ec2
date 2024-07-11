locals {
  listerner_list = flatten([
    for key, value in var.target_groups : [
      for listener in value.listeners : merge(
        listener,
        {
          key       = "${key}-${listener.default_action.type}"
          group_key = key
        }
      )
    ]
  ])

  listerner_map = { for key, value in local.listerner_list : value.key => value }

}
