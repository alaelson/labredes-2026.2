# Implementação - Grupo 16 - bsi-26-1

## Visão Geral do Projeto

Este documento descreve o passo-a-passo para implementar um ambiente de rede virtualizado com 4 máquinas virtuais Ubuntu Server para a disciplina de Fundamentos de Redes de Computadores. O projeto consiste em criar uma infraestrutura de rede com configuração estática de IPs, hostnames, usuários e testes de conectividade entre os servidores.

### Objetivos do Projeto

1. **Criar 4 máquinas virtuais Ubuntu Server** - Estabelecer um ambiente completo e funcional
2. **Configurar rede estática** - Atribuir IPs fixos em uma sub-rede /28
3. **Definir hostnames e domínios** - Implementar nomenclatura padronizada (FQDN)
4. **Adicionar usuários** - Criar contas para cada integrante do grupo
5. **Configurar mapeamento de nomes** - Adicionar entradas em /etc/hosts para resolução de nomes local
6. **Testar conectividade** - Validar ping e SSH entre todos os servidores

---

## 1. Informações de Rede

**Explicação:** Esta seção define os parâmetros da sub-rede que será utilizada para o grupo 16. A máscara /28 permite 16 endereços IP (2^4), sendo 14 utilizáveis (2 reservados para rede e broadcast).

**Domínio:** grupo16.bsi-26-1.maceio.lab  
- **Estrutura:** `<grupoX>.<turma>.<campus>.lab`
- **Significado:** Identifica unicamente a sub-rede do grupo 16 da turma bsi-26-1 no câmpus de Maceió
- **Propósito:** Facilitar a identificação e resolução de nomes na rede local

**Máscara de Rede:** /28 (255.255.255.240)  
- **Conversão binária:** /28 significa 28 bits para a rede, deixando 4 bits para hosts
- **Total de endereços:** 16 (0-15)
- **Endereços utilizáveis:** 14 (1º é rede, último é broadcast)

**Faixa de IPs:** 192.168.26.240 - 192.168.26.255
- **192.168.26.240:** Endereço da rede (network address) - não atribuir a máquinas
- **192.168.26.241 a 192.168.26.254:** Endereços de hosts (utilizáveis para servidores)
- **192.168.26.255:** Endereço de broadcast - não atribuir a máquinas

### Tabela de Servidores

A tabela abaixo mostra a distribuição dos 4 servidores com seus respectivos hostnames, FQDNs e endereços IP:

| Hostname | FQDN | IP | Propósito |
|----------|------|-----|-----------|
| frances | frances.grupo16.bsi-26-1.maceio.lab | 192.168.26.241 | Servidor de bairro frances |
| pontaverde | pontaverde.grupo16.bsi-26-1.maceio.lab | 192.168.26.242 | Servidor de bairro pontaverde |
| pajuçara | pajuçara.grupo16.bsi-26-1.maceio.lab | 192.168.26.243 | Servidor de bairro pajuçara |
| jatiuca | jatiuca.grupo16.bsi-26-1.maceio.lab | 192.168.26.244 | Servidor de bairro jatiuca |

**Notas importantes:**
- Os nomes dos servidores referem-se a bairros de Maceió (Alagoas)
- Cada servidor tem um IP único dentro da sub-rede
- O FQDN (Fully Qualified Domain Name) combina o hostname com o domínio

---

## 2. Adição de Usuários

### Explicação e Propósito

Nesta etapa, criaremos 4 usuários em cada máquina virtual. Segundo os requisitos do projeto, cada VM deve ter:
- 1 usuário administrador (root ou com privilégios sudo)
- 4 usuários regulares com nomes dos integrantes do grupo

Os usuários são necessários para:
1. **Autenticação:** Cada integrante terá suas próprias credenciais
2. **Segurança:** Isolamento de acesso entre usuários
3. **Auditoria:** Rastreamento de quem executou cada ação no sistema
4. **Testes de SSH:** Validar acesso remoto com diferentes usuários

### Como Executar

Execute em **cada servidor** um dos conjuntos de comandos abaixo:

#### Opção 1: Interativa (Recomendado)

Este método é interativo e pede informações adicionais como nome completo, telefone, etc.

