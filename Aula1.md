# Aula Prática 01: Introdução à Virtualização e Instalação do Ubuntu Server 26.04

## 1. Objetivos da Aula
* Compreender os conceitos básicos de virtualização (Hipervisor, Máquina Virtual, Isolamento de Recursos).
* Preparar o ambiente de trabalho local utilizando o Oracle VM VirtualBox.
* Realizar a instalação limpa e personalizada do sistema operacional de rede Ubuntu Server 26.04 LTS utilizando particionamento LVM.
* Validar a instalação por meio do primeiro login e atualização dos repositórios de pacotes.

---

## 2. Preparação do Ambiente de Trabalho (Host Windows)
Para garantir a organização e o desempenho dos computadores do laboratório, utilizaremos o drive `C:` local das máquinas host. Siga rigorosamente a estrutura de diretórios abaixo:

1. **Obter a Imagem ISO:**
   * Pressione as teclas `Win + R` no teclado do Windows.
   * Digite o caminho do servidor de arquivos do laboratório: `\\172.20.22.179\labredes` e pressione Enter.
   * Copie o arquivo de imagem `ubuntu-26.04-live-server-amd64.iso` para a sua máquina física.

2. **Organização de Pastas no Host:**
   * Crie o diretório de originais: `C:\2026\BSI\VM\original`.
   * Mova a imagem ISO copiada para este diretório: `C:\2026\BSI\VM\original\ubuntu-26.04-live-server-amd64.iso`.
   * Crie o diretório de trabalho do aluno: `C:\2026\BSI\VM\<NomeDoAluno>` (substitua `<NomeDoAluno>` pelo seu primeiro e último nome, sem espaços ou acentos).
   * Dentro da sua pasta, crie a subpasta para a máquina virtual: `C:\2026\BSI\VM\<NomeDoAluno>\ubuntu_server`.

---

## 3. Criação e Configuração da VM no VirtualBox
Abra o Oracle VM VirtualBox e clique em **Novo** para configurar a máquina virtual com os seguintes parâmetros:

* **Nome:** `ubuntu_server`
* **Pasta da VM:** `C:\2026\BSI\VM\<NomeDoAluno>\ubuntu_server`
* **Tipo:** `Linux`
* **Versão:** `Ubuntu (64-bit)`
* **Tamanho de Memória (RAM):** `512 MB`
* **Processador:** `1 CPU`
* **Disco Rígido:** Escolha "Criar um novo disco rígido virtual agora".
  * **Tipo de arquivo:** `VDI (VirtualBox Disk Image)`
  * **Armazenamento:** `Dinamicamente Alocado`
  * **Tamanho:** `32 GB`

---

## 4. Instalação Passo a Passo do Ubuntu Server
Com a VM criada, clique em **Configurações** -> **Armazenamento**. Em "Controladora: IDE", selecione o ícone de disco óptico vazio e monte o arquivo ISO localizado em `C:\2026\BSI\VM\original\ubuntu-26.04-live-server-amd64.iso`.

Inicie a máquina virtual e execute os seguintes passos no instalador interativo:

### 4.1. Idioma e Teclado
* **Language:** Selecione `English` (recomendado para servidores).
* **Keyboard Configuration:** Em Layout e Variant, configure para `Portuguese (Brazil)` ou o layout correspondente ao teclado físico do seu terminal.

### 4.2. Conexão de Rede
* O instalador identificará a interface `enp0s3` e tentará obter uma configuração de rede padrão automaticamente via DHCP.
* Verifique se ela exibe um endereço IP no formato `10.0.2.15/24` ou similar antes de avançar.

### 4.3. Proxy e Mirror
* **Proxy:** Deixe em branco (Apenas clique em `Done`).
* **Mirror:** Mantenha o endereço padrão do espelho do Ubuntu e clique em `Done`.

### 4.4. Particionamento do Sistema de Arquivos (Customizado LVM)
Não utilizaremos a instalação automática em disco inteiro. Selecione a opção **Custom storage layout** (ou manual) para criarmos um esquema de particionamento flexível utilizando LVM (Logical Volume Manager):

Criaremos as seguintes partições:
1. **Partição de Boot (/boot):**
   * **Tamanho:** `1 GB` (1024M)
   * **Formato:** `ext4`
   * **Ponto de Montagem:** `/boot`

2. **Grupo de Volumes LVM (ubuntu-vg):**
   * Crie o Volume Group com o restante do espaço em disco.

3. **Volume Lógico Root (/):**
   * **Nome:** `ubuntu-lv`
   * **Tamanho:** `29 GB`
   * **Formato:** `ext4`
   * **Ponto de Montagem:** `/`

4. **Volume Lógico Swap (SWAP):**
   * **Nome:** `swap-lv` (ou similar)
   * **Tamanho:** `2 GB` (ou o restante do espaço livre de ~2GB)
   * **Formato:** `swap`

*Selecione `Done` e confirme a gravação das alterações no disco.*

### 4.5. Configuração de Perfil (Profile Setup)
Insira as seguintes credenciais obrigatórias para padronização do laboratório:
* **Your name:** `Administrador`
* **Your server's name:** `ubuntu_server`
* **Pick a username:** `administrador` *(Não utilize "redes" ou "aluno")*
* **Choose a password:** `adminifal`
* **Confirm your password:** `adminifal`

### 4.6. Serviços Adicionais (SSH)
* Na tela de SSH, marque a opção **[X] Install OpenSSH Server** pressionando a barra de espaço. Isso é crucial para as práticas de acesso remoto futuras.
* Na tela de snaps adicionais, não selecione nenhum serviço. Prossiga e aguarde a conclusão da instalação.
* Quando finalizar, selecione **Reboot Now** e pressione Enter quando o instalador solicitar a remoção da mídia de instalação.

---

## 5. Pós-Instalação e Validação
Após o reboot, faça login com o usuário criado:
```bash
ubuntu_server login: administrador
Password: <digite adminifal - não aparecerá na tela>
```

Execute a atualização inicial do catálogo de pacotes do sistema:
```bash
sudo apt-get update
```

No computador host (máquina física Windows), certifique-se de que o **VirtualBox Extension Pack** correspondente à versão instalada esteja devidamente instalado para garantir a compatibilidade de drivers e USB.

---

## 6. Relatório Técnico (Entrega via GitHub)
Cada grupo ou aluno individual deverá documentar esta prática criando um repositório pessoal no GitHub e adicionando um arquivo chamado `README.md` estruturado com os 7 tópicos abaixo:

1. **Identificação:** Nome completo, curso, turma, data e título da prática.
2. **Objetivo:** Descrição curta do que foi executado e sua finalidade prática.
3. **Ambiente:** Especificação de hardware físico (Host), versão do VirtualBox, versão da ISO do S.O. e configurações da VM.
4. **Procedimento:** Passo a passo resumido com foco nos pontos críticos (particionamento LVM e criação do usuário administrador).
5. **Testes e Validação:** Evidências de sucesso, como a saída dos comandos `ip addr`, `df -h` (para ver o particionamento real) e `sudo apt-get update`.
6. **Problemas e Soluções:** Registro de quaisquer erros enfrentados (ex: travamento de ISO, erro de digitação de senha) e como foram corrigidos.
7. **Conclusão:** Síntese sobre o aprendizado adquirido sobre virtualização nesta aula prática.
