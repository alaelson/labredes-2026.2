# Migração do Projeto Final para as VMs do LabRedes (VPN)

Laboratório de Sistemas Operacionais de Redes — turma bsi-26-2 (2026.2)

Na Etapa 1, cada grupo montou a sua rede em VMs do VirtualBox, nos PCs do laboratório. No Projeto Final, o grupo passa a usar **VMs do LabRedes**, hospedadas no servidor do laboratório e acessadas pela **VPN da turma**. Este documento mostra o que muda em relação ao [enunciado do Projeto Final](README.md) e em que ordem o grupo trabalha.

O que não muda: os serviços, os nomes, a sub-rede `/28` do grupo e os testes. A implementação passa a ter **duas fases**:

| Fase | O que o grupo faz | Como os serviços são acessados |
|:--:|:--|:--|
| **A** | Implementa e testa **todos** os serviços (seções 8 a 13 do enunciado) | Direto pelo IP de cada VM na rede externa `10.26.2.0/24`, a partir do computador do aluno na VPN |
| **B** | Coloca a rede do grupo **atrás do `gw`**: roteamento, NAT, encaminhamento de portas, firewall e DNS interno e externo | Só pelo IP do `gw`: `www`, `ns1` e `samba` publicados; `ldap`, `bd` e `ns2` só na rede interna |

**Só comece a fase B depois que todos os testes da fase A funcionarem.**

## 1. O que muda

| Item | Etapa 1 (VirtualBox) | Projeto Final (LabRedes, pela VPN) |
|:--|:--|:--|
| Onde ficam as VMs | PCs do laboratório | Servidor do LabRedes |
| Como acessar | Console do VirtualBox | VPN e SSH, de qualquer lugar |
| Quantidade de VMs | 9 (gateway e VM1 a VM8) | 7 por grupo: `gw`, `ns1`, `ns2`, `www`, `bd`, `samba` e `ldap` |
| VM `cliente` | VM8 | Não existe: o cliente de testes é o computador do aluno, conectado à VPN |
| Placas de rede | `enp0s3` (e `enp0s8` no `gw`) | **Duas em todas as VMs:** `ens160` (rede externa) e `ens192` (rede interna do grupo) |
| Rede externa | Rede do laboratório `172.20.20.0/22` | `10.26.2.0/24`, na `ens160` |
| Rede interna | `/28` do grupo em `192.168.26.0/24` | A mesma `/28`, agora na `ens192` |
| *Snapshot* antes de cada serviço | Pelo VirtualBox | Não há: guarde os arquivos de configuração no repositório do grupo antes de cada mudança |

## 2. As duas placas de rede

Uma **placa de rede** (interface) é a ligação da VM com uma rede. O Ubuntu dá a cada placa um nome fixo, que depende do tipo de placa virtual: no VirtualBox eram `enp0s3` e `enp0s8`; no LabRedes são `ens160` e `ens192`.

**`ens160` — rede externa (`10.26.2.0/24`).** Já vem configurada.

- Cada VM tem um IP fixo nessa rede (seção 3). É por ele que vocês entram na VM por SSH e, na fase A, testam os serviços.
- No `gw`, ela é a **WAN**, como a `enp0s3` do gateway na Etapa 1. A saída para a internet é pelo pfSense (`10.26.2.1`).
- **Nunca apague nem troque o IP da `ens160`**: sem ele, a VM fica inacessível pela VPN, e só o professor ou o monitor conseguem recuperá-la.

**`ens192` — rede interna do grupo (`/28` do grupo).** Configurada por vocês.

- Recebe o IP da Etapa 1 (seção 3 e planilha de acompanhamento).
- No `gw`, é a **LAN**, como a `enp0s8` na Etapa 1.
- As `ens192` de todos os grupos ficam no mesmo segmento de rede, como os PCs do laboratório na Etapa 1: o que separa os grupos é a sub-rede `/28` de cada um. Use só os IPs da faixa do seu grupo.

## 3. VMs, funções e IPs

As VMs chegam com o hostname `gNN-vmK` (`NN` = número do grupo, `K` = número da VM). A função de cada uma é fixa:

