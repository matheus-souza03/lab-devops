// Para criar uma ecr
resource "aws_ecr_repository" "ecr_site" { // ecr-site é o nome do recurso aqui no código
  name                 = "site_prod"       // site_prod é o nome real do ecr na aws
  image_tag_mutability = "MUTABLE"

}

