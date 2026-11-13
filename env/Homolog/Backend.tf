terraform {
  backend "s3" {
    # O bucket precisa ser SEU e existir antes do "terraform init".
    # Nomes de bucket S3 são únicos no mundo: o "terraform-state-alura" era do instrutor.
    bucket = "terraform-state-api-go-cicd-enzodiasdev"
    key    = "Homolog/terraform.tfstate"
    region = "us-east-1"

    # Trava nativa do S3 (Terraform >= 1.10): impede dois applies ao mesmo tempo.
    use_lockfile = true
  }
}