| VM | Função | Rede interna (`ens192`) | FQDN (Grupo X) | Na fase B |
|:--|:--|:--|:--|:--|
| `gNN-vm1` | `gw` | `16·X + 1` | `gw.grupoX.bsi-26-2.maceio.lab` | Gateway, NAT e firewall |
| `gNN-vm2` | `ns1` | `16·X + 2` | `ns1.grupoX.bsi-26-2.maceio.lab` | Publicado (porta 53) |
| `gNN-vm3` | `ns2` | `16·X + 3` | `ns2.grupoX.bsi-26-2.maceio.lab` | Só rede interna |
| `gNN-vm4` | `www` | `16·X + 4` | `www.grupoX.bsi-26-2.maceio.lab` | Publicado (portas 80 e 2222) |
| `gNN-vm5` | `bd` | `16·X + 5` | `bd.grupoX.bsi-26-2.maceio.lab` | Só rede interna |
| `gNN-vm6` | `samba` (servidor de arquivos) | `16·X + 6` | `samba.grupoX.bsi-26-2.maceio.lab` | Publicado (porta 445) |
| `gNN-vm7` | `ldap` | `16·X + 7` | `ldap.grupoX.bsi-26-2.maceio.lab` | Só rede interna |

IPs de cada grupo:

| Grupo | VM1 a VM7 (`ens160`) | Rede interna (`ens192`) | `gw` (LAN) |
|:--|:--|:--|:--|
| 0 (modelo, professor) | `10.26.2.51` a `.57` | `192.168.26.0/28` (`.1` a `.7`) | `192.168.26.1` |
| 1 | `10.26.2.101` a `.107` | `192.168.26.16/28` (`.17` a `.23`) | `192.168.26.17` |
| 2 | `10.26.2.108` a `.114` | `192.168.26.32/28` (`.33` a `.39`) | `192.168.26.33` |
| 3 | `10.26.2.115` a `.121` | `192.168.26.48/28` (`.49` a `.55`) | `192.168.26.49` |
| 4 | `10.26.2.122` a `.128` | `192.168.26.64/28` (`.65` a `.71`) | `192.168.26.65` |

A VM1 de cada grupo usa o primeiro IP da faixa, a VM2 o segundo, e assim por diante. A planilha de acompanhamento tem a tabela completa, VM por VM. Os exemplos deste documento são do **Grupo 1**.

## 4. Como acessar

A **VPN** (*Virtual Private Network*) cria um túnel cifrado entre o seu computador e a rede do laboratório: com ela conectada, o seu computador alcança a rede `10.26.2.0/24` como se estivesse lá. O cliente usado é o **OpenVPN**.

1. Instale o cliente OpenVPN e importe o perfil `.ovpn` da turma (publicado no Classroom).
2. Conecte com o seu usuário e a sua senha da VPN (planilha de usuários da turma). Essa conta é só da VPN: não é a conta das VMs nem a do LDAP do grupo.
3. Entre na VM por SSH, trocando o IP pelo da VM que você quer acessar:

```bash
ssh administrador@10.26.2.101
```

O usuário `administrador` e a senha são os mesmos da Etapa 1. Ele continua sendo o acesso de emergência em todas as VMs.

Com a VPN conectada, o seu computador usa como DNS os servidores do LabRedes (`172.20.0.10` e `172.20.0.11`). Confira no Linux com `resolvectl status`, no macOS com `scutil --dns` e no Windows com `ipconfig /all`.

## 5. Fase A — Implementar e testar pela rede externa

Na fase A, a rede de cada VM fica como veio: a rota padrão e o DNS estão na `ens160`. Todos os serviços são acessados e testados pelos IPs `10.26.2.x`.

### 5.1 Preparação

**Passo 1. Guardar o que foi feito no VirtualBox.** Copie para o repositório do grupo no GitHub os arquivos de configuração da Etapa 1: Netplan, `/etc/hosts`, regras do NAT do gateway e as configurações dos serviços já iniciados (por exemplo, as zonas do DNS). As VMs novas começam limpas.

