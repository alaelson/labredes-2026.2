# Roteiro: VM base enxuta para o Projeto (Etapa 1 e Projeto Final)

No Projeto, cada grupo usa **9 VMs** Ubuntu Server 26.04 LTS: 8 VMs distribuídas em **4 PCs** do laboratório (2 por PC) e a VM **gateway** no PC1. O Projeto Final usa as mesmas 9 VMs da Etapa 1.

Instalar o Ubuntu 9 vezes leva tempo e enche o disco dos PCs. Este roteiro mostra o caminho mais rápido:

1. instalar e preparar **uma única VM base**;
2. **reduzir** o tamanho dela;
3. **exportar** um `.ova` pequeno, **importar** nos outros PCs e **clonar** a segunda VM de cada PC;
4. dar **identidade própria** a cada VM (hostname, `machine-id` e chaves SSH).

> 💡 **Resultado real.** Aplicando a redução numa VM Ubuntu Server 26.04, o disco usado caiu de **5,6 GB para 2,5 GB**, e o arquivo `.ova` caiu de **5 GB para 1,05 GB**.

> ⚠️ **Como usar este roteiro.** Os comandos estão separados, **um por bloco**, de propósito. Copie e execute **um de cada vez**, leia a saída e só então passe para o próximo. Vários deles apagam arquivos ou pacotes, e um erro no meio de um bloco colado de uma vez pode deixar a VM sem rede ou sem espaço em disco.

---

## 1. Conceitos antes de começar

Antes de usar os comandos, é preciso entender o que cada coisa é.

| Termo | O que é |
|---|---|
| **VDI** (*VirtualBox Disk Image*) | Formato de arquivo de disco virtual próprio do VirtualBox. É o arquivo `.vdi` que guarda o "HD" da VM no seu computador. |
| **VMDK** (*Virtual Machine Disk*) | Outro formato de disco virtual, criado pela VMware e também aceito pelo VirtualBox. É o formato usado dentro dos arquivos `.ova`. |
| **Disco dinâmico** | Disco virtual que começa pequeno e **cresce** à medida que a VM grava dados. Ele cresce, mas **não encolhe sozinho** quando você apaga arquivos dentro da VM. |
| **Espaço livre "sujo"** | Quando um arquivo é apagado, o sistema só marca o espaço como livre; os dados antigos continuam no disco. Para o VirtualBox, esses blocos ainda estão "em uso" e entram na exportação. |
| **`/dev/zero`** | Arquivo especial do Linux que, quando lido, devolve uma sequência infinita de bytes zero. |
| **`dd`** | Comando do Linux que copia dados, bloco a bloco, de uma origem (`if=`, *input file*) para um destino (`of=`, *output file*). Aqui ele vai copiar zeros de `/dev/zero` para um arquivo, até encher o espaço livre. |
| **OVF / OVA** | O **OVF** (*Open Virtualization Format*) é um padrão aberto para descrever e transportar VMs. O **OVA** é um único arquivo (um pacote `tar`) com a descrição OVF e os discos em VMDK **comprimido**. Blocos zerados quase não ocupam espaço nele. |
| **Swap** | Área do disco usada como extensão da memória RAM. Na instalação do laboratório, ela é o volume lógico `swap-lv`, de cerca de 2 GB, criado no particionamento LVM. |
| **Kernel** | O núcleo do sistema operacional. O Ubuntu mantém kernels antigos instalados depois de atualizações, por segurança. |
| **Firmware** | Pequenos programas carregados em dispositivos físicos (placas Wi-Fi, placas de vídeo, etc.). Uma VM usa dispositivos virtuais e não precisa deles. No Ubuntu, eles vêm nos pacotes `linux-firmware*`. |
| **Metapacote** | Pacote vazio que só existe para "puxar" outros como dependências. Exemplo: `linux-generic` puxa o kernel mais recente **e** o `linux-firmware`. |
| **`apt purge` / `apt autoremove`** | `purge` remove um pacote **e** seus arquivos de configuração. `autoremove` remove pacotes que foram instalados como dependência e não são mais necessários. |
| **Snapshot** | "Fotografia" do estado de uma VM em um instante, para a qual é possível voltar depois. |
| **Clone completo × clone vinculado** | O **clone completo** copia o disco inteiro. O **clone vinculado** (*linked clone*) cria um disco pequeno que guarda **só as diferenças** em relação a um *snapshot* da VM original. |
| **`machine-id`** | Identificador único da instalação, gravado em `/etc/machine-id`. Serviços como o DHCP do `systemd-networkd` usam esse valor. VMs clonadas ou importadas do mesmo OVA herdam o mesmo `machine-id`, e é preciso gerar um novo em cada uma. |
| **Chaves de host SSH** | Par de chaves que identifica o servidor SSH de cada máquina (arquivos `/etc/ssh/ssh_host_*`). VMs clonadas herdam as mesmas chaves e devem gerar as suas. |
| **netplan** | Ferramenta de configuração de rede do Ubuntu. Lê arquivos YAML em `/etc/netplan/`. |
| **`ip`** | Comando do pacote `iproute2`, a ferramenta atual do Linux para ver e configurar a rede (substitui o antigo `ifconfig`). Neste material usamos sempre **`ip -c -4 a`**: `-c` colore a saída (nome da interface, estado `UP`/`DOWN` e endereço destacados), `-4` mostra só IPv4 (não usamos IPv6 por enquanto) e `a` é a abreviação de `address`. |

