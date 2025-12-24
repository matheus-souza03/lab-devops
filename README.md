# lab-devops

Laboratório focado em praticar com diversas ferramentas de DevOps, tendo apenas o aprendizado como finalidade!

Este projeto é desenvolvido de acordo com o guia x

## Passo 1

Após clonar o repositório onde o site está hospedado, iremos "empacotar" os arquivos do site, ou seja, criar uma imagem para essa aplicação

Primeiramente, criaremos o dockerfile. Que será o arquivo onde estará todas as instruções para a criação do ambiente onde a aplicação irá rodar. Assim criaremos a imagem com o seguinte comando

docker build -t meu-site:v1.0 .

Onde meu_site é o nome da imagem, v1.0 a versão, e "." indica em qual diretório a imagem está

Uma imagem empacota uma aplicação, e assim, você pode rodar vários containers com a mesma imagem

Para subir um container:

docker run -d -p 3000:80 --name nome_container meu-site:v1.0

-d indica para não mostrar os logs, e conseguir sair do terminal
-p indica as portas
3000 porta do pc local
80 porta do container

após criar o conteiner basta apenas verificar se está tudo certo com o comando docker ps

Com o container pronto, está na hora de criar um ECR na aws. Fazer isso pelo aws console na web, e fazer login pela cli: (Muito importante, verificar se fez login no mesmo local onde subiu o ecr)

aws ecr get-login-password --region "regiao_do_ecr" | docker login --username AWS --password-stdin "id_usuario".dkr.ecr."regiao_ecr".amazonaws.com

Já logado na mesma região do ECR, agora precisa criar uma tag para subir o container nesse ecr:

Tag é uma cópia da imagem criada a ser armazenada no ecr.

docker tag meu-site:v1.0 339495469954.dkr.ecr.us-east-2.amazonaws.com/site-prod:v1.0

meu-site: container local
v1.0: versão do container local
339495469954: id do usuario
us-east-2: região do ecr
site-prod: nome do ecr criado por você

Isso feito, basta dar um docker push na tag, para subir a imagem na aws:

docker push 339495469954.dkr.ecr.us-east-2.amazonaws.com/site-prod:v1.0

## Passo 2 - Subir a imagem do ECR para uma máquina na nuvem EC2

Iremos para a aba EC2 na aws console, e criaremos uma instância, onde escolheremos o OS, a arquitetura do processador e o tipo de máquina que utilizaremos.
Nesse caso será uma t3.micro, pois está inclusa no plano gratuito e é a mais barata. É necessário criar uma chave ssh e settar as configurações de rede.

Após isso, clique no botão de criar instância e irá subir esta máquina na nuvem.

Com a máquina criada, basta acessá-la atraves da chave ssh que foi instalada, com o seguinte comando:

ssh -i "nome_arquivo_com_chave_ssh" "usuario"@"ip_publico"

As informações de usuário e ip é possivel acessar selecionando a instância da máquina e clicando em "conectar".
Ao rodar este comando aparecerá um erro de permissão, pois todos podem ver e modificar o arquivo com a chave ssh, você deve alterar as permissões para que somente o usuário root posa ler o arquivo:

chmod 400 "nome_arquivo_com_chave_ssh"

E, assim, você consegue acessar a máquina na aws.

Agora você deve atualizar o OS, caso tenha alguma pendência, e instalar o docker.

sudo yum update -y
sudo yum install docker
sudo systemctl start docker

O usuário não estará no grupo do docker e assim não terá permissões necessárias, para garantir essas permissões:

sudo usermod -a -G docker "usuario"

Saia e retorne à máquina para pegar as permissões.

Ao tentar dar um "pull" na imagem que subimos na ECR aparecerá um erro, pois esta instância da EC2 em que estamos não tem permissão para acessar aquela ECR, pois criamos uma ECR privada.
Para resolver este problema precisamos criar uma Role e adicionar uma politica de leitura, chamada "AmazonEC2ContainerRegistryReadOnly".

Para criar uma Role: IAM -> Recursos IAM -> Funções (roles) -> Criar perfil (botao superior direito), marcar serviço da AWS e escolher caso de uso EC2, assim poderá selecionar a politica indicada.
Para adicionar esta role na instância EC2:

- Selecione a instância
- Clique em ações -> Segurança -> Modificar Função do IAM
- Selecione a Role

Após isso, faça login na ecr pela máquina da aws, e dê um pull

docker pull "URL_imagem/site":versao

E por fim, basta dar um docker run:

docker run --name site -d -p 80:80 "URL_imagem/site":versao

E Pronto!