**Passo 2. Ajustar o nome de cada VM.** Em cada VM, troque o hostname `gNN-vmK` pelo FQDN da seção 3. Exemplo para o `ns1`:

```bash
sudo hostnamectl set-hostname ns1.grupo1.bsi-26-2.maceio.lab
```

Ajuste também a linha `127.0.1.1` do `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

**Passo 3. Configurar a rede interna (`ens192`).** O **Netplan** é a ferramenta do Ubuntu que lê os arquivos YAML de `/etc/netplan/` e configura as placas de rede. Edite o arquivo da VM:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Mantenha o bloco da `ens160` como está e altere só o bloco da `ens192`, com o IP da VM na rede interna. Exemplo para o `ns1`:

```yaml
    ens192:            # LAN - rede interna do grupo
      dhcp4: false
      addresses:
        - 192.168.26.18/28
```

Na fase A, a `ens192` não leva gateway nem DNS.

**Passo 4. Aplicar com segurança.** Use o `netplan try`: ele aplica a configuração e a desfaz sozinho em 120 segundos se você não confirmar. Se um erro derrubar a conexão SSH, basta esperar e entrar de novo.

```bash
sudo netplan try
```

Se a conexão SSH continuar funcionando, aperte **Enter** para confirmar. Confira:

```bash
ip -c -4 a
```

**Passo 5. Testar a rede interna.** De cada VM, faça `ping` para as outras pelos IPs da rede interna. Exemplo, do `ns1` para o `ldap`:

```bash
ping -c 3 192.168.26.23
```

### 5.2 Serviços

Implemente os serviços na ordem do enunciado (seções 8 a 13), com estas adaptações:

**DNS (`ns1` e `ns2`).**

- Na fase A, os registros `A` da zona apontam para os **IPs externos** (`10.26.2.x`), que são os que o computador do aluno alcança pela VPN. Exemplo: `www IN A 10.26.2.104`.
- O `ns1` e o `ns2` encaminham para os DNS do LabRedes os nomes que não são do grupo. Em `/etc/bind/named.conf.options`:

```
        forwarders { 172.20.0.10; 172.20.0.11; };
        allow-query { any; };
        allow-recursion { 127.0.0.1; 10.26.2.0/24; 192.168.26.16/28; };
