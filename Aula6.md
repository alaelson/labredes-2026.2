# Aula 06: Configuração de Rede Estática com Netplan e Modo Placa em Ponte (Bridge Adapter) no VirtualBox

Nesta aula prática de laboratório, você aprenderá a reconfigurar o adaptador de rede da sua máquina virtual Ubuntu Server no VirtualBox do modo **NAT** para o modo **Placa em Ponte (Bridge Adapter)**, conforme documentado na guia oficial de rede do Ubuntu Server. Com isso, sua VM passará a fazer parte diretamente da rede física do laboratório do IFAL, recebendo ou definindo um endereço de rede próprio na sub-rede `172.20.20.0/22`.

Em seguida, aplicaremos a configuração de um **endereço IP estático**, máscara de sub-rede, gateway e servidores de nomes (DNS) utilizando o utilitário **Netplan** através do arquivo `/etc/netplan/00-installer-config.yaml` com a sintaxe YAML moderna e padronizada da documentação do Ubuntu Server. Para finalizar, realizaremos testes de conectividade bidirecional entre o Host (Windows) e o Guest (Linux), além de diagnóstico de rotas externas com `traceroute`.

---

## 1. Fundamentos Técnicos: Modo Placa em Ponte (Bridge) vs. NAT

### O Modo Placa em Ponte (Bridge Adapter)
Enquanto no modo NAT o VirtualBox isola a VM atrás de um roteador virtual interno (atribuindo o IP privado `10.0.2.15`), no modo **Placa em Ponte (Bridge Adapter)** o hipervisor conecta a placa de rede virtual (`enp0s3`) diretamente à placa de rede física do computador hospedeiro (Windows).

*   **Comportamento na Rede:** A VM passa a se comportar como se fosse um computador físico independente conectado ao switch do laboratório.
*   **Visibilidade:** A máquina virtual consegue se comunicar diretamente com outras máquinas da rede local (incluindo o host) e com roteadores externos sem requerer regras de redirecionamento de portas (*Port Forwarding*).
*   **Endereçamento:** A VM utilizará o bloco de endereçamento oficial da rede do laboratório: `172.20.20.0/22` (máscara `255.255.252.0`).

---

## 2. Configuração do Adaptador de Rede no VirtualBox

Antes de alterar as configurações internas do sistema operacional, precisamos modificar a placa de rede virtual no hipervisor.

### Passo a Passo no VirtualBox:

1.  Com a máquina virtual **`ubuntu_server`** desligada (ou executando), abra o menu **Configurações** no VirtualBox (`Ctrl + S`).
2.  No menu lateral esquerdo, selecione **Rede**.
3.  No **Adaptador 1**:
    *   Certifique-se de que a opção **Habilitar Placa de Rede** está marcada.
    *   No campo **Conectado a:**, altere de *NAT* para **Placa em Ponte** (Bridge Adapter).
    *   No campo **Nome:**, selecione a placa de rede física do computador do laboratório que está conectada à rede (ex: *Realtek PCIe GbE Family Controller* ou *Intel Ethernet*).
4.  Clique na aba **Avançado** e confirme se o cabo de rede está marcado como **Conectado**.
5.  Clique em **OK** para salvar as alterações.

```text
[ Configurações da VM ] 
   └── Rede
        └── Adaptador 1: [X] Habilitar Placa de Rede
             ├── Conectado a: Placa em Ponte (Bridge Adapter)
             └── Nome: <Placa_Rede_Fisica_do_Host>
```

---

## 3. Busca e Seleção de Endereço IP Estático Livre

Na rede `172.20.20.0/22` (máscara `255.255.252.0`), o bloco abrange os endereços IP de `172.20.20.1` até `172.20.23.254`. Para evitar conflitos de IP na rede do laboratório, utilizaremos a faixa inicial a partir de **`172.20.23.1`**.

Antes de aplicar o IP no Linux, você deve testar a disponibilidade do endereço a partir da máquina física (Windows Host).

### Passo 3.1: Teste de Disponibilidade via Ping no Windows (Host)

1.  No computador físico Windows, abra o **PowerShell** ou o **Prompt de Comando (CMD)**.
2.  Execute um comando `ping` direcionado ao endereço candidato **`172.20.23.1`**:

```powershell
PS C:\Users\Aluno> ping 172.20.23.1
```

