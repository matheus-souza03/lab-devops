#lab-devops
##📌 Visão Geral

Este repositório contém um laboratório prático de DevOps, com o objetivo de consolidar conhecimentos em Docker e AWS, realizando o deploy de um site estático em nuvem.

O projeto abrange todo o fluxo de:

Criação de imagem Docker

Armazenamento da imagem no Amazon ECR

Provisionamento de uma instância EC2

Deploy do container na nuvem

⚠️ Projeto desenvolvido exclusivamente para fins de aprendizado e prática.

##🛠️ Tecnologias Utilizadas

Docker

AWS EC2

AWS ECR

AWS IAM

Linux (Amazon Linux)

SSH

📂 Estrutura do Projeto
Fase01/
├── website/
│ └── arquivos do site estático
├── Dockerfile
└── README.md

##🚀 Passo 1 – Criar a imagem Docker e enviar para o Amazon ECR
1️⃣ Criar a imagem Docker

Após clonar o repositório, o primeiro passo é empacotar a aplicação, criando uma imagem Docker.

Crie o Dockerfile contendo as instruções para o ambiente da aplicação e execute:

docker build -t meu-site:v1.0 .

Parâmetros:

meu-site: nome da imagem

v1.0: versão da imagem

.: diretório onde está o Dockerfile

📌 Uma imagem representa a aplicação empacotada, permitindo a execução de múltiplos containers a partir dela.

2️⃣ Executar o container localmente (opcional)
docker run -d -p 3000:80 --name nome_container meu-site:v1.0

Explicação dos parâmetros:

-d: executa em segundo plano

-p 3000:80: mapeia a porta 3000 do host para a porta 80 do container

--name: nome do container

Verifique se o container está em execução:

docker ps

3️⃣ Criar um repositório no Amazon ECR

Crie um repositório no Amazon ECR via AWS Console.

Após a criação, faça login no ECR utilizando a AWS CLI:

aws ecr get-login-password --region REGIAO_DO_ECR \
| docker login --username AWS --password-stdin ID_USUARIO.dkr.ecr.REGIAO_DO_ECR.amazonaws.com

⚠️ Certifique-se de estar autenticado na mesma região onde o ECR foi criado.

4️⃣ Criar a tag da imagem para o ECR

A tag representa uma cópia da imagem local que será enviada ao ECR.

docker tag meu-site:v1.0 339495469954.dkr.ecr.us-east-2.amazonaws.com/site-prod:v1.0

Parâmetros:

339495469954: ID da conta AWS

us-east-2: região do ECR

site-prod: nome do repositório no ECR

v1.0: versão da imagem

5️⃣ Enviar a imagem para o ECR
docker push 339495469954.dkr.ecr.us-east-2.amazonaws.com/site-prod:v1.0

##☁️ Passo 2 – Deploy da imagem em uma instância EC2
1️⃣ Criar a instância EC2

No AWS Console:

Acesse EC2

Crie uma nova instância

Selecione o sistema operacional

Escolha o tipo t3.micro (Free Tier)

Crie ou selecione uma chave SSH

Configure as regras de rede (porta 22 e 80 liberadas)

2️⃣ Acessar a instância via SSH

Antes de conectar, ajuste a permissão da chave SSH:

chmod 400 nome_arquivo_com_chave_ssh

Conecte-se à instância:

ssh -i nome_arquivo_com_chave_ssh usuario@ip_publico

3️⃣ Atualizar o sistema e instalar o Docker
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker

Adicione o usuário ao grupo Docker:

sudo usermod -a -G docker usuario

⚠️ Saia e entre novamente na instância para aplicar as permissões.

4️⃣ Permitir acesso da EC2 ao ECR (IAM Role)

Como o ECR é privado, é necessário conceder permissão à EC2.

Crie uma IAM Role com a política:

AmazonEC2ContainerRegistryReadOnly

Associe a Role à instância EC2:

Selecione a instância

Ações → Segurança

Modificar função do IAM

Selecione a Role criada

5️⃣ Fazer pull da imagem e executar o container

Faça o pull da imagem do ECR:

docker pull URL_IMAGEM/site:versao

Execute o container:

docker run -d --name site -p 80:80 URL_IMAGEM/site:versao

##✅ Resultado Final

O site estático estará disponível publicamente através do IP público da instância EC2, na porta 80.

##📚 Objetivo do Projeto

Praticar Docker na criação de imagens

Trabalhar com ECR e EC2 na AWS

Entender controle de permissões com IAM

Simular um fluxo real de deploy em nuvem

Se quiser, posso:

Adaptar o README para inglês

Criar uma arquitetura em diagrama

Ajustar para um padrão mais corporativo (ex: CI/CD, Terraform)

Deixar no formato ideal para recrutadores DevOps

Só me dizer 👍

O ChatGPT pode cometer erros. Confira informações importantes. Consulte as Preferências de cookies.
