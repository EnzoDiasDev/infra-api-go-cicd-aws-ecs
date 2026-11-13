variable "imagem" {
  description = "Imagem Docker da API, ex.: enzodias31/go_ci3:42. Passada pelo pipeline com -var."
  type        = string
}

module "homolog" {
    source = "../../infra"

    nome_repositorio = "homolog"
    cargoIAM = "homolog"
    ambiante = "homolog"
    imagem   = var.imagem
}

output "IP_alb" {
  value = module.homolog.IP
}
