# Aula 10: Projeto Final — Gateway com Firewall, DNS do Grupo e Login Unificado com LDAP

Objetivo: transformar as 9 VMs da Etapa 1 no ambiente do [Projeto Final](projeto-final/README.md), com os serviços que todos os outros dependem: o **gateway com NAT, firewall e encaminhamento de portas**, o **DNS primário e secundário** do grupo e o **diretório LDAP** com o **login unificado** (SSSD) em todas as VMs. Corresponde às seções 3.1, 7, 8, 9 e 10 do enunciado, no escopo de 2026.2 (LDAP sem TLS).

**Duração:** 1h30 em sala + continuação pelo grupo · **Ambiente:** VirtualBox, VMs da Etapa 1 · **Base:** Aulas 06 a 09

**Até a Aula 11 (25/11), tudo desta aula precisa estar funcionando:** os serviços da Aula 11 (arquivos e web) usam o DNS e as contas do LDAP.

---

## Organização da aula

| Tempo | Parte | O que o grupo faz |
|:--|:--|:--|
| 0–10 min | Orientação | Topologia, mapa das VMs e divisão de tarefas (seção 0) |
| 10–25 min | Preparação e gateway | Snapshot, hostnames, contas locais (seção 1); firewall e DNAT no `gw` (seção 2) |
| 25–50 min | DNS | `ns1` primário e `ns2` secundário, DNS de todas as VMs apontado para o grupo (seção 3) |
| 50–80 min | LDAP e login unificado | Diretório do grupo na VM `ldap` e SSSD nas 9 VMs (seções 4 e 5) |
| 80–90 min | Checagem | Testes da seção 6 e o que fica para casa |

---

## 0. Antes de começar

### 0.1 Mapa das VMs

As VMs da Etapa 1 continuam nos mesmos PCs e com os mesmos IPs. Muda o papel de cada uma, que passa a ter o **nome do serviço** como hostname. O último octeto é o mesmo do servidor do laboratório, para facilitar a migração.

**Tabela 1:** Mapa do Grupo 0 (modelo). Para o Grupo **X**, some `16·X` ao último octeto: no Grupo 1, o `ns1` é `192.168.26.18`.

| PC | VM da Etapa 1 | Serviço | IP (Grupo 0) | FQDN |
|:--:|:--|:--|:--|:--|
| PC1 | Gateway | `gw` | WAN `172.20.23.x` · LAN `192.168.26.1` | `gw.grupo0.bsi-26-2.maceio.lab` |
| PC1 | VM1 | `ns1` (DNS primário) | `192.168.26.2` | `ns1.grupo0.bsi-26-2.maceio.lab` |
| PC1 | VM2 | `ns2` (DNS secundário) | `192.168.26.3` | `ns2.grupo0.bsi-26-2.maceio.lab` |
| PC2 | VM3 | `www` (Aula 11) | `192.168.26.4` | `www.grupo0.bsi-26-2.maceio.lab` |
| PC2 | VM4 | `bd` (Aula 11) | `192.168.26.5` | `bd.grupo0.bsi-26-2.maceio.lab` |
| PC3 | VM5 | `arquivos` (Aula 11) | `192.168.26.6` | `arquivos.grupo0.bsi-26-2.maceio.lab` |
| PC3 | VM6 | `ldap` | `192.168.26.7` | `ldap.grupo0.bsi-26-2.maceio.lab` |
| PC4 | VM7 | `mail` (bônus) | `192.168.26.8` | `mail.grupo0.bsi-26-2.maceio.lab` |
| PC4 | VM8 | `cliente` (testes) | `192.168.26.9` | `cliente.grupo0.bsi-26-2.maceio.lab` |

Em todos os comandos desta aula, troque `grupo0` pelo seu grupo e `192.168.26.x` pelos IPs do seu grupo. A rede do Grupo 0 é `192.168.26.0/28`; a do Grupo 1, `192.168.26.16/28`.

### 0.2 Divisão de tarefas

As seções 3 e 4 podem andar **em paralelo**: enquanto um integrante monta o DNS, outro monta o LDAP. Sugestão para um grupo de quatro:

