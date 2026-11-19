#!/bin/bash

################################################################################
# VALIDAÇÃO AUTOMÁTICA DE IMPLEMENTAÇÃO - Grupo 16
# Script para verificar se toda a implementação foi feita corretamente
# Pode ser executado remotamente via SSH ou localmente
#
# Uso local:
#   chmod +x validation.sh
#   ./validation.sh
#
# Uso remoto:
#   ssh usuario1@frances "bash -s" < validation.sh
#   ssh usuario1@pontaverde "bash -s" < validation.sh
#   ssh usuario1@pajuçara "bash -s" < validation.sh
#   ssh usuario1@jatiuca "bash -s" < validation.sh
################################################################################

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
PASSED=0
FAILED=0
WARNINGS=0

# Definições esperadas
EXPECTED_SERVERS=("192.168.26.241" "192.168.26.242" "192.168.26.243" "192.168.26.244")
EXPECTED_HOSTNAMES=("frances" "pontaverde" "pajuçara" "jatiuca")
EXPECTED_DOMAIN="grupo16.bsi-26-1.maceio.lab"
EXPECTED_USERS=("usuario1" "usuario2" "usuario3" "usuario4")
SUBNET_MASK="28"

################################################################################
# FUNÇÕES DE UTILIDADE
################################################################################

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}→ $1${NC}"
}

test_pass() {
    echo -e "${GREEN}✅ PASSOU:${NC} $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}❌ FALHOU:${NC} $1"
    ((FAILED++))
}

test_warning() {
    echo -e "${YELLOW}⚠️  AVISO:${NC} $1"
    ((WARNINGS++))
}

test_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

################################################################################
# 1. TESTES DE CONFIGURAÇÃO DE REDE
################################################################################

