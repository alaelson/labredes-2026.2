# Laboratório de Sistemas Operacionais e Redes (LSOR) — BSI 2026.02

Repositório oficial para a organização e acompanhamento das práticas de laboratório da disciplina **Laboratório de Sistemas Operacionais e Redes (LSOR)** do curso de **Bacharelado em Sistemas de Informação (BSI)** no **Instituto Federal de Alagoas (IFAL) - Campus Maceió**, para o semestre letivo **2026.02**.

Esta disciplina tem natureza eminentemente prática e aplicada, na qual cada conceito de redes e sistemas operacionais é transformado em configuração, teste, diagnóstico e documentação técnica.

---

## 💻 Informações Gerais do Laboratório

Para manter a padronização das práticas, a compatibilidade de redes e a segurança nos testes, adotamos as seguintes diretrizes de ambiente de hardware e credenciais:

*   **Hipervisor:** [VirtualBox](https://www.virtualbox.org/) (com o respetivo *Extension Pack* instalado no hospedeiro).
*   **Sistema Operacional Guest:** Ubuntu Server 26.04 LTS (64-bit).
*   **Hardware Padrão da VM:** 512 MB de Memória RAM, 1 CPU Virtual e 32 GB de Disco Rígido (VDI, Alocação Dinâmica).
*   **Usuário Administrativo Padrão:**  *(Nota: o usuário 'redes' do semestre anterior não é utilizado neste laboratório)*.
*   **Senha de Laboratório:** .

### 📁 Estrutura de Diretórios no Host (Windows do Laboratório)
*   **Diretório de ISOs originais:** .
*   **Diretório de Trabalho do Aluno:** .
*   **Servidor de Arquivos da Rede (Acesso a ISO/VM):**  (Usuário:  | Senha: )

---

## 📚 Roteiros das Aulas Práticas e Exercícios

Os links abaixo apontam para os roteiros detalhados de cada prática realizada em laboratório, bem como os exercícios para fixação de conteúdo.

1.  **[Aula 01: Instalação e Configuração Básica do Ubuntu Server](Aula1.md)**
    *   Cópia da ISO a partir do compartilhamento local  para .
    *   Criação de VM no VirtualBox.
    *   Particionamento avançado de disco usando LVM:  (29 GB),  (1 GB) e  (2 GB).
    *   Primeiro boot, atualização de repositórios (Ign:1 http://deb.debian.org/debian bookworm InRelease
Ign:2 https://deb.nodesource.com/node_22.x nodistro InRelease
Ign:3 http://deb.debian.org/debian bookworm-updates InRelease
Ign:4 http://deb.debian.org/debian-security bookworm-security InRelease
Ign:2 https://deb.nodesource.com/node_22.x nodistro InRelease
Ign:1 http://deb.debian.org/debian bookworm InRelease
Ign:3 http://deb.debian.org/debian bookworm-updates InRelease
Ign:4 http://deb.debian.org/debian-security bookworm-security InRelease
Ign:2 https://deb.nodesource.com/node_22.x nodistro InRelease
Ign:1 http://deb.debian.org/debian bookworm InRelease
Ign:3 http://deb.debian.org/debian bookworm-updates InRelease
Ign:4 http://deb.debian.org/debian-security bookworm-security InRelease
Err:2 https://deb.nodesource.com/node_22.x nodistro InRelease
  Temporary failure resolving 'deb.nodesource.com'
Err:1 http://deb.debian.org/debian bookworm InRelease
  Temporary failure resolving 'deb.debian.org'
Err:3 http://deb.debian.org/debian bookworm-updates InRelease
  Temporary failure resolving 'deb.debian.org'
Err:4 http://deb.debian.org/debian-security bookworm-security InRelease
  Temporary failure resolving 'deb.debian.org'
Reading package lists...) e verificação de conectividade básica.
2.  **[Aula 02: Administração de Usuários, Grupos e Permissões](Aula2.md)**
    *   Criação e gerenciamento de contas de usuários (, ,  e ).
    *   Criação de grupos de trabalho () e atribuição de membros.
    *   Configuração fina de permissões em diretórios compartilhados (, , ).
    *   Testes de controle de acesso local e isolamento de segurança.
3.  **[Aula 03: Estrutura de Diretórios, Pastas do Sistema e Permissões FHS](Aula3.md)**
    *   Navegação e utilidade das pastas do padrão FHS (, , , , , etc.).
    *   Criação recursiva de diretórios aninhados corporativos usando .
    *   Aplicação de permissões avançadas de segurança ( / ) em grupos organizacionais (, ).
    *   Simulação de restrição de navegação e tratativas de segurança de arquivos no Linux.
    *   **[Exercícios de Revisão — Aulas 1, 2 e 3 (Google Forms)](Exercicios-Aula3.md)**: Lista completa de exercícios integrados de fixação para autoavaliação.
4.  **[Aula 04: Manipulação, Edição, Permissões e Automação de Arquivos](Aula4.md)**
    *   Edição de texto no terminal com os editores Nano e Vim (modos, comandos e atalhos de salvamento).
    *   Comandos práticos de manipulação (, , , ) e paginação/leitura de logs (, , , ).
    *   Automação administrativa: criação de scripts executáveis em shell (Bash) usando laço  para criação de usuários () e definição de senhas em lote ().
    *   Auditoria do sistema de contas e grupos locais usando o utilitário Try `getent --help' or `getent --usage' for more information. (root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin
_apt:x:42:65534::/nonexistent:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-network:x:998:998:systemd Network Management:/:/usr/sbin/nologin
messagebus:x:100:101::/nonexistent:/usr/sbin/nologin
sandbox:x:1000:1000::/home/sandbox:/bin/sh e root:x:0:
daemon:x:1:
bin:x:2:
sys:x:3:
adm:x:4:
tty:x:5:
disk:x:6:
lp:x:7:
mail:x:8:
news:x:9:
uucp:x:10:
man:x:12:
proxy:x:13:
kmem:x:15:
dialout:x:20:
fax:x:21:
voice:x:22:
cdrom:x:24:
floppy:x:25:
tape:x:26:
sudo:x:27:
audio:x:29:
dip:x:30:
www-data:x:33:
backup:x:34:
operator:x:37:
list:x:38:
irc:x:39:
src:x:40:
shadow:x:42:
utmp:x:43:
video:x:44:
sasl:x:45:
plugdev:x:46:
staff:x:50:
games:x:60:
users:x:100:
nogroup:x:65534:
systemd-journal:x:999:
systemd-network:x:998:
messagebus:x:101:
sandbox:x:1000:).
    *   **[Exercícios de Revisão — Aulas 1 a 4 (Google Forms)](Exercicios-Aula4.md)**: Lista completa de exercícios integrados de fixação para autoavaliação.
