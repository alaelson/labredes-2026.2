# Aula 08: Configuração do Gateway (VM1) — IPTables, NAT e Testes

Objetivo: nesta continuação aplicamos NAT/mascaramento no gateway (VM1), habilitamos encaminhamento IP, persistimos as regras e executamos testes de conectividade a partir da VM2 (cliente).

---

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

## 3. Persistência das Regras

Instalar e salvar:
```bash
sudo apt update
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```

As regras ficam em /etc/iptables/rules.v4 (IPv4) e /etc/iptables/rules.v6 (IPv6).

Alternativas: criar unit systemd que aplica regras no boot ou usar ferramentas de gerenciamento (ansible, scripts).

---

## 4. Testes de Conectividade (na VM2 - cliente)

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

## 5. Solução de Problemas Rápida

- Se ping externo falhar: confirme ip_forward, regras iptables na VM1 e rota default em VM1.
- Se DNS falhar por nome: verifique nameservers em /etc/netplan/*.yaml e /etc/resolv.conf.
- Se regras não carregarem no boot: verifique /etc/iptables/rules.v4 e serviço netfilter-persistent.

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