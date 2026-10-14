let requirement = `Not_required
let setup_status = Sgs_setup_ep_status.run ~requirement
let setup_admin = Sgs_setup_ep_admin_create.run ~requirement
let license_status = Sgs_service_license_oss_ep_status.run
