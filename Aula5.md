# Aula 05: Acesso Remoto SSH via Redirecionamento de Portas no VirtualBox e Diagnóstico de Rede

Nesta aula prática, você aprenderá a configurar o acesso remoto seguro via SSH (Secure Shell) à sua máquina virtual Ubuntu Server no VirtualBox, utilizando o mecanismo de **Redirecionamento de Portas (Port Forwarding)** do modo NAT. Além disso, faremos a inspeção diagnóstica das interfaces de rede, identificando endereços IPv4, máscaras e endereços MAC tanto no sistema Linux convidado (Guest) quanto no sistema Windows hospedeiro (Host).

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

## 2. Diagnóstico de Rede e Instalação de Pacotes

Antes de alterar o hipervisor, acesse seu servidor Ubuntu Server no VirtualBox com o usuário `administrador` e a senha `adminifal` para realizar a inspeção inicial e preparar os utilitários de diagnóstico.

### Passo 2.1: Leitura do Estado da Rede com Netplan
No Ubuntu Server moderno, o utilitário `netplan` gerencia as configurações de rede. Execute o comando a seguir para visualizar o status das interfaces ativas (sem alterar nenhum arquivo de configuração estática):

```bash
administrador@ubuntu_server:~$ netplan status
```

Observe que a interface `enp0s3` estará listada com o modo DHCP ativo e o endereço IP dinâmico atribuído pelo VirtualBox (`10.0.2.15/24`).

### Passo 2.2: Verificação do Serviço OpenVPN e Instalação do Net-Tools
1.  **Verificar se o pacote OpenVPN está instalado:**
    Execute o comando `dpkg` para checar se o serviço de VPN do servidor já se encontra presente no sistema:
    ```bash
    administrador@ubuntu_server:~$ dpkg -l | grep openvpn
    ```
    *Se nada for retornado ou o pacote não estiver instalado, o sistema não exibirá linhas ativas para o serviço.*

2.  **Instalar o conjunto de ferramentas clássicas de rede (`net-tools`):**
    Atualize o índice de repositórios e instale o pacote `net-tools` (que fornece utilitários tradicionais como `ifconfig`, `netstat` e `route`):
    ```bash
    administrador@ubuntu_server:~$ sudo apt update
    administrador@ubuntu_server:~$ sudo apt install -y net-tools
    ```

### Passo 2.3: Inspeção de Interfaces com `ifconfig` no Ubuntu Server
Com o pacote instalado, execute o comando `ifconfig` no console da sua VM:

```bash
administrador@ubuntu_server:~$ ifconfig
```

*Analise os parâmetros da saída exibida:*
*   **Interface Ethernet (`enp0s3`):**
    *   **`inet 10.0.2.15`:** Endereço IPv4 atribuído à máquina virtual.
    *   **`netmask 255.255.255.0`:** Máscara de sub-rede (equivalente ao prefixo `/24`).
    *   **`ether 08:00:27:ca:9b:66` (ou `HWaddr`):** Endereço Físico (MAC Address) da placa de rede virtual gravado pelo VirtualBox.
*   **Interface de Loopback (`lo`):**
    *   **`inet 127.0.0.1`:** Endereço de ecoretorno local. Esta interface de software é utilizada para comunicação interna de processos do próprio sistema operacional, sem enviar pacotes para a rede física ou virtual.

### Passo 2.4: Inspeção de Interfaces com `ipconfig` no Windows Host
Agora, abra o **PowerShell** ou o **Prompt de Comando (CMD)** no seu computador físico (Windows do laboratório) e execute:

```powershell
PS C:\Users\Aluno> ipconfig /all
```

*Compare a infraestrutura das duas máquinas:*
1.  **Placa de Rede Física (Realtek / Intel / Wi-Fi):** Exibe o IP real do computador do laboratório fornecido pela rede do IFAL.
2.  **Adaptador VirtualBox Host-Only Network (se ativo):** Exibe o IP da interface virtual criada pelo VirtualBox no Windows.
3.  **Comparação de MAC Address:** Observe que o endereço MAC da placa física do Windows é diferente do MAC virtual (`08:00:27:...`) visto dentro da VM Linux com o `ifconfig`.

---

## 3. Configuração do Redirecionamento de Portas no VirtualBox

Agora vamos configurar o VirtualBox para redirecionar conexões da porta local **`5222`** do Windows para a porta **`22`** do Ubuntu Server.

### Passo a Passo no VirtualBox:

1.  No painel principal do Oracle VM VirtualBox, selecione a máquina virtual **`ubuntu_server`**.
2.  Clique no botão **Configurações** (ou pressione `Ctrl + S`).
3.  No menu lateral esquerdo, selecione **Rede**.
4.  Certifique-se de que o **Adaptador 1** está habilitado e conectado a **NAT**.
5.  Clique na opção **Avançado** para expandir as configurações adicionais.
6.  Clique no botão **Redirecionamento de Portas** (Port Forwarding).

```text
[ Configurações da VM ] 
   └── Rede
        └── Adaptador 1 (Conectado a: NAT)
             └── Avançado ▾
                  └── [ Redirecionamento de Portas ]
```

7.  Na janela de Regras de Redirecionamento de Portas, clique no ícone **`+`** (Inserir nova regra) no canto superior direito e preencha exatamente com os seguintes valores:

| Nome | Protocolo | IP do Hospedeiro | Porta do Hospedeiro | IP do Convidado | Porta do Convidado |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **SSH** | `TCP` | `127.0.0.1` | **`5222`** | **`10.0.2.15`** | **`22`** |

> **Nota:** Se preferir, o campo "IP do Hospedeiro" pode ser deixado em branco ou preenchido com `127.0.0.1` (loopback local).

8.  Clique em **OK** na janela de regras e em **OK** na janela de configurações para aplicar as alterações.

---

## 4. Testando o Acesso Remoto SSH a partir do Host Windows

Com a máquina virtual em execução e a regra aplicada, abra o **PowerShell** no Windows do laboratório para realizar o acesso remoto.

### Passo 4.1: Conectar via SSH pelo Terminal do Windows
Execute o comando de conexão SSH indicando a porta personalizada **`5222`** através do parâmetro `-p`:

```powershell
PS C:\Users\Aluno> ssh -p 5222 administrador@127.0.0.1
```

*O que acontecerá durante a primeira conexão:*
1.  **Alerta de Autenticidade (Fingerprint):** O OpenSSH exibirá uma mensagem informando que a chave do host remoto é desconhecida. Digite **`yes`** e pressione `Enter`.
    ```text
    The authenticity of host '[127.0.0.1]:5222' can't be established.
    ED25519 key fingerprint is SHA256:xX...Xx.
    Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
    ```
2.  **Solicitação de Senha:** Digite a senha do usuário da VM (`adminifal`) e pressione `Enter`.
    ```text
    administrador@127.0.0.1's password: adminifal
    ```

3.  **Acesso Concedido:** O terminal do PowerShell exibirá o banner de boas-vindas do Ubuntu Server e o prompt remoto:
    ```bash
    Welcome to Ubuntu 26.04 LTS (GNU/Linux 6.8.0-generic x86_64)
    ...
    administrador@ubuntu_server:~$
    ```

### Passo 4.2: Confirmar a Conexão Remota
Dentro da sessão SSH estabelecida no PowerShell, rode o comando `whoami` e `hostname` para comprovar que você está controlando a máquina virtual remotamente:

```bash
administrador@ubuntu_server:~$ whoami
administrador
administrador@ubuntu_server:~$ hostname
ubuntu_server
```

Para encerrar a sessão SSH remota e retornar ao PowerShell do Windows, digite:
```bash
administrador@ubuntu_server:~$ exit
Connection to 127.0.0.1 closed.
```

---

## 5. Tarefa Prática de Laboratório (Entrega via GitHub)

Para consolidar os conhecimentos de diagnósticos de rede e acesso remoto, cada aluno deverá realizar os testes em seu ambiente e registrar as evidências em seu repositório pessoal do GitHub, criando o arquivo **`Aula5.md`** estruturado no **Modelo de 7 Passos**:

### Roteiro da Tarefa:

1.  **Inspeção de Interfaces:**
    *   Execute `ifconfig` na VM Linux e grave a saída identificando o IP e o MAC Address da interface `enp0s3`.
    *   Execute `ipconfig /all` no PowerShell do Windows Host e identifique a interface física de rede.
2.  **Redirecionamento de Portas:**
    *   Configure a regra de redirecionamento no VirtualBox (Porta Host `5222` -> Porta Guest `22` no IP `10.0.2.15`).
    *   Capture uma imagem (print) da janela de regras do VirtualBox mostrando a regra `SSH` ativa.
3.  **Teste de Conexão SSH:**
    *   Abra o PowerShell do Windows e conecte-se via `ssh -p 5222 administrador@127.0.0.1`.
    *   Execute os comandos `uptime` e `netplan status` dentro da sessão SSH remota e grave a captura de tela como evidência de funcionamento.
4.  **Publicação:**
    *   Crie o arquivo `Aula5.md` no seu repositório no GitHub contendo os 7 passos (Identificação, Objetivo, Ambiente, Procedimento, Testes e Evidências, Problemas/Soluções e Conclusão) e atualize o `README.md` principal do seu repositório com o link para esta aula.

---

## 📝 Modelo de Relatório Técnico (Estrutura de 7 Passos)

1.  **Identificação:** Nome completo, matrícula, turma (BSI 2026.02), data e título da prática.
2.  **Objetivo:** Explicação clara do redirecionamento de portas NAT no VirtualBox e acesso SSH remoto.
3.  **Ambiente:** Especificação das especificações do Host Windows e do Guest Ubuntu Server 26.04 LTS no VirtualBox.
4.  **Procedimento:** Descrição das etapas de instalação do `net-tools`, verificação do `openvpn`, configuração da regra no VirtualBox e comando SSH no PowerShell.
5.  **Testes e Evidências:** Capturas de tela da regra NAT no VirtualBox, saídas dos comandos `ifconfig` e `ipconfig`, e tela do PowerShell com a sessão SSH ativa.
6.  **Problemas e Soluções:** Registro de erros de porta ou recusa de conexão e como foram sanados.
7.  **Conclusão:** Reflexão técnica sobre como o redirecionamento de portas possibilita gerenciar servidores em redes NAT isoladas.