---

## 2. Antes de começar

1. **Crie a VM base** seguindo a [Aula 01](Aula1.md) (Ubuntu Server 26.04, LVM, OpenSSH), com o nome `ubuntu-base`. Ainda em **NAT**, atualize o sistema e instale os pacotes usados no projeto. Tudo que for **igual nas 9 VMs** deve ser feito na base, antes da redução.
1. **Faça um snapshot** da VM: *Máquina → Tirar Snapshot*, com o nome `antes-da-limpeza`. Se algo der errado, basta restaurá-lo.
1. Tenha à mão o caminho do disco da VM. No VirtualBox, abra *Configurações → Armazenamento*, clique no disco e veja o campo **Localização**. Exemplo: `C:\2026.2\BSI\VM\<NomeDoAluno>\ubuntu-base\ubuntu-base.vdi`.

---

## 3. Diagnóstico: quanto e onde está ocupado

Estes comandos **só consultam** informações e não alteram nada na VM.

Uso total da partição raiz (`/`):

```bash
df -h /
```

As 15 maiores pastas, em ordem crescente de tamanho (`-x` não atravessa para outras partições):

```bash
sudo du -xh / --max-depth=2 2>/dev/null | sort -h | tail -15
```

Área de swap em uso (na instalação do laboratório, o volume lógico `swap-lv`):

```bash
swapon --show
```

Versão do kernel **que está rodando agora**:

```bash
uname -r
```

> 📝 **Anote essa versão.** O kernel em uso **nunca** pode ser removido.

Kernels, headers e firmwares instalados:

```bash
dpkg -l | grep -E '^ii +linux-(image|headers|modules|firmware|generic|virtual)'
```

Um Ubuntu Server recém-instalado costuma ocupar de 2 a 3 GB. Os maiores culpados costumam ser `/usr/lib/firmware`, `/usr/lib/modules` (kernels) e `/usr/src` (headers de kernel).

---

## 4. Limpeza

### 4.1 Cache de pacotes e logs

Apague os pacotes `.deb` baixados em `/var/cache/apt/archives`:

```bash
sudo apt clean
```

Reduza os logs do sistema (o *journal* do `systemd`) para no máximo 20 MB:

```bash
sudo journalctl --vacuum-size=20M
```

### 4.2 Kernels antigos

**Passo 1.** Confira o kernel em uso:

```bash
uname -r
```

**Passo 2.** Compare com a lista do `dpkg -l` da seção 3. Se houver um kernel **mais novo** que o mostrado pelo `uname -r`, a VM foi atualizada, mas ainda não está usando o kernel novo. **Reinicie antes de continuar:**

```bash
sudo reboot
```

Depois do boot, rode o `uname -r` de novo.

**Passo 3.** Remova os kernels antigos que o próprio sistema considera desnecessários:

```bash
sudo apt autoremove --purge
```

