# Aula 04: Manipulação, Edição, Permissões e Automação de Arquivos no Linux

Nesta aula prática de laboratório, você aprenderá a manipular, visualizar e editar arquivos diretamente através do terminal do Ubuntu Server 26.04 LTS. Além disso, daremos os primeiros passos em automação de tarefas administrativas criando scripts em Shell para criação e gerenciamento de contas de usuários em lote.

---

## 1. Fundamentos Técnicos: Edição e Visualização de Arquivos

Em servidores Linux, a maior parte das configurações de serviços é armazenada em arquivos de texto simples. Dominar os editores de texto de terminal e os comandos de manipulação é uma habilidade fundamental para qualquer administrador de sistemas.

### Editores de Texto no Terminal

*   **Nano:** Um editor simples, intuitivo e muito ágil para edições rápidas. Seus atalhos são exibidos na parte inferior da tela (o símbolo `^` representa a tecla `Ctrl`).
    *   `Ctrl + O`: Salvar o arquivo (Gravar).
    *   `Ctrl + X`: Sair do editor.
    *   `Ctrl + W`: Buscar um texto dentro do arquivo.
*   **Vim (Vi Improved):** Um editor extremamente poderoso e eficiente, amplamente utilizado por profissionais de infraestrutura. Ele opera em modos:
    *   **Modo de Comando (padrão):** Onde as teclas executam ações de navegação e edição. Pressione `Esc` para retornar a este modo.
    *   **Modo de Inserção:** Permite digitar texto. Para entrar, pressione a tecla `i`.
    *   **Como Salvar e Sair no Vim:** Pressione `Esc` para ir ao modo de comando, digite `:` e em seguida:
        *   `w`: Gravar/salvar.
        *   `q`: Sair.
        *   `wq`: Salvar e sair.
        *   `q!`: Sair sem salvar as alterações.

### Comandos de Leitura e Visualização

Ao lidar com arquivos extensos ou logs do sistema, utilize ferramentas apropriadas para evitar poluir o terminal:
*   **`cat`:** Exibe o conteúdo completo do arquivo de uma só vez. Ideal para arquivos pequenos.
*   **`less`:** Permite navegar por arquivos grandes página por página usando as setas do teclado. Pressione `q` para sair.
*   **`head -n X`:** Exibe apenas as primeiras `X` linhas de um arquivo.
*   **`tail -n X`:** Exibe apenas as últimas `X` linhas de um arquivo. Muito usado com a opção `-f` (`tail -f <arquivo>`) para monitorar novos logs em tempo real.

---

## 2. Manipulação de Arquivos e Diretórios

No terminal, execute os comandos a seguir com seu usuário `administrador` para praticar a criação, cópia, movimentação e remoção segura de arquivos:

### Passo 2.1: Criação e Edição Básica
1.  Crie um arquivo de texto vazio usando o comando `touch`:
    ```bash
    administrador@ubuntu_server:~$ touch configuracao.conf
    ```
2.  Abra o arquivo com o editor Nano:
    ```bash
    administrador@ubuntu_server:~$ nano configuracao.conf
    ```
3.  Insira as linhas abaixo, salve com `Ctrl + O` e saia com `Ctrl + X`:
    ```text
    # Configuração de Teste do Laboratório
    PORTA=8080
    TIMEOUT=30
    ```

### Passo 2.2: Cópia e Movimentação
1.  Crie uma pasta chamada `backups` no seu diretório home:
    ```bash
    administrador@ubuntu_server:~$ mkdir backups
    ```
2.  Copie o arquivo criado para dentro da pasta `backups` usando `cp`:
    ```bash
    administrador@ubuntu_server:~$ cp configuracao.conf backups/
    ```
3.  Mova (ou renomeie) o arquivo original do seu diretório atual para `config_antiga.conf` usando `mv`:
    ```bash
    administrador@ubuntu_server:~$ mv configuracao.conf config_antiga.conf
    ```

