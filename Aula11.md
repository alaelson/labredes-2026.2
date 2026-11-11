# Aula 11: Projeto Final — Servidor de Arquivos (Samba e SFTP) e Aplicação Web em Duas Camadas

Objetivo: implantar os serviços que o usuário final enxerga, todos usando as contas do LDAP da [Aula 10](Aula10.md): o **servidor de arquivos** com as mesmas pastas por Samba e por SFTP, e o **site do grupo** com Apache e PHP no `www` e MariaDB no `bd`, com a área de administração protegida pelo LDAP. Fecha com o **roteiro da apresentação de 02/12**. Corresponde às seções 11, 12 e 14 do [Projeto Final](projeto-final/README.md).

**Duração:** 1h30 em sala + continuação pelo grupo · **Ambiente:** VirtualBox, VMs da Etapa 1 · **Pré-requisito:** Aula 10 funcionando (DNS do grupo, LDAP e SSSD em todas as VMs)

---

## Organização da aula

| Tempo | Parte | O que o grupo faz |
|:--|:--|:--|
| 0–5 min | Orientação | Conferir o pré-requisito (seção 0) e dividir as tarefas |
| 5–35 min | Arquivos | Samba e SFTP na VM `arquivos`, testes do `cliente` e do PC do laboratório (seção 1) |
| 35–75 min | Web e banco | MariaDB no `bd`, Apache e PHP no `www`, site demo e área `/admin` com LDAP (seção 2) |
| 75–90 min | Apresentação | Roteiro de 02/12 e ensaio dos testes (seção 3) |

As seções 1 e 2 podem andar **em paralelo**: um integrante no `arquivos` (PC3), outros dois no `www` e no `bd` (PC2).

---

## 0. Pré-requisito (na VM `cliente`)

```bash
dig +short arquivos www bd ldap      # quatro IPs do grupo
getent passwd fulano.tal             # uid 10001, vindo do LDAP
ssh fulano.tal@www 'id'              # entra com a senha do LDAP e mostra o grupo lsor-g0
```

Se algum dos três falhar, termine a Aula 10 antes de continuar. Tire um **snapshot** do `arquivos`, do `www` e do `bd` (`antes-aula11`).

---

## 1. Servidor de arquivos — `arquivos`

O `arquivos` oferece **as mesmas pastas** por dois protocolos: Samba, para abrir no Explorer do Windows, e SFTP, para transferir com FileZilla, WinSCP ou o `sftp` do terminal [1, 2].

**Tabela 1:** Pastas e acessos (Grupo 0)

| Compartilhamento | Caminho | Samba | SFTP |
|:--|:--|:--|:--|
| `publico` | `/srv/arquivos/publico` | Leitura para todos, inclusive convidado | Leitura para os integrantes |
| `grupo0` | `/srv/arquivos/grupo0` | Leitura e escrita só para o grupo `lsor-g0` | Leitura e escrita para os integrantes |
| — | `/srv/sftp/novato/arquivos` | — | Só o `novato`, preso a essa pasta e sem terminal |

### 1.1 Instalação e pastas

```bash
sudo apt-get update
sudo apt-get install -y samba smbclient
sudo systemctl status smbd --no-pager
sudo ss -tlnp | grep -E ':(139|445)\s'      # Samba escutando nas portas 139 e 445

sudo mkdir -p /srv/arquivos/publico /srv/arquivos/grupo0
sudo chown root:lsor-g0 /srv/arquivos/publico /srv/arquivos/grupo0   # lsor-g0 vem do LDAP
sudo chmod 2775 /srv/arquivos/publico
sudo chmod 2770 /srv/arquivos/grupo0
ls -ld /srv/arquivos/*
```

O bit **setgid** (o `2` de `2770`) faz todo arquivo criado na pasta herdar o grupo `lsor-g0`, venha ele pelo Samba ou pelo SFTP.

### 1.2 Configuração do Samba

Guarde o arquivo original e crie um novo, só com o necessário:

```bash
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.original
sudo nano /etc/samba/smb.conf
```

