# Aula 03: Estrutura de Diretórios, Pastas do Sistema (FHS) e Permissões Avançadas no Linux Server

Nesta aula prática, você aprenderá a explorar a árvore padrão de diretórios do Linux (Filesystem Hierarchy Standard - FHS), compreender a utilidade e o propósito das pastas essenciais do sistema operacional e configurar estruturas complexas de diretórios corporativos com controle fino de permissões de acesso local.

---

## 1. Objetivos da Aula
Ao final desta prática, você será capaz de:
* Navegar e explicar a utilidade das pastas estruturais do padrão FHS (`/etc`, `/var`, `/srv`, `/tmp`, `/bin`, `/sbin`).
* Criar caminhos de diretórios aninhados de forma recursiva e segura com o comando `mkdir -p`.
* Gerenciar e segregar acessos departamentais utilizando grupos do sistema e as permissões numéricas/octais.
* Validar e diagnosticar restrições de acesso simulando sessões reais de login no terminal.
* Compreender e aplicar a diferença operacional crítica entre os comandos `su` e `su -`.

---

## 2. Contexto Teórico: O Padrão FHS (Filesystem Hierarchy Standard)

O sistema de arquivos do Linux é organizado de forma hierárquica a partir de um único diretório base, denominado **Raiz (Root)** e representado pela barra diagonal `/`. O padrão FHS define as regras de organização das pastas do sistema operacional:

| Diretório | Função Essencial no Sistema Operacional e na Rede |
| :--- | :--- |
| **`/`** | Diretório raiz do sistema. Todas as outras pastas estão aninhadas sob ele. |
| **`/etc`** | Armazena os arquivos de configuração locais do sistema e de todos os serviços instalados (ex: Netplan, SSH, DNS). |
| **`/var`** | Contém dados variáveis e dinâmicos, como logs do sistema (`/var/log`), caches e bancos de dados em execução. |
| **`/srv`** | Destinado a armazenar dados de serviços locais fornecidos por este servidor (ex: pastas de rede, sites locais). |
| **`/tmp`** | Armazena arquivos temporários criados por programas. Geralmente é limpo automaticamente no boot do sistema. |
| **`/bin`** | Contém comandos e utilitários binários executáveis essenciais do sistema, acessíveis por qualquer usuário (ex: `ls`, `mkdir`, `ping`). |
| **`/sbin`** | Contém binários essenciais de administração e manutenção do sistema, restritos ou executados com privilégios de root (ex: `ip`, `reboot`, `netplan`). |
| **`/home`** | Pasta que abriga os diretórios pessoais dos usuários comuns do sistema (ex: `/home/fulano`). |

---

## 3. Roteiro Prático Passo a Passo

> **Importante:** Para realizar esta prática, faça login com o seu usuário administrativo padrão do laboratório: **`administrador`** com a senha **`adminifal`**. Sempre que executar comandos administrativos de sistema, utilize o prefixo `sudo`.

### Passo 1: Inspeção de Pastas do Sistema
Antes de criar nossa estrutura, vamos inspecionar como o Linux organiza seus arquivos internos.

1. Navegue até o diretório `/etc` e liste seu conteúdo de forma compacta:
```bash
administrador@ubuntu_server:~$ cd /etc
administrador@ubuntu_server:/etc$ ls -F | head -n 15
```
*(As barras `/` ao final de alguns nomes indicam que são diretórios de configurações de serviços específicos instalados).*

2. Verifique o seu diretório de trabalho atual:
```bash
administrador@ubuntu_server:/etc$ pwd
/etc
```

3. Exiba as últimas 10 linhas do arquivo de logs de autenticação do sistema localizado na árvore do `/var`:
```bash
administrador@ubuntu_server:/etc$ sudo tail -n 10 /var/log/auth.log
```
*(Este comando lê os registros dinâmicos de tentativas de login e elevações de privilégios com o `sudo` ocorridos no servidor).*

---

### Passo 2: Criação Recursiva de Diretórios Departamentais
Criaremos um cenário corporativo sob o diretório de serviços `/srv`. Precisamos criar duas pastas de departamentos distintas:
*   `/srv/ti-dept` (Diretório para equipe de Tecnologia)
*   `/srv/vendas-dept` (Diretório para equipe de Vendas)

Para criar os diretórios e seus subdiretórios internos de notas de uma única vez, utilizamos a flag recursiva **`-p` (parents)** do comando `mkdir`:

```bash
administrador@ubuntu_server:/etc$ cd /srv
administrador@ubuntu_server:/srv$ sudo mkdir -p ti-dept/projetos vendas-dept/relatorios
```

Para certificar-se de que a árvore de diretórios foi criada com sucesso, liste o diretório `/srv` de forma recursiva:
```bash
administrador@ubuntu_server:/srv$ ls -R
.:
ti-dept  vendas-dept

./ti-dept:
projetos

./vendas-dept:
relatorios
```