test_network_config() {
    print_section "Validando Configuração de Rede"
    
    # Teste 1: Verificar IP configurado
    local ip_addr=$(ip addr show enp0s3 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    if [[ ! -z "$ip_addr" ]]; then
        if [[ "$ip_addr" == "192.168.26."* ]]; then
            test_pass "IP configurado: $ip_addr"
        else
            test_fail "IP fora da faixa esperada: $ip_addr"
        fi
    else
        test_fail "Nenhum IP configurado em enp0s3"
    fi
    
    # Teste 2: Verificar máscara /28
    local mask=$(ip addr show enp0s3 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f2)
    if [[ "$mask" == "$SUBNET_MASK" ]]; then
        test_pass "Máscara de rede correta: /$mask"
    else
        test_fail "Máscara incorreta. Esperado: /$SUBNET_MASK, Obtido: /$mask"
    fi
    
    # Teste 3: Verificar interface UP
    if ip link show enp0s3 2>/dev/null | grep -q "UP"; then
        test_pass "Interface enp0s3 está UP"
    else
        test_fail "Interface enp0s3 não está UP"
    fi
    
    # Teste 4: Verificar tabela de roteamento
    if ip route show 2>/dev/null | grep -q "192.168.26.240/28"; then
        test_pass "Sub-rede 192.168.26.240/28 nas rotas"
    else
        test_warning "Sub-rede 192.168.26.240/28 não encontrada nas rotas"
    fi
    
    # Teste 5: Verificar gateway
    local gateway=$(ip route show | grep "default via" | awk '{print $3}')
    if [[ ! -z "$gateway" ]]; then
        test_pass "Gateway configurado: $gateway"
    else
        test_warning "Nenhum gateway padrão configurado"
    fi
    
    # Teste 6: Verificar DNS
    if grep -q "nameserver" /etc/resolv.conf 2>/dev/null; then
        test_pass "DNS configurado em /etc/resolv.conf"
    else
        test_warning "DNS não encontrado em /etc/resolv.conf"
    fi
}

################################################################################
# 2. TESTES DE HOSTNAME
################################################################################

test_hostname() {
    print_section "Validando Configuração de Hostname"
    
    # Teste 1: Verificar hostname corrente
    local current_hostname=$(hostname)
    if [[ "$current_hostname" == *"$EXPECTED_DOMAIN"* ]]; then
        test_pass "Hostname com domínio: $current_hostname"
    else
        test_fail "Hostname sem domínio esperado: $current_hostname"
    fi
    
    # Teste 2: Verificar /etc/hostname
    if [[ -f /etc/hostname ]]; then
        local file_hostname=$(cat /etc/hostname)
        if [[ "$file_hostname" == "$current_hostname" ]]; then
            test_pass "/etc/hostname corresponde ao hostname atual"
        else
            test_warning "/etc/hostname diferente do hostname atual"
        fi
    else
        test_fail "Arquivo /etc/hostname não existe"
    fi
    
    # Teste 3: Verificar com hostnamectl
    if hostnamectl status &>/dev/null; then
        test_pass "hostnamectl disponível e funcional"
    else
        test_fail "hostnamectl não funcional"
    fi
}

################################################################################
# 3. TESTES DE USUÁRIOS
################################################################################

test_users() {
    print_section "Validando Usuários do Sistema"
    
    local user_count=0
    
    for user in "${EXPECTED_USERS[@]}"; do
        # Teste: Usuário existe
        if id "$user" &>/dev/null; then
            test_pass "Usuário '$user' existe"
            ((user_count++))
            
            # Teste: Home directory existe
            local home_dir="/home/$user"
            if [[ -d "$home_dir" ]]; then
                test_pass "Diretório home de '$user' existe"
            else
                test_fail "Diretório home de '$user' não existe"
            fi
            
            # Teste: Shell padrão
            local shell=$(getent passwd "$user" | cut -d: -f7)
            if [[ "$shell" == "/bin/bash" ]]; then
                test_pass "Usuário '$user' com shell /bin/bash"
            else
                test_warning "Usuário '$user' com shell $shell (esperado /bin/bash)"
            fi
        else
            test_fail "Usuário '$user' não existe"
        fi
    done
    
    # Resumo de usuários
    test_info "Total de usuários encontrados: $user_count/${#EXPECTED_USERS[@]}"
}

################################################################################
# 4. TESTES DE /etc/hosts
################################################################################

test_hosts_file() {
    print_section "Validando /etc/hosts"
    
    # Teste 1: Arquivo existe
    if [[ -f /etc/hosts ]]; then
        test_pass "Arquivo /etc/hosts existe"
    else
        test_fail "Arquivo /etc/hosts não existe"
        return
    fi
    
    # Teste 2: Contar entradas do grupo
    local hosts_count=$(grep -c "grupo16" /etc/hosts 2>/dev/null || echo 0)
    if [[ $hosts_count -ge 4 ]]; then
        test_pass "4 ou mais entradas para grupo16 encontradas ($hosts_count)"
    else
        test_fail "Apenas $hosts_count entradas encontradas (esperado 4)"
    fi
    
    # Teste 3: Verificar cada servidor
    local entries_found=0
    for i in {1..4}; do
        local ip="192.168.26.$((240 + i))"
        if grep -q "$ip" /etc/hosts; then
            ((entries_found++))
            test_pass "Entrada para $ip encontrada"
        else
            test_fail "Entrada para $ip não encontrada"
        fi
    done
    
    # Teste 4: Verificar FQDN
    if grep -q "$EXPECTED_DOMAIN" /etc/hosts; then
        test_pass "Domínio $EXPECTED_DOMAIN encontrado em /etc/hosts"
    else
        test_fail "Domínio $EXPECTED_DOMAIN não encontrado"
    fi
}

################################################################################
# 5. TESTES DE RESOLUÇÃO DE NOMES
################################################################################

test_dns_resolution() {
    print_section "Validando Resolução de Nomes"
    
    # Teste 1: getent para cada hostname
    for hostname in "${EXPECTED_HOSTNAMES[@]}"; do
        if getent hosts "$hostname" &>/dev/null; then
            local resolved_ip=$(getent hosts "$hostname" | awk '{print $1}')
            test_pass "Hostname '$hostname' resolve para $resolved_ip"
        else
            test_fail "Hostname '$hostname' não resolve"
        fi
    done
    
    # Teste 2: Testar FQDN
    if getent hosts "frances.$EXPECTED_DOMAIN" &>/dev/null; then
        test_pass "FQDN resolve: frances.$EXPECTED_DOMAIN"
    else
        test_fail "FQDN não resolve: frances.$EXPECTED_DOMAIN"
    fi
}

################################################################################
# 6. TESTES DE CONECTIVIDADE
################################################################################

test_connectivity() {
    print_section "Validando Conectividade de Rede"
    
    # Teste 1: Ping para todos os IPs
    for ip in "${EXPECTED_SERVERS[@]}"; do
        if ping -c 1 -W 2 "$ip" &>/dev/null; then
            test_pass "Ping para $ip respondeu"
        else
            test_fail "Ping para $ip não respondeu (timeout)"
        fi
    done
    
    # Teste 2: Ping usando nomes
    for hostname in "${EXPECTED_HOSTNAMES[@]}"; do
        if ping -c 1 -W 2 "$hostname" &>/dev/null; then
            test_pass "Ping para $hostname respondeu"
        else
            test_fail "Ping para $hostname não respondeu"
        fi
    done
}

################################################################################
# 7. TESTES DE SSH
################################################################################

test_ssh() {
    print_section "Validando Serviço SSH"
    
    # Teste 1: SSH está rodando
    if systemctl is-active --quiet ssh; then
        test_pass "Serviço SSH está ativo"
    else
        test_fail "Serviço SSH não está ativo"
    fi
    
    # Teste 2: Verificar porta SSH
    if ss -tlnp 2>/dev/null | grep -q ":22"; then
        test_pass "SSH escutando na porta 22"
    else
        test_fail "SSH não está escutando na porta 22"
    fi
    
    # Teste 3: Verificar arquivo de configuração SSH
    if [[ -f /etc/ssh/sshd_config ]]; then
        test_pass "Arquivo /etc/ssh/sshd_config existe"
        
        # Verificar PasswordAuthentication
        if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
            test_pass "PasswordAuthentication habilitado"
        else
            test_warning "PasswordAuthentication pode estar desabilitado"
        fi
    else
        test_fail "Arquivo /etc/ssh/sshd_config não existe"
    fi
    
    # Teste 4: Testar conexão SSH local
    if ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no localhost "echo OK" &>/dev/null; then
        test_pass "Conexão SSH local funciona"
    else
        test_warning "Conexão SSH local pode estar com problemas"
    fi
}

################################################################################
# 8. TESTES DE SEGURANÇA
################################################################################

test_security() {
    print_section "Validando Configurações de Segurança"
    
    # Teste 1: Permissões de /etc/shadow
    local shadow_perms=$(stat -c %a /etc/shadow 2>/dev/null)
    if [[ "$shadow_perms" == "640" ]] || [[ "$shadow_perms" == "600" ]]; then
        test_pass "/etc/shadow com permissões seguras ($shadow_perms)"
    else
        test_warning "/etc/shadow com permissões: $shadow_perms (recomendado: 640 ou 600)"
    fi
    
    # Teste 2: Permissões de /etc/passwd
    local passwd_perms=$(stat -c %a /etc/passwd 2>/dev/null)
    if [[ "$passwd_perms" == "644" ]]; then
        test_pass "/etc/passwd com permissões corretas"
    else
        test_warning "/etc/passwd com permissões: $passwd_perms (recomendado: 644)"
    fi
    
    # Teste 3: Verificar senhas com hash SHA-512
    local sha512_count=$(sudo grep "usuario" /etc/shadow 2>/dev/null | grep -c '\$6\$' || echo 0)
    if [[ $sha512_count -gt 0 ]]; then
        test_pass "Senhas usando SHA-512 ($sha512_count usuários)"
    else
        test_warning "Nem todos os usuários têm hash SHA-512"
    fi
    
    # Teste 4: Verificar sudo group
    if getent group sudo | grep -q usuario1; then
        test_pass "Usuários no grupo sudo"
    else
        test_warning "Usuários podem não estar no grupo sudo"
    fi
    
    # Teste 5: Firewall status
    if command -v ufw &>/dev/null; then
        local fw_status=$(sudo ufw status 2>/dev/null | grep -o "Status: .*" || echo "Status: unknown")
        test_info "Firewall status: $fw_status"
    else
        test_info "UFW não instalado"
    fi
}

################################################################################
# 0. VALIDAÇÃO REMOTA VIA SSH
################################################################################

run_remote_validations() {
    print_section "Executando validação remota nos servidores"

    for i in "${!EXPECTED_SERVERS[@]}"; do
        ip="${EXPECTED_SERVERS[$i]}"
        user="${EXPECTED_USERS[$i]}"

        test_info "Conectando em ${user}@${ip}..."

        if ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=no "${user}@${ip}" 'bash -s' < "$0"; then
            test_pass "Validação remota em ${user}@${ip} concluída com sucesso"
        else
            rc=$?
            test_fail "Validação remota em ${user}@${ip} falhou (exit $rc)"
        fi
    done
}

################################################################################
# 9. TESTES DE NETPLAN
################################################################################

test_netplan() {
    print_section "Validando Configuração de Netplan"
    
    # Teste 1: Arquivo netplan existe
    if [[ -f /etc/netplan/00-installer-config.yaml ]]; then
        test_pass "Arquivo /etc/netplan/00-installer-config.yaml existe"
        
        # Teste 2: Validar sintaxe
        if sudo netplan validate &>/dev/null; then
            test_pass "Configuração netplan válida"
        else
            test_fail "Configuração netplan inválida"
        fi
        
        # Teste 3: Verificar conteúdo
        if grep -q "dhcp4: false" /etc/netplan/00-installer-config.yaml; then
            test_pass "DHCP desabilitado (IP estático)"
        else
            test_fail "DHCP aparentemente ativo"
        fi
        
        if grep -q "192.168.26." /etc/netplan/00-installer-config.yaml; then
            test_pass "IP na faixa 192.168.26.x encontrado"
        else
            test_fail "IP não está na faixa esperada"
        fi
    else
        test_fail "Arquivo /etc/netplan/00-installer-config.yaml não existe"
    fi
}

################################################################################
# 10. TESTES DE PERFORMANCE
################################################################################

test_performance() {
    print_section "Validando Performance e Latência"
    
    # Teste 1: Latência para localhost
    local latency=$(ping -c 1 -W 2 127.0.0.1 2>/dev/null | grep time= | awk -F'time=' '{print $2}' | cut -d' ' -f1)
    if [[ ! -z "$latency" ]]; then
        test_pass "Latência localhost: ${latency}ms"
    fi
    
    # Teste 2: Carga do sistema
    local load=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1)
    if (( $(echo "$load < 1.0" | bc -l) )); then
        test_pass "Carga do sistema: $load (baixa)"
    else
        test_warning "Carga do sistema: $load (moderada)"
    fi
    
    # Teste 3: Memória disponível
    local mem_available=$(free -h | awk '/^Mem:/ {print $7}')
    test_info "Memória disponível: $mem_available"
}

