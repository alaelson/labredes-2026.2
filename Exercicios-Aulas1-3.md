# Banco de Questões — Revisão Prática (Aulas 1, 2 e 3)
## Disciplina: Laboratório de Sistemas Operacionais e Redes (LSOR) — BSI 2026.02
### Professor: Alaelson Jatobá

Este banco de questões foi atualizado e expandido para contemplar os conteúdos práticos e teóricos das **Aulas 1, 2 e 3**. Ele foi estruturado no formato ideal para copiar e colar diretamente no **Google Forms**, contendo as alternativas, a indicação da resposta correta e o feedback didático de cada questão para correção automática.

---

## 🛠️ SEÇÃO I: Configuração e Instalação do Ambiente (Aula 1)

### Questão 1
**Enunciado:** Para iniciar os trabalhos práticos no laboratório da disciplina, qual o caminho do compartilhamento de rede no Windows que o aluno deve acessar para copiar a imagem ISO original do Ubuntu Server 26.04?
*   [ ] A) `C:\2026\BSI\VM\original`
*   [ ] B) `\\172.20.22.179\redes`
*   [x] C) `\\172.20.22.179\labredes`
*   [ ] D) `\\172.20.22.179\original`

**Gabarito:** C
**Feedback Pedagógico:** O servidor de arquivos do laboratório hospeda a imagem ISO original do Ubuntu Server no caminho de compartilhamento Windows `\\172.20.22.179\labredes`. Os arquivos locais do aluno devem ficar armazenados no disco local `C:`.

---

### Questão 2
**Enunciado:** Ao criar uma nova Máquina Virtual (VM) no VirtualBox para o nosso servidor Linux de laboratório, quais são as configurações mínimas de hardware recomendadas no roteiro prático?
*   [ ] A) 1024 MB de RAM, 2 CPUs e 20 GB de Disco Rígido (VDI Estático).
*   [x] B) 512 MB de RAM, 1 CPU e 32 GB de Disco Rígido (VDI Alocação Dinâmica).
*   [ ] C) 512 MB de RAM, 1 CPU e 10 GB de Disco Rígido (VDI Estático).
*   [ ] D) 2048 MB de RAM, 1 CPU e 32 GB de Disco Rígido (VDI Alocação Dinâmica).

**Gabarito:** B
**Feedback Pedagógico:** Conforme o roteiro de laboratório, configuramos a VM com recursos otimizados para o ambiente acadêmico: 512 MB de RAM, 1 CPU e 32 GB de Disco Rígido no formato VDI com alocação dinâmica para economizar espaço físico na máquina hospedeira.

---

### Questão 3
**Enunciado:** Durante o processo de particionamento personalizado via LVM (Logical Volume Manager) na instalação do Ubuntu Server, quais são os tamanhos de partições que os alunos devem configurar, respectivamente, para a raiz (`/`), o diretório de inicialização (`/boot`) e a área de troca (`SWAP`)?
*   [ ] A) `/` com 32 GB, `/boot` com 512 MB e `SWAP` com 1 GB.
*   [ ] B) `/` com 30 GB, `/boot` com 1 GB e `SWAP` não é necessária.
*   [x] C) `/` com 29 GB, `/boot` com 1 GB e `SWAP` com 2 GB.
*   [ ] D) `/` com 20 GB, `/boot` com 2 GB e `SWAP` com 10 GB.

**Gabarito:** C
**Feedback Pedagógico:** O layout de particionamento padrão do laboratório exige a divisão do disco virtual de 32 GB em 3 partições essenciais: `/` com 29 GB, `/boot` com 1 GB e `SWAP` com 2 GB, para fins de flexibilidade lógica e segurança de dados.

---

### Questão 4
**Enunciado:** No processo de configuração de perfil (*Profile setup*) durante a instalação do Ubuntu Server 26.04 no laboratório do semestre 2026.02, quais credenciais padrão devem ser utilizadas?
*   [ ] A) Nome de usuário `redes` com a senha `adminifal`.
*   [x] B) Nome de usuário `administrador` com a senha `adminifal`.
*   [ ] C) Nome de usuário `aluno` com a senha `ifalredes`.
*   [ ] D) Nome de usuário `root` com a senha vazia.

**Gabarito:** B
**Feedback Pedagógico:** No semestre 2026.02, o laboratório adotou o nome de usuário administrativo padrão `administrador` com a senha `adminifal`. O usuário `redes` utilizado em períodos anteriores foi descontinuado.

---

### Questão 5
**Enunciado:** Após concluir a instalação do sistema operacional e realizar o primeiro login no terminal, qual comando o aluno deve executar para sincronizar os índices dos repositórios de pacotes do Ubuntu antes de instalar novos serviços?
*   [ ] A) `sudo apt-get upgrade`
*   [ ] B) `sudo apt-get install openvpn`
*   [x] C) `sudo apt-get update`
*   [ ] D) `sudo reboot`

