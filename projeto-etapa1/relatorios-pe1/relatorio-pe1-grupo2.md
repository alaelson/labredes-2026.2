# Relatório de Avaliação do Projeto Etapa 1 — Grupo 2

**INSTITUTO FEDERAL DE EDUCAÇÃO, CIÊNCIA E TECNOLOGIA DE ALAGOAS (IFAL) — Campus Maceió**  
**Curso:** Bacharelado em Sistemas de Informação (BSI)  
**Disciplina:** Laboratório de Sistemas Operacionais e Redes (LSOR) — 2026.2  
**Professor:** Alaelson de Castro Jatobá Neto  
**Grupo:** 2 — rede `192.168.26.32/28` · domínio `grupo2.bsi-26-2.maceio.lab`  
**Matrículas:** 2023000622 · 2023002055 · 2023002289 · 2023002369  
**Apresentação:** 28/10/2026 · **Versão do roteiro avaliada:** commit `2b83451` (29/10/2026), `README.md` e pasta `Imagens/`  
**Data do relatório:** 04/11/2026

---

## Sumário da avaliação

| Componente | Nota |
|---|---|
| Apresentação e testes no laboratório (28/10) | 10,0 |
| Roteiro no GitHub | 9,0 |
| **Nota do Projeto Etapa 1 (Avaliação 2)** | **9,5** |

> **Composição:** a nota do projeto é a média da apresentação (testes ao vivo no laboratório) e do roteiro. Ela entra com peso de 80% na Nota 2 (Nota 2 = 20% da Atividade 3 + 80% do Projeto Etapa 1).

---

## Checklist do enunciado

| Requisito (enunciado do Projeto Etapa 1) | Situação | Observação |
|---|---|---|
| Identificação (Modelo de 7 Passos) | Parcial | Faltam as matrículas; não há seção de Objetivo nem de Referências. |
| Topologia lógica e física com os IPs do grupo | Atende | Refeitas em 29/10 com nomes, IPs e tabela do grupo. |
| Tabela de endereçamento e FQDN | Atende | Tabela da seção 2 completa e no padrão. |
| Hardware de cada VM | Parcial | Só a RAM aparece (2048 MB). O disco é de 10 GB, abaixo do padrão de 32 GB. |
| Placas em Bridge no VirtualBox | Atende | Prints dos dois adaptadores do gateway e das VMs do PC2. |
| Hostname no padrão `g2-pcY-vmZ` / `g2-pc1-gw` | Parcial | VMs corretas; o gateway aparece como `g2-pc1-g2` em todos os prompts. |
| Netplan do gateway e das VMs | Parcial | Gateway e 4 VMs (PC2 e PC3) com print; faltam as do PC1 e do PC4. |
| `/etc/hosts` em todas as VMs | Parcial | Erros no print e no texto (ver "Roteiro", item 1). |
| Usuários `nome.sobrenome` em todas as VMs | Parcial | Três dos quatro usuários diferem da coluna "Usuário da VM" da planilha. |
| `ip_forward`, NAT, FORWARD e persistência | Parcial | Falta a saída de `sysctl net.ipv4.ip_forward`; regras duplicadas. |
| SSH entre VMs com os usuários dos integrantes | Parcial | SSH feito por IP; a única sessão pelo nome aparece sem o comando, e um print é login no console. |
| Ping entre as VMs por IP, nome curto e FQDN | Atende | Testes a partir de 5 VMs. |
| Saída para a internet e `traceroute` (1º salto no gateway) | Atende | 1º salto em `g2-pc1-gw (192.168.26.33)` a partir de 5 VMs. |
| Verificações no gateway (`iptables -t nat`, `iptables -L`) | Atende | Figuras 16 e 17, com contadores mostrando tráfego encaminhado. |
| Problemas e Soluções | Atende | Sintoma, causa e solução bem descritos. |

---

## Apresentação em sala (28/10) · Nota 10,0

**O que vocês fizeram bem:** Todos os testes foram feitos no laboratório e em todas as VMs: `traceroute` a partir do gateway e das VMs, ping com resolução pelo `/etc/hosts` e usuários configurados. O roteiro apresentado já era o mais completo da turma, bem explicado, com comandos e saídas.

