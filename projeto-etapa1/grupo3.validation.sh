#!/bin/bash

################################################################################
# VALIDAÇÃO AUTOMÁTICA DE IMPLEMENTAÇÃO - Grupo 3
# Uso:
#   chmod +x group3.validation.sh
#   ./group3.validation.sh
#   ./group3.validation.sh remote   # roda validação remota usando SSH
################################################################################

# Cores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Contadores
PASSED=0; FAILED=0; WARNINGS=0

# Expectativas Grupo 3
EXPECTED_SERVERS=( \
  "192.168.26.241" "192.168.26.242" "192.168.26.243" "192.168.26.244" \
  "192.168.26.245" "192.168.26.246" "192.168.26.247" "192.168.26.248" )
EXPECTED_HOSTNAMES=( "servidor" "cliente1" "cliente2" "cliente3" "cliente4" "cliente5" "cliente6" "cliente7" )
EXPECTED_DOMAIN="grupo3.bsi-26-1.maceio.lab"
EXPECTED_USERS=( "pedro.rocha" "wallex.brandao" "marcelo.feitoza" "werython.santo" )
SUBNET_MASK="28"
NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"
IFACE="enp0s3"

# Helpers
print_section(){ echo ""; echo -e "${BLUE}→ $1${NC}"; }
test_pass(){ echo -e "${GREEN}✅ PASSOU:${NC} $1"; ((PASSED++)); }
test_fail(){ echo -e "${RED}❌ FALHOU:${NC} $1"; ((FAILED++)); }
test_warning(){ echo -e "${YELLOW}⚠️  AVISO:${NC} $1"; ((WARNINGS++)); }
test_info(){ echo -e "${BLUE}ℹ️  INFO:${NC} $1"; }

# 1 Network
test_network_config(){
  print_section "Validando Configuração de Rede"
  ip_addr=$(ip addr show "$IFACE" 2>/dev/null | awk '/inet /{print $2}' | cut -d'/' -f1)
  if [[ -n "$ip_addr" ]]; then
    [[ "$ip_addr" == 192.168.26.* ]] && test_pass "IP configurado: $ip_addr" || test_fail "IP fora da faixa: $ip_addr"
  else
    test_fail "Nenhum IP configurado em $IFACE"
  fi

  mask=$(ip addr show "$IFACE" 2>/dev/null | awk '/inet /{print $2}' | cut -d'/' -f2)
  [[ "$mask" == "$SUBNET_MASK" ]] && test_pass "Máscara correta: /$mask" || test_fail "Máscara incorreta. Esperado: /$SUBNET_MASK, obtido: /$mask"

  ip link show "$IFACE" 2>/dev/null | grep -q "UP" && test_pass "Interface $IFACE está UP" || test_fail "Interface $IFACE não está UP"

  ip route show 2>/dev/null | grep -q "192.168.26.240/28" && test_pass "Sub-rede 192.168.26.240/28 nas rotas" || test_warning "Sub-rede 192.168.26.240/28 não encontrada nas rotas"

  gw=$(ip route show | awk '/default via/ {print $3; exit}')
  [[ -n "$gw" ]] && test_pass "Gateway configurado: $gw" || test_warning "Nenhum gateway padrão configurado"

  grep -q "nameserver" /etc/resolv.conf 2>/dev/null && test_pass "DNS configurado em /etc/resolv.conf" || test_warning "DNS não encontrado em /etc/resolv.conf"
}

# 2 Hostname
test_hostname(){
  print_section "Validando Hostname"
  cur=$(hostname)
  [[ "$cur" == *"$EXPECTED_DOMAIN"* ]] && test_pass "Hostname com domínio: $cur" || test_fail "Hostname sem domínio esperado: $cur"

  if [[ -f /etc/hostname ]]; then
    file_h=$(cat /etc/hostname)
    [[ "$file_h" == "$cur" ]] && test_pass "/etc/hostname corresponde ao hostname atual" || test_warning "/etc/hostname diferente do hostname atual"
  else
    test_fail "/etc/hostname não existe"
  fi

  hostnamectl status &>/dev/null && test_pass "hostnamectl disponível" || test_warning "hostnamectl não disponível"
}

