# Projeto de LSOR — Turma bsi-26-2 (2026.2)

## Etapa 1 — Rede virtualizada com 8 VMs e Gateway NAT

### 1. Apresentação

Nas aulas práticas, cada aluno instalou o Ubuntu Server, administrou usuários e permissões, colocou a VM na rede do laboratório em modo Placa em Ponte e montou um gateway NAT com duas placas de rede. O projeto reúne essas práticas em um único ambiente, construído em grupo.

Cada grupo vai montar uma rede privada com **8 máquinas virtuais** Ubuntu Server distribuídas em **4 PCs** do laboratório, além de uma **VM gateway**. O gateway liga a rede do grupo à rede do laboratório e faz o roteamento e o mascaramento (NAT) do tráfego. Todas as máquinas do grupo têm endereço fixo, nome próprio dentro do domínio do grupo e os mesmos usuários, de modo que qualquer integrante consiga acessar qualquer VM pelo nome.

A Etapa 1 trata do planejamento e da montagem desse ambiente. O resultado esperado é a rede funcionando e documentada em um tutorial no repositório do grupo.

### 2. Objetivos

Ao final da etapa, o grupo deve ser capaz de:

1. Planejar o endereçamento de uma sub-rede /28 e distribuir os endereços entre o gateway e as VMs.
2. Criar e configurar 9 VMs Ubuntu Server: 8 VMs do grupo e 1 VM gateway.
3. Configurar IP estático com Netplan em todas as VMs e as duas interfaces (WAN e LAN) do gateway.
4. Ativar o encaminhamento de pacotes e o NAT no gateway, para que as VMs do grupo alcancem a internet por ele.
5. Padronizar hostnames, domínio, `/etc/hosts` e usuários em todas as VMs.
6. Testar e documentar a conectividade entre as VMs e delas com a internet.

### 3. Aulas de base

Cada parte do projeto foi praticada antes em uma aula. Consulte os roteiros durante a implementação:

| Aula | Conteúdo | Onde é usado no projeto |
|:--|:--|:--|
| [Aula 01](../Aula1.md) | Instalação do Ubuntu Server no VirtualBox e particionamento LVM | Criação das 9 VMs |
| [Aula 02](../Aula2.md) e [Aula 04](../Aula4.md) | Usuários, grupos, permissões e criação de usuários em lote com script | Contas dos integrantes (seção 8) |
| [Aula 05](../Aula5.md) | Acesso remoto SSH e diagnóstico de rede (`ip`, `route`, `traceroute`, `w`) | Testes de SSH e de rotas (seção 11) |
| [Aula 06](../Aula6.md) | Placa em Ponte (Bridge), escolha de IP livre e IP estático com Netplan | Placas de rede de todas as VMs e IP WAN do gateway (seções 5 e 10) |
| [Aula 07](../Aula7.md) | Gateway com duas placas (WAN e LAN) e cliente que usa o gateway | Netplan do gateway e das VMs do grupo (seção 10) |
| [Aula 08](../Aula8.md) | `hostnamectl`, `ip_forward`, regras IPTables de NAT, persistência e testes | Hostnames, configuração do gateway e testes (seções 9 a 11) |

### 4. Topologia

**Figura 1:** Topologia lógica e endereçamento (exemplo do Grupo 0, modelo).

![Topologia lógica](topologia-logica-etapa1.png)

**Figura 2:** Topologia física. São 4 PCs do laboratório, com 2 VMs em cada um, e o gateway como VM extra no PC1.

![Topologia física](topologia-fisica-etapa1.png)

