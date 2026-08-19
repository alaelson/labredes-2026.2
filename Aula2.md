# Aula 02: Administração de Usuários, Grupos e Permissões no Linux

## 1. Objetivos da Aula
O objetivo desta aula prática é capacitar você a administrar usuários, grupos e permissões de acesso a arquivos e diretórios no Ubuntu Server 26.04 LTS. Ao final desta prática, você será capaz de:
* Criar e gerenciar usuários e senhas via terminal.
* Organizar usuários em grupos de trabalho.
* Compreender e manipular permissões de leitura, escrita e execução usando a notação simbólica e a notação octal (numérica).
* Controlar a posse de arquivos e pastas com os utilitários `chown` e `chgrp`.
* Validar as restrições de acesso simulando diferentes perfis de usuário no terminal.

---

## 2. Contexto Teórico de Suporte

No sistema operacional Linux, a segurança e a integridade dos dados baseiam-se em um modelo rígido de propriedade e privilégios. Todo arquivo ou diretório possui exatamente:
1. **Um Usuário Dono (Owner/User - `u`):** Normalmente quem criou o arquivo.
2. **Um Grupo Associado (Group - `g`):** Um conjunto de usuários que compartilham permissões em comum.
3. **Outros (Others - `o`):** Qualquer outro usuário do sistema que não seja o dono nem pertença ao grupo associado.

As permissões básicas aplicadas a cada uma dessas três esferas são:
* **Leitura (Read - `r` ou `4`):** Permite ler o conteúdo de um arquivo ou listar os arquivos de um diretório.
* **Escrita (Write - `w` ou `2`):** Permite modificar ou apagar um arquivo, ou criar/remover arquivos dentro de um diretório.
* **Execução (Execute - `x` ou `1`):** Permite executar um arquivo como programa/script ou entrar (navegar) em um diretório com o comando `cd`.

---

## 3. Roteiro Prático Passo a Passo

> **Importante:** Para realizar esta prática, faça login com o usuário **`administrador`** e a senha **`adminifal`** configurados na Aula 1. Sempre que precisar de privilégios elevados, utilize o prefixo `sudo`.

### Passo 1: Criação dos Novos Usuários no Sistema
Nesta etapa, criaremos quatro novas contas de usuário que representarão colaboradores da nossa infraestrutura fictícia: `fulano`, `cicrano`, `beltrano` e `novato`.

Execute os comandos a seguir no console do seu servidor. O utilitário `adduser` criará automaticamente o diretório de início (`/home/<usuario>`), definirá o interpretador de comandos padrão (bash) e solicitará a criação de uma senha individual para cada conta.

```bash
administrador@ubuntu_server:~$ sudo adduser fulano
[sudo] password for administrador: 
Adding user `fulano' ...
Adding new group `fulano' (1001) ...
Adding new user `fulano' (1001) with group `fulano' (1001) ...
Creating home directory `/home/fulano' ...
Copying files from `/etc/skel' ...
New password: 
Retype new password: 
passwd: password updated successfully
Changing the user information for fulano
Enter the new value, or press ENTER for the default
	Full Name []: Fulano de Tal
	Room Number []: 
	Work Phone []: 
	Home Phone []: 
	Other []: 