5.  **[Aula 05: Acesso Remoto SSH via Redirecionamento de Portas e Diagnóstico de Rede](Aula5.md)**
    *   Configuração do modo NAT no VirtualBox e regra de redirecionamento de portas (Porta Host  -> Porta Guest ).
    *   Inspeção de interfaces com ,  (Linux) e  (Windows).
    *   Diagnóstico de rotas e terminais com ,  e  22:14:12 up 0 min,  0 user,  load average: 0.00, 0.00, 0.00
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT.
    *   Análise de portas no PowerShell com  antes, depois e durante a conexão SSH.
6.  **[Aula 06: Configuração de Rede Estática com Netplan e Modo Placa em Ponte (Bridge Adapter)](Aula6.md)**
    *   Transição do adaptador VirtualBox para o modo Placa em Ponte (Bridge Adapter).
    *   Busca de IP livre a partir de  na sub-rede .
    *   Configuração de IP estático, gateway e DNS no arquivo oficial  ().
    *   Validação com , ,  bidirecional e .
7.  **[Aula 07: Roteamento e Gateway NAT com IPTables e Rede Interna no VirtualBox](Aula7.md)**
    *   Topologia com 2 VMs: VM1 (Gateway com Bridge e Rede Interna) e VM2 (Cliente exclusivo em Rede Interna).
    *   Configuração de rede interna ( na VM1 e  na VM2 apontando gateway ).
    *   Ativação de encaminhamento de pacotes () e mascaramento IPTables () na VM1.
    *   Bateria de testes de conectividade local e externa ( e  para  e  a partir da VM2).

---

### 📑 Avaliações da Disciplina
*   **[Avaliação Prático-Teórica I (Template de Entrega)](template-prova-1-v2.md)**: Atividade integrada de laboratório baseada na importação da VM  (disponível em ). Contém 10 questões que mesclam a prática de terminal com reflexões teóricas de administração de usuários, permissões, criação de dados estruturados JSON e automação de relatórios eleitorais via Shell Script ().

---

## 📝 Diretrizes para Entrega de Relatórios Técnicos

Como parte do comportamento profissional esperado na disciplina, todas as práticas de laboratório devem ser documentadas individualmente pelos alunos em seus respectivos repositórios pessoais no GitHub.

Os relatórios devem seguir estritamente o **Modelo de 7 Passos** estabelecido:

1.  **Identificação:** Nome completo, matrícula, turma, data e título da prática.
2.  **Objetivo:** Explicação clara do serviço ou configuração que se pretendia realizar.
3.  **Ambiente:** Detalhamento do cenário de testes (especificações da VM, endereços IP, etc.).
4.  **Procedimento:** Descrição passo a passo dos comandos executados e arquivos de configuração modificados.
5.  **Testes:** Evidências de funcionamento (capturas de tela, saídas de comandos como , , etc.).
6.  **Problemas e Soluções:** Registro de quaisquer erros encontrados durante a prática e como foram solucionados.
7.  **Conclusão:** Reflexão sobre o que foi validado e aprendido na atividade.

---

## 🛠️ Dicas de Laboratório e Solução de Problemas

*   **Teclado Desconfigurado no Console:** Caso o layout do seu teclado esteja incorreto no terminal virtual da VM, configure-o para o padrão brasileiro ABNT2 com o comando:
    
*   **Isolamento no VirtualBox:** Ao realizar configurações de rede interna, lembre-se de que o modo *Host-Only* permite que a sua máquina real acesse a máquina virtual, mas impede que ela acesse a internet pública diretamente sem um serviço de NAT ou roteamento ativado.

---

## 📖 Referências Bibliográficas Recomendadas

*   LACROIX, Jay. **Mastering Ubuntu Server**. 4. ed. Packt Publishing, 2023.
*   SOYINKA, Wale. **Linux Administration: A Beginner's Guide**. 8. ed. McGraw-Hill, 2020.
*   KUROSE, James F.; ROSS, Keith W. **Redes de Computadores e a Internet**. 8. ed. Pearson, 2022.
