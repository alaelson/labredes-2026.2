# Projeto de LSOR — Turma bsi-26-2 (2026.2)

## Projeto Final — Serviços de rede com login unificado

### 1. Apresentação

Na Etapa 1, cada grupo montou uma rede privada com 8 VMs Ubuntu Server e um gateway NAT, com endereços fixos, nomes no domínio do grupo e os mesmos usuários em todas as máquinas. No Projeto Final, essa rede passa a oferecer **serviços**: cada VM recebe uma função e o grupo entrega um ambiente completo, como o de uma pequena empresa.

| Serviço | O que o grupo vai implantar |
|:--|:--|
| **DNS** | Servidor de nomes primário (master) e secundário (slave) com BIND9 para o domínio do grupo, com zona direta e reversa |
| **Login unificado** | Diretório OpenLDAP com os usuários e grupos do projeto; todas as VMs passam a autenticar nele pelo SSSD |
| **Servidor de arquivos** | Compartilhamentos Samba com acesso controlado pelos grupos do LDAP |
| **Servidor web (LAMP)** | Apache, MariaDB e PHP com a página do projeto do grupo e uma área restrita que pede login do LDAP |
| **SFTP** | Transferência segura de arquivos com OpenSSH, com usuários presos ao próprio diretório (*chroot*) |
| **E-mail** | Postfix (SMTP) e Dovecot (IMAP) para o domínio do grupo, com as contas do LDAP |

O ponto central do projeto é o **login unificado**: cada pessoa tem **uma única conta e senha**, guardadas no LDAP, e usa essa mesma conta para entrar por SSH em qualquer VM, abrir os arquivos do grupo, enviar arquivos por SFTP, ler e-mail e acessar a área restrita do site.

### 2. Objetivos

Ao final do projeto, o grupo deve ser capaz de:

1. Configurar um DNS autoritativo com servidor primário e secundário, transferência de zona e resolução reversa.
2. Criar um diretório LDAP com usuários e grupos POSIX e protegê-lo com TLS.
3. Integrar clientes Linux ao LDAP com SSSD e PAM, centralizando login, criação do diretório home e `sudo`.
4. Publicar compartilhamentos de arquivos com permissões por grupo.
5. Montar um servidor web dinâmico com banco de dados e autenticação pelo LDAP.
6. Oferecer SFTP restrito com *chroot*.
7. Configurar entrega e leitura de e-mail dentro do domínio do grupo.
8. Expor serviços internos pelo gateway com redirecionamento de portas (DNAT).
9. Testar e documentar cada serviço com evidências.

### 3. Pré-requisito: Etapa 1 funcionando

O Projeto Final é construído **sobre as VMs da Etapa 1**. Antes de começar, confira no ambiente do grupo:

- as 9 VMs ligadas, com IP estático e hostname no padrão `gx-pcy-vmz.grupoX.bsi-26-2.maceio.lab`;
- o gateway com `ip_forward` ativo, NAT persistente e as VMs saindo para a internet por ele;
- SSH ativo em todas as VMs.

Consulte o [enunciado da Etapa 1](../projeto-etapa1/README.md) e os roteiros das [Aulas 01 a 08](../README.md) sempre que precisar.

### 4. Topologia

**Figura 1:** Topologia lógica com os serviços de cada VM (exemplo do Grupo 0, modelo).

![Topologia lógica com os serviços](topologia-servicos-pf.png)

**Figura 2:** Login unificado. Todos os serviços consultam o mesmo diretório LDAP.

![Login unificado com LDAP](login-unificado-ldap.png)

A topologia física continua a da Etapa 1: 4 PCs do laboratório, 2 VMs em cada um, o gateway como VM extra no PC1 e todas as placas em modo Placa em Ponte (Bridge) ([Figura 2 da Etapa 1](../projeto-etapa1/topologia-fisica-etapa1.png)).