3.  **Análise do Resultado:**
    *   **Se o comando retornar "Esgotado o tempo limite do pedido" (Request timed out) ou "Host de destino inacessível":** Significa que **nenhuma máquina na rede está usando esse IP**. O endereço **`172.20.23.1` está LIVRE** e você pode usá-lo na sua VM!
    *   **Se houver resposta (ex: "Resposta de 172.20.23.1: bytes=32 tempo<1ms..."):** Significa que outro colega ou equipamento já está usando esse IP. Teste o próximo endereço: `ping 172.20.23.2`, `ping 172.20.23.3`, e assim por diante, até encontrar um endereço que **não responda**.

> **Anote o IP livre encontrado!** No nosso exemplo, assumiremos que o IP **`172.20.23.1`** estava livre.

---

## 4. Configuração Estática de Rede com Netplan (Documentação Oficial do Ubuntu Server)

No Ubuntu Server, o gerenciamento de rede é realizado pelo **Netplan** através do arquivo de configuração padronizado **`/etc/netplan/00-installer-config.yaml`**.

### Parâmetros da Rede do Laboratório:
*   **Endereço IP da VM:** `172.20.23.X/22` *(substitua X pelo número do IP livre encontrado)*
*   **Máscara de Sub-rede:** `255.255.252.0` (notação CIDR: `/22`)
*   **Gateway Padrão:** `172.20.20.1`
*   **Servidores DNS (Nameservers):** `172.20.20.1`, `1.1.1.1`, `8.8.8.8`

### Passo 4.1: Edição do Arquivo YAML (`00-installer-config.yaml`)

1.  Acesse o console da sua VM Ubuntu Server com o usuário `administrador`.
2.  Verifique o arquivo de configuração no diretório `/etc/netplan/`:
    ```bash
    administrador@ubuntu_server:~$ ls /etc/netplan/
    00-installer-config.yaml
    ```

3.  Abra o arquivo para edição utilizando o editor `nano` com privilégios de `sudo`:
    ```bash
    administrador@ubuntu_server:~$ sudo nano /etc/netplan/00-installer-config.yaml
    ```

4.  Modifique o conteúdo do arquivo para aplicar a configuração estática seguindo rigorosamente o padrão da documentação do Ubuntu Server (incluindo o renderizador `networkd` e a estrutura de `routes`).

> ⚠️ **Atenção às regras de sintaxe do YAML:**
> *   Utilize **espaços simples** para indentação (nunca utilize a tecla `Tab`).
> *   A indentação precisa ser rígida e alinhada a cada nível (2 espaços por nível).

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 172.20.23.1/22
      routes:
        - to: default
          via: 172.20.20.1
      nameservers:
        addresses:
          - 172.20.20.1
          - 1.1.1.1
          - 8.8.8.8
