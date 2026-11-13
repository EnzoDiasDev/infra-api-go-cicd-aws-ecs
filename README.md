
# Resumo do projeto

  
> 📚 Repositório de estudo baseado no projeto do curso **Integração Contínua: Rollback e teste de carga**, da [Alura](https://www.alura.com.br).
> Infraestrutura usada pela API do repositório [api-go-cicd-aws-ecs](https://github.com/EnzoDiasDev/api-go-cicd-aws-ecs).

Projeto de Infraestrutura como código para auxiliar o Curso de testes de carga de CI/CD

  
## ✔️ Técnicas e tecnologias utilizadas

  

Neste App são exploradas as seguintes técnicas e tecnologias:

  

-  **Criação de maquinas para executar containers Docker**: criação de maquinas de forma automática pelo ECS (Elastic Container Service) da AWS feito de forma automática pelo Fargate

-  **Utilização de módulos**: Utilização dos módulos do Terraform, desenvolvidos pelos provedores e comunidade

-  **Separação de ambientes**: 2 ambientes separados, construídos de forma automática pelo Terraform, reutilizando código.

  

## 📁 Acesso ao projeto

  

Você pode [baixar o zip](https://github.com/leollo98/iac-curso5/archive/refs/heads/Aula_6.zip) do projeto base para esse ou [acessar o código fonte](https://github.com/leollo98/iac-curso5/tree/Aula_6) do projeto final.

  

## 🛠️ Abrir e rodar o projeto

  

O projeto foi desenvolvido no VSC (Visual Studio Code), sendo assim, instale o VSC (pode ser uma versão mais recente) e, na tela inicial, procure a opção extensões, ou aperte Ctrl+Shift+X, e busque por HashiCorp Terraform, assim teremos o suporte do intellisense, tornando o trabalho de escrever o código mais rápido.

  

> Caso baixou o zip, extraia o projeto antes de procurá-lo, pois não é possível abrir via arquivo zip

  

Vá até a paste a abra a pasta do projeto. Após abrir o projeto abra um terminal, pode ser o integrado com o VSC, navegue até a pasta `env/Homolog`  e execute o comando `terraform init` dentro dela, agora temos o Terraform iniciado e podemos começar a utilizá-lo. Para criar a infraestrutura, execute o `terraform apply` na pastas de Produção (`env/Homolog`).

  

🏆
