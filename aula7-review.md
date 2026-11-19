# Aula 07 (Revisado): Roteamento e Gateway NAT com IPTables e Rede Interna no VirtualBox

Nesta aula prática você configurará um Ubuntu Server como **Gateway** usando NAT (Network Address Translation) e regras de roteamento via **iptables**. A versão revisada corrige placeholders, padroniza nomes de interface (enp0s3 = WAN, enp0s8 = LAN), ajusta netplan, e desloca as instruções de NAT/mascaramento para uma seção dedicada com métodos recomendados de persistência.

---

## Topologia e VMs

- VM1 — Gateway / Router
  - Interface WAN: enp0s3 (modo Bridge)
  - Interface LAN: enp0s8 (modo Internal Network, ex: intnet)
- VM2 — Cliente da LAN
  - Interface LAN: enp0s3 (modo Internal Network, mesmo nome da rede interna da VM1)

Use `ip addr show` ou `ip a` nas VMs para confirmar os nomes das interfaces reais antes de aplicar os exemplos.

---

## 1. Fundamentos Técnicos

O gateway encaminha tráfego entre redes distintas. Aqui configuramos um gateway que:
- NATs os endereços da LAN para o IP da interface WAN;
- Encaminha pacotes entre LAN e WAN;
- Mantém rastreio de conexões (conntrack) para encaminhar respostas.

As definições detalhadas de NAT e regras do firewall estão na Seção 7.

---

## 2. Configuração dos Adaptadores no VirtualBox

2.1 VM1 (Gateway)
- Adaptador 1: Bridge Adapter → ligado à placa física do host (WAN) — enp0s3
- Adaptador 2: Internal Network (nome: intnet) — enp0s8

2.2 VM2 (Cliente)
- Adaptador 1: Internal Network (nome: intnet) — enp0s3

Assegure que o nome da "Rede Interna" seja igual nas duas VMs (ex: intnet).

---

## 3. Topologia de Rede e Endereçamento

Tabela 1 — Rede Externa (WAN, interface enp0s3 da VM1)
| Parâmetro | Endereço / Configuração |
| :--- | :--- |
| Rede Externa (WAN) | 172.20.20.0/22 |
| Máscara de Sub-rede | /22 (255.255.252.0) |
| IP do Gateway Externo | 172.20.20.1 |
| IP da VM1 (enp0s3) | 172.20.23.1 |
| Servidores DNS | 172.20.20.1, 1.1.1.1, 8.8.8.8 |

Tabela 2 — Rede Interna (LAN)
| Descrição / Equipamento | Endereço IP / Configuração |
| :--- | :--- |
| Rede Interna (LAN) | 10.0.0.0/24 |
| Máscara de Sub-rede | /24 (255.255.255.0) |
| Broadcast | 10.0.0.255 |
| Gateway Interno (VM1 - enp0s8) | 10.0.0.1 |
| Cliente da LAN (VM2 - enp0s3) | 10.0.0.2 |

---

## 4. Configuração do Servidor Gateway (VM1)

Edite o netplan em VM1: `/etc/netplan/00-installer-config.yaml`

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
    enp0s8:
      dhcp4: false
      addresses:
        - 10.0.0.1/24
```

Aplique as configurações do netplan:

```bash
sudo netplan apply
```

Verifique se as interfaces estão com os endereços corretos:

```bash
ifconfig
route -n
```

ou

```bash
ip addr show
ip route show
```
---

## 5. Configuração do IPTables para NAT

### 5.1. Regras de Mascaramento e NAT

As regras de NAT e mascaramento permitem que os clientes na rede interna acessem a internet usando o IP da interface WAN do gateway.

```bash
# Limpar regras existentes
sudo iptables -F
sudo iptables -t nat -F

# Habilitar o encaminhamento de pacotes
sudo sysctl -w net.ipv4.ip_forward=1

# Mascaramento da rede interna (LAN)
sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE

# Permitir tráfego da LAN para a WAN
sudo iptables -A FORWARD -i enp0s8 -o enp0s3 -j ACCEPT

# Permitir tráfego estabelecido e relacionado de volta para a LAN
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

### 5.2. Salvando as Regras do IPTables

Para garantir que as regras do IPTables persistam após reinicializações, use o `iptables-persistent` ou salve as regras em um script de inicialização.

Instale o `iptables-persistent`:

```bash
sudo apt install iptables-persistent
```

Salve as regras atuais:

```bash
sudo netfilter-persistent save
```

---

## 6. Testes de Conectividade

### 6.1. Teste de Conectividade Básica

Verifique a conectividade entre as VMs e o gateway:

```bash
# Em VM2 (Cliente)
ping -c 4 10.0.0.1  # Ping no Gateway Interno
ping -c 4 8.8.8.8   # Ping em um servidor externo (Google DNS)
```

### 6.2. Teste de Resolução de Nomes

Verifique se a resolução de nomes está funcionando:

```bash
# Em VM2 (Cliente)
ping -c 4 google.com
```

---

## 7. Solução de Problemas

Se encontrar problemas, verifique:

- As configurações de rede no VirtualBox estão corretas?
- O netplan foi aplicado corretamente?
- As regras do IPTables estão ativas e corretas?
- O serviço de rede está ativo e sem erros? (`sudo systemctl status systemd-networkd`)

---

## 8. Considerações Finais

Nesta aula, você aprendeu a configurar um gateway básico usando IPTables e NAT. Essa configuração é fundamental para permitir que dispositivos em uma rede interna acessem recursos externos de forma segura e controlada.

Na próxima aula, abordaremos tópicos avançados de roteamento e segurança de rede.

---