Diagrama editável no Lucid: [LSOR BSI - Etapa 1 - Topologia com Gateway](https://lucid.app/lucidchart/abc3cbc7-cc7c-443f-92e4-6e01df18e10d/view)

> **Por que Bridge e não Rede Interna?** Na Aula 07, o gateway e o cliente estavam no mesmo PC, e a *Rede Interna* do VirtualBox ligava as duas VMs. Aqui as VMs ficam em **4 PCs diferentes**, e a Rede Interna só existe dentro de um mesmo hospedeiro. Por isso todas as placas usam **Placa em Ponte (Bridge)**, como na Aula 06. A rede do grupo (192.168.26.x/28) é um segmento lógico que trafega pelo mesmo switch físico do laboratório.

### 5. Rede física do laboratório

| Parâmetro | Valor |
|:--|:--|
| Rede do laboratório | `172.20.20.0/22` (255.255.252.0) |
| Gateway / DNS do laboratório | `172.20.20.1` |
| Faixa para IPs estáticos (ver Aula 06) | a partir de `172.20.23.1` (testar com `ping` antes de usar) |

Somente a interface WAN (`enp0s3`) do gateway recebe um IP desta rede. As VMs do grupo usam apenas endereços da rede do grupo.

### 6. Endereçamento IP dos grupos

- A turma **bsi-26-2** usa a rede **192.168.26.0/24**, dividida em sub-redes **/28** (255.255.255.240), uma por grupo.
- O Grupo **X** usa a rede `192.168.26.(16 × X)/28`. O Grupo 0 (modelo) usa o 1º range, o Grupo 1 o 2º, o Grupo 2 o 3º, e assim por diante.
- Uma sub-rede /28 tem 16 endereços [5]: o primeiro identifica a rede, o último é o broadcast e os 14 do meio podem ser atribuídos a máquinas. Dentro de cada sub-rede:
  - 1º IP útil: **gateway**, interface LAN `enp0s8`;
  - 2º ao 9º IP útil: **VM1 a VM8**, interface `enp0s3`;
  - os demais endereços ficam livres.

| Grupo | Rede /28 | Gateway (LAN) | VM1 … VM8 | Broadcast |
|:--:|:--|:--|:--|:--|
| 0 (modelo) | 192.168.26.0 | .1 | .2 – .9 | .15 |
| 1 | 192.168.26.16 | .17 | .18 – .25 | .31 |
| 2 | 192.168.26.32 | .33 | .34 – .41 | .47 |
| 3 | 192.168.26.48 | .49 | .50 – .57 | .63 |
| 4 | 192.168.26.64 | .65 | .66 – .73 | .79 |
| 5 | 192.168.26.80 | .81 | .82 – .89 | .95 |

### 7. Nomes de máquina e domínio (FQDN)

- O domínio de cada grupo segue o formato `grupoX.bsi-26-2.maceio.lab`.
- O hostname curto segue o padrão da planilha de acompanhamento, sempre em **minúsculas**:
  - gateway: `gx-pc1-gw`;
  - VMs: `gx-pcy-vmz`, com PC de 1 a 4 e VM 1 ou 2 em cada PC.
- O FQDN é o hostname curto seguido do domínio: `<hostname>.grupoX.bsi-26-2.maceio.lab`.
- O hostname de cada VM é configurado com o **FQDN completo** (seção 9). O nome curto é usado como apelido no `/etc/hosts`.

**Tabela de referência — Grupo 0 (modelo):**

| Host | Placa / modo VirtualBox | Interface | IP / máscara | Gateway padrão | FQDN |
|:--|:--|:--|:--|:--|:--|
| g0-pc1-gw | Adaptador 1 · Bridge (WAN) | enp0s3 | 172.20.23.X/22 (IP livre) | 172.20.20.1 | g0-pc1-gw.grupo0.bsi-26-2.maceio.lab |
| g0-pc1-gw | Adaptador 2 · Bridge (LAN) | enp0s8 | 192.168.26.1/28 | — | — |
| g0-pc1-vm1 (VM1) | Adaptador 1 · Bridge | enp0s3 | 192.168.26.2/28 | 192.168.26.1 | g0-pc1-vm1.grupo0.bsi-26-2.maceio.lab |
| g0-pc1-vm2 (VM2) | Adaptador 1 · Bridge | enp0s3 | 192.168.26.3/28 | 192.168.26.1 | g0-pc1-vm2.grupo0.bsi-26-2.maceio.lab |
| g0-pc2-vm1 (VM3) | Adaptador 1 · Bridge | enp0s3 | 192.168.26.4/28 | 192.168.26.1 | g0-pc2-vm1.grupo0.bsi-26-2.maceio.lab |
| g0-pc2-vm2 (VM4) | Adaptador 1 · Bridge | enp0s3 | 192.168.26.5/28 | 192.168.26.1 | g0-pc2-vm2.grupo0.bsi-26-2.maceio.lab |
| g0-pc3-vm1 (VM5) | Adaptador 1 · Bridge | enp0s3 | 192.168.26.6/28 | 192.168.26.1 | g0-pc3-vm1.grupo0.bsi-26-2.maceio.lab |
| g0-pc3-vm2 (VM6) | Adaptador 1 · Bridge | enp0s3 | 192.168.26.7/28 | 192.168.26.1 | g0-pc3-vm2.grupo0.bsi-26-2.maceio.lab |
| g0-pc4-vm1 (VM7) | Adaptador 1 · Bridge | enp0s3 | 192.168.26.8/28 | 192.168.26.1 | g0-pc4-vm1.grupo0.bsi-26-2.maceio.lab |
| g0-pc4-vm2 (VM8) | Adaptador 1 · Bridge | enp0s3 | 192.168.26.9/28 | 192.168.26.1 | g0-pc4-vm2.grupo0.bsi-26-2.maceio.lab |

### 8. Usuários

- Cada uma das 9 VMs tem o **usuário administrador** criado na instalação (`administrador`) e **um usuário para cada integrante** do grupo.
- O nome de usuário de cada integrante é o informado na coluna **"Usuário da VM"** da planilha de acompanhamento, no formato `nome.sobrenome`, em minúsculas, sem acentos e sem espaços (ex.: `marlos.silva`).
- O conjunto de usuários é **o mesmo em todas as VMs**, inclusive no gateway.
- Cada usuário tem diretório home em `/home/<usuário>`, shell `/bin/bash` e pertence ao grupo `sudo`.

Exemplo para o Grupo 0, executado em cada VM (ver [Aula 04](../Aula4.md)) [6]:

```bash
for u in marlos.silva victor.lima nicolas.costa yury.araujo; do
  sudo useradd -m -s /bin/bash "$u"
  sudo usermod -aG sudo "$u"
  sudo passwd "$u"
done

# Verificação
getent passwd marlos.silva victor.lima nicolas.costa yury.araujo
ls -l /home
```

### 9. Hostname e /etc/hosts

**Hostname.** Em cada VM, configure o hostname com o FQDN completo usando `hostnamectl` (ver [Aula 08](../Aula8.md), seção 0):

```bash
# Exemplo na VM1 do Grupo 0
sudo hostnamectl set-hostname g0-pc1-vm1.grupo0.bsi-26-2.maceio.lab
hostname
cat /etc/hostname
```

**/etc/hosts.** Como o grupo ainda não tem um servidor DNS, a resolução de nomes é feita localmente pelo arquivo `/etc/hosts`. O arquivo de **todas as 9 VMs** deve conter uma linha para cada máquina do grupo, incluindo o gateway, no formato:

```
IP    FQDN    apelido
```

Exemplo do Grupo 0:

```
# Grupo 0 - bsi-26-2 - grupo0.bsi-26-2.maceio.lab
192.168.26.1    g0-pc1-gw.grupo0.bsi-26-2.maceio.lab     g0-pc1-gw
192.168.26.2    g0-pc1-vm1.grupo0.bsi-26-2.maceio.lab    g0-pc1-vm1
192.168.26.3    g0-pc1-vm2.grupo0.bsi-26-2.maceio.lab    g0-pc1-vm2
192.168.26.4    g0-pc2-vm1.grupo0.bsi-26-2.maceio.lab    g0-pc2-vm1
192.168.26.5    g0-pc2-vm2.grupo0.bsi-26-2.maceio.lab    g0-pc2-vm2
192.168.26.6    g0-pc3-vm1.grupo0.bsi-26-2.maceio.lab    g0-pc3-vm1
192.168.26.7    g0-pc3-vm2.grupo0.bsi-26-2.maceio.lab    g0-pc3-vm2
192.168.26.8    g0-pc4-vm1.grupo0.bsi-26-2.maceio.lab    g0-pc4-vm1
192.168.26.9    g0-pc4-vm2.grupo0.bsi-26-2.maceio.lab    g0-pc4-vm2
```

- O gateway entra com o IP da LAN (`enp0s8`), que é o endereço que as VMs do grupo alcançam diretamente.
- A linha `127.0.1.1`, criada na instalação, deve apontar para o nome da própria VM:

```
127.0.1.1    g0-pc1-vm1.grupo0.bsi-26-2.maceio.lab    g0-pc1-vm1
```

Verificação:

```bash
grep grupo0 /etc/hosts
getent hosts g0-pc1-gw
getent hosts g0-pc4-vm2.grupo0.bsi-26-2.maceio.lab
```

### 10. Configuração de rede (Netplan) e do gateway

Todas as VMs usam o arquivo `/etc/netplan/00-installer-config.yaml` com IP estático (`dhcp4: false`), como nas Aulas 06 e 07 [1, 2]. Depois de editar, aplique com `sudo netplan apply`.

**Gateway (`g0-pc1-gw`).** As duas placas ficam em modo Bridge. A `enp0s3` leva à rede do laboratório e tem a rota padrão. A `enp0s8` atende a rede do grupo e não tem rota padrão.

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:            # WAN - rede do laboratório
      dhcp4: false
      addresses:
        - 172.20.23.X/22   # IP livre escolhido conforme a Aula 06
      routes:
        - to: default
          via: 172.20.20.1
      nameservers:
        addresses: [172.20.20.1, 1.1.1.1, 8.8.8.8]
    enp0s8:            # LAN - rede do grupo
      dhcp4: false
      addresses:
        - 192.168.26.1/28
```

Em seguida, siga a [Aula 08](../Aula8.md) para transformar a VM em roteador [3, 4, 5]:

- habilitar `net.ipv4.ip_forward=1` de forma persistente;
- criar a regra de NAT (`MASQUERADE` na `enp0s3`) e as regras de `FORWARD` entre `enp0s8` e `enp0s3`;
- tornar as regras persistentes com `iptables-persistent`.

**VMs do grupo (exemplo: `g0-pc1-vm1`).** Uma única placa em modo Bridge, com o gateway do grupo como rota padrão:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.26.2/28
      routes:
        - to: default
          via: 192.168.26.1
      nameservers:
        addresses: [172.20.20.1, 1.1.1.1, 8.8.8.8]
```

### 11. Requisitos e testes

1. **Hardware:** listar a configuração de cada VM (memória, CPUs, disco). O padrão da disciplina é 512 MB de RAM, 1 vCPU e 32 GB de disco.
2. **Ambiente:** criar VMs novas especificamente para este projeto.
3. **SSH:** serviço `ssh` ativo em todas as VMs, aceitando login por senha dos usuários dos integrantes (ver [Aula 05](../Aula5.md)).
4. **Testes:** registrar no tutorial os comandos e as saídas de:
   - `ping` entre todas as VMs, usando IP, nome curto e FQDN;
   - `ssh <usuário>@<hostname>` entre as VMs, com os usuários dos integrantes;
   - saída para a internet a partir das VMs, passando pelo gateway: `ping 1.1.1.1`, `ping google.com` e `traceroute google.com`. O primeiro salto deve ser o gateway do grupo;
   - no gateway: `sysctl net.ipv4.ip_forward`, `sudo iptables -t nat -L -n -v` e `sudo iptables -L -n -v`.

---

## Prazos e entregas

### Etapa 1 — data a definir

a) Preencher, na planilha de acompanhamento, as tabelas de **nomes, usuários e IPs** de todas as VMs do grupo, incluindo o gateway (seções 6 a 8).