################################################################################
# 11. TESTE DE LOGS
################################################################################

test_logs() {
    print_section "Analisando Logs de Sistema"
    
    # Teste 1: Verificar logs de autenticação
    if [[ -f /var/log/auth.log ]]; then
        local failed_attempts=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo 0)
        if [[ $failed_attempts -lt 5 ]]; then
            test_pass "Poucos erros de autenticação: $failed_attempts"
        else
            test_warning "Múltiplas tentativas falhadas: $failed_attempts"
        fi
        
        local ssh_connections=$(grep -c "Accepted password" /var/log/auth.log 2>/dev/null || echo 0)
        test_info "Conexões SSH bem-sucedidas: $ssh_connections"
    else
        test_warning "Arquivo /var/log/auth.log não encontrado"
    fi
    
    # Teste 2: Verificar erros de kernel
    if [[ -f /var/log/syslog ]]; then
        local kernel_errors=$(grep -c "ERROR" /var/log/syslog 2>/dev/null || echo 0)
        if [[ $kernel_errors -lt 5 ]]; then
            test_pass "Sem erros críticos no kernel"
        else
            test_warning "Múltiplos erros encontrados no syslog"
        fi
    fi
}

################################################################################
# RELATÓRIO FINAL
################################################################################

print_report() {
    echo ""
    echo ""
    print_header "RELATÓRIO FINAL DE VALIDAÇÃO"
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    RESUMO DOS TESTES                      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    local total=$((PASSED + FAILED + WARNINGS))
    local pass_percentage=$((PASSED * 100 / total))
    
    echo -e "  ${GREEN}✅ PASSOU${NC}:        $PASSED"
    echo -e "  ${RED}❌ FALHOU${NC}:        $FAILED"
    echo -e "  ${YELLOW}⚠️  AVISOS${NC}:       $WARNINGS"
    echo -e "  ${BLUE}📊 TOTAL${NC}:        $total"
    echo ""
    echo "  Percentual de sucesso: ${GREEN}$pass_percentage%${NC}"
    echo ""
    
    # Determinar resultado geral
    if [[ $FAILED -eq 0 ]]; then
        echo -e "  ${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${GREEN}║  ✅ IMPLEMENTAÇÃO BEM-SUCEDIDA                              ║${NC}"
        echo -e "  ${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    elif [[ $FAILED -lt 5 ]]; then
        echo -e "  ${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${YELLOW}║  ⚠️  IMPLEMENTAÇÃO PARCIAL - REVISAR FALHAS                ║${NC}"
        echo -e "  ${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "  ${RED}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${RED}║  ❌ IMPLEMENTAÇÃO COM FALHAS CRÍTICAS                        ║${NC}"
        echo -e "  ${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    fi
    
    echo ""
    echo "Data/Hora: $(date '+%d/%m/%Y %H:%M:%S')"
    echo "Hostname: $(hostname)"
    echo "IP: $(ip addr show enp0s3 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1)"
    echo ""
}

################################################################################
# FUNÇÃO PRINCIPAL
################################################################################

main() {
    clear
    
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  VALIDAÇÃO AUTOMÁTICA DE IMPLEMENTAÇÃO - GRUPO 16         ║"
    echo "║  bsi-26-1 - Fundamentos de Redes de Computadores         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    
    # Executar todos os testes
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
    
    # Mostrar relatório
    print_report
}

# Executar script
if [[ "$1" == "remote" ]]; then
    run_remote_validations
    print_report
    if [[ $FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
else
    main

    # Retornar código apropriado
    if [[ $FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
fi
