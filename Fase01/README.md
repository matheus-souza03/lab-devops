# lab-devops Fase01 - Docker e AWS

Laboratório para praticar ferramentas e fluxos de DevOps — objetivo principal: aprendizado e experimentação. Neste projeto demonstramos o empacotamento de um site estático em Docker, push da imagem para o Amazon ECR e execução da imagem em uma instância EC2.

Badges:

- Build: ![build](https://img.shields.io/badge/build-experimental-orange)
- Docker: ![docker](https://img.shields.io/badge/docker-ready-blue)
- AWS: ![aws](https://img.shields.io/badge/aws-demo-orange)
- License: ![license](https://img.shields.io/badge/license-MIT-lightgrey)

---

## Índice

- [Resumo](#resumo)
- [Arquitetura](#arquitetura)
- [Tecnologias](#tecnologias)
- [Pré-requisitos](#pré-requisitos)
- [Build da imagem Docker](#build-da-imagem-docker)
- [Publicar imagem no Amazon ECR](#publicar-imagem-no-amazon-ecr)
- [Executar imagem em EC2](#executar-imagem-em-ec2)
- [Comandos úteis](#comandos-úteis)
- [Como funciona (detalhes técnicos)](#como-funciona-detalhes-técnicos)
- [Limpeza / Remoção](#limpeza--remoção)
- [Problemas conhecidos e solução de problemas](#problemas-conhecidos-e-solução-de-problemas)
- [Segurança / Boas práticas](#segurança--boas-práticas)

---

## Resumo

Este repositório demonstra um fluxo simples de implantação de um site estático:

1. Empacotar o site em uma imagem Docker;
2. Publicar a imagem em um repositório privado no Amazon ECR;
3. Executar a imagem em uma instância EC2.

O objetivo é ensinar os passos e comandos necessários para esse fluxo, com foco em praticar conceitos de containerização, registro de imagens e permissões AWS.

## Arquitetura

Fluxo resumido:

- Criar imagem Docker localmente.
- Imagem é taggeada e enviada (push) para Amazon ECR (repositório privado).
- Instância EC2 (com permissão adequada) puxa (pull) a imagem do ECR e executa o container.
- Tráfego HTTP é servido pelo container na porta 80 (mapeada para a porta pública desejada da EC2).

## Tecnologias

- Docker (construção e execução de containers)
- AWS ECR (Elastic Container Registry) — repositório de imagens
- AWS EC2 — instância para executar containers
- AWS IAM — controle de permissões (role com política `AmazonEC2ContainerRegistryReadOnly`)
- Shell / AWS CLI

## Pré-requisitos

- Conta AWS com permissões para criar ECR, EC2 e IAM roles (ou autorização para pedir a um administrador).
- AWS CLI configurada (aws configure) com credenciais e região.
- Docker instalado localmente para build/push.

## Build da imagem Docker

1. Crie um arquivo `Dockerfile` (exemplo simples para site estático usando nginx):
   ```dockerfile
   FROM nginx:stable-alpine
   COPY ./website /usr/share/nginx/html:ro
   EXPOSE 80
   ```
2. Construir a imagem:
   docker build -t meu-site:v1.0 .
   - `meu-site` = nome da imagem local
   - `v1.0` = tag/versão
3. Testar localmente:
   docker run -d -p 3000:80 --name meu-site-test meu-site:v1.0
   - Acesse http://localhost:3000 para validar.

## Publicar imagem no Amazon ECR

Observação: substitua os placeholders abaixo pelos valores do seu ambiente.

1. Criar um repositório no ECR (pelo Console AWS ou CLI):
   aws ecr create-repository --repository-name site-prod --region <AWS_REGION>

2. Fazer login no ECR (na região correta):
   aws ecr get-login-password --region <AWS_REGION> | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com

3. Taggar a imagem local para apontar ao ECR:
   docker tag meu-site:v1.0 <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/site-prod:v1.0

4. Push da imagem:
   docker push <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/site-prod:v1.0

Observação de segurança: substitua `<AWS_ACCOUNT_ID>`, `<AWS_REGION>` e `<TAG>` pelos valores apropriados. Não suba credenciais em texto plano no repositório; use o AWS CLI configurado localmente ou CI com secrets.

## Executar imagem em EC2

Resumo dos passos para executar a imagem ECR numa instância EC2:

1. Criar instância EC2

   - Tipo sugerido para testes: `t3.micro`.
   - Escolha a AMI compatível (ex.: Amazon Linux 2).
   - Criar/associar um par de chaves SSH (arquivo `.pem`).

2. Acessar via SSH (exemplo):
   chmod 400 <PATH_TO_KEY>.pem
   ssh -i "<PATH_TO_KEY>.pem" <EC2_USER>@<EC2_PUBLIC_IP>

   - Substitua `<EC2_USER>` (ex.: `ec2-user`, `ubuntu`) e `<EC2_PUBLIC_IP>`.

3. Instalar e iniciar Docker (Amazon Linux 2 exemplo):
   sudo yum update -y
   sudo yum install -y docker
   sudo systemctl start docker
   sudo usermod -aG docker $(whoami)

   # Efetue logout/login para que as permissões do grupo docker sejam aplicadas.

4. Conceder à EC2 permissão para acessar o ECR

   - Crie uma IAM Role com a política gerenciada `AmazonEC2ContainerRegistryReadOnly`.
   - Anexe essa Role à instância EC2 (Actions → Security → Modify IAM role).
   - Isso permite que a instância faça `docker pull` de repositórios privados ECR sem inserir credenciais estáticas.

5. No EC2, autenticar no ECR
   aws ecr get-login-password --region <AWS_REGION> | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com

6. Pull e execução:
   docker pull <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/site-prod:v1.0
   docker run --name site -d -p 80:80 <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/site-prod:v1.0

7. Acesse o site apontando para o IP público da EC2 (ex.: http://<EC2_PUBLIC_IP>/).

## Comandos úteis

- Listar containers: docker ps
- Ver logs: docker logs -f <container_id_or_name>
- Parar container: docker stop <container>
- Remover container: docker rm <container>
- Remover imagem local: docker rmi <image>
- Listar imagens: docker images
- Fazer login ECR: aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com
- Criar repositório ECR: aws ecr create-repository --repository-name <name> --region <region>

## Como funciona (detalhes técnicos)

- Dockerfile: empacota conteúdos estáticos (HTML/CSS/JS) em uma imagem baseada em nginx, expondo porta 80.
- Tagging: criar uma tag com o endpoint do ECR permite push/pull entre Docker local e ECR.
- IAM Role para EC2: evita uso de credenciais estáticas na instância; privilegia o uso de identidade associada à instância.

## Limpeza / Remoção

- Remover containers e imagens da EC2:
  docker stop site
  docker rm site
  docker rmi <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/site-prod:v1.0
- Remover repositório ECR
  aws ecr delete-repository --repository-name site-prod --force --region <AWS_REGION>

## Problemas conhecidos e solução de problemas

- Erro ao executar `docker login`/`docker pull` do ECR:
  - Verifique se `aws configure` está com credenciais e região corretas.
  - Se a EC2 usa IAM Role, confirme que a Role está anexada e contém `AmazonEC2ContainerRegistryReadOnly`.
- Permissão SSH: se ao tentar conectar ocorrer erro de permissão no arquivo `.pem`, rode `chmod 400 <PATH_TO_KEY>.pem`.
- Permissões docker na EC2: se precisar do usuário não-root executar docker, adicione-o ao grupo docker e faça logout/login.
- Erro 403/403 Forbidden ao acessar conteúdo servido: verifique se o container está rodando e o mapeamento de portas (host:container) está correto.

## Segurança / Boas práticas

- Nunca commit credenciais (AWS keys, .pem, tokens) no repositório.
- Use IAM roles para instâncias EC2 em vez de chaves embutidas.
- Para produção, utilize balanceadores (ALB), HTTPS (TLS) e mecanismos de auto-scaling.
