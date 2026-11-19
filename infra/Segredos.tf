# Segredos da aplicação: gerados aqui e guardados no AWS Secrets Manager.
# A task do ECS lê os valores direto do Secrets Manager (bloco "secrets" em
# ECS.tf), então eles não aparecem no código nem na task definition.
#
# Atenção: o state do Terraform guarda esses valores. O bucket do state precisa
# ser privado e criptografado.

resource "random_password" "db" {
  length = 32
  # Sem caracteres especiais: a API monta a string de conexão no formato
  # "chave=valor" separado por espaço, e aspas ou espaços quebrariam o formato.
  special = false
}

resource "random_password" "api_key_leitura" {
  length  = 40
  special = false
}

resource "random_password" "api_key_admin" {
  length  = 40
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  name_prefix = "${var.ambiante}-api-go-db-"
  description = "Usuário e senha do RDS da API Go (${var.ambiante})"
  # O ambiente é destruído e recriado a cada teste de carga. Sem isto, o
  # segredo fica 30 dias "agendado para exclusão" e o próximo apply falha.
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = aws_db_instance.default.username
    password = random_password.db.result
  })
}

resource "aws_secretsmanager_secret" "api_keys" {
  name_prefix             = "${var.ambiante}-api-go-api-keys-"
  description             = "Chaves de API (leitura e admin) da API Go (${var.ambiante})"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode({
    API_KEY_LEITURA = random_password.api_key_leitura.result
    API_KEY_ADMIN   = random_password.api_key_admin.result
  })
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "api_keys_secret_arn" {
  value = aws_secretsmanager_secret.api_keys.arn
}
