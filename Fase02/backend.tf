terraform {
  backend "s3" {
    bucket  = "terraform-state-matheusouza" // Nome do bucket criado no S3
    key     = "site/terraform.tfstate"      // Caminho dentro do bucket para o arquivo de estado .tfstate
    region  = "us-east-2"
    encrypt = true // para os dados ficarem criptografados
  }
}