```

- O `ns2` busca a zona no `ns1` pelo IP externo do `ns1` (`primaries { 10.26.2.102; };`). Na fase B, esse IP muda (seção 6.5).
- Os DNS do LabRedes são donos da zona `maceio.lab` e **delegam** a zona `grupoX.bsi-26-2.maceio.lab` para o `ns1` do grupo, com um registro `NS` e o IP externo do `ns1`, como no DNS da internet. Com isso, o computador do aluno na VPN resolve os nomes do grupo: ele pergunta ao DNS do LabRedes, que busca a resposta no `ns1` do grupo. Enquanto o `ns1` do grupo não responder, os nomes do grupo dão `SERVFAIL`.

**Demais serviços.** Nos arquivos de configuração, use sempre os **nomes** dos servidores (`ldap.grupo1.bsi-26-2.maceio.lab`, `bd.grupo1.bsi-26-2.maceio.lab`), não os IPs. Assim, na fase B, basta o DNS passar a responder os IPs internos.

- No MariaDB, libere o usuário da aplicação para as duas redes do `www`: `'app'@'10.26.2.104'` (fase A) e `'app'@'192.168.26.20'` (fase B).
- O SFTP da fase A usa a porta 22 do próprio `www`.

### 5.3 Testes da fase A

Os testes da seção 14 do enunciado são feitos **do computador do aluno**, conectado à VPN, no lugar da VM `cliente`. Exemplos:

```bash
dig www.grupo1.bsi-26-2.maceio.lab
```

```bash
ssh fulano.tal@www.grupo1.bsi-26-2.maceio.lab
```

```bash
curl -s http://www.grupo1.bsi-26-2.maceio.lab/
```

No Windows, o `dig` não vem instalado: use `nslookup www.grupo1.bsi-26-2.maceio.lab`. O Samba é testado pelo Explorador de Arquivos (`\\samba.grupo1.bsi-26-2.maceio.lab\publico`) ou pelo `smbclient`, no Linux e no macOS.

Os testes que precisam de um cliente dentro da rede do grupo (por exemplo, `ldapsearch` e o `SELECT` no banco) são feitos por SSH em uma das VMs.

**Registre as evidências de todos os testes antes de passar para a fase B.**

## 6. Fase B — Rede do grupo atrás do `gw`

Na fase B, a rede interna passa a sair para a internet pelo `gw`, como na Etapa 1. Só três serviços continuam acessíveis de fora, pelo **IP externo do `gw`**, por encaminhamento de portas:

| Porta no `gw` (`10.26.2.101`) | Destino | Serviço |
|:--|:--|:--|
| 53 (UDP e TCP) | `ns1` (`192.168.26.18:53`) | DNS |
| 80 | `www` (`192.168.26.20:80`) | Web |
| 2222 | `www` (`192.168.26.20:22`) | SFTP (a porta 22 é o SSH do próprio `gw`) |
| 445 | `samba` (`192.168.26.22:445`) | Samba |

O `ldap`, o `bd` e o `ns2` são servidores de ***backend***: só os outros servidores do grupo precisam deles, então ficam só na rede interna. O `ns2` passa a ser o DNS secundário da rede interna: se o `ns1` cair, as VMs do grupo continuam resolvendo nomes.

Faça os passos **na ordem**: primeiro o `gw`, depois as outras VMs.

### 6.1 Encaminhamento e NAT no `gw`

Refaça a configuração do gateway da Etapa 1, trocando os nomes das placas: a WAN agora é a `ens160` (era a `enp0s3`). O **encaminhamento de pacotes** (`ip_forward`) faz o Linux repassar pacotes entre as placas, como um roteador. Ligue e confira (deve mostrar `= 1`):

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

Para ficar ligado após o *reboot*, acrescente a linha `net.ipv4.ip_forward=1` em `/etc/sysctl.conf`:

```bash
sudo nano /etc/sysctl.conf
```

O **NAT** (*Network Address Translation*), com o alvo `MASQUERADE` do `iptables`, troca o IP de origem dos pacotes da rede interna pelo IP externo do `gw` [3]:

```bash
sudo iptables -t nat -A POSTROUTING -s 192.168.26.16/28 -o ens160 -j MASQUERADE
```

### 6.2 Encaminhamento de portas no `gw`

O **encaminhamento de portas** (DNAT, *Destination NAT*) troca o IP de destino: o que chega numa porta do `gw` é repassado para um servidor da rede interna [3]. Uma regra por linha da tabela da seção 6:

```bash
sudo iptables -t nat -A PREROUTING -i ens160 -p udp --dport 53 -j DNAT --to-destination 192.168.26.18
```

```bash
sudo iptables -t nat -A PREROUTING -i ens160 -p tcp --dport 53 -j DNAT --to-destination 192.168.26.18
```

```bash
sudo iptables -t nat -A PREROUTING -i ens160 -p tcp --dport 80 -j DNAT --to-destination 192.168.26.20
```

```bash
sudo iptables -t nat -A PREROUTING -i ens160 -p tcp --dport 2222 -j DNAT --to-destination 192.168.26.20:22
```

```bash
sudo iptables -t nat -A PREROUTING -i ens160 -p tcp --dport 445 -j DNAT --to-destination 192.168.26.22
```

### 6.3 Firewall no `gw`

O **firewall** decide quais pacotes o `gw` repassa (cadeia `FORWARD`). A política passa a ser bloquear tudo (`DROP`) e liberar só o necessário. Primeiro, as respostas de conexões já aceitas:

```bash
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

A saída da rede interna para fora:

```bash
sudo iptables -A FORWARD -i ens192 -o ens160 -s 192.168.26.16/28 -j ACCEPT
```

As conexões que chegaram pelas portas encaminhadas (seção 6.2):