```ini
[global]
   workgroup = LSOR
   server string = Arquivos do Grupo 0
   server role = standalone server
   map to guest = Bad User
   log file = /var/log/samba/log.%m
   max log size = 1000

[publico]
   path = /srv/arquivos/publico
   read only = yes
   guest ok = yes
   write list = @lsor-g0

[grupo0]
   path = /srv/arquivos/grupo0
   valid users = @lsor-g0
   read only = no
   force group = lsor-g0
   create mask = 0660
   directory mask = 2770
```

```bash
testparm -s                 # deve terminar sem erros e listar os dois compartilhamentos
sudo systemctl restart smbd
```

### 1.3 Senha do Samba para cada integrante

O Samba autentica com um *hash* próprio, que o LDAP do projeto não guarda. Cadastre cada integrante **com a mesma senha do LDAP**. O `smbpasswd` só aceita o login porque o SSSD já faz o sistema enxergar a conta:

```bash
sudo smbpasswd -a fulano.tal
sudo smbpasswd -a beltrano.silva
sudo pdbedit -L             # integrantes cadastrados no Samba
```

### 1.4 SFTP

**Integrantes:** nada a configurar. O SFTP é parte do SSH, e o login já vem do LDAP. Eles enxergam o sistema todo, com as permissões normais, e trabalham em `/srv/arquivos`.

**`novato`:** só SFTP, preso à própria pasta. No **final** do `/etc/ssh/sshd_config`:

```
Match Group sftpusers
    ChrootDirectory /srv/sftp/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
```

```bash
sudo mkdir -p /srv/sftp/novato/arquivos
sudo chown root:root /srv/sftp/novato && sudo chmod 755 /srv/sftp/novato   # exigência do ChrootDirectory
sudo chown novato:sftpusers /srv/sftp/novato/arquivos
sudo sshd -t && sudo systemctl restart ssh
```

### 1.5 Testes do servidor de arquivos

**Da VM `cliente`:**

```bash
sudo apt-get install -y smbclient mariadb-client              # clientes de teste (uma vez)
smbclient -L //arquivos -N                                   # lista publico e grupo0 sem senha
smbclient //arquivos/grupo0 -U fulano.tal -c 'put /etc/hostname teste-smb.txt; ls'
sftp fulano.tal@arquivos <<< 'ls /srv/arquivos/grupo0'       # o arquivo do Samba aparece no SFTP
smbclient //arquivos/grupo0 -U novato -c 'ls'                # NT_STATUS_ACCESS_DENIED
sftp novato@arquivos <<< 'ls'                                # só a pasta arquivos
ssh novato@arquivos                                          # recusado: só SFTP
```

**Do PC do laboratório**, pelo encaminhamento de portas do `gw` (Aula 10, seção 2):

| Teste | Como | Resultado esperado |
|:--|:--|:--|
| Samba | No Explorer, `\\<WAN do gw>\grupo0`, com usuário `fulano.tal` e a senha | Pasta aberta; criar e apagar um arquivo funciona |
| SFTP | FileZilla ou WinSCP: servidor `<WAN do gw>`, porta **2206**, protocolo SFTP; ou `sftp -P 2206 fulano.tal@<WAN do gw>` no PowerShell | O arquivo gravado pelo Explorer aparece em `/srv/arquivos/grupo0` |

> O Windows 10 e 11 bloqueiam o acesso de **convidado** a compartilhamentos por padrão. O `publico` abre no Explorer com a conta de um integrante; o acesso sem senha se testa com o `smbclient -N` no `cliente` [6].

---

## 2. Aplicação web em duas camadas — `bd` e `www`

O passo a passo completo está no [README do site demo](projeto-final/site-demo/README.md) [3, 4, 5]. Siga-o com as adaptações abaixo, que valem para a fase do VirtualBox.

**Tabela 2:** Adaptações para o VirtualBox (Grupo 0)

