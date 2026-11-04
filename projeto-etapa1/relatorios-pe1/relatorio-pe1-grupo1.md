# Relatório de Avaliação do Projeto Etapa 1 — Grupo 1

**INSTITUTO FEDERAL DE EDUCAÇÃO, CIÊNCIA E TECNOLOGIA DE ALAGOAS (IFAL) — Campus Maceió**  
**Curso:** Bacharelado em Sistemas de Informação (BSI)  
**Disciplina:** Laboratório de Sistemas Operacionais e Redes (LSOR) — 2026.2  
**Professor:** Alaelson de Castro Jatobá Neto  
**Grupo:** 1 — rede `192.168.26.16/28` · domínio `grupo1.bsi-26-2.maceio.lab`  
**Matrículas:** 2023007098 · 2023007122 · 2023011920 · 2023011930  
**Apresentação:** 28/10/2026 · **Versão do roteiro avaliada:** commit `eb92d2f` (04/11/2026), arquivos `README.md` e `Configuracao-VMs.md`  
**Data do relatório:** 04/11/2026

---

## Sumário da avaliação

| Componente | Nota |
|---|---|
| Apresentação e testes no laboratório (28/10) | 9,0 |
| Roteiro no GitHub | 8,0 |
| **Nota do Projeto Etapa 1 (Avaliação 2)** | **8,5** |

> **Composição:** a nota do projeto é a média da apresentação (testes ao vivo no laboratório) e do roteiro. Ela entra com peso de 80% na Nota 2 (Nota 2 = 20% da Atividade 3 + 80% do Projeto Etapa 1).

---

## Checklist do enunciado

| Requisito (enunciado do Projeto Etapa 1) | Situação | Observação |
|---|---|---|
| Identificação (Modelo de 7 Passos) | Parcial | Faltam as matrículas e o título da prática no cabeçalho. |
| Topologia lógica e física com os IPs do grupo | Atende | Figuras 1 e 2 refeitas com nomes e endereços do Grupo 1. |
| Tabela de endereçamento e FQDN | Atende | Tabela 3.3 completa. |
| Hardware de cada VM | Atende | 2 GB de RAM, 1 vCPU, 32 GB. |
| Placas em Bridge no VirtualBox | Atende | Prints dos dois adaptadores do gateway e da VM7. |
| Hostname no padrão `g1-pcY-vmZ` / `g1-pc1-gw` | Não atende | Usados `vm1`…`vm8` e `vm-gateway` (também na planilha). |
| Netplan do gateway | Atende | Arquivo, `ip -br a` e `ip route` corretos. |
| Netplan e hostname de cada VM | Parcial | Há um bloco por VM, mas o Netplan aparece só como modelo; as Figuras 7 a 15 estão sem imagem. |
| `/etc/hosts` em todas as VMs | Parcial | Print apenas da VM7. |
| Usuários `nome.sobrenome` em todas as VMs | Parcial | Formato fora do padrão (sem ponto); o laço usa `usuario1…usuario4`. |
| `ip_forward`, NAT, FORWARD e persistência | Atende, com erro no texto | Ver "Roteiro", item 2. |
| SSH entre VMs com os usuários dos integrantes | Parcial | Só um dos três prints mostra o comando `ssh`. |
| Ping entre as VMs por IP, nome curto e FQDN | Parcial | O teste por FQDN e IP é da VM pingando ela mesma. |
| Saída para a internet e `traceroute` (1º salto no gateway) | Atende | `ping 1.1.1.1`, `ping google.com` e `traceroute` com o 1º salto em `192.168.26.17`. |
| Verificações no gateway (`sysctl`, `iptables -t nat`, `iptables -L`) | Atende | Figuras 6 a 8. |
| Problemas e Soluções | Não atende | Diz que não houve problemas, mas a apresentação mostrou três. |

---

## Apresentação em sala (28/10) · Nota 9,0

