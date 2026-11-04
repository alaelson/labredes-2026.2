# Relatório de Avaliação do Projeto Etapa 1 — Grupo 3

**INSTITUTO FEDERAL DE EDUCAÇÃO, CIÊNCIA E TECNOLOGIA DE ALAGOAS (IFAL) — Campus Maceió**  
**Curso:** Bacharelado em Sistemas de Informação (BSI)  
**Disciplina:** Laboratório de Sistemas Operacionais e Redes (LSOR) — 2026.2  
**Professor:** Alaelson de Castro Jatobá Neto  
**Grupo:** 3 — rede `192.168.26.48/28` · domínio `grupo3.bsi-26-2.maceio.lab`  
**Matrículas:** 2021008710 · 2021008953 · 2023007730 · 2024014201  
**Apresentação:** 28/10/2026 (testes suspensos; reapresentação pendente) · **Versão do roteiro avaliada:** commit `362121c` (04/11/2026, 16h10), `README.md`  
**Data do relatório:** 04/11/2026

---

## Sumário da avaliação

| Componente | Nota |
|---|---|
| Apresentação e testes no laboratório (28/10) | 6,0 (provisória, até a reapresentação) |
| Roteiro no GitHub | 4,5 |
| **Nota do Projeto Etapa 1 (Avaliação 2)** | **5,25** (provisória) |

> **Composição:** a nota do projeto é a média da apresentação (testes ao vivo no laboratório) e do roteiro. Ela entra com peso de 80% na Nota 2 (Nota 2 = 20% da Atividade 3 + 80% do Projeto Etapa 1).
>
> **Entrega:** até a data deste relatório, o grupo não havia preenchido o formulário de entrega do roteiro, e o link do repositório não estava na planilha de acompanhamento. Entregas após 04/11/2026 valem no máximo 80% da nota do roteiro.

---

## Checklist do enunciado

| Requisito (enunciado do Projeto Etapa 1) | Situação | Observação |
|---|---|---|
| Identificação (Modelo de 7 Passos) | Não atende | Faltam instituição, disciplina, professor, matrículas e data; não há Objetivo, Conclusão nem Referências. |
| Topologia lógica e física com os IPs do grupo | Parcial | Topologia física refeita em 04/11, com um erro de nome; não há topologia lógica. |
| Tabela de endereçamento e FQDN | Atende | Seção 3, no padrão `g3-pcY-vmZ`. |
| Hardware de cada VM | Parcial | Preenchido, mas com 25 GB de disco (padrão: 32 GB). |
| Placas em Bridge no VirtualBox | Não atende | Afirmado no texto, sem nenhum print; na apresentação havia VMs em NAT. |
| Netplan do gateway | Parcial | IP da WAN preenchido (`172.20.23.49`), diferente do informado na planilha (`.50`); sem print do arquivo real. |
| Netplan de cada VM | Não atende | Só um exemplo, e o print de outra VM contradiz o arquivo documentado (ver "Roteiro", item 1). |
| `/etc/hosts` em todas as VMs | Parcial | Print de uma VM; na apresentação, o gateway e outras VMs não tinham o arquivo. |
| Usuários `nome.sobrenome` em todas as VMs | Parcial | Correto, com os quatro integrantes, mas comprovado em uma VM só. |
| `ip_forward`, NAT, FORWARD e persistência | Não atende | A seção 9 tem só os tópicos do esqueleto, sem nenhum comando. |
| SSH entre VMs com os usuários dos integrantes | Parcial | Um teste pelo nome (`g3-pc4-vm1` → `g3-pc3-vm2`). |
| Ping entre as VMs por IP, nome curto e FQDN | Não atende | Só os comandos; a tabela de resultados está vazia e não há print. |
| Saída para a internet e `traceroute` (1º salto no gateway) | Não atende | Só os comandos, sem print. |
| Verificações no gateway (`sysctl`, `iptables`) | Não atende | Só os comandos, sem print. |
| Problemas e Soluções | Não atende | Tabela vazia. |

---

## Apresentação em sala (28/10) · Nota 6,0 (provisória)

**O que vocês fizeram bem:** A definição das interfaces estava correta, e o roteiro apresentado trazia vários testes de conectividade com ping e SSH.

**Como melhorar:** Nos testes apareceram vários problemas que o grupo não conseguiu resolver em sala: VMs com a placa de rede em **NAT** em vez de Bridge, ausência de ping entre as máquinas e falta do `/etc/hosts` no gateway e em outras VMs. Os testes foram suspensos até a correção, e o grupo deve **reapresentar** o ambiente. A nota da apresentação será revista na reapresentação.