> ⚠️ O `apt` mostra a lista do que vai remover e pede confirmação. **Leia a lista**: ela **não pode** conter a versão mostrada pelo `uname -r`.

**Passo 4 (só se ainda sobrar um kernel antigo).** Remova-o pela versão. No exemplo, a versão antiga é `7.0.0-30`; **troque pela versão antiga da sua VM**:

```bash
sudo apt purge 'linux-*7.0.0-30*'
```

> ⚠️ Confira de novo a lista antes de confirmar.

**Passo 5 (só se sobrar uma pasta de módulos de kernel já removido).** Veja se algum pacote é dono da pasta. No exemplo, a pasta é a do kernel `7.0.0-14`:

```bash
dpkg -S /usr/lib/modules/7.0.0-14-generic
```

Se a resposta for `no path found matching pattern` (nenhum pacote é dono), apague a pasta:

```bash
sudo rm -rf /usr/lib/modules/7.0.0-14-generic
```

> ⚠️ **Nunca** apague a pasta do kernel mostrado pelo `uname -r`.

### 4.3 Firmware (opcional, maior ganho: de 500 MB a 1 GB)

Os pacotes `linux-firmware*` só servem para hardware físico. No Ubuntu 26.04 eles vêm divididos em vários pacotes (`linux-firmware-intel-wireless`, `linux-firmware-nvidia-graphics`, etc.), e o `'linux-firmware*'` abaixo pega todos. Para removê-los sem perder o kernel em uso, primeiro marque o kernel como "instalado manualmente" e só depois remova o metapacote `linux-generic`.

**Passo 1.** Marque o kernel em uso como manual. O `$(uname -r)` é substituído automaticamente pela versão do kernel em uso:

```bash
sudo apt-mark manual linux-image-$(uname -r) linux-modules-$(uname -r)
```

O `apt-mark manual` impede que o `apt` remova o kernel em uso, que antes era apenas uma dependência do `linux-generic`.

**Passo 2.** Remova o metapacote e os firmwares:

```bash
sudo apt purge linux-generic linux-image-generic linux-headers-generic 'linux-firmware*'
```

> ⚠️ **Leia a lista antes de confirmar.** Ela **não pode** conter `linux-image-` nem `linux-modules-` com a versão mostrada pelo `uname -r`.

**Passo 3.** Remova as dependências que sobraram:

```bash
sudo apt autoremove --purge
```

**Passo 4.** Reinicie a VM:

```bash
sudo reboot
```

**Passo 5.** Depois do boot, confira se o kernel continua o mesmo e se a rede funciona:

```bash
uname -r
```

```bash
ip -c -4 a
```

Se a VM não subir ou ficar sem rede, restaure o snapshot `antes-da-limpeza` e pule esta seção.

> ℹ️ Sem o metapacote `linux-generic`, o `apt upgrade` deixa de instalar kernels novos. Para VMs de prática, isso não é problema. Para voltar ao comportamento normal, use `sudo apt install linux-generic`.

### 4.4 E o swap?

Não mexa no swap. Na instalação do laboratório, ele é o volume lógico `swap-lv`, de cerca de 2 GB, e o disco virtual dinâmico só ocupa espaço no Windows pela parte do swap que já foi usada de fato. Com só 512 MB de RAM em cada VM, o swap é importante para o sistema não ficar sem memória.

### 4.5 Snaps e atualizador de firmware

O **snap** é um formato de pacote da Canonical, gerenciado pelo serviço `snapd`, que traz o programa junto com as bibliotecas de que ele precisa. O Ubuntu Server já vem com alguns snaps instalados que não são usados nas práticas, como os `core` (sistema base dos snaps), o `lxd` (gerenciador de contêineres) e o `hwctl` (ferramenta de certificação de hardware). Na VM de teste do Ubuntu 26.04, remover o `snapd` liberou perto de **1 GB**.

**Passo 1.** Veja os snaps instalados:

```bash
snap list
```

Se aparecerem só snaps de base ou de sistema (como `core20`, `core22`, `core24`, `snapd`, `lxd` ou `hwctl`), pode remover o `snapd`. Se aparecer algum programa usado nas aulas, pule esta seção.