| Integrante | Seção | VMs |
|:--|:--|:--|
| A (PC1) | 2 e 3 | `gw`, `ns1`, `ns2` |
| B (PC3) | 4 | `ldap` |
| C (PC2) e D (PC4) | 1 em todas as VMs; depois 5 | `www`, `bd`, `arquivos`, `mail`, `cliente` |

---

## 1. Preparação de cada VM (todas as 9)

### 1.1 Snapshot

No VirtualBox, selecione a VM e use **Máquina → Tirar Snapshot** (nome: `antes-aula10`). Se algo quebrar, volte a ele em **Snapshots → Restaurar**. Repita antes de cada serviço novo.

### 1.2 Hostname com o nome do serviço

Exemplo na VM1, que vira o `ns1`:

```bash
sudo hostnamectl set-hostname ns1.grupo0.bsi-26-2.maceio.lab
sudo nano /etc/hosts
```

Deixe no `/etc/hosts` só a própria máquina. Os demais nomes passam a vir do DNS (seção 3):

```
127.0.0.1   localhost
127.0.1.1   ns1.grupo0.bsi-26-2.maceio.lab ns1
```

### 1.3 Remover as contas locais dos integrantes

Na Etapa 1, cada integrante ganhou uma conta local em todas as VMs. Com o LDAP, essas contas atrapalham: o Linux consulta primeiro o `/etc/passwd` e usaria a conta local, com outro `uidNumber` e outra senha. **Mantenha o `administrador`** e remova só as contas dos integrantes:

```bash
# Entre como administrador. Troque pela lista do seu grupo.
for u in fulano.tal beltrano.silva cicrano.souza; do
  sudo deluser --remove-home "$u"
done
getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 {print $1, $3}'   # deve sobrar só o administrador
```

> Se houver algum arquivo da Etapa 1 que você queira guardar, copie-o antes para o home do `administrador`.

---

## 2. Gateway — NAT, firewall e encaminhamento de portas (`gw`)

O `gw` já faz encaminhamento e NAT desde a Etapa 1. Agora ele também **filtra** o que entra na rede do grupo e **encaminha portas** (DNAT) para que o PC do laboratório alcance o site, a pasta compartilhada e o SFTP do grupo pelo IP da WAN do `gw`.

**Tabela 2:** Encaminhamento de portas no `gw` (Grupo 0)

| Porta na WAN do `gw` | Destino | Serviço | Uso pelo PC do laboratório |
|:--:|:--|:--|:--|
| 80 | `www` `192.168.26.4:80` | Site do grupo (Aula 11) | `http://<WAN do gw>/` |
| 2204 | `www` `192.168.26.4:22` | SSH e SFTP no `www` | `sftp -P 2204 fulano.tal@<WAN do gw>` |
| 445 | `arquivos` `192.168.26.6:445` | Samba (Aula 11) | `\\<WAN do gw>\grupo0` no Explorer |
| 2206 | `arquivos` `192.168.26.6:22` | SSH e SFTP no `arquivos` | `ssh -p 2206 fulano.tal@<WAN do gw>` |

As regras abaixo **substituem** as da Etapa 1. Defina as variáveis com os dados do seu grupo e execute o bloco no `gw`:

```bash
WAN=enp0s3; LAN=enp0s8
REDE=192.168.26.0/28          # rede do grupo
LABNET=172.20.20.0/22         # rede do laboratório (PCs)
WWW=192.168.26.4; ARQ=192.168.26.6

# Começar do zero
sudo iptables -F; sudo iptables -t nat -F; sudo iptables -X

# NAT: só o tráfego da rede do grupo que sai pela WAN
sudo iptables -t nat -A POSTROUTING -s $REDE -o $WAN -j MASQUERADE

# Firewall: o que não for liberado abaixo não atravessa o gw
sudo iptables -P FORWARD DROP
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -i $LAN -o $WAN -s $REDE -j ACCEPT

# Encaminhamento de portas (DNAT) e liberação correspondente
sudo iptables -t nat -A PREROUTING -i $WAN -p tcp --dport 80   -j DNAT --to-destination $WWW:80
sudo iptables -t nat -A PREROUTING -i $WAN -p tcp --dport 2204 -j DNAT --to-destination $WWW:22
sudo iptables -t nat -A PREROUTING -i $WAN -p tcp --dport 445  -j DNAT --to-destination $ARQ:445
sudo iptables -t nat -A PREROUTING -i $WAN -p tcp --dport 2206 -j DNAT --to-destination $ARQ:22
sudo iptables -A FORWARD -i $WAN -o $LAN -s $LABNET -d $WWW -p tcp -m multiport --dports 80,22  -j ACCEPT
sudo iptables -A FORWARD -i $WAN -o $LAN -s $LABNET -d $ARQ -p tcp -m multiport --dports 445,22 -j ACCEPT

# Gravar para sobreviver ao reboot (pacote iptables-persistent da Aula 08)
sudo netfilter-persistent save
```