# 3 Users
test_users(){
  print_section "Validando Usuários"
  count=0
  for u in "${EXPECTED_USERS[@]}"; do
    if id "$u" &>/dev/null; then
      test_pass "Usuário '$u' existe"; ((count++))
      [[ -d "/home/$u" ]] && test_pass "Home de $u existe" || test_fail "Home de $u não existe"
      shell=$(getent passwd "$u" | cut -d: -f7)
      [[ "$shell" == "/bin/bash" ]] && test_pass "Shell /bin/bash para $u" || test_warning "Shell para $u: $shell (esperado /bin/bash)"
    else
      test_fail "Usuário '$u' não existe"
    fi
  done
  test_info "Usuários encontrados: $count/${#EXPECTED_USERS[@]}"
}

# 4 /etc/hosts
test_hosts_file(){
  print_section "Validando /etc/hosts"
  [[ -f /etc/hosts ]] && test_pass "/etc/hosts existe" || { test_fail "/etc/hosts não existe"; return; }

  hosts_count=$(grep -c "grupo3" /etc/hosts 2>/dev/null || echo 0)
  (( hosts_count >= ${#EXPECTED_HOSTNAMES[@]} )) && test_pass "${hosts_count} entradas para grupo3 encontradas" || test_warning "Apenas $hosts_count entradas para grupo3 encontradas"

  found=0
  for i in $(seq 1 ${#EXPECTED_SERVERS[@]}); do
    ip="192.168.26.$((240 + i))"
    grep -q "$ip" /etc/hosts && { test_pass "Entrada para $ip encontrada"; ((found++)); } || test_warning "Entrada para $ip não encontrada"
  done

  grep -q "$EXPECTED_DOMAIN" /etc/hosts && test_pass "Domínio $EXPECTED_DOMAIN presente em /etc/hosts" || test_warning "Domínio $EXPECTED_DOMAIN ausente em /etc/hosts"
}

# 5 DNS resolution
test_dns_resolution(){
  print_section "Validando Resolução de Nomes"
  for h in "${EXPECTED_HOSTNAMES[@]}"; do
    if getent hosts "$h" &>/dev/null; then
      ip=$(getent hosts "$h" | awk '{print $1}')
      test_pass "Hostname $h resolve para $ip"
    else
      test_fail "Hostname $h não resolve"
    fi
  done

  getent hosts "servidor.$EXPECTED_DOMAIN" &>/dev/null && test_pass "FQDN servidor.$EXPECTED_DOMAIN resolve" || test_warning "FQDN servidor.$EXPECTED_DOMAIN não resolve"
}

# 6 Connectivity
test_connectivity(){
  print_section "Validando Conectividade"
  for ip in "${EXPECTED_SERVERS[@]}"; do
    ping -c1 -W2 "$ip" &>/dev/null && test_pass "Ping para $ip respondeu" || test_warning "Ping para $ip não respondeu"
  done
  for h in "${EXPECTED_HOSTNAMES[@]}"; do
    ping -c1 -W2 "$h" &>/dev/null && test_pass "Ping para $h respondeu" || test_warning "Ping para $h não respondeu"
  done
}

# 7 SSH
test_ssh(){
  print_section "Validando SSH"
  systemctl is-active --quiet ssh && test_pass "Serviço SSH ativo" || test_warning "Serviço SSH inativo"
  ss -tlnp 2>/dev/null | grep -q ":22" && test_pass "SSH escutando na porta 22" || test_warning "SSH não escutando na porta 22"
  [[ -f /etc/ssh/sshd_config ]] && test_pass "sshd_config existe" || test_fail "sshd_config ausente"
  ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no localhost "echo OK" &>/dev/null && test_pass "SSH local responde" || test_warning "SSH local pode não responder"
}

# 8 Security
test_security(){
  print_section "Validando Segurança"
  sp=$(stat -c %a /etc/shadow 2>/dev/null || echo "NA")
  [[ "$sp" =~ ^(600|640)$ ]] && test_pass "/etc/shadow com permissões seguras ($sp)" || test_warning "/etc/shadow permissões: $sp"
  pp=$(stat -c %a /etc/passwd 2>/dev/null || echo "NA")
  [[ "$pp" == "644" ]] && test_pass "/etc/passwd permissões corretas" || test_warning "/etc/passwd permissões: $pp"
  sha_count=0
  for u in "${EXPECTED_USERS[@]}"; do
    sudo grep -E "^${u}:" /etc/shadow 2>/dev/null | grep -q '\$6\$' && ((sha_count++))
  done
  (( sha_count > 0 )) && test_pass "Senhas SHA-512 encontradas ($sha_count)" || test_warning "Nenhuma senha SHA-512 detectada para usuários esperados"
  sudo getent group sudo | grep -E "$(IFS='|'; echo "${EXPECTED_USERS[*]}")" &>/dev/null && test_pass "Algum usuário esperado no grupo sudo" || test_warning "Usuários esperados podem não estar no sudo"
  command -v ufw &>/dev/null && test_info "UFW: $(sudo ufw status 2>/dev/null | head -n1)" || test_info "UFW não instalado"
}

# 9 Netplan
test_netplan(){
  print_section "Validando Netplan"
  if [[ -f "$NETPLAN_FILE" ]]; then
    test_pass "$NETPLAN_FILE existe"
    sudo netplan validate &>/dev/null && test_pass "netplan válido" || test_warning "netplan inválido"
    grep -q "dhcp4: false" "$NETPLAN_FILE" && test_pass "DHCP desabilitado" || test_warning "DHCP possivelmente habilitado"
    grep -q "192.168.26." "$NETPLAN_FILE" && test_pass "IP na faixa 192.168.26.x encontrado" || test_warning "IP não encontrado no netplan"
  else
    test_warning "$NETPLAN_FILE ausente"
  fi
}

# 10 Performance
test_performance(){
  print_section "Verificando Performance"
  lat=$(ping -c1 -W2 127.0.0.1 2>/dev/null | awk -F'time=' '/time=/{print $2}' | cut -d' ' -f1)
  [[ -n "$lat" ]] && test_pass "Latência localhost: $lat"
  load=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1)
  if (( $(echo "$load < 1.0" | bc -l) )); then test_pass "Carga baixa: $load"; else test_warning "Carga: $load"; fi
  mem=$(free -h | awk '/^Mem:/ {print $7}')
  test_info "Memória disponível: $mem"
}

# 11 Logs
test_logs(){
  print_section "Analisando Logs"
  if [[ -f /var/log/auth.log ]]; then
    fa=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo 0)
    (( fa < 5 )) && test_pass "Erros de autenticação: $fa" || test_warning "Muitas falhas de auth: $fa"
  else
    test_warning "/var/log/auth.log não encontrado"
  fi
  if [[ -f /var/log/syslog ]]; then
    errs=$(grep -c "ERROR" /var/log/syslog 2>/dev/null || echo 0)
    (( errs < 5 )) && test_pass "Erros no syslog: $errs" || test_warning "Muitos erros no syslog: $errs"
  fi
}

# Remote validations
run_remote_validations(){
  print_section "Executando validação remota"
  for i in "${!EXPECTED_SERVERS[@]}"; do
    ip="${EXPECTED_SERVERS[$i]}"
    user="${EXPECTED_USERS[$(( i % ${#EXPECTED_USERS[@]} ))]}"
    test_info "Conectando em ${user}@${ip}..."
    if ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=no "${user}@${ip}" 'bash -s' < "$0"; then
      test_pass "Validação remota ${user}@${ip} OK"
    else
      rc=$?; test_warning "Validação remota ${user}@${ip} falhou (exit $rc)"
    fi
  done
}

# Report
print_report(){
  echo ""; echo -e "${BLUE}===== RELATÓRIO FINAL - GRUPO 3 =====${NC}"
  total=$((PASSED+FAILED+WARNINGS))
  [[ $total -gt 0 ]] && pct=$((PASSED*100/total)) || pct=0
  echo -e "${GREEN}PASSOU:${NC} $PASSED  ${RED}FALHOU:${NC} $FAILED  ${YELLOW}AVISOS:${NC} $WARNINGS  TOTAL: $total"
  echo -e "Percentual de sucesso: ${pct}%"
  echo -e "Data: $(date '+%F %T') Host: $(hostname) IP: $(ip addr show $IFACE 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1)"
}

# Main
main(){
  clear
  echo "Validação automática - Grupo 3"
  test_network_config
  test_hostname
  test_users
  test_hosts_file
  test_dns_resolution
  test_connectivity
  test_ssh
  test_security
  test_netplan
  test_performance
  test_logs
  print_report
}

if [[ "$1" == "remote" ]]; then
  run_remote_validations
  print_report
  exit 0
else
  main
  [[ $FAILED -eq 0 ]] && exit 0 || exit 1
fi