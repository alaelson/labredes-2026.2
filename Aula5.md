# Aula 05: Acesso Remoto SSH via Redirecionamento de Portas no VirtualBox e Diagnóstico de Rede

Nesta aula prática, você aprenderá a configurar o acesso remoto seguro via SSH (Secure Shell) à sua máquina virtual Ubuntu Server no VirtualBox, utilizando o mecanismo de **Redirecionamento de Portas (Port Forwarding)** do modo NAT. Além disso, faremos a inspeção diagnóstica profunda das interfaces de rede, rotas padrão, rastreamento de pacotes, sessões ativas de terminal e monitoramento de portas TCP tanto no sistema Linux convidado (Guest) quanto no sistema Windows hospedeiro (Host).

---

## 1. Fundamentos Técnicos: NAT, SSH e Redirecionamento de Portas

### O Modo NAT no VirtualBox
Por padrão, a primeira interface de rede da sua VM é configurada no modo **NAT (Network Address Translation)**. Nesse modo, o VirtualBox cria uma rede privada virtual oculta para a máquina virtual, atribuindo-lhe comumente o endereço IP `10.0.2.15`. 

*   **Acesso de Saída:** A VM consegue navegar na internet e acessar a rede externa utilizando a conexão do computador físico (Host).
*   **Acesso de Entrada:** O computador hospedeiro (Windows) **não consegue alcançar o IP `10.0.2.15` diretamente**, pois ele pertence a uma sub-rede privada isolada pelo roteador virtual do VirtualBox.

### O Protocolo SSH e a Necessidade do Redirecionamento
O **SSH (Secure Shell)** opera por padrão na porta **TCP 22** e permite administrar o servidor Linux remotamente por linha de comando de forma criptografada. 

Para que o terminal do Windows consiga conectar-se ao serviço SSH do servidor virtualizado sob modo NAT, precisamos criar uma **Regra de Redirecionamento de Portas (Port Forwarding)** no VirtualBox:

$$\text{Terminal Windows (Host: 127.0.0.1:5222)} \longrightarrow \text{VirtualBox NAT} \longrightarrow \text{Ubuntu Server (Guest: 10.0.2.15:22)}$$

Ao enviar tráfego para a porta **`5222`** do computador local (Host), o VirtualBox intercepta o pacote e o repassa automaticamente para a porta **`22`** do IP **`10.0.2.15`** da máquina virtual.

---

## 2. Diagnóstico de Rede e Instalação de Utilitários no Ubuntu Server

Antes de alterar as configurações do hipervisor, acesse seu servidor Ubuntu Server no VirtualBox com o usuário `administrador` e a senha `adminifal` para realizar a inspeção inicial da rede e preparar os utilitários de diagnóstico.

### Passo 2.1: Leitura do Estado da Rede com Netplan
No Ubuntu Server moderno, o utilitário `netplan` gerencia as configurações de rede. Execute o comando a seguir para visualizar o status das interfaces ativas (sem alterar nenhum arquivo de configuração estática):

```bash
administrador@ubuntu_server:~$ netplan status
```

Observe que a interface `enp0s3` estará listada com o modo DHCP ativo e o endereço IP dinâmico atribuído pelo VirtualBox (`10.0.2.15/24`).

### Passo 2.2: Verificação do Serviço OpenSSH e Instalação de Pacotes Diagnósticos
1.  **Verificar se o pacote OpenSSH Server está instalado:**
    Execute o comando `dpkg` para checar se o serviço SSH (`openssh-server`) já se encontra presente no sistema:
    ```bash
    administrador@ubuntu_server:~$ dpkg -l | grep openssh-server
    ```
2.  **Instalar os pacotes `net-tools` e `traceroute`:**
    Atualize o índice de repositórios e instale as ferramentas tradicionais de diagnóstico de rede:
    ```bash
    administrador@ubuntu_server:~$ sudo apt update
    administrador@ubuntu_server:~$ sudo apt install -y net-tools traceroute
    ```

### Passo 2.3: Inspeção de Interfaces com `ifconfig`
Com o pacote `net-tools` instalado, execute o comando `ifconfig` no console da sua VM:

```bash
administrador@ubuntu_server:~$ ifconfig
```

*Analise os parâmetros da saída exibida:*
*   **Interface Ethernet (`enp0s3`):**
    *   **`inet 10.0.2.15`:** Endereço IPv4 atribuído à máquina virtual.
    *   **`netmask 255.255.255.0`:** Máscara de sub-rede (equivalente ao prefixo `/24`).
    *   **`ether 08:00:27:ca:9b:66` (ou `HWaddr`):** Endereço Físico (MAC Address) da placa de rede virtual.
*   **Interface de Loopback (`lo`):**
    *   **`inet 127.0.0.1`:** Endereço de ecoretorno local para comunicação interna de processos.