```bash
sudo iptables -A FORWARD -i ens160 -o ens192 -m conntrack --ctstate DNAT -j ACCEPT
```

Por último, a política padrão:

```bash
sudo iptables -P FORWARD DROP
```

Confira as regras:

```bash
sudo iptables -L FORWARD -n -v
```

```bash
sudo iptables -t nat -L -n -v
```

Deixe as regras persistentes após o *reboot*, como na Etapa 1, com o pacote `iptables-persistent`:

```bash
sudo netfilter-persistent save
```

### 6.4 Rede das outras VMs

Nas VMs `ns1`, `ns2`, `www`, `bd`, `samba` e `ldap`, a rota padrão passa a ser o `gw`. A `ens160` **mantém o IP**, mas fica sem gateway, sem rotas e sem DNS.

Isso é obrigatório. As conexões que chegam pelo encaminhamento de portas entram pelo `gw`, e a resposta precisa voltar por ele, para o `gw` desfazer a troca de endereço. Se a VM tivesse uma rota para a VPN pela `ens160`, a resposta sairia direto para o pfSense e a conexão quebraria.

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Exemplo completo para o `ns1` (troque os IPs pelos da VM):

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens160:            # Rede externa - só o IP, sem rotas
      dhcp4: false
      addresses:
        - 10.26.2.102/24
    ens192:            # LAN - rede interna do grupo
      dhcp4: false
      addresses:
        - 192.168.26.18/28
      routes:
        - to: default
          via: 192.168.26.17
      nameservers:
        addresses: [192.168.26.18, 192.168.26.19]
        search: [grupo1.bsi-26-2.maceio.lab]
```

O DNS das VMs passa a ser o `ns1` e o `ns2` do grupo, pela rede interna.

**A partir daqui, o SSH pela VPN direto nessa VM para de funcionar**, e o acesso passa a ser pelo `gw`. Por isso, antes de aplicar, abra uma segunda sessão SSH pelo `gw`, com a opção `-J` (*jump*), que usa o `gw` como ponte:

```bash
ssh -J administrador@10.26.2.101 administrador@192.168.26.18
```

Na sessão aberta pelo `gw`, aplique com o `netplan try` e confirme com **Enter**:

```bash
sudo netplan try
```

Confira a rota padrão, que deve apontar para o IP de LAN do `gw`:

```bash
ip -c route
```

E a saída para a internet pelo NAT do `gw`:

```bash
ping -c 2 1.1.1.1
```

### 6.5 DNS interno e externo (*views*)

Na fase B, o mesmo nome precisa responder IPs diferentes para quem está dentro e para quem está fora:

| Nome | Para a rede interna | Para quem está fora (VPN) |
|:--|:--|:--|
| `www`, `samba`, `ns1` | IP interno (`192.168.26.x`) | IP externo do `gw` (`10.26.2.101`) |
| `ldap`, `bd`, `ns2` | IP interno (`192.168.26.x`) | Não existe |

No BIND, isso se faz com **visões** (*views*): cada `view` tem a sua cópia da zona, e o BIND escolhe a visão pelo IP de quem pergunta (`match-clients`) [5]. No `ns1`, cada zona passa a ficar dentro de uma `view`, em `/etc/bind/named.conf.local`:

```
acl interna { 127.0.0.1; 192.168.26.16/28; };

view "interna" {
    match-clients { interna; };
    recursion yes;
    forwarders { 172.20.0.10; 172.20.0.11; };
    include "/etc/bind/named.conf.default-zones";

    zone "grupo1.bsi-26-2.maceio.lab" {
        type primary;
        file "/etc/bind/db.grupo1.interna";
        allow-transfer { 192.168.26.19; };
    };
    zone "26.168.192.in-addr.arpa" {
        type primary;
        file "/etc/bind/db.192.168.26";
        allow-transfer { 192.168.26.19; };
    };
};