```bash
# Criar usuário 1
sudo adduser usuario1
# Será solicitado: senha, nome completo, número de telefone, etc.

# Criar usuário 2
sudo adduser usuario2

# Criar usuário 3
    enp0s3:                             # Nome da interface (verifique com: ip link show)

# Criar usuário 4
sudo adduser usuario4
```

**Vantagens:**
- Interface amigável
- Permite adicionar informações do usuário (GECOS)
- Mais seguro para entrada de senha (não aparece em histórico de comandos)

#### Opção 2: Não-interativa (Para Automação)

Este método cria os usuários sem interação, útil para scripts ou automação.

```bash
# Criar usuários com diretório home (-m) e shell padrão (-s /bin/bash)
sudo useradd -m -s /bin/bash usuario1
sudo useradd -m -s /bin/bash usuario2
sudo useradd -m -s /bin/bash usuario3
sudo useradd -m -s /bin/bash usuario4

# Definir senhas para cada usuário
    enp0s3:
echo "usuario1:password1" | sudo chpasswd
echo "usuario2:password2" | sudo chpasswd
echo "usuario3:password3" | sudo chpasswd
echo "usuario4:password4" | sudo chpasswd
```

**Explicação dos parâmetros:**
- `-m`: Cria o diretório home do usuário automaticamente
- `-s /bin/bash`: Define o shell padrão como Bash
- `chpasswd`: Ferramenta para definir senhas via pipe

**Boas práticas:**
- Usar nomes de usuários em minúsculas
- Nomes descritivos ou correspondentes aos integrantes do grupo
- Senhas fortes (combinação de maiúsculas, minúsculas, números e símbolos)

### Verificação

Para verificar se os usuários foram criados com sucesso:

```bash
# Listar todos os usuários do sistema
    enp0s3:

# Verificar grupos do usuário
groups usuario1

# Verificar se o diretório home foi criado
ls -la /home/
```

---

## 3. Configuração de Hostname

### Explicação e Propósito

O hostname é o nome que identifica uma máquina na rede. Nesta etapa, configuraremos o FQDN (Fully Qualified Domain Name) de cada servidor, que consiste em:
- **Hostname local:** frances, pontaverde, pajuçara, jatiuca
- **Domínio:** grupo16.bsi-26-1.maceio.lab

**Por que mudar o hostname?**
1. **Identificação:** Facilita a administração e o reconhecimento de cada máquina
2. **Comunicação:** O hostname é usado em protocolos de rede (DNS, SSH, etc.)
3. **Logs:** Registros de sistema identificam claramente qual máquina gerou o evento
    enp0s3:

### Como Executar

Execute **em cada servidor** o comando correspondente. O `hostnamectl` é o método moderno no Ubuntu para gerenciar hostnames:

#### Server 1 - frances

```bash
# Comando para alterar o hostname
sudo hostnamectl set-hostname frances.grupo16.bsi-26-1.maceio.lab

# Explicação:
# - hostnamectl: ferramenta de controle de hostname do systemd
# - set-hostname: subcomando para definir novo hostname
# - frances.grupo16.bsi-26-1.maceio.lab: novo hostname com FQDN completo
```

#### Server 2 - pontaverde

```bash
sudo hostnamectl set-hostname pontaverde.grupo16.bsi-26-1.maceio.lab
```

#### Server 3 - pajuçara

```bash
sudo hostnamectl set-hostname pajuçara.grupo16.bsi-26-1.maceio.lab
```

#### Server 4 - jatiuca

```bash
sudo hostnamectl set-hostname jatiuca.grupo16.bsi-26-1.maceio.lab
```

### Verificação da Mudança

Após executar o comando, verifique se a alteração foi aplicada corretamente:

```bash
# Comando 1: Mostra apenas o hostname
hostname

# Saída esperada: frances.grupo16.bsi-26-1.maceio.lab

# Comando 2: Mostra informações detalhadas sobre o hostname
hostnamectl status

# Saída esperada:
#    Static hostname: frances.grupo16.bsi-26-1.maceio.lab
#          Icon name: computer-vm
#            Chassis: vm
#         Machine ID: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#            Boot ID: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#     Virtualization: kvm
#   Operating System: Ubuntu 22.04.x LTS
#             Kernel: Linux 5.x.x-xx-generic
#       Architecture: x86-64
```