---

### Passo 3: Criação de Grupos Departamentais e Associação de Usuários
Para isolar o acesso às pastas dos departamentos, criaremos dois grupos locais no servidor:

```bash
administrador@ubuntu_server:/srv$ sudo groupadd ti-group
administrador@ubuntu_server:/srv$ sudo groupadd vendas-group
```

Agora, vamos adicionar nossos usuários de teste (criados na Aula 2) aos respectivos grupos correspondentes:
*   O usuário **`fulano`** pertencerá ao grupo **`ti-group`**.
*   O usuário **`cicrano`** pertencerá ao grupo **`vendas-group`**.

```bash
administrador@ubuntu_server:/srv$ sudo usermod -aG ti-group fulano
administrador@ubuntu_server:/srv$ sudo usermod -aG vendas-group cicrano
```
*(Nota: O usuário `novato` continuará sem grupo para representar o acesso externo geral).*

---

### Passo 4: Ajuste de Propriedades e Permissões de Isolamento
Atualmente, as pastas recém-criadas pertencem inteiramente ao usuário `root`:
```bash
administrador@ubuntu_server:/srv$ ls -ld ti-dept vendas-dept
drwxr-xr-x 3 root root 4096 Aug 19 14:35 ti-dept
drwxr-xr-x 3 root root 4096 Aug 19 14:35 vendas-dept
```

Para garantir a administração centralizada e o isolamento entre departamentos, configure as posses e permissões de forma estrita:

1. Altere o dono de `ti-dept` para o `administrador` e o grupo associado para `ti-group`:
```bash
administrador@ubuntu_server:/srv$ sudo chown administrador:ti-group ti-dept
```

2. Altere o dono de `vendas-dept` para o `administrador` e o grupo associado para `vendas-group`:
```bash
administrador@ubuntu_server:/srv$ sudo chown administrador:vendas-group vendas-dept
```

3. Aplique a política de isolamento absoluto em formato octal (**`770`**) em ambas as pastas departamentais. Isso garante que apenas o administrador e os membros do grupo do departamento possam ler, gravar ou navegar na pasta, bloqueando qualquer outro usuário do sistema:
```bash
administrador@ubuntu_server:/srv$ sudo chmod 770 ti-dept
administrador@ubuntu_server:/srv$ sudo chmod 770 vendas-dept
```

4. Aplique a alteração de propriedade e permissões de forma **recursiva** (flag `-R`) nas subpastas e arquivos internos para que herdem a mesma regra de segurança:
```bash
administrador@ubuntu_server:/srv$ sudo chown -R administrador:ti-group ti-dept/
```

Valide as alterações realizadas:
```bash
administrador@ubuntu_server:/srv$ ls -ld ti-dept vendas-dept
drwxrwx--- 3 administrador ti-group     4096 Aug 19 14:35 ti-dept
drwxrwx--- 3 administrador vendas-group 4096 Aug 19 14:35 vendas-dept
```
As máscaras de acesso foram alteradas com sucesso para **`drwxrwx---`**!

---

### Passo 5: Criação de Arquivos de Testes Internos
Crie um arquivo confidencial de teste dentro da pasta de Tecnologia:
```bash
administrador@ubuntu_server:/srv$ sudo touch ti-dept/projetos/arquitetura_rede_vpn.txt
```

Altere as posses do arquivo interno para que o grupo possa manipulá-lo livremente e aplique a permissão octal **`660`** (Dono e Grupo leem e escrevem, Outros sem qualquer acesso):
```bash
administrador@ubuntu_server:/srv$ sudo chown administrador:ti-group ti-dept/projetos/arquitetura_rede_vpn.txt
administrador@ubuntu_server:/srv$ sudo chmod 660 ti-dept/projetos/arquitetura_rede_vpn.txt
```

---

## 4. Testes e Validação de Isolamento no Laboratório

Para testar o isolamento das pastas corporativas sem precisar desligar o console ou efetuar logouts físicos no servidor, utilizaremos o comando `su` (substitute user).

> ### 🔍 Observação Técnica de Extrema Importância: `su <usuario>` vs `su - <usuario>`
> Nos laboratórios práticos, é muito comum cometer o erro de digitar apenas `su administrador` ou `su fulano`. Contudo, há uma diferença sutil, mas crítica, no comportamento do sistema:
> 
> *   **`su nome_usuario` (sem o hífen):** Altera a identidade do usuário atual no terminal, mas **preserva o diretório de trabalho anterior e as variáveis de ambiente** (como `PATH`, `HOME` e `SHELL`) do usuário de origem. Você assume a identidade do novo usuário, mas continua operando "dentro do contexto" e do caminho de diretórios do usuário anterior.
> *   **`su - nome_usuario` (com o hífen):** Realiza uma **sessão de login completa (Login Shell)**. O sistema limpa as variáveis antigas, altera o diretório atual diretamente para a pasta pessoal (`/home/nome_usuario`) do novo usuário e carrega todos os scripts de inicialização específicos dele (como `.bashrc` e `.profile`).
> 
> **Por que sempre usamos `su -` nos testes?**
> Para testar permissões de diretórios com isolamento real, precisamos que o sistema carregue o ambiente limpo do usuário. Se usarmos apenas `su`, o terminal tentará manter o diretório atual do usuário anterior, o que pode gerar mensagens de erro confusas ou falsos positivos de acesso devido ao contexto herdado.

