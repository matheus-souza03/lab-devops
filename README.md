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

docker tag meu-site:v1.0 339495469954.dkr.ecr.us-east-2.amazonaws.com/site-prod:v1.0

meu-site: container local
v1.0: versão do container local
339495469954: id do usuario
us-east-2: região do ecr
site-prod: nome do ecr criado por você

Isso feito, basta da um docker push na tag, para subir o container na aws:

docker push 339495469954.dkr.ecr.us-east-2.amazonaws.com/site-prod:v1.0
