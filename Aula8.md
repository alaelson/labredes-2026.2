# Aula 08: Configuração do Gateway (VM1) — IPTables, NAT e Testes

Objetivo: nesta continuação aplicamos NAT/mascaramento no gateway (VM1), habilitamos encaminhamento IP, persistimos as regras e executamos testes de conectividade a partir da VM2 (cliente).

---

## 0. Configurar os nomes das VMs

Para configurar os nomes internos utilizados pelo ubuntu server que aparecem no prompt, deve-se utilizar a interface **hostnamectl**

| DESCRIÇÃO   | HOSTNAME      |
|:------------|:------------- |
| VM1         | vm1-gateway   |
| VM2         | vm2-cliente   |

### Na VM1
```bash
sudo hostnamectl set-hostname vm1-gateway
hostname
```
### Na VM2
```bash
sudo hostnamectl set-hostname vm2-cliente
hostname
```

### Nome da máquina × identificador da máquina (`machine-id`)

O **hostname** é o nome da máquina **para as pessoas**: aparece no prompt, nos logs e é usado para encontrar a máquina na rede. Além dele, cada instalação do Linux tem um **identificador interno**, o **`machine-id`**: um número hexadecimal de 32 caracteres, gravado no arquivo `/etc/machine-id` e criado automaticamente no primeiro boot do sistema. Ele também aparece na saída do `hostnamectl`, na linha `Machine ID`.

Os dois são **independentes**: trocar o hostname **não** muda o `machine-id`.

**Por que isso importa?** Quando uma VM é **clonada** no VirtualBox, ou importada de um mesmo arquivo `.ova`, a cópia herda o `machine-id` da original, mesmo recebendo um nome e um endereço MAC novos. O Ubuntu Server usa esse identificador, por exemplo, para montar o **identificador de cliente DHCP**: duas VMs clonadas, na mesma rede e usando DHCP, podem receber **o mesmo endereço IP**, porque o servidor DHCP enxerga as duas como a mesma máquina.

Veja o `machine-id` nas duas VMs (VM1 e VM2):

```bash
cat /etc/machine-id
```

Se os valores da VM1 e da VM2 forem **iguais**, uma delas foi clonada da outra. Gere um identificador novo **somente na VM clonada**:

**Passo 1.** Apague o identificador herdado e também a cópia dele usada pelo D-Bus (`/var/lib/dbus/machine-id`). Se essa cópia for um arquivo comum, e não um link, o `systemd-machine-id-setup` do passo 2 copia o ID antigo de volta a partir dela:

```bash
sudo rm -f /etc/machine-id /var/lib/dbus/machine-id
```

**Passo 2.** Gere um identificador novo e único. O `systemd-machine-id-setup` é a ferramenta do `systemd` que cria o `/etc/machine-id` quando ele não existe:

```bash
sudo systemd-machine-id-setup
```

**Passo 3.** Recrie a cópia do D-Bus como um link para o arquivo novo, para os dois ficarem sempre iguais:

```bash
sudo ln -sf /etc/machine-id /var/lib/dbus/machine-id
```
**Passo 4.** Reinicie a VM para que todos os serviços passem a usar o novo identificador:

```bash
sudo reboot
```

Depois do boot, rode `cat /etc/machine-id` de novo e confira que agora os valores são diferentes.

> Se as VMs foram instaladas do zero, uma a uma, os identificadores já são diferentes e não é preciso fazer nada.

## 1. Habilitar encaminhamento de IP (VM1)

Habilitar imediatamente:
```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

Tornar persistente:
```bash
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-ipforward.conf
sudo sysctl --system
```

Verificar:
```bash
sudo sysctl net.ipv4.ip_forward
```

---

## 2. Regras IPTables para NAT / Mascaramento (VM1)

Limpar regras antigas (opcional):
```bash
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -X
```

Regras sugeridas (substitua enp0s3/enp0s8 pelos nomes reais se diferente):
```bash
# Mascaramento: saída para a WAN
sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE

# Permitir tráfego da LAN para WAN
sudo iptables -A FORWARD -i enp0s8 -o enp0s3 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Permitir tráfego de retorno/relacionado
sudo iptables -A FORWARD -i enp0s3 -o enp0s8 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

Verifique as regras:
```bash
sudo iptables -t nat -L -n -v
sudo iptables -L -n -v
```

---

## 3. Testes de Conectividade (na VM2 - cliente)

### 3.1: Edição do Netplan na VM2
Edite o arquivo de rede na **VM2**:
Insira a configuração conforme a **Tabela 2**:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 10.0.0.2/24
    routes:
        - to: default
          via: 10.0.0.1
      nameservers:
        addresses:
          - 172.20.20.1
          - 1.1.1.1
          - 8.8.8.8

```

Aplique as configurações:
Aplique as alterações:
```bash
$ sudo netplan apply
```

Execute os testes abaixo na VM2 após aplicar NAT no gateway:

Ping
```bash
ping -c 4 10.0.0.1     # gateway interno
ping -c 4 172.20.20.1  # gateway externo / salto seguinte
ping -c 4 1.1.1.1      # teste de conectividade à internet
```

Resolução de nomes (DNS)
```bash
nslookup google.com
# ou
dig +short google.com
```

Rastreamento de rota
```bash
traceroute google.com
# se traceroute não estiver disponível:
tracepath google.com
```

Verificações adicionais (na VM1):
```bash
sudo sysctl net.ipv4.ip_forward
sudo iptables -t nat -L -n -v
sudo iptables -L -n -v
```
---

## 4. Persistência das Regras

Instalar e salvar:
```bash
sudo apt update
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```

As regras ficam em /etc/iptables/rules.v4 (IPv4) e /etc/iptables/rules.v6 (IPv6).

Alternativas: criar unit systemd que aplica regras no boot ou usar ferramentas de gerenciamento (ansible, scripts).

---

## 5. Solução de Problemas Rápida

- Se ping externo falhar: confirme ip_forward, regras iptables na VM1 e rota default em VM1.
- Se DNS falhar por nome: verifique nameservers em /etc/netplan/*.yaml e /etc/resolv.conf.
- Se regras não carregarem no boot: verifique /etc/iptables/rules.v4 e serviço netfilter-persistent.
- Se duas VMs clonadas receberem o mesmo IP por DHCP: compare o `/etc/machine-id` das duas e gere um novo na VM clonada (seção 0).

---

## 6. Entrega — Relatório no GitHub (instrução aos alunos)

Crie um relatório no seu repositório GitHub com evidências dos testes. Inclua:

- Print das configurações de rede no VirtualBox (VM1 e VM2).
- Conteúdo dos arquivos netplan em VM1 e VM2.
- Saída de `sysctl net.ipv4.ip_forward` na VM1.
- Saídas de `sudo iptables -t nat -L -n -v` e `sudo iptables -L -n -v` na VM1.
- Prints/capturas dos testes executados na VM2:
  - ping (ex.: 10.0.0.1, 1.1.1.1)
  - nslookup (ex.: google.com)
  - traceroute (ex.: google.com)
- Breve comentário sobre problemas encontrados e como foram resolvidos.

Faça commit do relatório (ex: aula08-relatorio.md) e envie o link do repositório conforme instruções do professor.

---
```

---

## Referências

* FREEDESKTOP.ORG. **machine-id(5)**: identificador local da máquina. Disponível em: <https://www.freedesktop.org/software/systemd/man/latest/machine-id.html>.
* FREEDESKTOP.ORG. **systemd-machine-id-setup(1)**. Disponível em: <https://www.freedesktop.org/software/systemd/man/latest/systemd-machine-id-setup.html>.
* FREEDESKTOP.ORG. **systemd.network(5)**, opção `ClientIdentifier=` da seção `[DHCPv4]`. Disponível em: <https://www.freedesktop.org/software/systemd/man/latest/systemd.network.html>.
