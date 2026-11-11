# Aula 10: Diretório LDAP do Grupo e Login Unificado com SSSD

Objetivo: entender como funciona um diretório LDAP e montar, na VM `ldap`, o **diretório do grupo** com os usuários e grupos do projeto, e depois ligar o **login unificado** (SSSD) nas 9 VMs: cada integrante passa a ter uma única conta e senha, guardadas no LDAP. Corresponde às seções 9 e 10 do [Projeto Final](projeto-final/README.md).

**Duração:** 1h30 · **Ambiente:** VirtualBox, as 9 VMs da Etapa 1 · **Base:** [Aula 09](Aula9.md) (DNS do grupo funcionando)

**Pré-requisito:** todas as VMs resolvem `ldap.grupo0.bsi-26-2.maceio.lab` → `192.168.26.7` (seção 8 da Aula 09). Confira na VM `cliente` com `dig +short ldap`.

---

## Organização da aula

| Tempo | Parte | Conteúdo |
|:--|:--|:--|
| 0–20 min | Teoria | LDAP: árvore do diretório, DN, classes de objeto, LDIF e login unificado (seção 1) |
| 20–50 min | Prática 1 | OpenLDAP na VM `ldap`: grupos e contas dos integrantes (seções 2 e 3) |
| 50–80 min | Prática 2 | Login unificado: remover as contas locais e configurar o SSSD nas 9 VMs (seções 4 e 5) |
| 80–90 min | Checagem | Testes da seção 6 e o que precisa estar pronto para a Aula 11 |

---

## 1. Conceitos

### 1.1 Diretório LDAP

O LDAP é um protocolo de acesso a um **diretório**: um banco de dados organizado em árvore, otimizado para muitas leituras e poucas escritas, usado para guardar as contas, os grupos e as senhas de uma organização [1, 2]. Com o esquema da RFC 2307, cada entrada guarda os mesmos campos de `/etc/passwd` e `/etc/group` [3].

**Figura 1:** Árvore do diretório do Grupo 0.

```mermaid
flowchart TD
    B["dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab<br/>(base, vem do domínio DNS)"] --> U["ou=usuarios"]
    B --> G["ou=grupos"]
    U --> F["uid=fulano.tal<br/>uidNumber 10001"]
    U --> BE["uid=beltrano.silva<br/>uidNumber 10002"]
    U --> N["uid=novato<br/>uidNumber 10100"]
    G --> L["cn=lsor-g0<br/>gidNumber 10000"]
    G --> S["cn=sftpusers<br/>gidNumber 10001"]
```

| Termo | Significado | Exemplo |
|:--|:--|:--|
| **DN** (*Distinguished Name*) | Endereço completo e único de uma entrada, da folha até a base | `uid=fulano.tal,ou=usuarios,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab` |
| **Base** | Raiz da árvore: o domínio DNS escrito em componentes `dc=` | `dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab` |
| **OU** | Pasta que organiza entradas | `ou=usuarios`, `ou=grupos` |
| **objectClass** | Define quais atributos a entrada pode ou deve ter | `posixAccount` exige `uidNumber`, `gidNumber` e `homeDirectory` |
| **LDIF** | Formato de texto para criar ou alterar entradas | arquivo `grupo0.ldif` da seção 3 |
| **Bind** | Autenticação no LDAP com um DN e uma senha | `ldapwhoami -D uid=fulano.tal,...` |

**De onde vem a base.** Por convenção, cada parte do nome DNS vira um componente `dc=` (*domain component*) [4]: o domínio `grupo0.bsi-26-2.maceio.lab` gera a base `dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab`. No Grupo 1, `dc=grupo1,dc=bsi-26-2,dc=maceio,dc=lab`.

**Do `/etc/passwd` para o LDAP.** A mesma informação, em outro lugar:

| `/etc/passwd` e `/etc/group` | Atributo no LDAP | Valor de `fulano.tal` |
|:--|:--|:--|
| nome de usuário | `uid` | `fulano.tal` |
| UID | `uidNumber` | `10001` |
| GID do grupo primário | `gidNumber` | `10000` (`lsor-g0`) |
| nome completo | `cn` | `Fulano de Tal` |
| diretório home | `homeDirectory` | `/home/fulano.tal` |
| shell | `loginShell` | `/bin/bash` |
| senha (no `/etc/shadow`) | `userPassword` | `{SSHA}...` |
| membros do grupo | `memberUid` (no `posixGroup`) | `fulano.tal` |

### 1.2 Login unificado

Quando o Linux procura um usuário, ele consulta o **NSS** (quem é: UID, grupos, home) e o **PAM** (a senha confere?). Com o **SSSD**, essas consultas vão ao LDAP, e a mesma conta passa a valer em todas as VMs [5, 6]:

**Figura 2:** Caminho de um `ssh fulano.tal@www`.

```mermaid
flowchart LR
    S["ssh fulano.tal@www"] --> N["NSS e PAM<br/>(na VM www)"]
    N --> X["SSSD<br/>(com cache)"]
    X -->|"1. onde fica ldap.grupo0...?"| DNS["ns1 / ns2"]
    X -->|"2. busca a conta e faz o bind com a senha"| L["ldap<br/>192.168.26.7"]
```

> **Segurança.** A porta 389 trafega em texto puro, inclusive a senha do *bind*. No projeto deste semestre isso é aceito porque tudo fica na rede interna do grupo; o SSSD exige uma opção explícita para isso (seção 5). Em produção, usa-se TLS — é um dos bônus do projeto.

---

## 2. Prática 1 — Instalar o OpenLDAP (`ldap`)

Tire um *snapshot* da VM `ldap` (`antes-aula10`). Depois [7]:

```bash
sudo apt-get update
sudo apt-get install -y slapd ldap-utils
sudo dpkg-reconfigure slapd
```

| Pergunta | Resposta (Grupo 0) |
|:--|:--|
| *Omit OpenLDAP server configuration?* | **No** |
| *DNS domain name* | `grupo0.bsi-26-2.maceio.lab` (gera a base `dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab`) |
| *Organization name* | `LSOR Grupo 0` |
| *Administrator password* | senha definida pelo grupo (não publique) |
| *Do you want the database to be removed when slapd is purged?* | **No** |
| *Move old database?* | **Yes** |

Confira a base e a conta do administrador:

```bash
sudo slapcat | head -20                                            # dn: dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
ldapwhoami -x -H ldap://localhost -D cn=admin,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab -W
```

---

## 3. Grupos e contas do projeto (`ldap`)

### 3.1 Gerar as senhas

Para cada integrante e para o `novato`, gere um *hash* da senha:

```bash
slappasswd          # digite a senha duas vezes; copie a saída {SSHA}...
```

O LDIF guarda só o *hash*, nunca a senha em texto puro.

### 3.2 Criar o LDIF

Crie o `grupo0.ldif` com **uma entrada por integrante**, seguindo o modelo (troque `fulano.tal` e `beltrano.silva` pelos logins do seu grupo, os mesmos da Etapa 1):

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
| `gidNumber 10000` (grupo `lsor-g0`) para os integrantes | É o grupo que dá `sudo`, a pasta do grupo e o `/admin` do site |
| `novato` no grupo `sftpusers`, com `/usr/sbin/nologin` | Só vai usar SFTP restrito no `arquivos` (Aula 11) |
| Uma linha em branco entre as entradas | É o separador de entradas do LDIF |

### 3.3 Carregar e consultar

```bash
ldapadd -x -D cn=admin,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab -W -f grupo0.ldif
```

Consultas, primeiro na própria VM `ldap` e depois na VM `cliente` (pelo nome do DNS):

```bash
sudo apt-get install -y ldap-utils         # só no cliente

# 1. As contas POSIX, com os campos usados pelo Linux
ldapsearch -x -LLL -H ldap://ldap.grupo0.bsi-26-2.maceio.lab \
  -b dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab "(objectClass=posixAccount)" uid uidNumber gidNumber loginShell

# 2. Os membros do grupo lsor-g0
ldapsearch -x -LLL -H ldap://ldap -b ou=grupos,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab "(cn=lsor-g0)" memberUid

# 3. Bind com a conta de fulano.tal: confere a senha
ldapwhoami -x -H ldap://ldap -D uid=fulano.tal,ou=usuarios,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab -W
```

