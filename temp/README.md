# Laboratório de Sistemas Operacionais e Redes (LSOR) — BSI 2026.02

Repositório oficial para a organização e acompanhamento das práticas de laboratório da disciplina **Laboratório de Sistemas Operacionais e Redes (LSOR)** do curso de **Bacharelado em Sistemas de Informação (BSI)** no **Instituto Federal de Alagoas (IFAL) - Campus Maceió**, para o semestre letivo **2026.02**.

Esta disciplina tem natureza eminentemente prática e aplicada, na qual cada conceito de redes e sistemas operacionais é transformado em configuração, teste, diagnóstico e documentação técnica.

---

## 💻 Informações Gerais do Laboratório

Para manter a padronização das práticas, a compatibilidade de redes e a segurança nos testes, adotamos as seguintes diretrizes de ambiente de hardware e credenciais:

*   **Hipervisor:** [VirtualBox](https://www.virtualbox.org/) (com o respetivo *Extension Pack* instalado no hospedeiro).
*   **Sistema Operacional Guest:** Ubuntu Server 26.04 LTS (64-bit).
*   **Hardware Padrão da VM:** 512 MB de Memória RAM, 1 CPU Virtual e 32 GB de Disco Rígido (VDI, Alocação Dinâmica).
*   **Usuário Administrativo Padrão:** `administrador` *(Nota: o usuário 'redes' do semestre anterior não é utilizado neste laboratório)*.
*   **Senha de Laboratório:** `adminifal`.

### 📁 Estrutura de Diretórios no Host (Windows do Laboratório)
*   **Diretório de ISOs originais:** `C:\2026\BSI\VM\original`.
*   **Diretório de Trabalho do Aluno:** `C:\2026\BSI\VM\<NomeDoAluno>`.
*   **Servidor de Arquivos da Rede (Acesso a ISO):** `\\172.20.22.179\labredes`

---

## 📚 Roteiros das Aulas Práticas e Exercícios

Os links abaixo apontam para os roteiros detalhados de cada prática realizada em laboratório, bem como os exercícios para fixação de conteúdo.

1.  **[Aula 01: Instalação e Configuração Básica do Ubuntu Server](Aula1-v4.md)**
    *   Cópia da ISO a partir do compartilhamento local `\\172.20.22.179\labredes` para `C:\2026\BSI\VM\original`.
    *   Criação de VM no VirtualBox.
    *   Particionamento avançado de disco usando LVM: `/` (29 GB), `/boot` (1 GB) e `SWAP` (2 GB).
    *   Primeiro boot, atualização de repositórios (`apt-get update`) e verificação de conectividade básica.
2.  **[Aula 02: Administração de Usuários, Grupos e Permissões](Aula2-v4.md)**
    *   Criação e gerenciamento de contas de usuários (`fulano`, `cicrano`, `beltrano` e `novato`).
    *   Criação de grupos de trabalho (`devs`) e atribuição de membros.
    *   Configuração fina de permissões em diretórios compartilhados (`chown`, `chgrp`, `chmod`).
    *   Testes de controle de acesso local e isolamento de segurança.
3.  **[Aula 03: Estrutura de Diretórios, Pastas do Sistema e Permissões FHS](Aula3-v3.md)**
    *   Navegação e utilidade das pastas do padrão FHS (`/etc`, `/var`, `/srv`, `/bin`, `/sbin`, etc.).
    *   Criação recursiva de diretórios aninhados corporativos usando `mkdir -p`.
    *   Aplicação de permissões avançadas de segurança (`770` / `drwxrwx---`) em grupos organizacionais (`ti-dept`, `vendas-dept`).
    *   Simulação de restrição de navegação e tratativas de segurança de arquivos no Linux.
    *   **[Exercícios de Revisão — Aulas 1, 2 e 3 (Google Forms)](Exercicios-Aula3-v3.md)**: Lista completa de exercícios integrados de fixação para autoavaliação.
4.  *Aula 04: Configuração de Acesso Remoto Seguro com OpenSSH (Em breve)*
5.  *Aula 05: Conectividade Avançada via Rede Host-Only no VirtualBox (Em breve)*
6.  *Aula 06: Configuração de Nomes Estáticos de Host (Em breve)*
7.  *Aula 07: Implantação de Rede Virtual Privada com OpenVPN (Em breve)*

---

## 📝 Diretrizes para Entrega de Relatórios Técnicos

Como parte do comportamento profissional esperado na disciplina, todas as práticas de laboratório devem ser documentadas individualmente pelos alunos em seus respectivos repositórios pessoais no GitHub.

Os relatórios devem seguir estritamente o **Modelo de 7 Passos** estabelecido:

1.  **Identificação:** Nome completo, matrícula, turma, data e título da prática.
2.  **Objetivo:** Explicação clara do serviço ou configuração que se pretendia realizar.
3.  **Ambiente:** Detalhamento do cenário de testes (especificações da VM, endereços IP, etc.).
4.  **Procedimento:** Descrição passo a passo dos comandos executados e arquivos de configuração modificados.
5.  **Testes:** Evidências de funcionamento (capturas de tela, saídas de comandos como `ping`, `ip addr`, etc.).
6.  **Problemas e Soluções:** Registro de quaisquer erros encontrados durante a prática e como foram solucionados.
7.  **Conclusão:** Reflexão sobre o que foi validado e aprendido na atividade.

---

## 🛠️ Dicas de Laboratório e Solução de Problemas

*   **Teclado Desconfigurado no Console:** Caso o layout do seu teclado esteja incorreto no terminal virtual da VM, configure-o para o padrão brasileiro ABNT2 com o comando:
    ```bash
    sudo dpkg-reconfigure keyboard-configuration
    ```
*   **Isolamento no VirtualBox:** Ao realizar configurações de rede interna, lembre-se de que o modo *Host-Only* permite que a sua máquina real acesse a máquina virtual, mas impede que ela acesse a internet pública diretamente sem um serviço de NAT ou roteamento ativado.

---

## 📖 Referências Bibliográficas Recomendadas

*   LACROIX, Jay. **Mastering Ubuntu Server**. 4. ed. Packt Publishing, 2023.
*   SOYINKA, Wale. **Linux Administration: A Beginner's Guide**. 8. ed. McGraw-Hill, 2020.
*   KUROSE, James F.; ROSS, Keith W. **Redes de Computadores e a Internet**. 8. ed. Pearson, 2022.
