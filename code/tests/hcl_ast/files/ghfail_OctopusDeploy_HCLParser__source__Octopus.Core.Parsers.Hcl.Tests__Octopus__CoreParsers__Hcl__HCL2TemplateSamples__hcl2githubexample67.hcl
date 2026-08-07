module "lb_galera_prod" {

  lb_members            = slice(module.galera_production.out_members_access_ip_v4, 0, length(module.galera_production.out_members_access_ip_v4) )

}