### Persistência da Configuração

O `hostnamectl` modifica automaticamente:
1. `/etc/hostname` - Arquivo que armazena o hostname
2. `/etc/hosts` - Arquivo de resolução local (pode precisar atualização manual)

**Nota importante:** O hostname mudará permanentemente e será mantido após reinicialização.

---

## 4. Configuração de Rede - Netplan

### Explicação e Propósito

Netplan é a ferramenta padrão de configuração de rede no Ubuntu moderno (18.04+). Ele gerencia interfaces de rede através de arquivos YAML declarativos.

**Por que usar Netplan?**
1. **Configuração estática:** Fixar IPs em vez de usar DHCP
2. **Persistência:** As configurações são mantidas após reinicialização
3. **Controle total:** Definir gateway, DNS, máscara de rede manualmente
4. **Automação:** Fácil de automatizar e aplicar em múltiplas máquinas

**O que será configurado em cada servidor:**
- **DHCP4: false** - Desabilita obtenção automática de IP via DHCP
- **Endereço IP com máscara:** IP estático com notação CIDR (/28)
- **Gateway:** Rota padrão para comunicação com outras redes
- **Nameservers:** Servidores DNS para resolução de nomes (Google DNS 8.8.8.8)
- **Search domain:** Sufixo de busca DNS para nomes locais

### Configuração de Cada Servidor

#### Server 1 - frances

**Arquivo:** `/etc/netplan/00-installer-config.yaml`

```bash
# Abrir o arquivo com editor de texto
sudo nano /etc/netplan/00-installer-config.yaml
```

**Conteúdo do arquivo:**
```yaml
# Configuração de rede para o servidor frances
network:
  version: 2                          # Versão do formato netplan (v2 é mais novo)
  ethernets:                          # Interfaces de rede
    enp0s3:                             # Nome da interface (verifique com: ip link show)
      dhcp4: false                    # Desabilitar DHCP automático
      addresses:                      # Lista de endereços IP
        - 192.168.26.241/28           # IP estático com máscara /28
      gateway4: 192.168.26.241        # Gateway para rotear tráfego externo
      nameservers:                    # Configuração de DNS
        addresses: [8.8.8.8, 8.8.4.4] # Servidores DNS primário e secundário (Google)
        search: [grupo16.bsi-26-1.maceio.lab] # Sufixo para busca automática
```

#### Server 2 - pontaverde

**Arquivo:** `/etc/netplan/00-installer-config.yaml`

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

**Conteúdo do arquivo:**
```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.26.242/28           # IP diferente do servidor frances
      gateway4: 192.168.26.241        # Mesmo gateway (frances é o gateway)
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
        search: [grupo16.bsi-26-1.maceio.lab]
```

#### Server 3 - pajuçara

**Arquivo:** `/etc/netplan/00-installer-config.yaml`

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

**Conteúdo do arquivo:**
```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.26.243/28
      gateway4: 192.168.26.241
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
        search: [grupo16.bsi-26-1.maceio.lab]
```

#### Server 4 - jatiuca

**Arquivo:** `/etc/netplan/00-installer-config.yaml`

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

**Conteúdo do arquivo:**
```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.26.244/28
      gateway4: 192.168.26.241
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
        search: [grupo16.bsi-26-1.maceio.lab]
```

### Aplicar e Verificar a Configuração

Após editar o arquivo em cada servidor, execute:

```bash
# Validar sintaxe do arquivo YAML
sudo netplan validate

# Saída esperada: "Valid configuration found."

# Aplicar a configuração de rede
sudo netplan apply

# Este comando:
# - Lê os arquivos em /etc/netplan/
# - Valida a sintaxe YAML
# - Aplica as configurações
# - Reinicia os serviços de rede necessários
```

### Verificação Detalhada

Para confirmar que a configuração foi aplicada corretamente:

```bash
# Comando 1: Mostrar todas as interfaces e seus IPs
ip addr show

# Saída esperada:
# enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
#     inet 192.168.26.241/28 brd 192.168.26.255 scope global enp0s3

# Comando 2: Mostrar a tabela de roteamento
ip route show

# Saída esperada:
# default via 192.168.26.241 dev enp0s3
# 192.168.26.240/28 dev enp0s3 proto kernel scope link src 192.168.26.241

# Comando 3: Testar resolução DNS
resolvectl status

# Comando 4: Ping para o próprio IP (teste local)
ping -c 1 192.168.26.241

# Comando 5: Ping para o gateway
ping -c 1 192.168.26.241
```

### Troubleshooting - Se Algo Não Funcionar

```bash
# Ver logs de erro do netplan
sudo netplan generate

# Se houver erro de sintaxe, o comando informará

# Reverter para configuração anterior (se aplicar sudo netplan apply --rollback)
sudo netplan apply --rollback

# Reiniciar serviço de rede manualmente
sudo systemctl restart networking

# Ver status do serviço de rede
sudo systemctl status networking
```

---

## 5. Configuração de /etc/hosts

### Explicação e Propósito

O arquivo `/etc/hosts` é um mapeamento estático local de nomes para endereços IP. Ele funciona como um servidor DNS local no próprio computador.

**Por que configurar /etc/hosts?**
1. **Resolução local:** Traduzir nomes (hostnames) para IPs sem depender de DNS externo
2. **Testes:** Facilita testar conectividade usando nomes em vez de IPs
3. **Redundância:** Se DNS falhar, as máquinas ainda conseguem se comunicar pelo nome
4. **Performance:** Consultas locais são mais rápidas que consultas a DNS remoto
5. **Desenvolvimento:** Padrão em ambientes de laboratório e desenvolvimento

**Formato das entradas:**
```
IP_ADDRESS    HOSTNAME    ALIAS1    ALIAS2
```

Exemplo:
```
192.168.26.241    frances.grupo16.bsi-26-1.maceio.lab    frances
```

Este exemplo significa: o IP 192.168.26.241 corresponde ao nome frances.grupo16.bsi-26-1.maceio.lab, e pode também ser acessado pelo apelido "frances"

### Como Executar

Execute **em cada servidor** para adicionar os mapeamentos. Isto garante que cada máquina consiga resolver os nomes das outras máquinas localmente.

#### Passo 1: Abrir o arquivo para edição

```bash
# Abrir arquivo com privilégios de administrador
sudo nano /etc/hosts

# Dica: Se preferir outro editor, use:
# sudo vim /etc/hosts
# sudo vi /etc/hosts
# sudo gedit /etc/hosts (interface gráfica)
```

#### Passo 2: Adicionar as entradas de rede local

Localize o final do arquivo e adicione as seguintes linhas:

```bash
# Mapeamento de endereços IP para nomes de servidores do Grupo 16
# Formato: IP    FQDN                                        Hostname_curto

192.168.26.241  frances.grupo16.bsi-26-1.maceio.lab        frances
192.168.26.242  pontaverde.grupo16.bsi-26-1.maceio.lab     pontaverde
192.168.26.243  pajuçara.grupo16.bsi-26-1.maceio.lab       pajuçara
192.168.26.244  jatiuca.grupo16.bsi-26-1.maceio.lab        jatiuca
```

**Explicação das colunas:**
- **Coluna 1 (IP):** Endereço IP do servidor
- **Coluna 2 (FQDN):** Nome completo com domínio
- **Coluna 3 (Alias):** Nome curto para referência rápida

**Exemplo completo de /etc/hosts após edição:**
```bash
# This file is automatically generated by cloud-init. Do not edit.
#
# If you want to manage entries in this file manually, please use the
# following format:
# IP_ADDRESS    HOSTNAME    ALIAS
#
127.0.0.1    localhost
127.0.1.1    frances

# The following lines are desirable for IPv6 capable hosts
::1    ip6-localhost    ip6-loopback
ff02::1    ip6-allnodes
ff02::2    ip6-allrouters

# Mapeamento de endereços IP para nomes de servidores do Grupo 16
192.168.26.241  frances.grupo16.bsi-26-1.maceio.lab        frances
192.168.26.242  pontaverde.grupo16.bsi-26-1.maceio.lab     pontaverde
192.168.26.243  pajuçara.grupo16.bsi-26-1.maceio.lab       pajuçara
192.168.26.244  jatiuca.grupo16.bsi-26-1.maceio.lab        jatiuca
```