Diagrama editável no Lucid: [LSOR BSI - Projeto Final - Topologia de Serviços](https://lucid.app/lucidchart/2545f7c4-b516-4c3a-9a05-80b9972dc18c/view)

### 5. Distribuição dos serviços nas VMs

Os hostnames, IPs e placas de rede **não mudam** em relação à Etapa 1. Cada VM ganha um **nome de serviço**, publicado no DNS (seção 7).

| VM | Hostname (Etapa 1) | IP (Grupo 0) | Nome do serviço | Função | Pacotes principais |
|:--:|:--|:--|:--|:--|:--|
| GW | `g0-pc1-gw` | 172.20.23.X (WAN) · 192.168.26.1 (LAN) | `gw` | Gateway, NAT e redirecionamento de portas | `iptables-persistent` |
| VM1 | `g0-pc1-vm1` | 192.168.26.2 | `ns1` | DNS primário (master) | `bind9`, `bind9-utils` |
| VM2 | `g0-pc1-vm2` | 192.168.26.3 | `ldap` | Diretório LDAP (login unificado) | `slapd`, `ldap-utils` |
| VM3 | `g0-pc2-vm1` | 192.168.26.4 | `ns2` | DNS secundário (slave) | `bind9`, `bind9-utils` |
| VM4 | `g0-pc2-vm2` | 192.168.26.5 | `arquivos` | Servidor de arquivos | `samba` |
| VM5 | `g0-pc3-vm1` | 192.168.26.6 | `www` | Servidor web LAMP | `apache2`, `mariadb-server`, `php`, `libapache2-mod-php`, `php-mysql` |
| VM6 | `g0-pc3-vm2` | 192.168.26.7 | `sftp` | SFTP com *chroot* | `openssh-server` |
| VM7 | `g0-pc4-vm1` | 192.168.26.8 | `mail` | E-mail (SMTP e IMAP) | `postfix`, `dovecot-imapd` |
| VM8 | `g0-pc4-vm2` | 192.168.26.9 | `cliente` | Estação de testes dos serviços | `dnsutils`, `ldap-utils`, `smbclient`, `swaks`, `curl` |

- Para os outros grupos, troque `g0`/`grupo0` pelo número do grupo e use os IPs da sub-rede do grupo (`192.168.26.(16 × X)/28`), na mesma ordem.
- O `ns2` fica num **PC diferente** do `ns1` de propósito: se o PC1 for desligado, o grupo continua resolvendo nomes.
- **Todas as VMs** recebem também o cliente do login unificado (`sssd-ldap`, `libnss-sss`, `libpam-sss`, `ldap-utils`), configurado na seção 9.
- **Memória:** o padrão da disciplina (512 MB) é suficiente para DNS, LDAP, arquivos, SFTP e cliente. Para `www` (MariaDB) e `mail`, use **1 GB** se o PC hospedeiro tiver memória livre; se não tiver, mantenha 512 MB e registre o uso de memória (`free -h`) no tutorial.

### 6. Ordem de implementação

Os serviços dependem uns dos outros. Siga esta ordem e só passe para o próximo item depois de testar o anterior:

| Passo | Serviço | Depende de | Seção |
|:--:|:--|:--|:--:|
| 1 | DNS primário e secundário | Etapa 1 | 7 |
| 2 | Servidor LDAP com TLS | DNS (nome `ldap`) | 8 |
| 3 | Login unificado em todas as VMs | LDAP | 9 |
| 4 | Servidor de arquivos (Samba) | Login unificado | 10 |
| 5 | Servidor web (LAMP) com área restrita | DNS e LDAP | 11 |
| 6 | SFTP com *chroot* | Login unificado | 12 |
| 7 | E-mail (Postfix e Dovecot) | DNS (registro MX) e login unificado | 13 |
| 8 | Redirecionamento de portas no gateway | `www` e `sftp` funcionando | 14 |

> Antes de cada passo, **tire um *snapshot*** da VM no VirtualBox (*Máquina → Criar Snapshot*). Se a configuração quebrar, volte ao *snapshot* em vez de reinstalar.

### 7. DNS — `ns1` (primário) e `ns2` (secundário)

O DNS substitui o `/etc/hosts` da Etapa 1 como fonte dos nomes do grupo [1, 2, 3].

**Requisitos:**

1. Instalar o BIND9 em `ns1` e `ns2`.
2. Em `ns1`, criar como **primário** (`type primary`, antigo `master`):
   - a zona direta `grupo0.bsi-26-2.maceio.lab`;
   - a zona reversa `26.168.192.in-addr.arpa`.
3. Em `ns2`, criar as mesmas zonas como **secundário** (`type secondary`, antigo `slave`), recebendo-as de `ns1` por transferência de zona.
4. Em `ns1`, liberar a transferência só para o `ns2` (`allow-transfer`) e avisá-lo das alterações (`also-notify`).
5. Aceitar consultas e recursão apenas da rede do grupo (`allow-query` e `allow-recursion`), encaminhando nomes externos para o DNS do laboratório (`forwarders { 172.20.20.1; 1.1.1.1; };`).
6. Incrementar o **serial** do SOA a cada alteração da zona, no formato `AAAAMMDDnn`.
7. Depois de testar, apontar o Netplan de **todas as VMs** para `ns1` e `ns2`, com o domínio de busca do grupo:

```yaml
      nameservers:
        search: [grupo0.bsi-26-2.maceio.lab]
        addresses: [192.168.26.2, 192.168.26.4]
```

**Registros da zona direta (Grupo 0):**

| Nome | Tipo | Valor | Observação |
|:--|:--:|:--|:--|
| `@` | NS | `ns1.grupo0.bsi-26-2.maceio.lab.` | |
| `@` | NS | `ns2.grupo0.bsi-26-2.maceio.lab.` | |
| `@` | MX 10 | `mail.grupo0.bsi-26-2.maceio.lab.` | Servidor de e-mail do domínio |
| `g0-pc1-gw` … `g0-pc4-vm2` | A | `192.168.26.1` … `192.168.26.9` | Um registro por VM, com o nome da Etapa 1 |
| `gw` | CNAME | `g0-pc1-gw` | |
| `ns1` | A | `192.168.26.2` | Registro **A**, não CNAME |
| `ns2` | A | `192.168.26.4` | Registro **A**, não CNAME |
| `mail` | A | `192.168.26.8` | Registro **A**, não CNAME |
| `ldap` | CNAME | `g0-pc1-vm2` | |
| `arquivos` | CNAME | `g0-pc2-vm2` | |
| `www` | CNAME | `g0-pc3-vm1` | |
| `sftp` | CNAME | `g0-pc3-vm2` | |
| `cliente` | CNAME | `g0-pc4-vm2` | |

> **Por que `ns1`, `ns2` e `mail` não podem ser CNAME?** Os registros NS e MX precisam apontar para um nome que tenha registro de endereço próprio; apontar para um apelido (CNAME) é proibido pela especificação do DNS [4]. Os demais serviços podem ser apelidos.

**Zona reversa:** um registro PTR para cada IP de `.1` a `.9`, apontando para o hostname da Etapa 1 (ex.: `2 IN PTR g0-pc1-vm1.grupo0.bsi-26-2.maceio.lab.`).

> **Sobre a zona reversa:** cada grupo usa só um pedaço (/28) da rede `192.168.26.0/24`, mas declara a zona do /24 inteiro. Isso funciona porque cada grupo consulta apenas os próprios servidores. Numa rede real, a delegação de um pedaço da zona reversa segue o método *classless* descrito na RFC 2317 [5] (desafio opcional, seção 16).

**Validação antes de recarregar:**

```bash
sudo named-checkconf
sudo named-checkzone grupo0.bsi-26-2.maceio.lab /etc/bind/db.grupo0
sudo named-checkzone 26.168.192.in-addr.arpa /etc/bind/db.192.168.26
sudo rndc reload
```

### 8. LDAP — `ldap` (diretório do login unificado)

O OpenLDAP guarda os usuários e grupos do projeto no formato POSIX (RFC 2307), o mesmo usado pelos arquivos `/etc/passwd` e `/etc/group` [6, 7, 8].

**Requisitos:**

1. Instalar `slapd` e `ldap-utils` e reconfigurar com `sudo dpkg-reconfigure slapd`, usando o domínio DNS do grupo. A base fica `dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab`.
2. Criar as unidades organizacionais `ou=usuarios` e `ou=grupos`.
3. Criar os grupos POSIX (`posixGroup`):

| Grupo | `gidNumber` | Membros (`memberUid`) | Uso |
|:--|:--:|:--|:--|
| `lsor-g0` | 10000 | todos os integrantes | Pasta do grupo no Samba, área restrita do site e `sudo` nas VMs |
| `sftpusers` | 10001 | `novato` | Usuários que só podem usar SFTP |

4. Criar um usuário (`inetOrgPerson`, `posixAccount`, `shadowAccount`) para **cada integrante**, com o mesmo login da Etapa 1 (`nome.sobrenome`), e o usuário extra `novato`, que só terá acesso por SFTP:
   - `uidNumber` a partir de **10001**, para não colidir com as contas locais (que começam em 1000);
   - `gidNumber` do grupo `lsor-g0` para os integrantes e de `sftpusers` para o `novato`;
   - `homeDirectory: /home/<login>`, `loginShell: /bin/bash` (o `novato` pode usar `/usr/sbin/nologin`);
   - `mail: <login>@grupo0.bsi-26-2.maceio.lab`;
   - senha gerada com `slappasswd` (nunca em texto puro no LDIF).

Exemplo de LDIF para um usuário do Grupo 0:

```ldif
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
userPassword: {SSHA}cole-aqui-a-saida-do-slappasswd
```

5. **Proteger o LDAP com TLS (StartTLS).** O SSSD só envia senhas por conexão criptografada, então este item é obrigatório:
   - criar uma autoridade certificadora (CA) do grupo e um certificado para o servidor LDAP com `openssl`, cujo campo *subjectAltName* contenha `ldap.grupo0.bsi-26-2.maceio.lab` e `g0-pc1-vm2.grupo0.bsi-26-2.maceio.lab`;
   - configurar `olcTLSCACertificateFile`, `olcTLSCertificateFile` e `olcTLSCertificateKeyFile` em `cn=config` com `ldapmodify -Y EXTERNAL -H ldapi:///`;
   - deixar a chave privada legível só por `root` e pelo grupo `openldap` (`chmod 640`);
   - copiar **apenas o certificado da CA** (`ca-grupo0.crt`) para `/usr/local/share/ca-certificates/` de todas as VMs e rodar `sudo update-ca-certificates`.

```bash
# CA do grupo e certificado do servidor LDAP (executar na VM ldap)
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout ca-grupo0.key -out ca-grupo0.crt -subj "/CN=CA do Grupo 0 - LSOR"
openssl req -newkey rsa:2048 -nodes -keyout ldap.key -out ldap.csr \
  -subj "/CN=ldap.grupo0.bsi-26-2.maceio.lab"
printf "subjectAltName=DNS:ldap.grupo0.bsi-26-2.maceio.lab,DNS:g0-pc1-vm2.grupo0.bsi-26-2.maceio.lab\n" > san.ext
openssl x509 -req -in ldap.csr -CA ca-grupo0.crt -CAkey ca-grupo0.key -CAcreateserial \
  -days 365 -extfile san.ext -out ldap.crt
```

**Verificação:**

```bash
ldapsearch -x -ZZ -H ldap://ldap.grupo0.bsi-26-2.maceio.lab \
  -b dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab "(objectClass=posixAccount)" uid uidNumber gidNumber
```

O parâmetro `-ZZ` obriga o StartTLS: se o certificado ou a CA estiverem errados, o comando falha.

> A chave da CA (`ca-grupo0.key`) e as senhas **não vão para o GitHub**. No tutorial, mostre os comandos e o resultado, não o conteúdo das chaves.

### 9. Login unificado em todas as VMs (SSSD)

Com o LDAP funcionando, **as 9 VMs** passam a buscar usuários, grupos e senhas nele pelo SSSD [9, 10].

**Requisitos:**

1. Instalar `sssd-ldap`, `libnss-sss`, `libpam-sss` e `ldap-utils`.
2. Criar `/etc/sssd/sssd.conf` (dono `root`, permissão `600`):

```ini
[sssd]
services = nss, pam
domains = grupo0

[domain/grupo0]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://ldap.grupo0.bsi-26-2.maceio.lab
ldap_search_base = dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
ldap_id_use_start_tls = true
ldap_tls_reqcert = demand
ldap_tls_cacert = /etc/ssl/certs/ca-certificates.crt
cache_credentials = true
```

3. Ativar a criação automática do home no primeiro login: `sudo pam-auth-update --enable mkhomedir`.
4. Dar `sudo` aos integrantes pelo grupo do LDAP, com `sudo visudo -f /etc/sudoers.d/lsor-g0`:

```
%lsor-g0 ALL=(ALL:ALL) ALL
```

5. **Remover as contas locais dos integrantes** criadas na Etapa 1 (`sudo userdel -r <login>`), depois de confirmar que o login pelo LDAP funciona. A conta local fica na frente da conta do LDAP e impediria o login unificado. **Mantenha o `administrador` local** em todas as VMs: ele é o acesso de emergência se o LDAP cair.

**Verificação (em cada VM):**

```bash
getent passwd fulano.tal          # deve mostrar uid 10001, vindo do LDAP
id fulano.tal                     # deve listar o grupo lsor-g0
grep fulano.tal /etc/passwd       # não deve aparecer: a conta local foi removida
ssh fulano.tal@www                # entra com a senha do LDAP e cria /home/fulano.tal
```

### 10. Servidor de arquivos — `arquivos` (Samba)

**Requisitos [11]:**

1. Criar dois compartilhamentos:

| Compartilhamento | Caminho | Acesso |
|:--|:--|:--|
| `publico` | `/srv/samba/publico` | Leitura para qualquer usuário, inclusive convidado (*guest*) |
| `grupo0` | `/srv/samba/grupo0` | Leitura e escrita só para o grupo `lsor-g0` do LDAP (`valid users = @lsor-g0`) |

2. A pasta `grupo0` pertence ao grupo `lsor-g0`, com permissão `2770` (o bit *setgid* faz os arquivos novos herdarem o grupo). No `smb.conf`, use `force group = lsor-g0`, `create mask = 0660` e `directory mask = 2770`.
3. O Samba guarda a senha dos usuários num formato próprio. Cadastre cada integrante com `sudo smbpasswd -a <login>`, usando a mesma senha do LDAP.
4. Validar a configuração com `testparm` antes de reiniciar o serviço.

> **Por que outra senha?** O Samba precisa de um *hash* de senha que o esquema POSIX do LDAP não guarda. Unificar também essa senha exige o esquema do Samba no LDAP (desafio opcional, seção 16).

**Verificação (na VM `cliente`):**

```bash
smbclient -L //arquivos.grupo0.bsi-26-2.maceio.lab -N
smbclient //arquivos.grupo0.bsi-26-2.maceio.lab/grupo0 -U fulano.tal -c 'put /etc/hostname teste.txt; ls'
smbclient //arquivos.grupo0.bsi-26-2.maceio.lab/grupo0 -U novato -c 'ls'   # deve ser negado
```

### 11. Servidor web — `www` (LAMP)

**Requisitos [12, 13, 14]:**

1. Instalar Apache, MariaDB e PHP, e rodar `sudo mysql_secure_installation`.
2. Criar um *virtual host* para `www.grupo0.bsi-26-2.maceio.lab` com a raiz em `/var/www/grupo0`.
3. Criar o banco `projeto`, com um usuário próprio (não usar o `root` do MariaDB na aplicação), e a tabela `servicos` com as colunas `hostname`, `ip`, `servico` e `descricao`, preenchida com a tabela da seção 5 do grupo.
4. Publicar a **página do projeto** (`index.php`) com:
   - o nome do grupo, os integrantes e o domínio;
   - a tabela `servicos`, lida do MariaDB pelo PHP (`mysqli` ou PDO);
   - um link para o repositório do grupo no GitHub.
5. Criar a **área restrita** `/restrito`, que pede usuário e senha do LDAP e só deixa entrar quem é do grupo `lsor-g0`, com o módulo `authnz_ldap` (`sudo a2enmod ldap authnz_ldap`):

```apache
# Fora do VirtualHost: confiar na CA do grupo
LDAPTrustedGlobalCert CA_BASE64 /usr/local/share/ca-certificates/ca-grupo0.crt

# Dentro do VirtualHost
<Location /restrito>
    AuthType Basic
    AuthName "Area restrita - Grupo 0"
    AuthBasicProvider ldap
    AuthLDAPURL "ldap://ldap.grupo0.bsi-26-2.maceio.lab/ou=usuarios,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab?uid" STARTTLS
    AuthLDAPGroupAttribute memberUid
    AuthLDAPGroupAttributeIsDN off
    Require ldap-group cn=lsor-g0,ou=grupos,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
</Location>
```

> Como os grupos POSIX guardam o **login** dos membros (`memberUid`) e não o DN completo, as duas linhas `AuthLDAPGroupAttribute` são necessárias para o `Require ldap-group` funcionar.

**Verificação (na VM `cliente`):**

```bash
curl -s http://www.grupo0.bsi-26-2.maceio.lab/ | head -20
curl -s -o /dev/null -w '%{http_code}\n' http://www.grupo0.bsi-26-2.maceio.lab/restrito/              # 401
curl -s -o /dev/null -w '%{http_code}\n' -u fulano.tal http://www.grupo0.bsi-26-2.maceio.lab/restrito/ # 200
curl -s -o /dev/null -w '%{http_code}\n' -u novato http://www.grupo0.bsi-26-2.maceio.lab/restrito/     # 401
```

### 12. SFTP — `sftp` (OpenSSH com *chroot*)

**Requisitos [15]:**

1. Usuários do grupo `sftpusers` do LDAP só podem usar SFTP nesta VM: sem terminal, sem redirecionamento de portas e presos ao próprio diretório. No final do `/etc/ssh/sshd_config`:

```
Match Group sftpusers
    ChrootDirectory /srv/sftp/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
```

2. O diretório do *chroot* precisa ser do `root` e não pode ter escrita para mais ninguém. O usuário escreve numa subpasta própria:

```bash
sudo mkdir -p /srv/sftp/novato/arquivos
sudo chown root:root /srv/sftp/novato && sudo chmod 755 /srv/sftp/novato
sudo chown novato:sftpusers /srv/sftp/novato/arquivos
```

3. Validar com `sudo sshd -t` antes de reiniciar o serviço `ssh`.
4. Os integrantes (grupo `lsor-g0`) continuam com acesso SSH normal à VM `sftp`.

**Verificação (na VM `cliente`):**

```bash
sftp novato@sftp.grupo0.bsi-26-2.maceio.lab     # put/get dentro de /arquivos funcionam
ssh novato@sftp.grupo0.bsi-26-2.maceio.lab      # deve ser recusado ("This service allows sftp connections only.")
```

### 13. E-mail — `mail` (Postfix e Dovecot)

O servidor entrega e-mail **apenas dentro do domínio do grupo**. As caixas postais são dos usuários do LDAP, que o SSSD já torna visíveis para o sistema [16, 17, 18].

**Requisitos:**

1. **Postfix** (configuração *Internet Site* na instalação):
   - `myhostname = mail.grupo0.bsi-26-2.maceio.lab` e `mydomain = grupo0.bsi-26-2.maceio.lab`;
   - `mydestination = $myhostname, $mydomain, localhost`;
   - `mynetworks = 127.0.0.0/8, 192.168.26.0/28` (só a rede do grupo envia pelo servidor);
   - `home_mailbox = Maildir/` (cada usuário recebe em `~/Maildir`).
2. **Dovecot** (`dovecot-imapd`), servindo IMAP com o formato Maildir e autenticando pelo PAM, que usa o SSSD. A forma de configurar o Maildir depende da versão (`dovecot --version`): na 2.4, em `/etc/dovecot/conf.d/10-mail.conf`, use `mail_driver = maildir` e `mail_path = ~/Maildir`; na 2.3, `mail_location = maildir:~/Maildir`.
3. O IMAP só aceita senha em conexão criptografada (STARTTLS); o certificado padrão do pacote serve para o projeto.
4. O diretório home de cada usuário precisa existir na VM `mail` antes da primeira mensagem: faça um login por SSH com cada integrante nessa VM (o `mkhomedir` cria o home).
5. O registro **MX** do domínio aponta para `mail` (seção 7).

**Verificação (na VM `cliente`):**

```bash
dig +short MX grupo0.bsi-26-2.maceio.lab
swaks --server mail.grupo0.bsi-26-2.maceio.lab \
      --from fulano.tal@grupo0.bsi-26-2.maceio.lab \
      --to beltrano.silva@grupo0.bsi-26-2.maceio.lab \
      --header "Subject: Teste do Projeto Final" --body "Mensagem de teste do Grupo 0"
curl -k --ssl-reqd -u beltrano.silva "imap://mail.grupo0.bsi-26-2.maceio.lab/INBOX" -X 'FETCH 1 BODY[HEADER.FIELDS (FROM SUBJECT)]'
```

Na VM `mail`, `sudo tail /var/log/mail.log` mostra a entrega (`status=sent`).

### 14. Gateway — redirecionamento de portas (DNAT)

As VMs do grupo ficam atrás do NAT, sem acesso a partir da rede do laboratório. No gateway, publique dois serviços na interface WAN com regras de DNAT e as regras de `FORWARD` correspondentes (ver [Aula 08](../Aula8.md)) [19]:

| Porta no gateway (WAN `172.20.23.X`) | Destino | Serviço |
|:--:|:--|:--|
| 80/tcp | `192.168.26.6:80` (`www`) | Página do projeto |
| 2222/tcp | `192.168.26.7:22` (`sftp`) | SFTP |

```bash
sudo iptables -t nat -A PREROUTING -i enp0s3 -p tcp --dport 80   -j DNAT --to-destination 192.168.26.6:80
sudo iptables -t nat -A PREROUTING -i enp0s3 -p tcp --dport 2222 -j DNAT --to-destination 192.168.26.7:22
sudo iptables -A FORWARD -i enp0s3 -o enp0s8 -p tcp -d 192.168.26.6 --dport 80 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o enp0s8 -p tcp -d 192.168.26.7 --dport 22 -m conntrack --ctstate NEW -j ACCEPT
sudo netfilter-persistent save
```

Teste a partir de um PC do laboratório (Windows): abrir `http://172.20.23.X/` no navegador e `sftp -P 2222 novato@172.20.23.X` no PowerShell.

> Os demais serviços (LDAP, DNS, Samba, IMAP) **não** são publicados: ficam acessíveis só dentro da rede do grupo.

### 15. Testes obrigatórios

Registre no tutorial o comando e a saída (texto ou captura de tela) de cada teste, a partir da VM `cliente` quando não houver outra indicação:

| # | Serviço | Teste | Resultado esperado |
|:--:|:--|:--|:--|
| 1 | DNS | `dig @ns1 www.grupo0.bsi-26-2.maceio.lab` e o mesmo com `@ns2` | CNAME para `g0-pc3-vm1` e o IP `.6`, com resposta autoritativa (`aa`) |
| 2 | DNS | `dig -x 192.168.26.8` | PTR `g0-pc4-vm1.grupo0.bsi-26-2.maceio.lab.` |
| 3 | DNS | `dig @ns1 grupo0.bsi-26-2.maceio.lab SOA` e `@ns2` | Mesmo serial nos dois servidores |
| 4 | DNS | Desligar `ns1` e repetir o teste 1 sem `@` | O `ns2` responde sozinho |
| 5 | DNS | `dig google.com` | Resposta via *forwarders* |
| 6 | LDAP | `ldapsearch -x -ZZ ...` (seção 8) | Usuários e grupos listados com StartTLS |
| 7 | Login | `getent passwd fulano.tal` e `id fulano.tal` em 3 VMs diferentes | Mesmo `uid` e grupos em todas |
| 8 | Login | `ssh fulano.tal@<vm>` em 3 VMs diferentes e `sudo -l` | Login com a senha do LDAP e `sudo` liberado |
| 9 | Login | Trocar a senha de um usuário no LDAP (`ldappasswd`) e entrar numa VM | A senha nova vale em todas as VMs |
| 10 | Samba | Comandos da seção 10 | `publico` legível, `grupo0` gravável só por integrantes |
| 11 | Web | `curl` da seção 11 | Página com a tabela do MariaDB; `/restrito` com 401, 200 e 401 |
| 12 | SFTP | Comandos da seção 12 | `novato` transfere arquivos, mas não abre terminal |
| 13 | E-mail | `swaks` e `curl imap://...` da seção 13 | Mensagem entregue e lida pelo IMAP |
| 14 | Gateway | Acesso pela WAN (seção 14) e `sudo iptables -t nat -L -n -v` | Contadores das regras de DNAT aumentam |

### 16. Desafios opcionais (bônus)

- **HTTPS** no `www`, com certificado assinado pela CA do grupo e redirecionamento de HTTP para HTTPS.
- **Webmail** (Roundcube) no `www`, lendo as caixas do `mail` por IMAP.
- **Senha única também no Samba**, com o esquema do Samba no LDAP.
- **Zona reversa *classless*** (RFC 2317) [5].
- **Replicação do LDAP** (*syncrepl*) para uma segunda VM.
- **Backup automático** do banco `projeto` e do diretório LDAP (`mysqldump` e `slapcat`) com `cron`, salvo no compartilhamento `grupo0`.

---

## Entregas

Seguem as mesmas regras da Etapa 1: o grupo documenta tudo no **repositório do projeto do grupo no GitHub**, com o tutorial no [Modelo de 7 Passos](../README.md).

1. **Planilha de acompanhamento:** completar as tabelas do grupo com o **nome de serviço** de cada VM e os usuários do LDAP (login e `uidNumber`). Nunca coloque senhas na planilha.
2. **Diagrama de topologia** do grupo, adaptado das Figuras 1 e 2 com os IPs e nomes do grupo.
3. **Tutorial**, com uma seção por serviço (seções 7 a 14), contendo:
   - a configuração de hardware de cada VM (memória, CPUs, disco);
   - os arquivos de configuração alterados (zonas do BIND, `sssd.conf`, `smb.conf`, *virtual host* do Apache, trecho do `sshd_config`, `main.cf` do Postfix, regras do `iptables`) — **sem senhas, chaves privadas ou *hashes***;
   - os LDIF usados para criar a estrutura do diretório, com o campo `userPassword` removido;
   - as evidências dos 14 testes da seção 15;
   - os problemas encontrados e como foram resolvidos.
4. **Apresentação final** do ambiente funcionando, com os testes executados ao vivo.

**Prazos:** data a definir.

---

## Referências

[1] INTERNET SYSTEMS CONSORTIUM. **BIND 9 Administrator Reference Manual**. Disponível em: <https://bind9.readthedocs.io/>.

[2] CANONICAL. **Domain Name Service (DNS)**. Ubuntu Server documentation. Disponível em: <https://ubuntu.com/server/docs/how-to/networking/install-dns/>.

[3] MOCKAPETRIS, P. **RFC 1034 — Domain Names: Concepts and Facilities** e **RFC 1035 — Domain Names: Implementation and Specification**. IETF, 1987. Disponíveis em: <https://www.rfc-editor.org/rfc/rfc1034> e <https://www.rfc-editor.org/rfc/rfc1035>.

[4] ELZ, R.; BUSH, R. **RFC 2181 — Clarifications to the DNS Specification** (seção 10.3: MX e NS não podem apontar para um apelido). IETF, 1997. Disponível em: <https://www.rfc-editor.org/rfc/rfc2181>.

[5] EIDNES, H.; DE GROOT, G.; VIXIE, P. **RFC 2317 — Classless IN-ADDR.ARPA delegation**. IETF, 1998. Disponível em: <https://www.rfc-editor.org/rfc/rfc2317>.

[6] CANONICAL. **Install and configure LDAP**. Ubuntu Server documentation. Disponível em: <https://documentation.ubuntu.com/server/how-to/openldap/install-openldap>.

[7] OPENLDAP FOUNDATION. **OpenLDAP Software Administrator's Guide**. Disponível em: <https://www.openldap.org/doc/admin26/>.

[8] HOWARD, L. **RFC 2307 — An Approach for Using LDAP as a Network Information Service**. IETF, 1998. Disponível em: <https://www.rfc-editor.org/rfc/rfc2307>.

[9] CANONICAL. **How to set up SSSD with LDAP**. Ubuntu Server documentation. Disponível em: <https://documentation.ubuntu.com/server/how-to/sssd/with-ldap>.

[10] SSSD PROJECT. **sssd-ldap(5)** — página de manual. Disponível em: <https://manpages.ubuntu.com/manpages/noble/man5/sssd-ldap.5.html>.

[11] CANONICAL. **Set up Samba as a file server**. Ubuntu Server documentation. Disponível em: <https://ubuntu.com/server/docs/how-to/samba/file-server/>.

[12] APACHE SOFTWARE FOUNDATION. **Apache HTTP Server Version 2.4 Documentation — Virtual Hosts**. Disponível em: <https://httpd.apache.org/docs/2.4/vhosts/>.

[13] APACHE SOFTWARE FOUNDATION. **Apache Module mod_authnz_ldap**. Disponível em: <https://httpd.apache.org/docs/2.4/mod/mod_authnz_ldap.html>.

[14] THE PHP GROUP. **PHP Manual — MySQL Improved Extension (mysqli)**. Disponível em: <https://www.php.net/manual/en/book.mysqli.php>.

[15] OPENBSD PROJECT. **sshd_config(5)** — opções `Match`, `ChrootDirectory` e `ForceCommand`. Disponível em: <https://man.openbsd.org/sshd_config>.

[16] CANONICAL. **Mail services**. Ubuntu Server documentation. Disponível em: <https://documentation.ubuntu.com/server/how-to/mail-services>.

[17] DOVECOT. **Upgrading Dovecot CE from 2.3 to 2.4**. Disponível em: <https://doc.dovecot.org/main/installation/upgrade/2.3-to-2.4.html>.

[18] KLENSIN, J. **RFC 5321 — Simple Mail Transfer Protocol**. IETF, 2008. Disponível em: <https://www.rfc-editor.org/rfc/rfc5321>.

[19] NETFILTER PROJECT. **iptables-extensions(8)** — alvo `DNAT` e módulo `conntrack`. Disponível em: <https://ipset.netfilter.org/iptables-extensions.man.html>.

[20] KUROSE, James F.; ROSS, Keith W. **Redes de Computadores e a Internet**. 8. ed. Pearson, 2022. (Capítulo 2: DNS e correio eletrônico.)

[21] LACROIX, Jay. **Mastering Ubuntu Server**. 4. ed. Packt Publishing, 2023.