### Passo 2.4: Verificação do Gateway Padrão com `route -n`
Para verificar por onde o tráfego do servidor é roteado para fora da rede local, inspecione a tabela de roteamento do kernel com o comando `route -n`:

```bash
administrador@ubuntu_server:~$ route -n
```

*Entendendo a saída:*
*   O parâmetro **`-n`** (numeric) exibe os endereços em formato numérico IP de forma instantânea, sem perder tempo tentando resolver nomes via DNS.
*   A linha iniciada por **`0.0.0.0`** (Destination) aponta para o **Gateway Padrão** (Gateway `10.0.2.2`), indicando que qualquer tráfego destinado à internet ou a redes externas será encaminhado para o roteador virtual do VirtualBox através da interface `enp0s3`.

### Passo 2.5: Rastreamento de Rotas de Pacotes com `traceroute`
Para acompanhar a trajetória dos pacotes de rede desde a sua VM até um servidor remoto na internet, utilize o utilitário `traceroute`:

```bash
administrador@ubuntu_server:~$ traceroute 8.8.8.8
```

*Análise pedagógica:*
*   O primeiro salto (hop 1) será o gateway interno do VirtualBox (`10.0.2.2`).
*   Os saltos seguintes mostram a passagem dos pacotes pelos roteadores da rede do IFAL até alcançarem o destino final.

### Passo 2.6: Inspeção de Terminais e Usuários Ativos com `w`
O comando `w` exibe em tempo real quais usuários estão conectados ao servidor, quais terminais estão utilizando e quais processos estão executando:

```bash
administrador@ubuntu_server:~$ w
```

*Exemplo de saída inicial (apenas console local):*
```text
 14:30:00 up 10 min,  1 user,  load average: 0.00, 0.01, 0.00
USER          TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
administrador tty1     -                14:20    0.00s  0.05s  0.01s w
```
*   **`tty1`:** Indica que o usuário está logado diretamente no console físico/virtual da máquina virtual.

---

## 3. Inspeção do Host Windows (PowerShell e `netstat -an`)

Antes de ativar o redirecionamento no VirtualBox, abra o **PowerShell** no Windows Host (máquina física do laboratório) para examinar as interfaces e o estado das portas locais.

### Passo 3.1: Inspeção de Interfaces com `ipconfig /all`
```powershell
PS C:\Users\Aluno> ipconfig /all
```
Observe o IP real do computador físico e verifique que o MAC Address do Windows é diferente do MAC virtual visto com o `ifconfig` na VM.

### Passo 3.2: Diagnóstico de Portas no Windows ANTES do Redirecionamento
O comando `netstat -an` exibe todas as conexões ativas e portas TCP/UDP em escuta no sistema operacional. Vamos filtrar a porta **`5222`** no PowerShell:

```powershell
PS C:\Users\Aluno> netstat -an | findstr 5222
```

*Resultado Esperado:* **Nenhuma linha é retornada**, pois a porta `5222` ainda não está reservada nem escutando no Windows.

---

## 4. Configuração do Redirecionamento de Portas no VirtualBox

Agora vamos configurar o VirtualBox para capturar o tráfego que chegar à porta local **`5222`** do Windows e redirecioná-lo para a porta **`22`** (SSH) da VM (`10.0.2.15`).

### Passo a Passo no VirtualBox:

1. No painel principal do Oracle VM VirtualBox, selecione a VM **`ubuntu_server`**.
2. Clique em **Configurações** (`Ctrl + S`) -> **Rede**.
3. Em **Adaptador 1** (NAT), clique em **Avançado** -> **Redirecionamento de Portas**.
4. Clique no ícone **`+`** (Inserir nova regra) e preencha a tabela exatamente como segue:

| Nome | Protocolo | IP do Hospedeiro | Porta do Hospedeiro | IP do Convidado | Porta do Convidado |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **SSH** | `TCP` | `127.0.0.1` | **`5222`** | **`10.0.2.15`** | **`22`** |

5. Clique em **OK** para salvar e fechar as janelas.

---

## 5. Validação com `netstat -an` e Teste de Conexão SSH Remota

### Passo 5.1: Diagnóstico no Windows DEPOIS de Ativar a Regra no VirtualBox
Com a regra aplicada no VirtualBox, execute novamente o comando `netstat -an` no PowerShell do Windows:

```powershell
PS C:\Users\Aluno> netstat -an | findstr 5222
```

*Resultado Esperado:*
```text
  TCP    127.0.0.1:5222         0.0.0.0:0              LISTENING
```
*   A porta **`5222`** agora aparece no estado **`LISTENING`** (Escutando), indicando que o processo do VirtualBox no Windows está pronto para receber conexões SSH de entrada!

### Passo 5.2: Conectar via SSH a partir do Windows
No PowerShell, execute a conexão SSH direcionada à porta `5222`:

```powershell
PS C:\Users\Aluno> ssh -p 5222 administrador@127.0.0.1
```
*   Digite **`yes`** para aceitar a chave de autenticidade (fingerprint) se for o primeiro acesso.
*   Insira a senha do usuário (`adminifal`).

### Passo 5.3: Diagnóstico de Conexão Ativa (`ESTABLISHED`) no Windows
Abra uma **segunda janela do PowerShell** no Windows enquanto a conexão SSH estiver aberta e execute:

```powershell
PS C:\Users\Aluno> netstat -an | findstr 5222
```

*Resultado Esperado:*
```text
  TCP    127.0.0.1:5222         0.0.0.0:0              LISTENING
  TCP    127.0.0.1:5222         127.0.0.1:54321        ESTABLISHED
  TCP    127.0.0.1:54321        127.0.0.1:5222         ESTABLISHED
```
*   A saída demonstra claramente o canal de comunicação ativo em estado **`ESTABLISHED`** entre o cliente SSH do Windows e a porta de redirecionamento do VirtualBox!

### Passo 5.4: Verificação de Sessão SSH e Terminais com `w` no Linux Remoto
Dentro do terminal SSH ativo no PowerShell, execute o comando `w`:

```bash
administrador@ubuntu_server:~$ w
```

*Resultado Esperado:*
```text
 14:45:12 up 25 min,  2 users,  load average: 0.02, 0.01, 0.00
USER          TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
administrador tty1     -                14:20    25:00s 0.05s  0.01s -bash
administrador pts/0    10.0.2.2         14:44    0.00s  0.02s  0.00s w
```
*   **Análise Pedagógica do `w`:**
    *   **`tty1`:** Sessão aberta no console físico/virtual do VirtualBox.
    *   **`pts/0` (Pseudo-Terminal):** Nova sessão remota aberta via SSH através da rede virtual. O campo **`FROM`** indica que a conexão partiu do gateway NAT (`10.0.2.2`).

Para sair da sessão SSH, digite `exit`.

---

## 6. Tarefa Prática de Laboratório (Entrega via GitHub)

Para consolidar a prática, cada aluno deverá executar todos os testes em seu ambiente e registrar as evidências em seu repositório pessoal do GitHub, criando o arquivo **`Aula5.md`** estruturado no **Modelo de 7 Passos**:

### Roteiro Obrigatório de Evidências:

1.  **Diagnósticos no Linux Guest:**
    *   Print/Saída do comando `ifconfig` identificando o IP `10.0.2.15` e o MAC Address.
    *   Print/Saída do comando `route -n` destacando o Gateway Padrão `10.0.2.2`.
    *   Print/Saída do comando `traceroute 8.8.8.8` mostrando os saltos da rede.
2.  **Diagnósticos de Portas no Windows Host (`netstat -an`):**
    *   Print/Saída do PowerShell executando `netstat -an | findstr 5222` **ANTES** de ativar o redirecionamento (vazio/sem resposta).
    *   Print da regra SSH criada no VirtualBox (Porta Host `5222` -> Porta Guest `22`).
    *   Print/Saída do `netstat -an | findstr 5222` no Windows **DEPOIS** de ativar a regra, mostrando a porta em estado **`LISTENING`**.
    *   Print/Saída do `netstat -an | findstr 5222` **DURANTE** a sessão SSH ativa, demonstrando o estado **`ESTABLISHED`**.
3.  **Conexão Remota e Sessão SSH:**
    *   Print do terminal remoto no PowerShell logado via `ssh -p 5222 administrador@127.0.0.1`.
    *   Print do comando `w` dentro da sessão SSH, destacando a presença do terminal `pts/0`.
4.  **Publicação:**
    *   Crie e envie o arquivo `Aula5.md` no seu repositório do GitHub e adicione o link de acesso na página inicial `README.md`.

---

## 📝 Modelo de Relatório Técnico (Estrutura de 7 Passos)

1. **Identificação:** Nome completo, matrícula, turma (BSI 2026.02), data e título da prática.
2. **Objetivo:** Explicação clara sobre diagnóstico de rotas, controle de portas via `netstat` e acesso remoto SSH em ambiente NAT.
3. **Ambiente:** Especificação das configurações do Host Windows e da VM Ubuntu Server 26.04 LTS no VirtualBox.
4. **Procedimento:** Descrição do processo de instalação do `net-tools` e `traceroute`, verificação do `openssh-server`, análise com `route -n`, `w`, `ipconfig`, `netstat -an` e configuração NAT.
5. **Testes e Evidências:** Capturas de tela organizadas com as saídas dos comandos diagnósticos no Linux e Windows.
6. **Problemas e Soluções:** Registro de quaisquer dificuldades encontradas (como recusa de porta no firewall ou erros de digitação de parâmetros) e como foram corrigidas.
7. **Conclusão:** Reflexão técnica sobre a utilidade dos comandos de auditoria e a importância de entender o fluxo de portas em redes virtualizadas.
