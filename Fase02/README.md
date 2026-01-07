# lab-devops Fase02 - Terraform

A fase 2 consiste em utilizar de terraform para automatizar a criação da infraestrutura

---

## Índice

- [Criação dos arquivos](#criação-dos-arquivos)
- [Comandos para subir a infra](#comandos-para-subir-a-infra)
- [Erros de Permissão](#erros-de-permissão)

---

## Criação dos arquivos

provider.tf indica qual provedor utilizaremos, neste caso aws.

backend.tf responsável por dizer que o .tfstate (estado da nossa infra) será armazenado de forma remota. No nosso caso será armazenado em um Bucket S3.

terraform.tfstate é o arquivo mais importante do terraform, pois "guarda" o que já foi criado, permite detectar mudanças e evita recriar recursos indevidamente.

Sem o backend.tf o .tfstate fica local, e isso ocasiona:

- risco de perder o arquivo;
- Impossível trabalhar em equipe;
- Conflitos de estado .

ecr.tf e ec2.tf são os arquivos que criam e configuram, respectivamente, as instâncias ecr e ec2.

---

## Comandos para subir a infra

# 🚨IMPORTANTE

Deve estar com a AWS CLI já configurada na máquina local e com as credenciais configuradas.
E também com o Terraform instalado.

Com isso pronto é só seguir os seguintes passos:

```
- terraform init // Para inicializar o backend
- terraform fmt // Para formatar todos os arquivos, deixando-os mais legíveis e dentro do padrão do terraform
- terraform validate // Verifica se o código está funcional, se apresentar algum erro ele mostrará
- terraform plan // Etapa que o terraform planeja tudo que será criado na aws
- terraform apply // Para, em fim, executar o código e criar toda a infraestrutura na aws
```

## Erros de Permissão

Após a primeira tentativa de "terraform init" recebi diversos erros de acesso negado.
Após averiguar percebi que meu usuário não tinha algumas permissões necessárias, como:

Permissão para acessar o s3 bucket

Permissão para criar a chave de acesso ssh.

Permissão para criar o security group

Permissão para destruir o .tfstate devido ao não cesso à interface de rede ENI

Permissão para criar uma IAM Role.

Como é um laboratório dei permissão para tudo.

Porém, no mundo real devemos seguir a premissa de segurança de acesso mínimo, e uma forma de seguir esta premissa utilizando Terraform é criar nossa própria política e anexar ao usuário, segue um exemplo de um como criar uma política com JSON:

```JSON
{
"Version": "2012-10-17",
"Statement": [
  { // Permissão para acessar o s3
    "Effect": "Allow",
    "Action": "s3:ListBucket", // Action: qual ação o usuário pode fazer
    "Resource": "arn:aws:s3:::terraform-state-matheusouza" // Resource: Em qual recurso
  },
  { // Permissão para acessar, editar e excluir o .tfstate presente no diretório /site
    "Effect": "Allow",
    "Action": [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject",

  ],
    "Resource": "arn:aws:s3:::terraform-state-matheusouza/site/terraform.tfstate"
  },
  { // Permissão para criar (importar), excluir e listar os Key Pairs
			"Effect": "Allow",
			"Action": [
				"ec2:ImportKeyPair",
				"ec2:DeleteKeyPair",
				"ec2:DescribeKeyPairs"
			],
			"Resource": "*"
		},
    { // Permissão para criar security groups e tags , remover sgs, autorizar criar e remover tráfego de entrada e de saída, listar os secury groups, as regras dos sgs e as vpcs, listar interfaces de rede
          "Effect": "Allow",
          "Action": [
            "ec2:CreateSecurityGroup",
            "ec2:CreateTags",
            "ec2:DeleteSecurityGroup",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:AuthorizeSecurityGroupEgress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupEgress",
            "ec2:DescribeSecurityGroupRules",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeVpcs",
            "ec2:DescribeNetworkInterfaces"
          ],
          "Resource": "*"
        },
        { // Permissão para criar e manipular IAM Role
          "Effect": "Allow",
          "Action": [
            "iam:CreateRole",
            "iam:DeleteRole",
            "iam:TagRole",
            "iam:AttachRolePolicy",
            "iam:CreateInstanceProfile",
            "iam:AddRoleToInstanceProfile",
            "iam:PassRole"
          ],
          "Resource": "*"
        }
]
}
```