#### Passo 3: Salvar o arquivo no nano

```bash
# No editor nano:
# 1. Pressione: Ctrl+O (salvar)
# 2. Pressione: Enter (confirmar nome do arquivo)
# 3. Pressione: Ctrl+X (sair do editor)
```

### Verificação da Configuração

Para confirmar que o mapeamento foi configurado corretamente:

```bash
# Comando 1: Ver o conteúdo completo do arquivo
cat /etc/hosts

# Comando 2: Procurar apenas as entradas dos servidores
grep "grupo16" /etc/hosts

# Saída esperada:
# 192.168.26.241  frances.grupo16.bsi-26-1.maceio.lab        frances
# 192.168.26.242  pontaverde.grupo16.bsi-26-1.maceio.lab     pontaverde
# 192.168.26.243  pajuçara.grupo16.bsi-26-1.maceio.lab       pajuçara
# 192.168.26.244  jatiuca.grupo16.bsi-26-1.maceio.lab        jatiuca

# Comando 3: Testar resolução de nomes com getent
getent hosts frances

# Saída esperada:
# 192.168.26.241 frances.grupo16.bsi-26-1.maceio.lab frances

# Comando 4: Usar nslookup para verificar resolução
nslookup frances

# Comando 5: Usar dig para consulta detalhada
dig frances
```

### Propagação de Configuração

**Importante:** Após editar /etc/hosts, não é necessário reiniciar o sistema. A resolução ocorre imediatamente para a maioria dos aplicativos. Alguns serviços em cache podem precisar ser reiniciados:

```bash
# Se usar resolvectl (systemd-resolved)
sudo systemctl restart systemd-resolved

# Ver cache DNS
systemd-resolve --statistics

# Limpar cache DNS
sudo systemd-resolve --flush-caches
```

---

## 6. Testes de Conectividade

### Explicação e Propósito

A fase de testes valida se toda a configuração foi executada corretamente. Dois testes principais serão realizados:

1. **Teste de Ping:** Verifica conectividade de rede e capacidade de resolver nomes
2. **Teste de SSH:** Valida autenticação e acesso remoto com os usuários criados

**Por que testar?**
- Confirmar que todas as máquinas conseguem se comunicar
- Identificar problemas de configuração antes de usar o ambiente
- Validar resolução de nomes (DNS local via /etc/hosts)
- Verificar que os usuários foram criados corretamente
- Gerar logs de testes para documentação do projeto

### 6.1 Teste de Ping

O ping envia pacotes ICMP (Internet Control Message Protocol) e aguarda respostas, comprovando:
- A conectividade entre máquinas
- A resolução correta de nomes para IPs
- A latência da rede

#### Teste com Endereços IP

Execute em qualquer servidor para testar conectividade com todos os outros:

```bash
# Testar servidor frances (IP 192.168.26.241)
ping -c 4 192.168.26.241

# Esperado: 4 pacotes enviados, 4 recebidos, 0% de perda
# Exemplo de saída:
# PING 192.168.26.241 (192.168.26.241) 56(84) bytes of data.
# 64 bytes from 192.168.26.241: icmp_seq=1 ttl=64 time=1.23 ms
# 64 bytes from 192.168.26.241: icmp_seq=2 ttl=64 time=1.45 ms
# 64 bytes from 192.168.26.241: icmp_seq=3 ttl=64 time=1.34 ms
# 64 bytes from 192.168.26.241: icmp_seq=4 ttl=64 time=1.42 ms
# --- 192.168.26.241 statistics ---
# 4 packets transmitted, 4 received, 0% packet loss, time 3005ms

# Testar servidor pontaverde (IP 192.168.26.242)
ping -c 4 192.168.26.242

# Testar servidor pajuçara (IP 192.168.26.243)
ping -c 4 192.168.26.243

# Testar servidor jatiuca (IP 192.168.26.244)
ping -c 4 192.168.26.244
```