| No README do site demo | No VirtualBox |
|:--|:--|
| `www` = `10.10.101.4`, `bd` = `10.10.101.5` | `www` = `192.168.26.4`, `bd` = `192.168.26.5` (some `16·X` no seu grupo) |
| `bind-address = 10.10.101.5` | `bind-address = 192.168.26.5` |
| Envio por SFTP do computador na VPN | Do PC do laboratório, porta **2204** do `gw`: `sftp -P 2204 fulano.tal@<WAN do gw>` |
| `AuthLDAPURL "ldap://…" STARTTLS` e `LDAPTrustedGlobalCert` | **Sem TLS:** apague a palavra `STARTTLS` do fim da linha e a linha `LDAPTrustedGlobalCert` |
| Teste com `curl http://www.grupo0…` do computador na VPN | Por nome, do `cliente`; no navegador do PC, `http://<WAN do gw>/` |

### 2.1 Banco de dados (`bd`)

```bash
sudo apt-get install -y mariadb-server
sudo mysql_secure_installation
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf     # bind-address = 192.168.26.5
```

Ajuste o script do banco ao seu grupo antes de carregá-lo. No Grupo 0, basta trocar o prefixo da rede; nos outros grupos, confira também o último octeto de cada VM na tabela `host`:

```bash
sed -i 's/10\.10\.101\./192.168.26./g' criar-banco.sql
nano criar-banco.sql                   # IP do www no usuário siteapp e a senha TROQUE-ESTA-SENHA
sudo systemctl restart mariadb
sudo mariadb < criar-banco.sql
sudo ss -tlnp | grep 3306             # 192.168.26.5:3306
```

### 2.2 Servidor web (`www`)

Siga a seção 2 do README do site demo: instalação de `apache2`, `php`, `libapache2-mod-php`, `php-mysql` e `mariadb-client`, teste de rede até o banco, envio do site por SFTP, permissões para o grupo `lsor-g0` e `config.php`.

No *virtual host*, aplique a variante sem TLS:

```apache
    AuthLDAPURL "ldap://ldap.grupo0.bsi-26-2.maceio.lab/ou=usuarios,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab?uid?one"
```

```bash
sudo a2enmod ldap authnz_ldap
sudo a2ensite www.grupo0.bsi-26-2.maceio.lab
sudo a2dissite 000-default            # o site do grupo passa a ser o padrão, inclusive pelo IP da WAN do gw
sudo apache2ctl configtest && sudo systemctl reload apache2
```

Desativar o `000-default` é o que faz `http://<WAN do gw>/` abrir o site do grupo: o pedido chega pelo DNAT com o IP no lugar do nome, e o Apache entrega o primeiro *virtual host* habilitado.

### 2.3 Testes da aplicação

**Da VM `cliente`:**

```bash
curl -s http://www.grupo0.bsi-26-2.maceio.lab/ | grep -o 'Conectado[^<]*'                         # conexão com o bd
curl -s -o /dev/null -w '%{http_code}\n' http://www/admin/                                       # 401
curl -s -o /dev/null -w '%{http_code}\n' -u fulano.tal http://www/admin/                         # 200
curl -s -o /dev/null -w '%{http_code}\n' -u novato http://www/admin/                             # 401: fora do lsor-g0
mariadb -h bd -u siteapp -p projeto -e 'SELECT 1'                                                 # recusado: só o www entra
```

**Do PC do laboratório:** abra `http://<WAN do gw>/` no navegador, entre em **Administrar** com a conta de um integrante e cadastre, edite e remova um registro de cada tabela. No `bd`, confira:

```bash
sudo mariadb projeto -e 'SELECT * FROM grupo; SELECT * FROM aluno; SELECT * FROM host;'
```

**Firewall:** no PowerShell do PC, `Test-NetConnection <WAN do gw> -Port 3306` deve falhar. Só as portas da Tabela 2 da Aula 10 atravessam o `gw`.

### 2.4 Problemas comuns

| Sintoma | Causa provável | O que fazer |
|:--|:--|:--|
| `testparm` acusa erro | Nome de parâmetro digitado errado | Corrija a linha indicada e rode de novo |
| Explorer pede senha e não aceita | Integrante sem `smbpasswd -a` | Seção 1.3 |
| `novato` não entra por SFTP | Pasta do *chroot* não pertence ao `root` ou tem escrita para o grupo | `ls -ld /srv/sftp/novato` deve mostrar `root root drwxr-xr-x` |
| Página mostra erro de conexão com o banco | `bind-address` ainda em `127.0.0.1`, ou usuário `siteapp` criado com outro IP | `ss -tlnp` no `bd` e o IP no `criar-banco.sql` |
| `/admin` sempre devolve 401 | `STARTTLS` ainda na linha `AuthLDAPURL`, ou base do LDAP errada | `sudo tail /var/log/apache2/www.grupo0-error.log` |
| `http://<WAN do gw>/` mostra a página padrão do Apache | `000-default` ainda habilitado | `sudo a2dissite 000-default` e `reload` |