| Opção | Significado |
|:--|:--|
| `-x` | Autenticação simples (DN e senha) |
| `-LLL` | Saída em LDIF, sem comentários |
| `-H ldap://ldap` | Servidor, pelo nome curto do DNS |
| `-b` | Base da busca |
| `-D` e `-W` | DN do *bind* e pedir a senha |

**Acrescentar um integrante depois:** crie um LDIF só com a nova conta e use `ldapadd`; para incluí-lo no grupo, use `ldapmodify` com:

```ldif
dn: cn=lsor-g0,ou=grupos,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
changetype: modify
add: memberUid
memberUid: cicrano.souza
```

> O `grupo0.ldif` com os *hashes* **não vai para o GitHub**. No tutorial, mostre o LDIF sem as linhas `userPassword`.

---

## 4. Prática 2 — Remover as contas locais (todas as 9 VMs)

Na Etapa 1, cada integrante ganhou uma conta local em todas as VMs. Com o LDAP, essas contas atrapalham: o Linux consulta primeiro o `/etc/passwd` e usaria a conta local, com outro UID e outra senha. **Mantenha o `administrador`** e remova só as contas dos integrantes:

```bash
# Entre como administrador. Troque pela lista do seu grupo.
for u in fulano.tal beltrano.silva cicrano.souza; do
  sudo deluser --remove-home "$u"
done
getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 {print $1, $3}'   # deve sobrar só o administrador
```

> Se houver algum arquivo da Etapa 1 que você queira guardar, copie-o antes para o home do `administrador`.

---

## 5. Login unificado com SSSD (todas as 9 VMs)

Faça primeiro na VM `cliente`, teste, e depois repita nas outras 8 (inclusive `gw` e `ldap`) [5, 6].

```bash
sudo apt-get install -y sssd-ldap libnss-sss libpam-sss ldap-utils
sudo nano /etc/sssd/sssd.conf
```

`/etc/sssd/sssd.conf`:

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
# Projeto sem TLS: libera o bind com senha em texto puro na rede interna
ldap_auth_disable_tls_never_use_in_production = true
```

| Linha | Função |
|:--|:--|
| `id_provider = ldap` | Usuários e grupos (NSS) vêm do LDAP |
| `auth_provider = ldap` | A senha (PAM) é conferida com um *bind* no LDAP |
| `ldap_uri` | Servidor, pelo nome do DNS |
| `cache_credentials` | Guarda a última senha válida: o login continua se o `ldap` cair por pouco tempo |
| `ldap_auth_disable_tls_never_use_in_production` | Sem ela, o SSSD recusa a senha por falta de TLS |

```bash
sudo chmod 600 /etc/sssd/sssd.conf          # o SSSD não sobe com outra permissão
sudo systemctl restart sssd
sudo pam-auth-update --enable mkhomedir     # cria o /home no primeiro login

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
getent passwd fulano.tal       # fulano.tal:*:10001:10000:Fulano de Tal:/home/fulano.tal:/bin/bash
id fulano.tal                  # grupo lsor-g0 (10000)
grep fulano.tal /etc/passwd    # não aparece: a conta não é local
```

> **Mantenha o `administrador` local em todas as VMs.** É o acesso de emergência se o LDAP ou o DNS caírem.

---

## 6. Checagem do fim da aula (na VM `cliente`)

Correspondem aos testes 6 a 8 da seção 13 do enunciado.

```bash
ldapsearch -x -LLL -H ldap://ldap -b dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab uid   # integrantes e novato
ssh fulano.tal@www          # senha do LDAP; o home é criado no primeiro login
id; sudo -l; exit           # grupo lsor-g0 e sudo liberado
ssh fulano.tal@bd           # mesma senha
ssh fulano.tal@arquivos     # mesma senha
ssh novato@www              # recusado: shell /usr/sbin/nologin
```

**Troca de senha valendo em todas as VMs**, na VM `ldap`:

```bash
ldappasswd -x -D cn=admin,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab -W -S \
  uid=fulano.tal,ou=usuarios,dc=grupo0,dc=bsi-26-2,dc=maceio,dc=lab