Is the information correct? [Y/n] Y
```

> **Atenção:** Defina uma senha padrão de teste fácil para os quatro usuários (ex: `senha123`) para facilitar a alternância de login durante os testes práticos.

Agora, repita o processo para os demais usuários:
```bash
administrador@ubuntu_server:~$ sudo adduser cicrano
administrador@ubuntu_server:~$ sudo adduser beltrano
administrador@ubuntu_server:~$ sudo adduser novato
```

Para verificar se as contas foram criadas com sucesso no banco de dados local do Linux, você pode inspecionar as últimas linhas do arquivo `/etc/passwd`:
```bash
administrador@ubuntu_server:~$ tail -n 4 /etc/passwd
fulano:x:1001:1001:Fulano de Tal,,,:/home/fulano:/bin/bash
cicrano:x:1002:1002:,,,:/home/cicrano:/bin/bash
beltrano:x:1003:1003:,,,:/home/beltrano:/bin/bash
novato:x:1004:1004:,,,:/home/novato:/bin/bash
```

---

### Passo 2: Criação e Organização de Grupos de Trabalho
Para gerenciar permissões de forma escalável, os usuários devem ser agrupados por funções. Criaremos um grupo chamado `devs` que reunirá a equipe de desenvolvimento de software:

```bash
administrador@ubuntu_server:~$ sudo groupadd devs
```

Agora, adicionaremos os usuários `fulano`, `cicrano` e `beltrano` a este novo grupo utilizando o comando `usermod` com as flags `-a` (append/adicionar) e `-G` (group/grupo):
```bash
administrador@ubuntu_server:~$ sudo usermod -aG devs fulano
administrador@ubuntu_server:~$ sudo usermod -aG devs cicrano
administrador@ubuntu_server:~$ sudo usermod -aG devs beltrano
```

> **Atenção:** Note que o usuário `novato` **não** deve ser adicionado ao grupo `devs`. Ele representará o perfil externo (Outros) que tentará acessar as pastas protegidas.

Para validar se os usuários foram associados corretamente ao grupo, execute:
```bash
administrador@ubuntu_server:~$ grep "devs" /etc/group
devs:x:1005:fulano,cicrano,beltrano
```

---

### Passo 3: Criação do Diretório de Trabalho Compartilhado
Criaremos uma pasta no diretório raiz do sistema chamada `/srv/projeto`. Esta pasta servirá como repositório de desenvolvimento comum do grupo de trabalho:

```bash
administrador@ubuntu_server:~$ sudo mkdir -p /srv/projeto
```

Por padrão, uma pasta criada pelo usuário root (via `sudo`) pertence ao root. Vamos observar as permissões originais do diretório utilizando o comando `ls -ld`:
```bash
administrador@ubuntu_server:~$ ls -ld /srv/projeto
drwxr-xr-x 2 root root 4096 Aug 12 11:30 /srv/projeto
```

**Explicando a saída acima:**
* `d`: Identifica que o item é um diretório (directory).
* `rwx`: O dono (root) tem permissão de leitura, escrita e navegação/execução.
* `r-x`: O grupo associado (root) possui apenas leitura e navegação (não pode criar arquivos).
* `r-x`: Todos os demais usuários (others) também possuem apenas leitura e navegação.

---

### Passo 4: Mudança de Dono e de Grupo Associado (`chown` e `chgrp`)
Como o diretório `/srv/projeto` deve ser administrado pelo usuário `administrador` e manipulado pela equipe de desenvolvimento (`devs`), precisamos atualizar a posse deste diretório:

1. Altere o usuário dono para `administrador`:
```bash
administrador@ubuntu_server:~$ sudo chown administrador /srv/projeto
```

2. Altere o grupo associado para `devs`:
```bash
administrador@ubuntu_server:~$ sudo chgrp devs /srv/projeto
```

Agora, valide a alteração das propriedades:
```bash
administrador@ubuntu_server:~$ ls -ld /srv/projeto
drwxr-xr-x 2 administrador devs 4096 Aug 12 11:30 /srv/projeto
```

---

### Passo 5: Configuração das Permissões de Acesso (Modo Octal)
Queremos implementar a seguinte política de segurança no diretório `/srv/projeto`:
1. **O Dono (`administrador`):** Deve ter controle total (Leitura, Escrita e Execução) $\rightarrow$ `rwx` (Valor octal: $4+2+1 = \mathbf{7}$).
2. **O Grupo Associado (`devs`):** Deve ter controle de colaboração (Leitura, Escrita para criar/editar código e Execução para entrar na pasta) $\rightarrow$ `rwx` (Valor octal: $4+2+1 = \mathbf{7}$).
3. **Outros (qualquer outro, incluindo `novato`):** Não devem sequer visualizar ou listar o conteúdo da pasta de desenvolvimento $\rightarrow$ `---` (Valor octal: $0+0+0 = \mathbf{0}$).

Para aplicar essa política usando a notação numérica/octal, utilizamos o comando `chmod 770`:
```bash
administrador@ubuntu_server:~$ sudo chmod 770 /srv/projeto
```

Valide as novas permissões aplicadas:
```bash
administrador@ubuntu_server:~$ ls -ld /srv/projeto
drwxrwx--- 2 administrador devs 4096 Aug 12 11:30 /srv/projeto
```
A máscara de permissões mudou para `drwxrwx---`, confirmando o isolamento absoluto de qualquer usuário externo ao grupo!

---

### Passo 6: Criação de Arquivos de Teste
Ainda utilizando seu usuário `administrador`, crie um arquivo de notas dentro de `/srv/projeto`:
```bash
administrador@ubuntu_server:~$ echo "Especificacao tecnica do roteador de borda" > /srv/projeto/config_redes.txt
```

Verifique se o arquivo foi criado e observe suas propriedades e permissões de herança padrão:
```bash
administrador@ubuntu_server:~$ ls -l /srv/projeto/config_redes.txt
-rw-r--r-- 1 administrador devs 42 Aug 12 11:30 /srv/projeto/config_redes.txt
```

Para garantir que qualquer membro do grupo de desenvolvimento possa editar este arquivo, aplique a permissão octal `660` (Dono e Grupo leem e escrevem; Outros não fazem nada) no arquivo:
```bash
administrador@ubuntu_server:~$ chmod 660 /srv/projeto/config_redes.txt
administrador@ubuntu_server:~$ ls -l /srv/projeto/config_redes.txt
-rw-rw---- 1 administrador devs 42 Aug 12 11:30 /srv/projeto/config_redes.txt
```

---

## 4. Testes e Validação do Ambiente (Laboratório)

Para testar o funcionamento das permissões sem precisar sair fisicamente da sua sessão atual, utilize o comando `su` (substitute user) acompanhado do hífen `-` (que carrega o ambiente do respectivo usuário):

> ### 🔍 Observação Técnica de Extrema Importância: `su <usuario>` vs `su - <usuario>`
> Nos laboratórios práticos, é muito comum cometer o erro de digitar apenas `su administrador` ou `su fulano`. Contudo, há uma diferença sutil, mas crítica, no comportamento do sistema:
> 
> *   **`su nome_usuario` (sem o hífen):** Altera a identidade do usuário atual no terminal, mas **preserva o diretório de trabalho anterior e as variáveis de ambiente** (como `PATH`, `HOME` e `SHELL`) do usuário de origem. Você assume a identidade do novo usuário, mas continua operando "dentro do contexto" e do caminho de diretórios do usuário anterior.
> *   **`su - nome_usuario` (com o hífen):** Realiza uma **sessão de login completa (Login Shell)**. O sistema limpa as variáveis antigas, altera o diretório atual diretamente para a pasta pessoal (`/home/nome_usuario`) do novo usuário e carrega todos os scripts de inicialização específicos dele (como `.bashrc` e `.profile`).
> 
> **Por que sempre usamos `su -` nos testes?**
> Para testar permissões de diretórios com isolamento real, precisamos que o sistema carregue o ambiente limpo do usuário. Se usarmos apenas `su`, o terminal tentará manter o diretório atual do usuário anterior, o que pode gerar mensagens de erro confusas ou falsos positivos de acesso devido ao contexto herdado.



### Teste A: Validação com Usuário do Grupo (`fulano`)
1. Alterne para a sessão do usuário `fulano`:
```bash
administrador@ubuntu_server:~$ su - fulano
Password: <digite a senha que configurou no Passo 1>
fulano@ubuntu_server:~$ 
```

2. Tente navegar até a pasta e visualizar o arquivo de configuração:
```bash
fulano@ubuntu_server:~$ cd /srv/projeto
fulano@ubuntu_server:/srv/projeto$ ls -l
total 4
-rw-rw---- 1 administrador devs 42 Aug 12 11:30 config_redes.txt
```

3. Tente adicionar uma linha de comentários ao arquivo (Escrita):
```bash
fulano@ubuntu_server:/srv/projeto$ echo "Revisado por Fulano" >> config_redes.txt
fulano@ubuntu_server:/srv/projeto$ cat config_redes.txt
Especificacao tecnica do roteador de borda
Revisado por Fulano
```
*Sucesso! O usuário `fulano` teve acesso total de leitura e escrita pois pertence ao grupo `devs`.*

4. Saia da sessão do usuário atual para retornar ao administrador:
```bash
fulano@ubuntu_server:/srv/projeto$ exit
logout
administrador@ubuntu_server:~$ 
```

---

### Teste B: Validação com Usuário Externo (`novato`)
1. Alterne para o usuário `novato`:
```bash
administrador@ubuntu_server:~$ su - novato
Password: <digite a senha que configurou no Passo 1>
novato@ubuntu_server:~$ 
```

2. Tente navegar até a pasta protegida `/srv/projeto` (Execução):
```bash
novato@ubuntu_server:~$ cd /srv/projeto
-bash: cd: /srv/projeto: Permission denied
```

3. Tente listar os arquivos internos mesmo sem entrar na pasta (Leitura):
```bash
novato@ubuntu_server:~$ ls -l /srv/projeto
ls: cannot open directory '/srv/projeto': Permission denied
```
*Sucesso! O sistema negou completamente o acesso ao usuário `novato` conforme as regras de controle estabelecidas no passo 5.*

4. Saia do terminal para voltar ao administrador:
```bash
novato@ubuntu_server:~$ exit
logout
administrador@ubuntu_server:~$ 
```

---

## 5. Exercício Prático de Fixação

Para consolidar as competências adquiridas, cada aluno ou grupo deverá executar de forma autônoma a seguinte tarefa:

1. **Criar um novo grupo** chamado `financeiro`.
2. **Associar os usuários** `cicrano` e `beltrano` ao grupo `financeiro` (além do grupo `devs` ao qual já pertencem).
3. **Criar uma nova pasta** compartilhada em `/srv/financeiro`.
4. **Definir as seguintes permissões de acesso:**
   * O usuário `administrador` deve ter controle total.
   * O grupo `financeiro` deve ter acesso de leitura e escrita.
   * Os membros do grupo `devs` (como `fulano`) e o usuário `novato` **não** devem ter acesso a esta pasta financeira.
5. **Demonstrar em testes de terminal** que `cicrano` consegue criar e alterar um relatório na pasta, enquanto `fulano` e `novato` recebem a mensagem `Permission denied`.

---

## 6. Modelo de Relatório Técnico (Entrega via GitHub)
As entregas de laboratório devem ser feitas sob a forma de um relatório técnico individual publicado no repositório GitHub dos alunos, respeitando estritamente a seguinte estrutura de 7 tópicos:

1. **Identificação:** Título da prática, nome completo do aluno, matrícula, turma e data de realização.
2. **Objetivo:** Explicação clara do que se pretendia validar nesta atividade prática de administração de usuários e permissões.
3. **Ambiente:** Especificação das versões do sistema operacional hospedeiro, hipervisor VirtualBox e a distribuição do Linux Server configurada.
4. **Procedimento:** Descrição textual de todas as etapas efetuadas para a criação das contas, grupos, diretórios e atribuição de permissões.
5. **Testes e Evidências:** Inserção de capturas de tela (prints) ou cópias integrais do terminal demonstrando o sucesso dos testes dos passos A e B e o resultado do Exercício Prático de Fixação.
6. **Problemas e Soluções:** Registro de quaisquer erros de permissão ou de comandos encontrados durante a execução da prática e as soluções aplicadas.
7. **Conclusão:** Síntese crítica sobre a importância do gerenciamento correto de permissões de diretórios para a segurança e integridade de servidores Linux corporativos.
