# Relatório de Avaliação do Projeto Etapa 1 — Grupo 4

**INSTITUTO FEDERAL DE EDUCAÇÃO, CIÊNCIA E TECNOLOGIA DE ALAGOAS (IFAL) — Campus Maceió**  
**Curso:** Bacharelado em Sistemas de Informação (BSI)  
**Disciplina:** Laboratório de Sistemas Operacionais e Redes (LSOR) — 2026.2  
**Professor:** Alaelson de Castro Jatobá Neto  
**Grupo:** 4 — rede `192.168.26.64/28` · domínio `grupo4.bsi-26-2.maceio.lab`  
**Matrículas:** 2023007104 · 2023007721 · 2023007786  
**Apresentação:** 28/10/2026 · **Entrega no formulário:** 04/11/2026 · **Versão do roteiro avaliada:** último commit de 03/11/2026 (`README.md`, `Definicoes comuns a todos.md` e pasta `imagens/`)  
**Data do relatório:** 04/11/2026

---

## Sumário da avaliação

| Componente | Nota |
|---|---|
| Apresentação e testes no laboratório (28/10) | 9,5 |
| Roteiro no GitHub | 7,0 |
| **Nota do Projeto Etapa 1 (Avaliação 2)** | **8,25** |

> **Composição:** a nota do projeto é a média da apresentação (testes ao vivo no laboratório) e do roteiro. Ela entra com peso de 80% na Nota 2 (Nota 2 = 20% da Atividade 3 + 80% do Projeto Etapa 1).

---

## Checklist do enunciado

| Requisito (enunciado do Projeto Etapa 1) | Situação | Observação |
|---|---|---|
| Identificação (Modelo de 7 Passos) | Atende | Faltam só as matrículas e o professor no cabeçalho. |
| Topologia com os IPs do grupo | Atende | Figura própria, com WAN, LAN, os 4 PCs e as 8 VMs. |
| Tabela de endereçamento e FQDN | Atende | Seção 3.2 e arquivo de definições, no padrão `g4-pcY-vmZ`. |
| Hardware de cada VM | Atende | 512 MB, 1 vCPU, 32 GB (padrão da disciplina). |
| Placas em Bridge no VirtualBox | Não atende | Nenhum print das configurações de rede no VirtualBox. |
| Hostname no padrão | Não atende | O hostname ficou com o FQDN e o nome curto colados (ver "Roteiro", item 2). |
| Netplan do gateway | Atende | WAN `172.20.23.222/22` e LAN `192.168.26.65/28`, com `ip a` e `ip route` coerentes. |
| Netplan de cada VM | Não atende | Há print de 7 das 8 VMs, e todas estão com máscara `/24` (ver "Roteiro", item 1). |
| `/etc/hosts` em todas as VMs | Atende | Print em 8 das 9 VMs (falta a `g4-pc3-vm1`), com as 9 linhas e a `127.0.1.1` correta. |
| Usuários `nome.sobrenome` em todas as VMs | Atende | Três integrantes em todas as VMs com print, no grupo `sudo`. |
| `ip_forward`, NAT, FORWARD e persistência | Parcial | Regras explicadas e verificadas; faltam os comandos do `ip_forward` persistente e do `iptables-persistent`. |
| SSH entre VMs com os usuários dos integrantes | Atende | SSH pelo nome entre várias VMs, com usuários dos integrantes e o `administrador`. |
| Ping entre as VMs por IP, nome curto e FQDN | Parcial | Ping por nome entre PCs diferentes; um print é a VM pingando ela mesma. |
| Saída para a internet e `traceroute` (1º salto no gateway) | Atende | `ping 1.1.1.1`, `ping google.com` e `traceroute` com o 1º salto em `g4-pc1-gw (192.168.26.65)`. |
| Verificações no gateway (`sysctl`, `iptables`) | Atende | `ip_forward = 1`, `MASQUERADE` e FORWARD com contadores de tráfego. |
| Problemas e Soluções | Parcial | Um problema real registrado (falta de NAT); os erros de máscara e hostname não foram percebidos. |

---

## Apresentação em sala (28/10) · Nota 9,5

**O que vocês fizeram bem:** Todos os testes de conectividade passaram:
- ping entre as VMs e ping do gateway;
- ping para a internet passando pelo gateway;
- ping pelo nome curto e pelo FQDN, com o `/etc/hosts` configurado;
- placas de rede em Bridge;
- usuários dos integrantes configurados nas VMs testadas.

Depois de instalados os pacotes que faltavam, o `traceroute` funcionou a partir do gateway e das VMs. A própria instalação já comprovou que o gateway estava encaminhando o tráfego para a internet.

**Como melhorar:** O `traceroute` e o pacote `net-tools` não estavam instalados nas VMs. Isso mostra que esses testes não foram feitos antes da apresentação para serem documentados no roteiro.

---

## Roteiro · Nota 7,0