```

Repita `ssh fulano.tal@www` e `ssh fulano.tal@bd` com a senha nova: ela vale nas duas sem mexer nas VMs.

### 6.1 Problemas comuns

| Sintoma | Causa provável | O que fazer |
|:--|:--|:--|
| `ldapadd: Invalid syntax` ou `objectClass violation` | Atributo obrigatório faltando, ou espaço no fim de uma linha do LDIF | Confira a entrada indicada na mensagem |
| `ldap_add: Already exists (68)` | A entrada já foi criada numa tentativa anterior | Carregue só as entradas que faltam |
| `ldapsearch` no `cliente` dá `Can't contact LDAP server` | DNS não resolve `ldap`, ou `slapd` parado | `dig +short ldap` e `sudo systemctl status slapd` |
| `getent passwd fulano.tal` mostra uid 1001 | A conta local da Etapa 1 ainda existe | Seção 4 |
| `getent` não mostra nada | `sssd.conf` com permissão diferente de 600, ou base errada | `sudo systemctl status sssd` e `sudo journalctl -u sssd -n 30` |
| Login recusado com a senha certa | Falta a linha `ldap_auth_disable_tls_never_use_in_production` | Confira o `sssd.conf` e reinicie o `sssd` |
| Senha nova não vale logo | *Cache* do SSSD | `sudo sss_cache -E` na VM |
| `sudo` negado para o integrante | Arquivo do `sudoers.d` com erro ou integrante fora do `lsor-g0` | `sudo visudo -c` e `id fulano.tal` |

---

## 7. Registro no repositório do grupo

Nas seções **LDAP** e **Login unificado** do tutorial do grupo, no [Modelo de 7 Passos](README.md):

1. As respostas do `dpkg-reconfigure slapd` (sem a senha).
2. O LDIF **sem as linhas `userPassword`** e a saída do `ldapsearch`.
3. O `sssd.conf`, o arquivo do `sudoers.d` e o `getent passwd`/`id` em três VMs diferentes.
4. O teste de troca de senha com `ldappasswd`.

---

## 8. Para a Aula 11 (25/11)

Chegue com:

- [ ] `ldapsearch` do `cliente` listando os integrantes e o `novato`.
- [ ] `ssh fulano.tal@<qualquer VM>` funcionando com a senha do LDAP e `sudo` liberado.
- [ ] Nenhuma conta local de integrante sobrando nas VMs.

Na Aula 11 o grupo monta o servidor de arquivos e a aplicação web, que usam essas mesmas contas e o grupo `lsor-g0`.

---

## Referências

[1] OPENLDAP FOUNDATION. **OpenLDAP Software Administrator's Guide**. Disponível em: <https://www.openldap.org/doc/admin26/>.

[2] ZEILENGA, K. (Ed.). **RFC 4510 — Lightweight Directory Access Protocol (LDAP): Technical Specification Road Map**. IETF, 2006. Disponível em: <https://www.rfc-editor.org/rfc/rfc4510>.

[3] HOWARD, L. **RFC 2307 — An Approach for Using LDAP as a Network Information Service**. IETF, 1998. Disponível em: <https://www.rfc-editor.org/rfc/rfc2307>.

[4] KILLE, S. et al. **RFC 2247 — Using Domains in LDAP/X.500 Distinguished Names**. IETF, 1998. Disponível em: <https://www.rfc-editor.org/rfc/rfc2247>.

[5] CANONICAL. **How to set up SSSD with LDAP**. Ubuntu Server documentation. Disponível em: <https://documentation.ubuntu.com/server/how-to/sssd/with-ldap>.

[6] SSSD PROJECT. **sssd-ldap(5)** — página de manual. Disponível em: <https://manpages.ubuntu.com/manpages/noble/man5/sssd-ldap.5.html>.

[7] CANONICAL. **Install and configure LDAP**. Ubuntu Server documentation. Disponível em: <https://documentation.ubuntu.com/server/how-to/openldap/install-openldap>.