**Gabarito:** C
**Feedback Pedagógico:** O comando `sudo apt-get update` é o responsável por baixar as informações atualizadas de pacotes das fontes de software oficiais, garantindo que o gerenciador de pacotes saiba quais versões mais recentes estão disponíveis.

---

## 👥 SEÇÃO II: Administração de Usuários, Grupos e Permissões (Aula 2)

### Questão 6
**Enunciado:** Um aluno precisa criar quatro novas contas de usuários para a prática de laboratório: `fulano`, `cicrano`, `beltrano` e `novato`. Qual comando interativo cria uma conta e já solicita a definição de senha, criação do diretório `/home` e preenchimento dos dados do usuário?
*   [ ] A) `sudo useradd fulano`
*   [x] B) `sudo adduser fulano`
*   [ ] C) `sudo groupadd fulano`
*   [ ] D) `sudo passwd fulano`

**Gabarito:** B
**Feedback Pedagógico:** O comando `adduser` é um script amigável de alto nível que cria o diretório home, copia os arquivos esqueleto, solicita interativamente uma senha e os dados do usuário. O comando `useradd` é de baixo nível e não define senha ou pasta pessoal por padrão, a menos que parâmetros adicionais sejam inseridos.

---

### Questão 7
**Enunciado:** Para fins de trabalho compartilhado em laboratório, foi criado o grupo `devs`. Qual comando abaixo adiciona o usuário `fulano` a esse grupo secundário mantendo-o nos demais grupos que já fazia parte?
*   [ ] A) `sudo usermod -g devs fulano`
*   [x] B) `sudo usermod -aG devs fulano`
*   [ ] C) `sudo useradd -g devs fulano`
*   [ ] D) `sudo chgrp devs fulano`

**Gabarito:** B
**Feedback Pedagógico:** O utilitário `usermod` com o parâmetro `-aG` (append e Group) adiciona o usuário a um novo grupo complementar sem removê-lo dos grupos aos quais ele já pertencia. O uso de `-g` (minúsculo) altera o grupo primário, removendo a associação antiga.

---

### Questão 8
**Enunciado:** Analise o seguinte cenário de permissões em um diretório chamado `/srv/projeto` no console do servidor:
```bash
administrador@ubuntu-server:~$ ls -ld /srv/projeto
drwxrwx--- 2 administrador devs 4096 Aug 12 14:30 /srv/projeto
```
O usuário `novato` **não** pertence ao grupo `devs`. O que acontece quando ele tenta acessar a pasta com o comando `cd /srv/projeto`?
*   [ ] A) O acesso é concedido temporariamente através de privilégios de convidado.
*   [ ] B) O sistema solicita a senha de root para autorizar a entrada.
*   [x] C) O acesso é bloqueado e o console exibe a mensagem: `-bash: cd: /srv/projeto: Permission denied`.
*   [ ] D) O usuário consegue entrar e listar os arquivos, mas não consegue criar novos arquivos.

**Gabarito:** C
**Feedback Pedagógico:** As permissões octais do diretório são `770` (`drwxrwx---`), o que significa: Dono (`administrador`) tem permissão total (`rwx`), Grupo (`devs`) tem permissão total (`rwx`) e Outros (*others*) não possuem nenhuma permissão (`---`). Como `novato` não é o dono e não pertence ao grupo `devs`, ele é enquadrado em Outros e tem seu acesso completamente negado.

---

### Questão 9
**Enunciado:** Qual o comando correto para alterar simultaneamente o dono de um diretório `/srv/projeto` para `administrador` e o grupo associado para `devs`?
*   [ ] A) `sudo chown administrador /srv/projeto` e depois `sudo chgrp devs /srv/projeto`
*   [ ] B) `sudo chgrp administrador:devs /srv/projeto`
*   [ ] C) `sudo chmod 770 administrador:devs /srv/projeto`
*   [x] D) `sudo chown administrador:devs /srv/projeto`

**Gabarito:** D
**Feedback Pedagógico:** O comando `chown` permite alterar tanto o usuário proprietário quanto o grupo proprietário de um arquivo ou diretório de uma única vez utilizando a sintaxe `usuario:grupo`.

---

## 📁 SEÇÃO III: Estrutura de Diretórios, Pastas do Sistema e FHS (Aula 3)

### Questão 10
**Enunciado:** O padrão FHS (Filesystem Hierarchy Standard) define o propósito e o local de cada tipo de arquivo em sistemas Linux. Em qual diretório do sistema o administrador deve procurar pelos arquivos de configuração locais de serviços de rede e do sistema operacional (como as configurações de rede, SSH ou do OpenVPN)?
*   [ ] A) `/var`
*   [x] B) `/etc`
*   [ ] C) `/srv`
*   [ ] D) `/sbin`

**Gabarito:** B
**Feedback Pedagógico:** O diretório `/etc` é reservado exclusivamente para os arquivos de configuração locais e globais do sistema operacional e dos serviços de rede instalados.

---

