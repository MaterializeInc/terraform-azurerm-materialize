output "load_balancer_details" {
  description = "Details of the Materialize instance load balancers."
  value = {
    for load_balancer in module.load_balancers : load_balancer.instance_name => {
      console_load_balancer_ip   = load_balancer.console_load_balancer_ip
      balancerd_load_balancer_ip = load_balancer.balancerd_load_balancer_ip
    }
  }
}

output "operator" {
  description = "Materialize operator details"
  value = var.install_materialize_operator ? {
    release_name          = module.operator[0].operator_release_name
    release_status        = module.operator[0].operator_release_status
    instances             = module.operator[0].materialize_instances
    instance_resource_ids = module.operator[0].materialize_instance_resource_ids
  } : null
}