Confira as regras e os contadores:

```bash
sudo iptables -t nat -L -n -v --line-numbers
sudo iptables -L FORWARD -n -v --line-numbers
sudo sysctl net.ipv4.ip_forward         # = 1 (Aula 08)
```

> **Por que o DNAT precisa de uma regra no `FORWARD`?** O DNAT só troca o endereço de destino na chegada (`PREROUTING`). O pacote ainda atravessa o `gw`, e a política `DROP` do `FORWARD` o descartaria se não houvesse a liberação para aquele destino e porta [1].

Quando o servidor do laboratório estiver pronto, o acesso passa a ser pela VPN e o DNAT deixa de ser necessário: o firewall do servidor roteia a rede da VPN até o `gw` (seção 7 do enunciado).

---

## 3. DNS do grupo — `ns1` primário e `ns2` secundário

A [Aula 09](Aula9.md) montou um servidor primário. Aqui são dois: o `ns1` guarda os arquivos das zonas e o `ns2` recebe uma cópia por **transferência de zona** e continua respondendo se o `ns1` cair [2, 3].

**Tabela 3:** Registros da zona `grupo0.bsi-26-2.maceio.lab`

| Nome | Tipo | Valor |
|:--|:--|:--|
| `@` | NS | `ns1`, `ns2` |
| `@` | MX | `10 mail` |
| `gw` | A | `192.168.26.1` |
| `ns1` | A | `192.168.26.2` |
| `ns2` | A | `192.168.26.3` |
| `www` | A | `192.168.26.4` |
| `bd` | A | `192.168.26.5` |
| `arquivos` | A | `192.168.26.6` |
| `ldap` | A | `192.168.26.7` |
| `mail` | A | `192.168.26.8` |
| `cliente` | A | `192.168.26.9` |

### 3.1 Instalação (`ns1` e `ns2`)

```bash
sudo apt-get update
sudo apt-get install -y bind9 bind9-utils dnsutils
```

### 3.2 Opções (`ns1` e `ns2`, o mesmo arquivo)

`/etc/bind/named.conf.options`:

```
acl grupo { 192.168.26.0/28; localhost; };

options {
    directory "/var/cache/bind";
    listen-on-v6 { none; };

    allow-query     { grupo; };                   // só as VMs do grupo
    allow-recursion { grupo; };                   // nomes de fora só para o grupo
    allow-transfer  { none; };                    // liberado só na zona, no ns1

    forwarders { 172.20.20.1; };
    dnssec-validation no;                         // só no laboratório (ver Aula 09)
};
```

### 3.3 Zonas no primário (`ns1`)

`/etc/bind/named.conf.local`. O `ns1` só entrega as zonas ao `ns2` e o avisa a cada mudança:

```
zone "grupo0.bsi-26-2.maceio.lab" {
    type primary;
    file "/etc/bind/db.grupo0";
    allow-transfer { 192.168.26.3; };
    also-notify    { 192.168.26.3; };
};

zone "26.168.192.in-addr.arpa" {
    type primary;
    file "/etc/bind/db.192.168.26";
    allow-transfer { 192.168.26.3; };
    also-notify    { 192.168.26.3; };
};
```

`/etc/bind/db.grupo0`:

```
$TTL 3600
@       IN  SOA ns1.grupo0.bsi-26-2.maceio.lab. administrador.grupo0.bsi-26-2.maceio.lab. (
                2026111801  ; serial (AAAAMMDDnn) - aumente a cada alteração
                3600        ; refresh: de quanto em quanto tempo o ns2 confere o serial
                900         ; retry
                604800      ; expire: o ns2 para de responder se ficar 7 dias sem o ns1
                300 )       ; TTL das respostas negativas

        IN  NS      ns1.grupo0.bsi-26-2.maceio.lab.
        IN  NS      ns2.grupo0.bsi-26-2.maceio.lab.
        IN  MX  10  mail.grupo0.bsi-26-2.maceio.lab.

gw       IN  A   192.168.26.1
ns1      IN  A   192.168.26.2
ns2      IN  A   192.168.26.3
www      IN  A   192.168.26.4
bd       IN  A   192.168.26.5
arquivos IN  A   192.168.26.6
ldap     IN  A   192.168.26.7
mail     IN  A   192.168.26.8
cliente  IN  A   192.168.26.9
```

`/etc/bind/db.192.168.26`. A zona reversa contém **só os endereços do seu grupo** (no Grupo 1, de `17` a `25`):

```
$TTL 3600
@       IN  SOA ns1.grupo0.bsi-26-2.maceio.lab. administrador.grupo0.bsi-26-2.maceio.lab. (
                2026111801 3600 900 604800 300 )

        IN  NS      ns1.grupo0.bsi-26-2.maceio.lab.
        IN  NS      ns2.grupo0.bsi-26-2.maceio.lab.

1       IN  PTR     gw.grupo0.bsi-26-2.maceio.lab.
2       IN  PTR     ns1.grupo0.bsi-26-2.maceio.lab.
3       IN  PTR     ns2.grupo0.bsi-26-2.maceio.lab.
4       IN  PTR     www.grupo0.bsi-26-2.maceio.lab.
5       IN  PTR     bd.grupo0.bsi-26-2.maceio.lab.
6       IN  PTR     arquivos.grupo0.bsi-26-2.maceio.lab.
7       IN  PTR     ldap.grupo0.bsi-26-2.maceio.lab.
8       IN  PTR     mail.grupo0.bsi-26-2.maceio.lab.
9       IN  PTR     cliente.grupo0.bsi-26-2.maceio.lab.
```

Valide e carregue:

```bash
sudo named-checkconf
sudo named-checkzone grupo0.bsi-26-2.maceio.lab /etc/bind/db.grupo0
sudo named-checkzone 26.168.192.in-addr.arpa /etc/bind/db.192.168.26
sudo systemctl restart named
dig @127.0.0.1 www.grupo0.bsi-26-2.maceio.lab +short     # 192.168.26.4
```

### 3.4 Zonas no secundário (`ns2`)

O `ns2` não tem arquivo de zona escrito à mão: ele baixa as zonas do `ns1` e as grava em `/var/cache/bind/`, a pasta em que o BIND pode escrever. `/etc/bind/named.conf.local`:

```
zone "grupo0.bsi-26-2.maceio.lab" {
    type secondary;
    primaries { 192.168.26.2; };
    file "/var/cache/bind/db.grupo0";
};

zone "26.168.192.in-addr.arpa" {
    type secondary;
    primaries { 192.168.26.2; };
    file "/var/cache/bind/db.192.168.26";
};
```

```bash
sudo named-checkconf
sudo systemctl restart named
sudo journalctl -u named --no-pager -n 20 | grep -i transfer   # "Transfer completed" para as duas zonas
ls -l /var/cache/bind/                                         # db.grupo0 e db.192.168.26 criados pelo BIND
```

> Os arquivos copiados ficam em formato binário (*raw*) a partir do BIND 9.9. Para ler o conteúdo, use `named-compilezone -f raw -F text -o - grupo0.bsi-26-2.maceio.lab /var/cache/bind/db.grupo0`.

### 3.5 Apontar o DNS de todas as VMs para o grupo

Em **todas as VMs** (inclusive `ns1`, `ns2` e o `gw`, na placa da LAN), no arquivo YAML de `/etc/netplan/`:

```yaml
      nameservers:
        search: [grupo0.bsi-26-2.maceio.lab]
        addresses: [192.168.26.2, 192.168.26.3]
```