```

*(Lembre-se de substituir `172.20.23.1` pelo IP livre verificado no Passo 3).*

5.  Salve o arquivo no Nano com `Ctrl + O`, confirme com `Enter` e saia com `Ctrl + X`.

### Passo 4.2: Exibição do Arquivo e Aplicação das Configurações

1.  Exiba o conteúdo do arquivo alterado com o comando `cat` para conferir a sintaxe antes de aplicar:
    ```bash
    administrador@ubuntu_server:~$ cat /etc/netplan/00-installer-config.yaml
    ```

2.  Valide e aplique a nova configuração de rede com o comando `netplan apply`:
    ```bash
    administrador@ubuntu_server:~$ sudo netplan apply
    ```

3.  Verifique se o novo endereço IP foi atribuído à interface `enp0s3`:
    ```bash
    administrador@ubuntu_server:~$ ip addr show enp0s3
    ```
    *(Você também pode utilizar o comando `sudo netplan status` para conferir os detalhes da interface e rotas ativas).*

---

## 5. Testes Práticos e Diagnóstico de Conectividade

Agora realizaremos a bateria de testes de conectividade local e externa para validar a configuração.

### Teste 1: Ping do Host Windows para a VM (Guest)
No **PowerShell do Windows**, execute o comando `ping` para o IP estático recém-configurado na sua VM:
```powershell
PS C:\Users\Aluno> ping 172.20.23.1
```
*Sucesso:* O Windows deve exibir respostas de pacotes recebidos sem perdas (`0% de perda`), comprovando que a VM está visível na rede local através da Placa em Ponte.

### Teste 2: Ping da VM (Guest) para o Host Windows
1.  No PowerShell do Windows, verifique o IP físico da máquina hospedeira executando `ipconfig`. Anote o IPv4 da placa de rede física (ex: `172.20.22.45`).
2.  No terminal da VM Linux, execute o `ping` direcionado ao IP do Windows Host:
    ```bash
    administrador@ubuntu_server:~$ ping -c 4 172.20.22.45
    ```
*Sucesso:* A VM deve receber as 4 respostas ICMP do computador hospedeiro.

### Teste 3: Rastreamento de Rota Externa para `google.com`
Teste a resolução de nomes via DNS e a rota de saída do gateway executando o `traceroute` para o domínio do Google:
```bash
administrador@ubuntu_server:~$ traceroute google.com
```
*Análise:* Observe o primeiro salto (*hop 1*), que deve corresponder ao gateway padrão do laboratório (`172.20.20.1`), seguido pelos saltos externos de saída para a internet pública.

### Teste 4: Rastreamento de Rota para `one.one.one.one` (Cloudflare DNS)
Realize o teste de rastreamento de rota para o nome oficial do servidor DNS da Cloudflare (`one.one.one.one` / IP `1.1.1.1`):
```bash
administrador@ubuntu_server:~$ traceroute one.one.one.one
```
*Análise:* Confirme a resolução do nome `one.one.one.one` para `1.1.1.1` e a sequência de roteamento até o destino final.

---

## 6. Tarefa Prática de Laboratório (Entrega via GitHub)

Cada aluno deverá realizar a prática completa em sua máquina virtual e registrar a documentação em seu repositório pessoal do GitHub, criando o arquivo **`Aula6.md`** formatado de acordo com o **Modelo de 7 Passos**.

### Checklist de Evidências Requeridas para o Relatório:

1.  **Print do Teste de IP Livre (Windows Host):** Tela do PowerShell mostrando o `ping 172.20.23.1` sem resposta, comprovando que o IP estava disponível antes da configuração.
2.  **Print da Janela de Configuração do VirtualBox:** Tela demonstrando a Placa de Rede 1 ajustada para o modo *Placa em Ponte (Bridge Adapter)*.
3.  **Print do Conteúdo do Arquivo Netplan (`cat`):** Tela do terminal da VM executando `cat /etc/netplan/00-installer-config.yaml` exibindo o arquivo de configuração completo com o bloco `renderer: networkd`, endereço estático e rotas.
4.  **Print da Atribuição de IP e Status (`ip addr show` / `netplan status`):** Tela do terminal da VM confirmando a aplicação do IP `172.20.23.X/22`.
5.  **Prints do Ping Bidirecional:**
    *   Ping do Windows Host para o IP da VM.
    *   Ping da VM para o IP do Windows Host.
6.  **Prints dos Comandos Traceroute:**
    *   Saída do comando `traceroute google.com`.
    *   Saída do comando `traceroute one.one.one.one`.

---

## 📝 Modelo de Relatório Técnico (Estrutura de 7 Passos)

1.  **Identificação:** Nome completo, matrícula, turma (BSI 2026.02), data e título da prática.
2.  **Objetivo:** Explicação sobre a transição do modo NAT para Placa em Ponte e a importância da atribuição de IP estático via Netplan conforme a documentação do Ubuntu Server.
3.  **Ambiente:** Especificação das configurações do Host Windows e do Guest Ubuntu Server 26.04 LTS no VirtualBox.
4.  **Procedimento:** Descrição passo a passo da busca de IP livre, alteração no VirtualBox, edição e exibição do arquivo `/etc/netplan/00-installer-config.yaml` e aplicação das regras com `netplan apply`.
5.  **Testes e Evidências:** Capturas de tela e saídas dos testes de ping bidirecional, exibição do arquivo YAML via `cat` e comandos `traceroute`.
6.  **Problemas e Soluções:** Registro de eventuais erros de sintaxe no YAML (erros de indentação) ou bloqueios de firewall e como foram resolvidos.
7.  **Conclusão:** Reflexão técnica sobre as vantagens e cuidados do uso de IPs estáticos e modo Bridge em servidores corporativos.