**Passo 2.** Remova o `snapd` e, com ele, todos os snaps:

```bash
sudo apt purge snapd
```

> ⚠️ **Leia a lista antes de confirmar.** Se aparecer o metapacote `ubuntu-server`, responda `n`: removê-lo faria o `autoremove` levar muitas ferramentas do sistema.

**Passo 3.** Apague a pasta de snaps da pasta pessoal:

```bash
rm -rf ~/snap
```

**Passo 4.** Remova o `fwupd`, o atualizador de firmware de hardware físico (BIOS, SSD, etc.), que não tem uso numa VM:

```bash
sudo apt purge fwupd
```

**Passo 5.** Remova as dependências que sobraram, lendo a lista antes de confirmar:

```bash
sudo apt autoremove --purge
```

### 4.6 Confira o resultado

```bash
df -h /
```

---

## 5. Zerar o espaço livre e desligar

Este é o passo que mais reduz o tamanho final.

> ⚠️ **Espaço no Windows.** Enquanto o `dd` enche a raiz de zeros, o arquivo `.vdi` cresce até quase o tamanho da raiz (cerca de **29 GB** na instalação do laboratório). Antes de começar, confira se o disco `C:` do PC tem **pelo menos 32 GB livres**. O espaço volta depois da compactação (seção 6).

**Passo 1.** Limpe o cache de pacotes mais uma vez:

```bash
sudo apt clean
```

**Passo 2.** Encha o espaço livre com zeros. `bs=1M` copia em blocos de 1 MB e `status=progress` mostra o andamento:

```bash
sudo dd if=/dev/zero of=/zero bs=1M status=progress
```

> ℹ️ O `dd` pode levar alguns minutos e **termina com a mensagem `No space left on device`**. Isso é esperado: ele para quando o disco enche de zeros.

**Passo 3.** Apague o arquivo de zeros. **Não pule este passo**, senão a VM fica com o disco cheio:

```bash
sudo rm /zero
```

**Passo 4.** Na instalação do laboratório, o `/boot` é uma partição separada, de 1 GB, fora do LVM. Confira se ele aparece numa linha própria:

```bash
df -h /boot
```

Se o `/boot` aparecer numa linha própria (por exemplo `/dev/sda2`), zere-o também:

```bash
sudo dd if=/dev/zero of=/boot/zero bs=1M status=progress
```

E apague o arquivo:

```bash
sudo rm /boot/zero
```

**Passo 5.** Apague o histórico de comandos do root e dos usuários:

```bash
sudo rm -f /root/.bash_history /home/*/.bash_history
```

**Passo 6.** Limpe o histórico da sessão aberta:

```bash
history -c
```

**Passo 7.** Impeça que a sessão grave o histórico de novo ao desligar:

```bash
unset HISTFILE
```

**Passo 8.** Desligue a VM:

```bash
sudo poweroff
```

> Os passos 6, 7 e 8 precisam ser feitos **no mesmo terminal**, nessa ordem.

---

## 6. Compactar o disco no computador hospedeiro

Com a VM **desligada**, abra o PowerShell no Windows.

**Passo 1.** Entre na pasta do VirtualBox:

```powershell
cd 'C:\Program Files\Oracle\VirtualBox'
```

O instalador do VirtualBox **não coloca** a pasta dele no `PATH` do Windows. O `PATH` é a variável de ambiente com a lista de pastas onde o sistema procura os programas digitados no terminal. Por isso, digitar só `VBoxManage` em qualquer pasta dá o erro *"O termo 'VBoxManage' não é reconhecido..."*, e é preciso entrar na pasta do VirtualBox antes.