---

## 3. Apresentação de 02/12

Cada grupo apresenta **ao vivo**, a partir da VM `cliente` e do PC do laboratório, nesta ordem. Deixe os comandos prontos num arquivo de texto e as VMs ligadas antes da aula.

| # | Serviço | O que mostrar | De onde |
|:--:|:--|:--|:--|
| 1 | Topologia | Diagrama do grupo e a tabela de nomes e IPs | Repositório do grupo |
| 2 | Gateway | `ping 1.1.1.1` de uma VM; `iptables -L FORWARD -n -v` no `gw` | `cliente` e `gw` |
| 3 | DNS | `dig www`, `dig -x` de um IP, `dig MX`, SOA igual no `ns1` e no `ns2` | `cliente` |
| 4 | DNS | Desligar o `named` do `ns1` e resolver um nome pelo `ns2` | `ns1` e `cliente` |
| 5 | LDAP | `ldapsearch` com as contas e os grupos | `cliente` |
| 6 | Login unificado | `ssh` com o mesmo integrante em três VMs; `id` e `sudo -l`; troca de senha com `ldappasswd` valendo em todas | `cliente` |
| 7 | Arquivos | Gravar pelo Explorer e ver o arquivo pelo SFTP; `novato` negado no Samba e preso no SFTP | PC do laboratório e `cliente` |
| 8 | Web | Site pelo IP da WAN do `gw`; `/admin` com a conta do LDAP; cadastro refletido no `bd` | PC do laboratório e `bd` |
| 9 | Firewall | Porta 3306 bloqueada a partir do PC | PC do laboratório |
| 10 | Bônus | TLS no LDAP, e-mail ou outro desafio da seção 15 do enunciado, se houver | — |

Cada integrante deve saber explicar pelo menos um serviço. Se o servidor do laboratório ficar pronto antes de 02/12, a mesma sequência é feita lá, pela VPN da turma.

---

## 4. Registro no repositório do grupo

1. **Arquivos:** `smb.conf`, `testparm -s`, `pdbedit -L`, o trecho `Match` do `sshd_config` e os testes da seção 1.5, incluindo a captura do Explorer.
2. **Web e banco:** `50-server.cnf` (só o `bind-address`), o *virtual host*, `apache2ctl -S`, os testes da seção 2.3 e capturas das páginas de início, consulta e administração.
3. Sem senhas, *hashes* ou o conteúdo do `config.php`.

---

## Referências

[1] SAMBA TEAM. **smb.conf(5)** — opções `valid users`, `write list`, `force group`, `create mask`, `directory mask` e `map to guest`. Disponível em: <https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html>.

[2] OPENBSD PROJECT. **sshd_config(5)** — opções `Match`, `ChrootDirectory` e `ForceCommand`. Disponível em: <https://man.openbsd.org/sshd_config>.

[3] APACHE SOFTWARE FOUNDATION. **Apache HTTP Server Version 2.4 Documentation — Virtual Hosts**. Disponível em: <https://httpd.apache.org/docs/2.4/vhosts/>.

[4] APACHE SOFTWARE FOUNDATION. **Apache Module mod_authnz_ldap**. Disponível em: <https://httpd.apache.org/docs/2.4/mod/mod_authnz_ldap.html>.

[5] MARIADB FOUNDATION. **MariaDB Knowledge Base — Configuring MariaDB for Remote Client Access**. Disponível em: <https://mariadb.com/kb/en/configuring-mariadb-for-remote-client-access/>.

[6] MICROSOFT. **Guest access in SMB2 and SMB3 disabled by default in Windows**. Disponível em: <https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/guest-access-in-smb2-is-disabled-by-default>.