**O que vocês fizeram bem:**
- A pasta `imagens/evidencias/` tem uma subpasta por VM, com hostname, `/etc/hosts`, `ip addr`, `ip route`, Netplan, usuários e SSH de cada máquina. É a cobertura mais completa da turma (só a `g4-pc3-vm1` ficou sem evidências próprias; ver item 3).
- A topologia foi desenhada pelo próprio grupo, com os IPs da WAN e da LAN e a distribuição das VMs pelos 4 PCs.
- A seção 4.6 explica cada regra de NAT e FORWARD. Os prints do gateway (`ip_forward = 1`, `MASQUERADE` e FORWARD com contadores de pacotes) comprovam que o tráfego foi encaminhado.
- O `traceroute google.com` a partir das VMs mostra o `g4-pc1-gw` como 1º salto e o roteador do laboratório (`172.20.20.1`) como 2º.
- O roteiro melhorou bastante em relação ao apresentado em 28/10: topologia, evidências por VM e a explicação das regras foram acrescentadas depois.

**Como melhorar:**
1. **Máscara errada nas VMs.** O Netplan das VMs está com `/24` (por exemplo, `192.168.26.66/24`), e o `ip route` confirma a rota `192.168.26.0/24` com broadcast `192.168.26.255`. A rede do grupo é `/28` (`255.255.255.240`), como a própria seção 3.2 e o exemplo do README dizem. Com `/24`, cada VM considera "local" a rede de todos os grupos e tenta falar diretamente com eles, sem passar pelo gateway. O arquivo `LEIA-ME.txt` da `g4-pc2-vm1` percebe o problema, mas ele aparece em quase todas as VMs. Corrijam para `/28` e registrem em Problemas e Soluções.
2. **Hostname com FQDN e nome curto colados.** O comando `hostname` mostra `g4-pc1-gw.grupo4.bsi-26-2.maceio.labg4-pc1-gw` em todas as VMs. O `/etc/hostname` foi editado com o FQDN e o apelido juntos (o arquivo de definições ensina `sudo nano /etc/hostname`). Usem `sudo hostnamectl set-hostname g4-pc1-gw.grupo4.bsi-26-2.maceio.lab`, como na seção 4.2, e confiram com `hostname` e `hostname -f`.
3. **Evidências trocadas.** A pasta `pc3/vm1` só tem prints da `g4-pc3-vm2` (IP `.71`), e não há nenhuma evidência da `g4-pc3-vm1`. O `Traceroute-google.png` de `pc3/vm2` foi feito na `g4-pc4-vm1`, e o de `pc4/vm1` na `g4-pc3-vm2`. O `ping_pc1_VM2-pc1_VM1.png` é a `g4-pc1-vm2` pingando ela mesma (resposta de `127.0.1.1`). Confiram o prompt de cada print antes de salvar.
4. **Evidências sem explicação.** O README só aponta para as pastas, sem dizer o que cada print comprova. Tragam para o texto pelo menos um exemplo de cada teste, com uma frase interpretando a saída, como fizeram na seção 4.6.
5. **Texto de planejamento.** Trechos como "Exemplo planejado", "Foi previsto um script", "registrar os resultados de..." (seção 5.4) e "a validação final será complementada" descrevem o que deveria ser feito, não o que foi feito. O roteiro deve relatar o que foi executado e o resultado. O exemplo de Netplan da seção 4.3 (`/28`) não é o que está nas VMs (`/24`).
6. **Placas de rede no VirtualBox.** Continua faltando o print dos Adaptadores 1 e 2 do gateway e do Adaptador 1 de cada VM em Placa em Ponte.
7. **Gateway.** Documentem os comandos que ativam o `ip_forward` de forma persistente (`/etc/sysctl.d/`) e salvam as regras (`iptables-persistent`, `netfilter-persistent save`). O banner do SSH para o gateway (`pc1/vm1`) mostra a `enp0s3` com `10.0.2.15`, o endereço do modo NAT do VirtualBox, e não `172.20.23.222`: os prints do PC1 parecem ter sido feitos em momentos e ambientes diferentes. Registrem onde e quando os testes foram refeitos.
8. **Detalhes para a Etapa 2.**
   - O Netplan das VMs clientes tem o comentário `# WAN - rede do laboratório`, copiado do gateway, e o primeiro DNS é `192.168.26.65`, que não roda servidor DNS.
   - Todas as VMs têm a **mesma chave de host SSH** (a mesma impressão digital ED25519), porque foram clonadas sem regenerar as chaves. Regenerem com `sudo rm /etc/ssh/ssh_host_*` seguido de `sudo dpkg-reconfigure openssh-server`.
   - O arquivo de definições publica a regra das senhas dos usuários; retirem do repositório.
   - Incluam as matrículas e o professor no cabeçalho.

---

## Próximos passos

- Corrijam a máscara para `/28` e o hostname nas 9 VMs antes da Etapa 2: o DNS do Projeto Final vai depender desses nomes.
- Para cada requisito da seção 11 do enunciado, coloquem o comando, o print **e uma frase dizendo o que a saída comprova**.
- Em caso de dúvida sobre algum ponto deste relatório, procurem o professor na próxima aula.