### Passo 2.3: Remoção Segura
1.  Para evitar remoções acidentais de arquivos críticos, utilize a flag `-i` (modo interativo), que solicita uma confirmação antes de apagar:
    ```bash
    administrador@ubuntu_server:~$ rm -i config_antiga.conf
    rm: remove regular file 'config_antiga.conf'? y
    ```
    *Digite `y` (yes/sim) ou `n` (no/não) e confirme com Enter.*

### Passo 2.3: Remoção forçada
1.  É possível remover arquivos e diretórios de forma direta com a flag `-f`, no caso de diretórios é necessário adicionar a flag `-r`
    ```bash
    administrador@ubuntu_server:~$ rm -rf backups 
    ```
    

---

## 3. Permissões de Arquivos vs. Permissões de Diretórios

Diferente dos diretórios (onde a execução `x` significa permissão para navegar com `cd`), em arquivos comuns as permissões possuem os seguintes papéis:
*   **Leitura (r / 4):** Permite abrir e ler o conteúdo do arquivo (usando `cat`, `less`, etc.).
*   **Escrita (w / 2):** Permite modificar ou apagar o conteúdo interno do arquivo.
*   **Execução (x / 1):** Permite rodar o arquivo como se fosse um aplicativo ou script de terminal.

---

## 4. Prática de Automação: Gerenciamento de Usuários em Lote

Em cenários reais de administração de redes corporativas, criar dezenas ou centenas de contas de usuários manualmente é inviável. Vamos criar dois scripts em shell para automatizar este processo de forma profissional.

### Passo 4.1: Criar a Lista de Usuários
Crie um arquivo contendo a lista dos 20 usuários que serão cadastrados. Abra o Nano:
```bash
administrador@ubuntu_server:~$ nano usuarios.txt
```
Digite exatamente a lista de nomes abaixo, um por linha, salve e saia:
```text
aluno01
aluno02
aluno03
aluno04
aluno05
aluno06
aluno07
aluno08
aluno09
aluno10
aluno11
aluno12
aluno13
aluno14
aluno15
aluno16
aluno17
aluno18
aluno19
aluno20
```

### Passo 4.2: Criar o Script de Cadastro (`passo1_criar.sh`)
Vamos criar o primeiro script de execução. Ele usará uma estrutura de repetição (`for`) para ler o conteúdo de `usuarios.txt` linha por linha e executar o utilitário de criação.

```bash
administrador@ubuntu_server:~$ nano passo1_criar.sh
```

Insira o código shell abaixo:
```bash
#!/bin/bash

# Script de criação de usuários em lote
for usuario in $(cat usuarios.txt); do
    echo "Processando criação do usuário: $usuario"
    # useradd -m: Cria o diretório home (/home/usuario)
    # -s /bin/bash: Define o interpretador de comandos padrão
    sudo useradd -m -s /bin/bash $usuario
done

echo "Processo de criação concluído!"
```
Salve e saia do Nano.

### Passo 4.3: Criar o Script de Senhas (`passo2_senhas.sh`)
Conforme as especificações, a senha de cada usuário deve ser exatamente igual ao seu próprio nome. Criaremos um segundo script separado para esta finalidade, utilizando o utilitário `chpasswd` (ideal para automação de senhas).

```bash
administrador@ubuntu_server:~$ nano passo2_senhas.sh
```

Insira o código shell abaixo:
```bash
#!/bin/bash

# Script de definição de senhas em lote
for usuario in $(cat usuarios.txt); do
    echo "Definindo senha padronizada para: $usuario"
    # Formato esperado pelo chpasswd: 'usuario:senha'
    echo "$usuario:$usuario" | sudo chpasswd
done

echo "Todas as senhas foram atualizadas com sucesso!"
```
Salve e saia do Nano.

---

## 5. Permissão de Execução e Testes de Validação

