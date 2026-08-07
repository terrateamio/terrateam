variable "rgname" {
  type        = string
  description = "リソースグループの名称を指定します"
}
variable "location" {
  type        = string
  description = "ロケーションを指定します"
}
variable "vnet_name" {
  type        = string
  description = "vnetの名称を指定します"
}
variable "address_space" {
  type        = list(string)
  description = "vnetのアドレス空間を指定します"
  default     = ["10.1.0.0/16"]
}
variable "subnet_name" {
  type        = string
  description = "サブネットの名称を指定します"
}
サブネットの名称を指定しますvariable "nic_name" {
  type        = string
  description = "NICの名称を指定します"
}
variable "vm_name" {
  type        = string
  description = "仮想マシンの名称を指定します"
}
variable "vm_size" {
  type        = string
  description = "仮想マシンのサイズを指定します。例: `Standard_F2`"
}
variable "admin_username" {
  type        = string
  description = "管理者のユーザ名を指定します。デフォルトは `azureuser`"
  default     = "azureuser"
}
variable "vm_publisher" {
  type        = string
  description = "VMのパブリッシャーを指定します"
}
variable "vm_offer" {
  type        = string
  description = "仮想マシンのオファーを指定します"
}
variable "vm_sku" {
  type        = string
  description = "仮想マシンのskuを指定します"
}
variable "vm_version" {
  type        = string
  description = "仮想マシンのOSのバージョンを指定します。デフォルトは `latest`"
  default     = "latest"
}
variable "keyvault_name" {
  type        = string
  description = "keyvaultの名称を指定します"
}
variable "sku_name" {
  type        = string
  description = "keyvaultのskuを指定します"
}
variable "keyvault_secret_name" {
  type        = string
  description = "keyvalut secretの名称を指定します。デフォルトは `vmpassword`"
  default     = "vmpassword"
}
variable "custom_tags" {
  description = "タグを指定します"
}
variable "account_tier" {
  type        = string
  description = "ストレージアカウントのtierを指定します"
}
variable "account_replication_type" {
  type        = string
  description = "ストレージアカウントのレプリケーションのタイプを指定します。`LRS`、`GRS` 等"
}