**O que vocês fizeram bem:** O ambiente passou nos testes de SSH, de ping e de resolução de nomes pelo `/etc/hosts`, e o `traceroute` funcionou tanto a partir do gateway quanto das VMs. O roteiro estava bem construído e o link do repositório estava na planilha de acompanhamento.

**Como melhorar:** Na hora dos testes, uma VM não tinha todos os usuários dos integrantes, e outra estava com o Netplan incompleto e o IP errado. Antes de apresentar, confiram as 9 VMs com os mesmos três comandos: `getent passwd <usuários>`, `ip -br a` e `cat /etc/hosts`.

---

## Roteiro · Nota 8,0

**O que vocês fizeram bem:**
- A topologia lógica e física foi refeita com os endereços do grupo, com tabela de hosts e faixa livre, e está entre as melhores da turma.
- A seção de NAT explica o papel do `MASQUERADE` e das regras de FORWARD com `conntrack`. Os prints de `ip_forward`, NAT, FORWARD e persistência mostram exatamente os comandos documentados.
- O `traceroute google.com` da VM7 mostra o gateway do grupo como 1º salto e o roteador do laboratório como 2º.
- O novo `Configuracao-VMs.md` organiza a configuração VM a VM e traz uma tabela útil de problemas comuns.

**Como melhorar:**
1. **Nomes fora do padrão.** O enunciado (seção 7) pede `g1-pc1-gw` e `g1-pcY-vmZ`. O roteiro usa `vm-gateway` e `vm1`…`vm8`, e o próprio diagrama em texto da seção 3.4 chama o gateway de `g1-pc1-gw`, o que deixa o documento inconsistente. Os nomes de usuário também deveriam seguir `nome.sobrenome`.
2. **Erro técnico na seção 4.4.** O texto afirma que "a política padrão de FORWARD é DROP", mas nenhum comando a altera, e o print da Figura 8 mostra `Chain FORWARD (policy ACCEPT ...)`. Ou incluam `sudo iptables -P FORWARD DROP` (e expliquem o efeito), ou corrijam o texto.
3. **Teste de ping inválido (Figura 13, 3º print).** A VM5 pinga `vm5.grupo1...` e `192.168.26.22`, que são o seu próprio nome e o seu próprio IP. A resposta vem de `127.0.1.1` em 0,03 ms. Isso não testa a rede. Façam o teste por FQDN e por IP **para outra VM**.
4. **SSH sem evidência (Figura 14).** Dois dos três prints mostram só um prompt (`usuario@vm2:~$`), sem o comando `ssh` nem a mensagem de login. Mostrem o comando `ssh <usuário>@<hostname>` e a sessão aberta.
5. **Testes de uma única origem.** Quase tudo parte da VM7. O enunciado pede ping entre todas as VMs. Uma tabela origem × destino preenchida, com um print por PC, resolve.
6. **`Configuracao-VMs.md` incompleto.** As Figuras 7 a 15 têm título e não têm imagem. O Netplan de cada VM aparece só como comentário (`# addresses: 192.168.26.18/28`); o ideal é o `cat` do arquivo real de cada uma.
7. **Problemas e Soluções.** A seção diz que não houve problemas, mas na apresentação apareceram três: usuário faltando, Netplan incompleto e IP errado. Registrar o que deu errado e como foi corrigido faz parte do relatório técnico.
8. **Detalhes.** Na tabela da seção 1, a `enp0s3` (WAN, `172.20.23.67`) aparece como "Interface interna" e a `enp0s8` como "externa"; está invertido. As Figuras 5 e 9 do README são o mesmo print. A conclusão cita `nslookup`, que não aparece nos testes.

---

## Próximos passos

- Padronizem os hostnames e os usuários antes da Etapa 2: os serviços de DNS, LDAP e e-mail do Projeto Final usarão esses nomes.
- Para cada requisito da seção 11 do enunciado, coloquem o comando, o print **e uma frase dizendo o que a saída comprova**.
- Em caso de dúvida sobre algum ponto deste relatório, procurem o professor na próxima aula.