---

### Teste A: Validação com Usuário Membro do Grupo (`fulano`)
1. Alterne a identidade para o usuário `fulano` utilizando o shell de login completo:
```bash
administrador@ubuntu_server:/srv$ su - fulano
Password: [digite a senha configurada]
fulano@ubuntu_server:~$ 
```

2. Verifique o seu diretório de login automático. Note que ele inicia diretamente em sua `/home`:
```bash
fulano@ubuntu_server:~$ pwd
/home/fulano
```

3. Tente navegar até a pasta confidencial do seu departamento (`ti-dept`) e listar o arquivo criado:
```bash
fulano@ubuntu_server:~$ cd /srv/ti-dept
fulano@ubuntu_server:/srv/ti-dept$ ls -l projetos/
-rw-rw---- 1 administrador ti-group 0 Aug 19 14:35 arquitetura_rede_vpn.txt
```
*(Sucesso! O usuário pertence ao grupo `ti-group`, possuindo livre acesso de navegação e leitura).*

---

### Teste B: Validação de Bloqueio com Usuário Externo (`cicrano`)
1. Saia da sessão atual do usuário `fulano`:
```bash
fulano@ubuntu_server:/srv/ti-dept$ exit
logout
administrador@ubuntu_server:/srv$ 
```

2. Alterne agora para o login de **`cicrano`** (que pertence à equipe de vendas):
```bash
administrador@ubuntu_server:/srv$ su - cicrano
Password: [digite a senha de cicrano]
cicrano@ubuntu_server:~$ 
```

3. Tente forçar a navegação e leitura dentro do diretório do departamento de Tecnologia:
```bash
cicrano@ubuntu_server:~$ cd /srv/ti-dept
-bash: cd: /srv/ti-dept: Permission denied
```
*(Excelente! O sistema operacional barrou o acesso com o erro de permissão negada, validando o isolamento entre departamentos).*

4. Saia da sessão do usuário `cicrano`:
```bash
cicrano@ubuntu_server:~$ exit
logout
administrador@ubuntu_server:/srv$ 
```

---

## 5. Roteiro Prático: Desafio de Laboratório (3 horas)

Para consolidar as competências adquiridas nesta aula, execute o seguinte desafio autônomo e registre os comandos e capturas de telas no seu relatório:

1.  Crie uma nova pasta de diretoria localizada em: `/srv/diretoria-dept`.
2.  Crie um novo grupo no sistema denominado `diretoria-group`.
3.  Adicione o usuário **`beltrano`** a este novo grupo de diretoria.
4.  Configure as propriedades de modo que o diretório `/srv/diretoria-dept` pertença ao usuário `administrador` e ao grupo `diretoria-group`.
5.  Aplique a permissão numérica que dê controle total ao dono, controle total ao grupo e proíba qualquer visualização ou navegação de usuários externos.
6.  Crie um arquivo confidencial `orcamento_ti.txt` dentro da nova pasta, configurando as posses e permissões adequadas de leitura e escrita apenas para a diretoria.
7.  Teste o acesso com o usuário `beltrano` (sucesso esperado) e tente o acesso com `fulano` (bloqueio esperado). Documente as saídas obtidas.

---

## 6. Modelo de Relatório Técnico (Entrega via GitHub)

O relatório individual do aluno deve ser adicionado ao seu repositório pessoal `labredes-bsi-2026.02` no GitHub, estruturado no modelo de 7 passos oficial:

1.  **Identificação:** Nome completo, matrícula, turma e data da prática.
2.  **Objetivo:** O que foi praticado nesta aula (FHS, navegação, criação com `mkdir -p` e permissões de diretórios).
3.  **Ambiente:** Versão do Ubuntu Server, hardware virtual e diretórios de trabalhos locais.
4.  **Procedimento:** Descrição passo a passo dos comandos aplicados na criação da estrutura, configuração de grupos e alteração de permissões corporativas.
5.  **Testes:** Captura das telas ou cópia das saídas de terminal dos testes de validação A (sucesso) e B (bloqueio `Permission denied` ao tentar navegar no diretório de TI).
6.  **Problemas e Soluções:** Registro de eventuais dificuldades (como confusão no uso de `su` vs `su -`) e como corrigiu.
7.  **Conclusão:** Síntese do aprendizado teórico-prático sobre conexões e segurança local de arquivos no Linux.