```bash
sudo netplan apply
resolvectl status | grep -A2 "DNS Servers"
```

### 3.6 Testes do DNS (na VM `cliente`)

```bash
dig www.grupo0.bsi-26-2.maceio.lab                 # flag aa e o IP .4
dig +short ldap                                    # domínio de busca completa o nome
dig -x 192.168.26.7 +short                         # ldap.grupo0.bsi-26-2.maceio.lab.
dig MX grupo0.bsi-26-2.maceio.lab +short           # 10 mail.grupo0.bsi-26-2.maceio.lab.
dig @192.168.26.2 grupo0.bsi-26-2.maceio.lab SOA +short
dig @192.168.26.3 grupo0.bsi-26-2.maceio.lab SOA +short   # mesmo serial do ns1
```

**Teste do secundário:**

1. No `ns1`, acrescente `teste IN A 192.168.26.14`, aumente o serial para `2026111802`, valide e rode `sudo rndc reload`.
2. No `ns2`, confira no log a notificação e a nova transferência: `sudo journalctl -u named -n 10`.
3. No `cliente`: `dig @192.168.26.3 teste.grupo0.bsi-26-2.maceio.lab +short`.
4. Desligue o `ns1` (`sudo systemctl stop named`) e repita `dig www.grupo0.bsi-26-2.maceio.lab` no `cliente`: o `ns2` responde sozinho. Religue o `ns1` depois.

**Exercícios de conferência** (registre no tutorial):

1. De cada VM, `ping -c 2` para `gw`, `ns1`, `ns2` e `ldap` pelo nome curto.
2. De cada VM, `dig +short` para os nomes da Tabela 3.
3. De cada VM, `dig -x` para os IPs de `gw`, `ns1`, `ns2` e `cliente`.
4. Do PC do laboratório (Windows), `nslookup www.grupo0.bsi-26-2.maceio.lab 192.168.26.2`. Ele **não** responde: o PC não tem rota para a rede do grupo. Explique no tutorial por quê, e por que o DNAT da seção 2 resolve o acesso ao site, mas não ao DNS.

---

## 4. Diretório LDAP do grupo (`ldap`)

O mesmo procedimento da [Aula 09](Aula9.md), seção 4, agora com o domínio do grupo e as contas reais dos integrantes [4, 5].

### 4.1 Instalação

```bash
sudo apt-get update
sudo apt-get install -y slapd ldap-utils
sudo dpkg-reconfigure slapd
```

| Pergunta | Resposta (Grupo 0) |
|:--|:--|
| *DNS domain name* | `grupo0.bsi-26-2.maceio.lab` (base `dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab`) |
| *Organization name* | `LSOR Grupo 0` |
| *Administrator password* | senha definida pelo grupo (não publique) |
| Demais perguntas | as mesmas da Aula 09 |

### 4.2 Estrutura, grupos e contas

Gere um *hash* com `slappasswd` para cada integrante e para o `novato`. Depois, crie o `grupo0.ldif` com **uma entrada por integrante**, seguindo o modelo:

```ldif
dn: ou=usuarios,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
objectClass: organizationalUnit
ou: usuarios

dn: ou=grupos,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
objectClass: organizationalUnit
ou: grupos

dn: cn=lsor-g0,ou=grupos,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
objectClass: posixGroup
cn: lsor-g0
gidNumber: 10000
memberUid: fulano.tal
memberUid: beltrano.silva

dn: cn=sftpusers,ou=grupos,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
objectClass: posixGroup
cn: sftpusers
gidNumber: 10001
memberUid: novato

dn: uid=fulano.tal,ou=usuarios,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: fulano.tal
cn: Fulano de Tal
sn: Tal
mail: fulano.tal@grupo0.bsi-26-2.maceio.lab
uidNumber: 10001
gidNumber: 10000
homeDirectory: /home/fulano.tal
loginShell: /bin/bash
userPassword: {SSHA}cole-aqui-o-hash

dn: uid=beltrano.silva,ou=usuarios,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: beltrano.silva
cn: Beltrano da Silva
sn: Silva
mail: beltrano.silva@grupo0.bsi-26-2.maceio.lab
uidNumber: 10002
gidNumber: 10000
homeDirectory: /home/beltrano.silva
loginShell: /bin/bash
userPassword: {SSHA}cole-aqui-o-hash

dn: uid=novato,ou=usuarios,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: novato
cn: Usuario Novato
sn: Novato
uidNumber: 10100
gidNumber: 10001
homeDirectory: /home/novato
loginShell: /usr/sbin/nologin
userPassword: {SSHA}cole-aqui-o-hash
```