Por padrão, novos arquivos criados no Linux não possuem permissão de execução por questões de segurança. Precisamos conceder essa permissão usando o modo simbólico `chmod +x` antes de rodar os scripts.

### Passo 5.1: Conceder Permissão de Execução
```bash
administrador@ubuntu_server:~$ chmod +x passo1_criar.sh
administrador@ubuntu_server:~$ chmod +x passo2_senhas.sh
```

### Passo 5.2: Executar os Scripts
Rode primeiro o script de criação:
```bash
administrador@ubuntu_server:~$ ./passo1_criar.sh
```
Em seguida, execute o script de senhas:
```bash
administrador@ubuntu_server:~$ ./passo2_senhas.sh
```

### Passo 5.3: Validar a Criação das Contas
Para validar se as contas foram integradas com sucesso à base de dados administrativa do sistema, utilize os comandos diagnósticos `getent passwd` e `getent group` combinados com o filtro `tail` para mostrar apenas os últimos 20 registros inseridos:

1.  **Visualizar as contas criadas:**
    ```bash
    administrador@ubuntu_server:~$ getent passwd | tail -n 20
    ```
2.  **Visualizar os grupos criados:**
    ```bash
    administrador@ubuntu_server:~$ getent group | tail -n 20
    ```

---

## 6. Guia de Comandos Utilizados

*   **`getent`:** Significa *get entries* (obter entradas). É um comando administrativo essencial que consulta as bases de dados do sistema (como `/etc/passwd` e `/etc/group`) de forma limpa e estruturada, sem a necessidade de acessar os arquivos de texto diretamente.
*   **`cat`:** Lê e exibe o conteúdo de um arquivo de texto no terminal. No script, é usado para ler a lista de nomes do arquivo `usuarios.txt`.
*   **`useradd`:** Comando padrão de baixo nível para criação de contas de usuários no Linux. A flag `-m` cria automaticamente a pasta pessoal e a flag `-s` define o shell padrão.
*   **`chpasswd`:** Utilitário projetado para ler uma lista de pares de "usuário:senha" a partir da entrada padrão e alterar as senhas em lote, eliminando a interação humana dos prompts convencionais do comando `passwd`.
*   **`for` (Laço de Repetição):** Estrutura lógica de programação em shell script que executa um bloco de comandos repetidamente, uma vez para cada elemento contido na lista fornecida.
*   **`sudo`:** Permite a usuários normais autorizados executar comandos administrativos com privilégios de superusuário (root).

---

## 7. Modelo de Relatório Técnico (Entrega via GitHub)

O relatório individual do aluno deve ser entregue em seu próprio repositório `labredes-bsi-2026.02` no GitHub, em formato Markdown, estruturado em 7 passos:

1.  **Identificação:** Nome completo, matrícula, turma (2026.02), data e título da prática.
2.  **Objetivo:** Explicação clara da atividade realizada (manipulação de arquivos e automação em lote).
3.  **Ambiente:** Especificação do sistema operacional (Ubuntu Server 26.04), hipervisor (VirtualBox) e recursos da VM (512 MB de RAM, 1 CPU, 32 GB HD).
4.  **Procedimento:** Descrição do processo de escrita dos dois scripts, incluindo a explicação dos comandos utilizados (`getent`, `chpasswd`, `for`, `cat`).
5.  **Testes e Evidências:** Capturas de tela (ou cópia textual formatada do console) demonstrando a execução bem-sucedida dos scripts, as saídas dos comandos `getent passwd | tail -n 20` e o primeiro login bem-sucedido com um dos novos usuários (ex: `su - aluno01` validando o carregamento do shell correto).
6.  **Problemas e Soluções:** Registro de eventuais dificuldades enfrentadas (como erros de sintaxe no shell, esquecimento de usar `sudo` ou de conceder permissão de execução com `chmod +x`) e como foram corrigidas.
7.  **Conclusão:** Reflexão sobre a importância do uso de scripts para a escalabilidade e produtividade em administração de redes de computadores.
