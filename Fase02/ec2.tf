// Criação da instância do EC2

resource "aws_instance" "website-server" {
  ami                    = "ami-00e428798e77d38d9" // ami é a imagem do sistema operacional, nesse caso a ami é: Amazon Linux 2023 kernel-6.1
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name              // Nome do par de chaves criado para acessar a instância via SSH, no resource aws_key_pair
  vpc_security_group_ids = [aws_security_group.website_sg.id]          // Nome do security group criado para permitir acesso SSH, HTTP, HTTPS
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name  // Nome da instância da IAM Role

  tags = {
    Name        = "website-server" // Nome da instância
    Provisioned = "Terraform"      // Tag para identificar que a instância foi provisionada via Terraform, para que não alterem manualmente essa instância ao verem que é provisionada por código
    Client      = "Matheus Souza"  // Tag para identificar o cliente dono dessa infraestrutura
  }
}


//  CRIAÇÃO DO PAR DE CHAVES PARA ACESSAR A INSTÂNCIA EC2 VIA SSH

resource "tls_private_key" "create_key" { // Recurso para criar a chave privada localmente, ele gera diversos atributos automaticamente, os principais são: private_key_pem (chave privada em formato PEM), public_key_pem (chave pública em formato PEM) e public_key_openssh (chave pública no formato OpenSSH).
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "private_key_pem" { // Recurso para salvar a chave privada em um arquivo localmente
  content         = tls_private_key.create_key.private_key_pem // Usa a chave privada gerada no recurso tls_private_key
  filename        = "/Users/matheus/Documents/keys/deployer-key.pem" // Caminho onde a chave privada será salvo localmente
  file_permission = "0400" // Permissão apenas de leitura para o dono do arquivo
}

resource "aws_key_pair" "deployer" { // Recurso para criar o par de chaves na AWS
  key_name   = "deployer-key"
  public_key = tls_private_key.create_key.public_key_openssh // Usa a chave pública gerada localmente
}


// CONFIGURAÇÃO DO SECURITY GROUP PARA PERMITIR ACESSO SSH, HTTP E HTTPS. (Security Group age como um firewall virtual para controlar as entradas e saídas.)

resource "aws_security_group" "website_sg" { // Recurso para criar o security group
  name   = "website_sg"
  vpc_id = "vpc-h3x4d3x1m4l" // ID da VPC onde o security group será criado

  tags = {
    Name        = "website_sg"
    Provisioned = "Terraform"
    Client      = "Matheus Souza"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" { // Recurso para permitir acesso SSH (porta 22)
  security_group_id = aws_security_group.website_sg.id       // ID do security group criado acima
  cidr_ipv4         = "seu_ip/32"                    // máscara /32 para permitir acesso apenas do seu IP
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" { // Recurso para permitir acesso HTTP (porta 80)
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "0.0.0.0/0" // máscara /0 para permitir acesso de qualquer IP
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" { // Recurso para permitir todo o tráfego de saída
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" // -1 significa todos os protocolos e todas as portas. os atributos "from_port" e "to_port" foram ignorados, para permitir acesso por todas as portas
}


// IAM ROLE PARA A INSTÂNCIA EC2 ACESSAR O ECR

resource "aws_iam_role" "ec2_role" { // Recurso para criar a IAM Role
  name = "ec2_role"

  assume_role_policy = jsonencode({ // Política que define quais instâncias podem assumir essa role
    Version = "2012-10-17"
    Statement = [

      {
        Action = "sts:AssumeRole" // Ação que permite assumir a role
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com" //dá acesso para instância ec2
        }
      }
    ]
  })

  tags = {
    Name        = "ec2_role"
    Provisioned = "Terraform"
    Client      = "Matheus Souza"
  }
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {                  // Recurso para indicar a permissão dada pela IAM Role 
  role       = aws_iam_role.ec2_role.name                                   // Indica a qual role pertence
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" // "arn (indica que é um Amazon Resource Name)" é o identificador único de qualquer recurso na AWS, "aws (indica que é a partição padrão da AWS)", "iam (indica que é um recurso do IAM)", ":: (vazio, indica que o IAM é global, não pertence a uma região)", "aws (indica que é uma política que pertence à AWS)", "policy:AmazonEC2ContainerRegistryReadOnly (indica que o recurso é uma política, e a politica é o último parâmetro)"
}

resource "aws_iam_instance_profile" "ec2_profile" { // Recurso que "conecta" o IAM Role à instância EC2
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name // Nome da role 
}