**Explicação do comando:**
- `ping`: Comando para enviar pacotes ICMP
- `-c 4`: Enviar 4 pacotes (útil para testes automatizados, sem -c o ping continua indefinidamente)
- `192.168.26.241`: Endereço IP de destino

#### Teste com Nomes (Hostname/FQDN)

Este teste valida que o mapeamento em /etc/hosts está funcionando:

```bash
# Usando apelido curto (requer /etc/hosts configurado)
ping -c 4 frances

# Esperado: Conecta-se ao IP 192.168.26.241 resolvido localmente
# Exemplo de saída:
# PING frances (192.168.26.241) 56(84) bytes of data.
# 64 bytes from 192.168.26.241: icmp_seq=1 ttl=64 time=1.23 ms

# Usando FQDN completo
ping -c 4 frances.grupo16.bsi-26-1.maceio.lab

# Usando apelidos dos outros servidores
ping -c 4 pontaverde
ping -c 4 pajuçara
ping -c 4 jatiuca
```

#### Interpretação de Resultados

| Resultado | Significado | Solução |
|-----------|------------|---------|
| 4 packets transmitted, 4 received, 0% packet loss | ✅ Sucesso - Conectividade OK | Nenhuma ação necessária |
| 4 packets transmitted, 0 received, 100% packet loss | ❌ Falha - Nenhuma resposta | Verificar se máquina está ligada, IP correto, firewall |
| name or service not known | ❌ Erro de resolução | Verificar /etc/hosts, DNS, entrada de hostname |
| Destination Host Unreachable | ❌ Rota inválida | Verificar configuração de rede, gateway |

### 6.2 Teste de SSH

SSH (Secure Shell) permite acesso remoto seguro à máquina. Este teste valida:
- Configuração de rede completa (IP, DNS)
- Criação correta de usuários
- Serviço SSH ativo e respondendo
- Autenticação funcionando

#### Teste de Conectividade SSH

Conecte-se a cada servidor usando SSH. O comando pede a senha do usuário:

```bash
# Conectar ao servidor frances como usuario1
ssh usuario1@192.168.26.241

# Será solicitado:
# The authenticity of host '192.168.26.241 (192.168.26.241)' can't be established.
# ED25519 key fingerprint is XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX.
# Are you sure you want to continue connecting (yes/no/[fingerprint])?
# Digite: yes

# Depois será solicitada a senha:
# usuario1@192.168.26.241's password: 
# Digite a senha (não aparecerá na tela por segurança)

# Se sucesso, você estará no prompt do servidor remoto:
# usuario1@frances:~$
```

#### Teste com Todos os Servidores

```bash
# Conectar via IP ao servidor frances
ssh usuario1@192.168.26.241

# Conectar via IP ao servidor pontaverde
ssh usuario1@192.168.26.242

# Conectar via IP ao servidor pajuçara
ssh usuario1@192.168.26.243

# Conectar via IP ao servidor jatiuca
ssh usuario1@192.168.26.244

# Conectar usando nome (requer /etc/hosts configurado)
ssh usuario1@frances
ssh usuario1@pontaverde
ssh usuario1@pajuçara
ssh usuario1@jatiuca

# Conectar usando FQDN
ssh usuario1@frances.grupo16.bsi-26-1.maceio.lab
ssh usuario1@pontaverde.grupo16.bsi-26-1.maceio.lab
ssh usuario1@pajuçara.grupo16.bsi-26-1.maceio.lab
ssh usuario1@jatiuca.grupo16.bsi-26-1.maceio.lab
```

#### Teste com Diferentes Usuários

```bash
# Testar acesso com usuario1
ssh usuario1@frances

# Testar acesso com usuario2
ssh usuario2@frances

# Testar acesso com usuario3
ssh usuario3@frances

# Testar acesso com usuario4
ssh usuario4@frances
```

#### Verificações Dentro da Sessão SSH

Depois de conectar via SSH, execute estes comandos no servidor remoto:

```bash
# Mostrar o hostname configurado
hostname

# Mostrar informações detalhadas do hostname
hostnamectl status

# Mostrar configuração de rede
ip addr show

# Testar ping para outro servidor (de dentro da sessão SSH)
ping -c 4 pontaverde

# Ver o endereço IP da máquina onde você conectou
who am i

# Sair da sessão SSH
exit

# Ou use Ctrl+D
```

#### Interpretação de Resultados de SSH

| Resultado | Significado | Solução |
|-----------|------------|---------|
| Connection established | ✅ Sucesso | Testes passaram |
| Connection refused | ❌ SSH não está rodando | Instalar/iniciar OpenSSH Server: `sudo apt install openssh-server` |
| Connection timed out | ❌ Host não responde | Verificar IP, firewall, se máquina está ligada |
| Permission denied (publickey, password) | ❌ Autenticação falhou | Verificar senha, se usuário foi criado corretamente |
| name or service not known | ❌ Nome não resolvido | Verificar /etc/hosts, hostname |

#### Documentação dos Testes

Para o relatório final do projeto, documente os testes com comandos e saídas:

```bash
# Exemplo de como documentar (salvar em arquivo)
ssh usuario1@frances "hostname && ip addr show" > teste_frances.log

# Ou fazer screenshot/print dos testes realizados
```

---

## 7. Resumo e Ordem de Execução

### 7.1 Visão Geral das Tarefas

O projeto consiste em 5 etapas principais que devem ser executadas em sequência específica:

| Etapa | Tarefa | Quantidade | Máquinas | Crítico |
|-------|--------|-----------|----------|---------|
| 1 | Configurar rede (Netplan) | 1 vez por servidor | 4 | ✅ Sim |
| 2 | Configurar hostname | 1 vez por servidor | 4 | ✅ Sim |
| 3 | Adicionar usuários | 1 vez por servidor | 4 | ✅ Sim |
| 4 | Configurar /etc/hosts | 1 vez por servidor | 4 | ⚠️ Recomendado |
| 5 | Testar conectividade | 1 vez por servidor | 4 | ✅ Sim |

### 7.2 Ordem Recomendada de Execução

**Por quê seguir esta ordem?**
- A rede deve estar funcionando antes de testar qualquer coisa
- Os hostnames devem estar configurados para /etc/hosts fazer sentido
- Os usuários devem existir antes de testar SSH
- Os testes finais validam se tudo está correto

#### Sequência Completa por Servidor

Para cada servidor (frances, pontaverde, pajuçara, jatiuca), siga esta ordem:

```
┌─────────────────────────────────────────────────────────┐
│ SERVIDOR: frances (exemplo)                             │
├─────────────────────────────────────────────────────────┤
│ 1. ✅ Conectar à máquina (via console ou SSH)           │
│ 2. ✅ Configurar Netplan (/etc/netplan/)               │
│    - Editar arquivo YAML                               │
│    - Executar: sudo netplan apply                       │
│    - Verificar: ip addr show                            │
│ 3. ✅ Configurar Hostname                              │
│    - Executar: sudo hostnamectl set-hostname ...        │
│    - Verificar: hostname                               │
│ 4. ✅ Adicionar 4 Usuários                             │
│    - Executar: sudo adduser usuarioX                   │
│    - Repetir 4 vezes                                   │
│ 5. ✅ Configurar /etc/hosts                            │
│    - Editar: sudo nano /etc/hosts                      │
│    - Adicionar 4 entradas de rede                      │
│ 6. ✅ Testar Conectividade                             │
│    - Ping: ping -c 4 frances (e outros)               │
│    - SSH: ssh usuario1@frances (e outros)             │
│    - Documentar resultados                             │
└─────────────────────────────────────────────────────────┘
```

#### Timeline Estimada por Servidor

```
Tempo estimado para completar um servidor:
├─ Configurar Netplan: 5-10 minutos
├─ Configurar Hostname: 2-3 minutos
├─ Adicionar 4 Usuários: 10-15 minutos (com interação)
├─ Configurar /etc/hosts: 5 minutos
└─ Testar Conectividade: 10-15 minutos
────────────────────────────
TOTAL POR SERVIDOR: 32-48 minutos

Para 4 SERVIDORES: 2-3 horas
```

#### Checklist de Execução

