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

# ARN dos segredos no Secrets Manager. Para ler a chave de API, por exemplo:
# aws secretsmanager get-secret-value --secret-id <api_keys_secret_arn>
output "db_secret_arn" {
  value = module.homolog.db_secret_arn
}

output "api_keys_secret_arn" {
  value = module.homolog.api_keys_secret_arn
}