---

## Roteiro · Nota 4,5

**O que vocês fizeram bem:**
- A tabela de endereçamento e o `/etc/hosts` estão corretos e no padrão de nomes, e o print de `getent hosts` comprova a resolução por nome curto e por FQDN.
- Os usuários dos quatro integrantes estão criados, com print do `getent passwd` e do `/home`.
- O `IP da WAN` e a tabela de hardware foram preenchidos, e a topologia física foi refeita com os IPs do grupo.
- As explicações acrescentadas nas seções 5 e 6 ajudam o leitor a entender o que cada comando faz.

**Como melhorar:**
1. **As VMs não estão usando só o IP estático.** O print do `ip a` / `ip route` da `g3-pc4-vm1` (seção 8) mostra **dois endereços** na `enp0s3`, o `192.168.26.56/28` estático e o `172.20.22.65/22` recebido por DHCP, e **duas rotas padrão**: uma via `192.168.26.49` e outra via `172.20.20.1`. O print do SSH mostra o mesmo na `g3-pc3-vm2` (`172.20.22.48`). Ou seja:
   - o `dhcp4: false` documentado **não é a configuração ativa**. Provavelmente há outro arquivo em `/etc/netplan/` (por exemplo, `50-cloud-init.yaml`) com DHCP ligado. Listem a pasta com `ls /etc/netplan/` e deixem um único arquivo;
   - com um IP da rede do laboratório, a VM sai para a internet **sem passar pelo gateway**, e o projeto deixa de testar o NAT. Isso também ajuda a explicar os problemas da apresentação.

   O print estava no roteiro e ninguém comentou a saída. Ler e interpretar o que o terminal mostra é parte essencial do relatório.
2. **Seção 9 (NAT) vazia.** Os três tópicos ("comandos usados para ativar `ip_forward`...", "comandos das regras MASQUERADE e FORWARD", "comandos de persistência") são o esqueleto do enunciado. Coloquem os comandos reais (Aula 08) e os prints de `sysctl net.ipv4.ip_forward`, `sudo iptables -t nat -L -n -v` e `sudo iptables -L -n -v`.
3. **Testes sem evidência.** Em 04/11 foram retirados do roteiro os prints de NAT, ping e `traceroute`. A seção 11 ficou só com comandos, a tabela de ping está vazia e o exemplo de SSH ainda usa `usuario1.sobrenome`. Preencham a tabela origem × destino, mostrem o ping por IP, nome curto e FQDN e o `traceroute google.com` **a partir de uma VM**, com o 1º salto em `192.168.26.49`.
4. **Placas de rede.** Incluam o print do Adaptador 1 (e do Adaptador 2 no gateway) em **Placa em Ponte** de cada VM. Foi exatamente o problema encontrado na apresentação.
5. **Topologia.** Na figura nova, a caixa do PC2 diz `g2-pc2-vm1`; o correto é `g3-pc2-vm1`. Incluam também a topologia lógica, com o gateway, as duas interfaces e a rede `/28`.
6. **IP da WAN.** O roteiro usa `172.20.23.49`, e a planilha de acompanhamento registra `172.20.23.50`. Confirmem qual está configurado e corrijam o outro.
7. **LVM.** O print da seção 5 mostra o volume `ubuntu-lv` com 11,5 GB e 11,5 GB livres no grupo de volumes: o volume não foi estendido. Usem `lvextend` e `resize2fs`, conforme a Aula 01, e comentem a saída.
8. **Modelo de 7 Passos.** Completem a identificação (instituição, disciplina, professor, matrículas, data) e incluam Objetivo, Problemas e Soluções (há muito a registrar: placas em NAT, DHCP ativo, `/etc/hosts` ausente), Conclusão e Referências.
9. **Entrega.** Preencham o formulário de entrega e coloquem o link do repositório na planilha de acompanhamento.

---

## Próximos passos

- Corrijam o ambiente antes da reapresentação: um único arquivo Netplan por VM, com `dhcp4: false`; placas em Bridge; `/etc/hosts` nas 9 VMs; NAT no gateway.
- Para cada requisito da seção 11 do enunciado, coloquem o comando, o print **e uma frase dizendo o que a saída comprova**.
- Em caso de dúvida sobre algum ponto deste relatório, procurem o professor na próxima aula.