b) Apresentar o **diagrama de topologia** do grupo, adaptado das Figuras 1 e 2 com os IPs do grupo.

c) Criar a página do projeto do grupo no GitHub, com o tutorial seguindo o Modelo de 7 Passos descrito no [README da disciplina](../README.md).

### Etapa 2 (final) — data a definir

Entrega e apresentação final do ambiente funcionando, com o tutorial completo e as evidências de testes.

---

## Referências

[1] CANONICAL. **Configuring networks**. Ubuntu Server documentation. Disponível em: <https://ubuntu.com/server/docs/configuring-networks>.

[2] NETPLAN. **Netplan reference** (YAML configuration). Disponível em: <https://netplan.readthedocs.io/en/latest/reference/>.

[3] ASC INC. **How to build a simple router with Ubuntu Server 18.04.1 LTS (Bionic Beaver)**. Disponível em: <https://www.ascinc.com/blog/linux/how-to-build-a-simple-router-with-ubuntu-server-18-04-1-lts-bionic-beaver/>.

[4] LAURENSON, Thomas. **Building a Ubuntu Linux gateway**. 2018. Disponível em: <https://www.thomaslaurenson.com/blog/2018/07/05/building-a-ubuntu-linux-gateway/>.

[5] KUROSE, James F.; ROSS, Keith W. **Redes de Computadores e a Internet**. 8. ed. Pearson, 2022.

[6] LACROIX, Jay. **Mastering Ubuntu Server**. 4. ed. Packt Publishing, 2023.