**Como melhorar:** Nada a corrigir na parte prática. Para a Etapa 2, mantenham o mesmo cuidado de deixar as ferramentas de diagnóstico (`traceroute`, `net-tools`) instaladas em todas as VMs.

---

## Roteiro · Nota 9,0

**O que vocês fizeram bem:**
- É o roteiro mais bem explicado da turma: cada figura tem uma legenda dizendo o que ela comprova.
- A topologia refeita é excelente, com os nomes, os IPs, a faixa livre e as regras do grupo.
- A estratégia de VM base com clonagem e geração de novos MACs está documentada e justificada, e o problema de conflito de MAC aparece em Problemas e Soluções.
- As evidências são reais e cobrem várias máquinas: Netplan de 5 VMs, ping por IP, nome curto e FQDN e `traceroute` com o 1º salto no `.33`. Os contadores da FORWARD (milhares de pacotes) provam que o tráfego passou pelo gateway.

**Como melhorar:**
1. **`/etc/hosts` com erro.** O texto da seção 3.2 manda gravar `127.0.1.1 g2-pc1-gw...` em **todas** as VMs; essa linha deve ter o nome da própria VM. No print (Figura 6), a linha `127.0.1.1` está como `vm_ubuntu` e a linha do `192.168.26.41` tem o apelido `g2-pc1-vm2` (deveria ser `g2-pc4-vm2`). Com isso, `g2-pc1-vm2` resolve para dois IPs diferentes.
2. **Hostname do gateway.** O prompt do gateway mostra `g2-pc1-g2` em todos os prints. Confiram `hostnamectl` e `/etc/hostname`.
3. **Regras de iptables duplicadas.** A Figura 16 mostra a regra `MASQUERADE` três vezes, e a Figura 17 tem as regras de FORWARD repetidas, sinal de que os comandos foram executados várias vezes. Além disso, a regra documentada (`-i enp0s8 -o enp0s3 -j ACCEPT`) não é a que aparece aplicada (`ctstate NEW,ESTABLISHED`). Limpem com `iptables -F` e `iptables -t nat -F`, apliquem uma vez só e salvem com `netfilter-persistent save`.
4. **Falta a verificação do `ip_forward`.** O enunciado pede a saída de `sysctl net.ipv4.ip_forward` no gateway.
5. **SSH pelo nome.** O texto mostra `ssh usuario@g2-pc2-vm1`, mas os prints das Figuras 20 e 21 fazem `ssh 192.168.26.36` e `ssh 192.168.26.40`, por IP. A Figura 22 mostra o fim de uma sessão (`Connection to g2-pc1-vm2 closed`) sem o comando que a abriu, e a Figura 23 é um login no console, não SSH. A legenda da Figura 21 ("SSH entre `g2-pc2-vm1` e `g2-pc2-vm2`") não corresponde ao print (gateway para `192.168.26.40`).
6. **Cobertura dos testes.** Nenhum teste parte do PC4, e a Figura 31, legendada como `g2-pc1-vm2`, foi feita na `g2-pc1-vm1`. Também faltam `ping 1.1.1.1` e `ping google.com` explícitos.
7. **Hardware e usuários.** Listem RAM, CPU e disco de cada VM e usem 32 GB de disco, como no padrão da disciplina. Alinhem os nomes de usuário com a planilha. E não publiquem a senha dos usuários (`chpasswd` com a senha em texto claro) num repositório público.
8. **Modelo de 7 Passos.** Incluam as matrículas, uma seção de Objetivo e as Referências ao final.

---

## Próximos passos

- Corrijam o `/etc/hosts` e o hostname do gateway antes da Etapa 2: o DNS do Projeto Final vai substituir esse arquivo e precisa partir de nomes corretos.
- Mantenham o padrão de legenda dizendo o que cada print comprova e confiram se a legenda corresponde ao print.
- Em caso de dúvida sobre algum ponto deste relatório, procurem o professor na próxima aula.