**Passo 2.** Compacte o disco. Troque o caminho pelo **Localização** do disco da sua VM (seção 2). O `.\` no início diz ao PowerShell para executar o programa **da pasta atual**, já que ele não procura programas na pasta atual sem esse prefixo:

```powershell
.\VBoxManage.exe modifymedium disk "C:\2026.2\BSI\VM\<NomeDoAluno>\ubuntu-base\ubuntu-base.vdi" --compact
```

* O `VBoxManage` é a ferramenta de linha de comando do VirtualBox. O subcomando `modifymedium disk ... --compact` devolve ao Windows o espaço dos blocos zerados.
* **Use aspas** no caminho do disco. Sem aspas, um espaço no caminho causa o erro `Invalid parameter`.
* O `--compact` só funciona com discos **`.vdi`**. Se o disco for `.vmdk`, pule este passo: a exportação para OVA já descarta os zeros.

Depois de compactar, tire um novo snapshot da VM: `base-limpa`.

---

## 7. Levar a VM base para os 4 PCs

As VMs do projeto ficam em **4 PCs**, com 2 VMs em cada um, mais a VM gateway no PC1. Em vez de instalar o Ubuntu em cada VM, o grupo exporta a VM base reduzida **uma vez** e a importa nos outros PCs.

### 7.1 Exportar a VM base (no PC onde ela foi preparada)

1. Com a VM desligada, vá em *Arquivo → Exportar Appliance* e selecione a VM base.
2. Formato **OVF 2.0** e nome `ubuntu-base.ova`, salvo em `C:\2026.2\BSI\VM\original`.
3. Em **Política de endereço MAC**, escolha **Remover todos os endereços MAC das placas de rede**.

Gere o *hash* do arquivo no PowerShell, para conferir se a cópia chegou íntegra:

```powershell
Get-FileHash 'C:\2026.2\BSI\VM\original\ubuntu-base.ova' -Algorithm SHA256
```

O **hash SHA-256** é uma "impressão digital" do arquivo. Se um único bit mudar, o hash muda, então dá para comparar a cópia com o original.

Com a VM reduzida, o `.ova` deve ficar em torno de **1 GB**.

### 7.2 Copiar e importar nos outros PCs

> **No PC onde a base foi preparada não é preciso importar.** Nele, crie as VMs como clones vinculados da própria `ubuntu-base` (seção 7.3) e deixe a `ubuntu-base` desligada, sem usá-la no projeto.

1. Copie o `ubuntu-base.ova` para a mesma pasta `C:\2026.2\BSI\VM\original` dos outros 3 PCs (pendrive ou pasta compartilhada entre os PCs do grupo) e confira o hash em cada um.
2. Em cada PC, vá em *Arquivo → Importar Appliance* e selecione o `.ova`.
3. Em **Pasta base da máquina**, use `C:\2026.2\BSI\VM\<NomeDoAluno>`.
4. Em **Política de endereço MAC**, escolha **Gerar novos endereços MAC para todas as placas de rede**.
5. Dê à VM importada o nome da **primeira VM daquele PC** (por exemplo `g0-pc2-vm1`).

### 7.3 Criar a segunda VM de cada PC com clone vinculado

O **clone vinculado** guarda só as diferenças em relação à VM original e ocupa poucos MB no começo, em vez de mais uma cópia inteira do disco.

1. Clique com o botão direito na VM importada (ou na `ubuntu-base`, no PC onde ela foi preparada) → **Clonar**.
2. Nos PCs que importaram o OVA, dê o nome da segunda VM daquele PC (por exemplo `g0-pc2-vm2`). No PC onde a base foi preparada, execute os passos 1 a 4 duas vezes a partir da `ubuntu-base`: uma para criar a primeira VM (por exemplo `g0-pc1-vm1`) e outra para criar a segunda (`g0-pc1-vm2`).
3. Em **Política de endereço MAC**, escolha **Gerar novos endereços MAC para todas as placas de rede**.
4. Em **Tipo de clone**, escolha **Clone vinculado**.

**No PC1, crie também a VM gateway:** faça mais um clone vinculado com o nome `gx-pc1-gw` e, com ele desligado, habilite o **Adaptador 2** em *Configurações → Rede*. As duas placas do gateway são configuradas depois, seguindo as [Aulas 06](Aula6.md) e [07](Aula7.md).

> ⚠️ Clones vinculados **dependem** da VM original e do snapshot dela. **Não apague nem mova** a VM original enquanto o clone existir.

### 7.4 Dar identidade própria a cada VM

Ligue cada VM importada ou clonada e faça os passos abaixo **uma vez em cada uma**.

**Passo 1.** Mude o nome da máquina para o FQDN do enunciado (por exemplo `g0-pc1-vm1.grupo0.bsi-26-2.maceio.lab`):

```bash
sudo hostnamectl set-hostname NOME-DA-VM
```

**Passo 2.** Ajuste a linha `127.0.1.1` do `/etc/hosts` para o novo nome:

```bash
sudo nano /etc/hosts
```

**Passo 3.** Apague o `machine-id` herdado da VM base. O hostname é o nome **para as pessoas**; o `machine-id` é o identificador **interno** da instalação, e trocar um não muda o outro. Toda VM importada ou clonada da mesma base fica com o mesmo `machine-id`, e o Ubuntu Server usa esse valor, por exemplo, como identificador de cliente DHCP: duas VMs com o mesmo `machine-id`, na mesma rede e usando DHCP, podem receber **o mesmo IP**.

```bash
sudo rm -f /etc/machine-id /var/lib/dbus/machine-id
```

**Passo 4.** Gere um `machine-id` novo e único:

```bash
sudo systemd-machine-id-setup
```

**Passo 5.** Apague as chaves de host SSH herdadas da VM base:

```bash
sudo rm -f /etc/ssh/ssh_host_*
```

**Passo 6.** Gere chaves novas. **Não pule este passo**, senão o servidor SSH não volta a funcionar:

```bash
sudo ssh-keygen -A
```

O `ssh-keygen -A` gera as chaves de host de todos os tipos que estiverem faltando.

**Passo 7.** Reinicie a VM:

```bash
sudo reboot
```


Depois disso, siga o enunciado do projeto a partir da configuração de rede: placas em **Bridge**, IP estático com Netplan (seção 10 do [enunciado da Etapa 1](projeto-etapa1/README.md)), NAT no gateway e testes.

> ⚠️ **Netplan das VMs importadas ou clonadas.** O instalador do Ubuntu costuma gravar no arquivo do netplan as linhas `match: macaddress:` e `set-name:`, que amarram a configuração ao endereço MAC da placa. Como cada VM importada ou clonada recebe um MAC novo, **substitua todo o conteúdo** do arquivo pelo modelo do enunciado, que identifica a placa pelo nome (`enp0s3`). Se essas linhas ficarem, a rede não sobe.

---

## 8. Checklist

- [ ] Snapshot `antes-da-limpeza`
- [ ] `apt clean` e `journalctl --vacuum-size`
- [ ] Kernel em uso conferido com `uname -r`; kernels antigos removidos
- [ ] (Opcional) Firmware removido, reboot e rede conferidos
- [ ] Snaps (`snapd`) e `fwupd` removidos, se não usados
- [ ] `dd` de zeros na raiz (e no `/boot`, se separado) + `rm` do arquivo
- [ ] Histórico apagado e VM desligada
- [ ] `VBoxManage ... --compact` no `.vdi`
- [ ] Snapshot `base-limpa`
- [ ] OVA exportado com MACs removidos e hash conferido
- [ ] OVA importado nos PCs 2 a 4 com MACs novos
- [ ] Segunda VM de cada PC (e gateway no PC1) como clone vinculado
- [ ] Em cada VM: hostname, `/etc/hosts`, `machine-id` e chaves SSH novos

---

## Referências

* ORACLE. **Oracle VirtualBox User Guide** (capítulos sobre armazenamento virtual, clonagem, importação/exportação de appliances e `VBoxManage modifymedium`). Disponível em: <https://www.virtualbox.org/manual/>.
* DMTF. **Open Virtualization Format (OVF)**. Disponível em: <https://www.dmtf.org/standards/ovf>.
* CANONICAL. **Ubuntu Server documentation**. Disponível em: <https://documentation.ubuntu.com/server/>.
* CANONICAL. **Netplan documentation**. Disponível em: <https://netplan.readthedocs.io/>.
* FREEDESKTOP.ORG. **machine-id(5) e systemd-machine-id-setup(1)**. Disponível em: <https://www.freedesktop.org/software/systemd/man/latest/machine-id.html>.
* Páginas de manual do Linux: `dd(1)`, `swapon(8)`, `apt(8)`, `apt-mark(8)`, `ssh-keygen(1)` — acessíveis na própria VM com `man <comando>`.