| Regra | Por quê |
|:--|:--|
| Login `nome.sobrenome`, igual ao da Etapa 1 | Os integrantes continuam com o mesmo nome de usuário |
| `uidNumber` dos integrantes a partir de 10001; `novato` com 10100 | Não colide com as contas locais (a partir de 1000) |
| `gidNumber 10000` (grupo `lsor-g0`) para os integrantes | É o grupo que dá `sudo` e acesso às pastas e ao site |
| `novato` com `/usr/sbin/nologin` | Só usará SFTP restrito (Aula 11) |

```bash
ldapadd -x -D cn=admin,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab -W -f grupo0.ldif
ldapsearch -x -LLL -H ldap://localhost -b dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab "(objectClass=posixAccount)" uid uidNumber gidNumber loginShell
```

> O `grupo0.ldif` com os *hashes* **não vai para o GitHub**. No tutorial, mostre o LDIF sem as linhas `userPassword`.

---

## 5. Login unificado nas 9 VMs (SSSD)

Em **cada uma das 9 VMs**, inclusive o `gw` e o `ldap`, as contas passam a vir do LDAP [6, 7]. Teste primeiro numa VM só (o `cliente`) e depois repita nas outras.

```bash
sudo apt-get install -y sssd-ldap libnss-sss libpam-sss ldap-utils
sudo nano /etc/sssd/sssd.conf
```

```ini
[sssd]
services = nss, pam
domains = grupo0

[domain/grupo0]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://ldap.grupo0.bsi-26-2.maceio.lab
ldap_search_base = dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
cache_credentials = true
# Escopo de 2026.2: LDAP sem TLS. Com o bônus do TLS, troque esta linha
# pelas opções de StartTLS da seção 10 do enunciado.
ldap_auth_disable_tls_never_use_in_production = true
```

```bash
sudo chmod 600 /etc/sssd/sssd.conf
sudo systemctl restart sssd
sudo pam-auth-update --enable mkhomedir

# sudo para os integrantes, pelo grupo do LDAP
echo '%lsor-g0 ALL=(ALL:ALL) ALL' | sudo tee /etc/sudoers.d/lsor-g0
sudo chmod 440 /etc/sudoers.d/lsor-g0
sudo visudo -c

# Login por senha no SSH (se a imagem vier com ele desligado)
echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/50-senha.conf
sudo sshd -t && sudo systemctl restart ssh
```

**Verificação em cada VM:**

```bash
getent passwd fulano.tal       # uid 10001, vindo do LDAP
id fulano.tal                  # grupo lsor-g0 (10000)
grep fulano.tal /etc/passwd    # não aparece: a conta não é local
```

> **Mantenha o `administrador` local em todas as VMs.** É o acesso de emergência se o LDAP ou o DNS caírem.

---

## 6. Checagem do fim da aula

Execute a partir da VM `cliente` e registre no tutorial (testes 1 a 5, 7, 8 e 9 da seção 14 do enunciado):

```bash
ping -c 2 1.1.1.1                                   # saída para a internet pelo NAT do gw
traceroute www                                      # um salto: a rede é a mesma
dig @ns1 grupo0.bsi-26-2.maceio.lab SOA +short
dig @ns2 grupo0.bsi-26-2.maceio.lab SOA +short      # mesmo serial
ssh fulano.tal@ns1                                  # senha do LDAP
ssh fulano.tal@ldap                                 # mesma senha
sudo -l                                             # (dentro da VM) sudo liberado pelo lsor-g0
```

**Troca de senha valendo em todas as VMs** (teste 9), na VM `ldap`:

```bash
ldappasswd -x -D cn=admin,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab -W -S \
  uid=fulano.tal,ou=usuarios,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
```

Repita o `ssh fulano.tal@ns1` com a senha nova.

**Do PC do laboratório**, teste o encaminhamento de portas da seção 2. O site e o Samba só respondem depois da Aula 11; por enquanto, o SFTP já funciona:

```powershell
ssh -p 2206 fulano.tal@172.20.23.x      # entra no arquivos com a conta do LDAP
```

### 6.1 Problemas comuns

| Sintoma | Causa provável | O que fazer |
|:--|:--|:--|
| `ns2` sem os arquivos em `/var/cache/bind` | `allow-transfer` do `ns1` sem o IP do `ns2`, ou arquivo do secundário fora de `/var/cache/bind` | Corrija e rode `sudo rndc retransfer grupo0.bsi-26-2.maceio.lab` no `ns2` |
| Mudança no `ns1` não chega ao `ns2` | Serial não aumentou | Aumente o serial e `sudo rndc reload` |
| `getent passwd fulano.tal` mostra uid 1001 | A conta local da Etapa 1 ainda existe | Seção 1.3 |
| `getent` não mostra nada | DNS não resolve `ldap`, ou `sssd.conf` com permissão diferente de 600 | `dig +short ldap`, `sudo systemctl status sssd`, `sudo journalctl -u sssd -n 30` |
| Login recusado com a senha certa | Falta a linha `ldap_auth_disable_tls_never_use_in_production` | Confira o `sssd.conf` e reinicie o `sssd` |
| `sudo` negado para o integrante | Arquivo do `sudoers.d` com erro ou integrante fora do `lsor-g0` | `sudo visudo -c` e `id fulano.tal` |
| PC do laboratório não alcança a porta 2206 | DNAT sem a regra correspondente no `FORWARD`, ou regras perdidas no reboot | `sudo iptables -L FORWARD -n -v` e `sudo netfilter-persistent save` |

---

## 7. Registro no repositório do grupo

No tutorial do grupo, uma seção por serviço, no [Modelo de 7 Passos](README.md):

1. **Gateway:** regras com `iptables -L -n -v` e `iptables -t nat -L -n -v`, e o teste de SFTP pelo DNAT.
2. **DNS:** `named.conf.options` e `named.conf.local` dos dois servidores, os dois arquivos de zona, o log da transferência no `ns2` e os testes da seção 3.6.
3. **LDAP:** o LDIF sem `userPassword` e o `ldapsearch` com as contas.
4. **Login unificado:** o `sssd.conf`, o `getent`/`id` em três VMs diferentes e o teste de troca de senha.

---

## Referências

[1] NETFILTER PROJECT. **iptables(8)** e **iptables-extensions(8)** — alvos `DNAT` e `MASQUERADE` e módulos `conntrack` e `multiport`. Disponível em: <https://ipset.netfilter.org/iptables-extensions.man.html>.

[2] INTERNET SYSTEMS CONSORTIUM. **BIND 9 Administrator Reference Manual** — zonas `primary` e `secondary`, `allow-transfer`, `also-notify` e `primaries`. Disponível em: <https://bind9.readthedocs.io/>.

[3] CANONICAL. **Domain Name Service (DNS)** — servidor secundário. Ubuntu Server documentation. Disponível em: <https://ubuntu.com/server/docs/how-to/networking/install-dns/>.

[4] CANONICAL. **Install and configure LDAP**. Ubuntu Server documentation. Disponível em: <https://documentation.ubuntu.com/server/how-to/openldap/install-openldap>.

[5] HOWARD, L. **RFC 2307 — An Approach for Using LDAP as a Network Information Service**. IETF, 1998. Disponível em: <https://www.rfc-editor.org/rfc/rfc2307>.

[6] CANONICAL. **How to set up SSSD with LDAP**. Ubuntu Server documentation. Disponível em: <https://documentation.ubuntu.com/server/how-to/sssd/with-ldap>.

[7] SSSD PROJECT. **sssd-ldap(5)** — página de manual. Disponível em: <https://manpages.ubuntu.com/manpages/noble/man5/sssd-ldap.5.html>.