view "externa" {
    match-clients { any; };
    recursion no;

    zone "grupo1.bsi-26-2.maceio.lab" {
        type primary;
        file "/etc/bind/db.grupo1.externa";
    };
};
```

- `db.grupo1.interna`: a zona da fase A, com os registros `A` trocados para os IPs internos (`192.168.26.x`).
- `db.grupo1.externa`: só `ns1`, `www` e `samba`, todos com o IP externo do `gw` (`10.26.2.101`), e **só o `ns1` no registro `NS`**. O `ns2` fica fora da visão externa: o DNS do LabRedes não alcança a rede interna e perderia tempo tentando o IP `192.168.26.x` dele.
- Quando há `view`, todas as zonas precisam estar dentro de uma. Por isso o `include "/etc/bind/named.conf.default-zones"` vai para a visão interna e sai do `/etc/bind/named.conf`.
- No `named.conf.options`, retire o `forwarders` e o `allow-recursion` da fase A: eles passam a ficar na visão interna.

No `ns2`, a zona continua `type secondary`, agora buscando no IP interno do `ns1` (`primaries { 192.168.26.18; };`). Como o `ns2` pergunta pela rede interna, ele recebe a zona da visão interna.

Confira a sintaxe e as zonas antes de recarregar:

```bash
sudo named-checkconf
```

```bash
sudo named-checkzone grupo1.bsi-26-2.maceio.lab /etc/bind/db.grupo1.externa
```

```bash
sudo rndc reload
```

Quando o encaminhamento da porta 53 estiver funcionando, avise o professor: ele troca, na zona `maceio.lab` do LabRedes, o IP da delegação do grupo, do IP externo do `ns1` para o IP externo do `gw`.

### 6.6 Testes da fase B

Repita os testes da fase A, agora pelos dois lados.

**Do computador do aluno (VPN):** `dig www.grupo1.bsi-26-2.maceio.lab` responde `10.26.2.101` (o `gw`). A página web, o Samba e o SFTP funcionam pelos nomes. O SFTP usa a porta 2222:

```bash
sftp -P 2222 novato@www.grupo1.bsi-26-2.maceio.lab
```

`dig ldap.grupo1.bsi-26-2.maceio.lab` não encontra o nome (`NXDOMAIN`).

**De uma VM da rede interna** (pelo `gw`, com `ssh -J`): os nomes respondem os IPs `192.168.26.x`; o login pelo LDAP, a aplicação web com o banco e a transferência de zona para o `ns2` funcionam pela rede interna.

## 7. Cuidados

- Nunca apague nem troque o IP da `ens160` no Netplan.
- Ao mexer na rede, use sempre `sudo netplan try` em vez de `sudo netplan apply`.
- Não desligue as VMs pelo sistema (`poweroff`): só o professor consegue ligá-las de novo. Se precisar reiniciar, use `sudo reboot`.
- Registre no repositório do grupo cada alteração de configuração feita nas VMs: é ela que substitui o *snapshot* do VirtualBox.
- Em caso de problema de acesso, procure o professor ou o monitor da disciplina.

---

## Referências

[1] CANONICAL. **Netplan documentation** — YAML configuration reference (`routes`, `nameservers`) e `netplan try`. Disponível em: <https://netplan.readthedocs.io/>.

[2] CANONICAL. **Configuring networks**. Ubuntu Server documentation. Disponível em: <https://ubuntu.com/server/docs/configuring-networks>.

[3] NETFILTER PROJECT. **iptables(8)** e **iptables-extensions(8)** — alvos `MASQUERADE` e `DNAT`, módulo `conntrack`. Disponível em: <https://ipset.netfilter.org/iptables-extensions.man.html>.

[4] OPENVPN INC. **OpenVPN Community Resources — Reference manual for OpenVPN 2.6**. Disponível em: <https://openvpn.net/community-resources/reference-manual-for-openvpn-2-6/>.

[5] INTERNET SYSTEMS CONSORTIUM. **BIND 9 Administrator Reference Manual** — `view`, `match-clients`, `forwarders` e zonas `forward`. Disponível em: <https://bind9.readthedocs.io/>.

[6] OPENSSH. **ssh(1)** — opção `-J` (*ProxyJump*). Disponível em: <https://man.openbsd.org/ssh>.