### Questão 11
**Enunciado:** Um administrador precisa criar a árvore de subdiretórios `/srv/ti/suporte/infra` de uma única vez, sabendo que as pastas intermediárias (`ti` e `suporte`) ainda não existem no servidor. Qual parâmetro do comando `mkdir` permite criar esses caminhos aninhados de forma recursiva sem gerar erros?
*   [ ] A) `mkdir -r /srv/ti/suporte/infra`
*   [x] B) `mkdir -p /srv/ti/suporte/infra`
*   [ ] C) `mkdir -v /srv/ti/suporte/infra`
*   [ ] D) `mkdir -f /srv/ti/suporte/infra`

**Gabarito:** B
**Feedback Pedagógico:** O parâmetro `-p` (parents) do comando `mkdir` instrui o sistema a criar todas as pastas intermediárias/pais necessárias ao longo do caminho especificado caso elas ainda não existam, sem apresentar mensagens de erro.

---

### Questão 12
**Enunciado:** De acordo com as definições do padrão FHS do Linux, qual a finalidade principal do diretório `/var` no sistema operacional?
*   [ ] A) Armazenar executáveis de comandos essenciais do sistema.
*   [ ] B) Guardar os arquivos de dados locais que pertencem aos usuários comuns.
*   [x] C) Armazenar arquivos de dados variáveis, como logs do sistema, filas de spool e arquivos temporários de serviços.
*   [ ] D) Servir como ponto de montagem temporário para mídias removíveis (CD-ROMs/USB).

**Gabarito:** C
**Feedback Pedagógico:** O diretório `/var` (*variable*) é destinado a guardar dados dinâmicos e que crescem constantemente ao longo do tempo durante a operação do sistema, como os registros de logs (`/var/log`), filas de e-mail e caches de pacotes.

---

### Questão 13
**Enunciado:** Analise as permissões de leitura (`r`), escrita (`w`) e execução (`x`) exibidas a seguir:
```bash
drwxr-xr-x 5 administrador ti-dept 4096 Aug 19 14:00 /srv/ti
```
O que os membros do grupo `ti-dept` podem fazer neste diretório?
*   [ ] A) Podem ler, gravar arquivos e executar scripts no diretório (permissão total).
*   [x] B) Podem ler e listar o conteúdo, além de entrar no diretório, mas não têm permissão para criar, modificar ou apagar arquivos.
*   [ ] C) Não possuem qualquer tipo de acesso ao diretório.
*   [ ] D) Podem apenas renomear o diretório, mas não ver seu conteúdo.

**Gabarito:** B
**Feedback Pedagógico:** As permissões para o grupo (caracteres do meio: `r-x`) concedem apenas leitura (`r` para listar conteúdo com `ls`) e execução (`x` para acessar a pasta com `cd`). A falta da permissão de escrita (`w` representado por `-`) impede que os membros do grupo criem ou modifiquem arquivos neste diretório.

---

### Questão 14
**Enunciado:** Um aluno precisa alterar recursivamente (ou seja, aplicando a pasta e a todos os seus subdiretórios e arquivos internos) as permissões de acesso do grupo do diretório `/srv/ti` para que todos pertençam ao grupo `ti-dept`. Qual comando executa essa tarefa corretamente?
*   [ ] A) `sudo chown ti-dept /srv/ti`
*   [ ] B) `sudo chgrp ti-dept /srv/ti`
*   [x] C) `sudo chgrp -R ti-dept /srv/ti`
*   [ ] D) `sudo chmod -R 770 /srv/ti`

**Gabarito:** C
**Feedback Pedagógico:** O comando `chgrp` altera o grupo proprietário de arquivos e pastas. O uso da opção `-R` (recursivo, em maiúsculo) garante que a alteração se propague para todas as pastas, subpastas e arquivos contidos abaixo do caminho indicado.

---

### Questão 15
**Enunciado:** O padrão FHS separa os binários executáveis das ferramentas do sistema entre as pastas `/bin` e `/sbin`. Qual é a diferença conceitual e operacional básica entre esses dois diretórios no Linux?
*   [ ] A) `/bin` armazena códigos em linguagem de máquina (binários compilados) e `/sbin` armazena scripts em shell.
*   [ ] B) `/bin` armazena arquivos temporários e `/sbin` armazena os arquivos estáticos de inicialização.
*   [x] C) `/bin` armazena comandos utilitários acessíveis a todos os usuários do sistema, enquanto `/sbin` armazena executáveis administrativos voltados para a manutenção e que geralmente exigem privilégios de superusuário (`root` ou `sudo`).
*   [ ] D) `/bin` armazena utilitários locais instalados manualmente e `/sbin` armazena comandos oficiais nativos do kernel.

**Gabarito:** C
**Feedback Pedagógico:** A pasta `/bin` guarda utilitários gerais que todos os usuários normais usam rotineiramente (ex: `ls`, `cd`, `mkdir`). A pasta `/sbin` (*system binaries*) armazena ferramentas cruciais do sistema usadas para administração, formatação de discos, firewall e roteamento, que necessitam de privilégios elevados para alterarem o estado da máquina.