Imprima ou copie este checklist para acompanhar:

```
SERVIDOR: _______________

Netplan Configuration
  [ ] Arquivo /etc/netplan/00-installer-config.yaml editado
  [ ] sudo netplan validate executado sem erros
  [ ] sudo netplan apply executado
  [ ] ip addr show mostra IP correto

Hostname Configuration
  [ ] sudo hostnamectl set-hostname <fqdn> executado
  [ ] hostname exibe o FQDN correto
  [ ] hostnamectl status mostra mudança

User Creation
  [ ] usuario1 criado com: sudo adduser usuario1
  [ ] usuario2 criado com: sudo adduser usuario2
  [ ] usuario3 criado com: sudo adduser usuario3
  [ ] usuario4 criado com: sudo adduser usuario4
  [ ] Verificado com: cat /etc/passwd | grep usuario

/etc/hosts Configuration
  [ ] sudo nano /etc/hosts aberto
  [ ] 4 entradas de rede adicionadas
  [ ] Arquivo salvo (Ctrl+O, Enter, Ctrl+X)
  [ ] grep "grupo16" /etc/hosts mostra 4 linhas

Connectivity Tests
  [ ] ping -c 4 frances respondeu
  [ ] ping -c 4 pontaverde respondeu
  [ ] ping -c 4 pajuçara respondeu
  [ ] ping -c 4 jatiuca respondeu
  [ ] ssh usuario1@frances conectou
  [ ] ssh usuario1@pontaverde conectou
  [ ] ssh usuario1@pajuçara conectou
  [ ] ssh usuario1@jatiuca conectou
  [ ] Resultados dos testes documentados
```

### 7.3 Remediação de Problemas

Se algo não funcionar, siga este processo:

```
1. Identificar qual fase falhou
2. Verificar a configuração específica daquela fase
3. Corrigir os erros
4. Repetir os testes

Exemplo: Se ping falha
├─ Verificar IP: ip addr show
├─ Verificar rota: ip route show
├─ Verificar DNS local: cat /etc/hosts
└─ Testar manualmente com ping -c 1 IP_ADDRESS
```

### 7.4 Documentação para Entrega

Para a Etapa 1 (11/06/2026), você deve fornecer:

✅ **Tabela de IPs:**
- 4 servidores
- Hostnames
- FQDNs
- IPs estáticos
- Máscara de rede

✅ **Tabela de Usuários:**
- Nome do usuário
- Servidor onde foi criado
- Shell padrão

✅ **Resultados de Testes:**
- Output de ping (de cada servidor para todos os outros)
- Output de SSH (conexão bem-sucedida com pelo menos um usuário)

Para a Etapa 2 (18/06/2026):

✅ **Documentação Completa:**
- Passo-a-passo de toda a configuração
- Screenshots/logs de todos os testes
- Problemas encontrados e soluções aplicadas

✅ **Repositório GitHub:**
- Arquivo implementation.md
- Arquivo com resultados dos testes
- Arquivo com problemas/soluções

### 7.5 Validação Final

Antes de entregar, valide:

```bash
# Em cada servidor, execute e capture os outputs:

# 1. Validar hostname
echo "=== HOSTNAME ===" && hostname && hostnamectl status

# 2. Validar rede
echo "=== REDE ===" && ip addr show && ip route show

# 3. Validar usuários
echo "=== USUÁRIOS ===" && cat /etc/passwd | grep "usuario"

# 4. Validar /etc/hosts
echo "=== /etc/hosts ===" && grep "grupo16" /etc/hosts

# 5. Validar ping de todos os servidores
echo "=== PING ===" && \
ping -c 4 192.168.26.241 && \
ping -c 4 192.168.26.242 && \
ping -c 4 192.168.26.243 && \
ping -c 4 192.168.26.244

# 6. Validar SSH
echo "=== SSH ===" && \
ssh usuario1@frances "echo 'SSH OK - frances'" && \
ssh usuario1@pontaverde "echo 'SSH OK - pontaverde'" && \
ssh usuario1@pajuçara "echo 'SSH OK - pajuçara'" && \
ssh usuario1@jatiuca "echo 'SSH OK - jatiuca'"
```
