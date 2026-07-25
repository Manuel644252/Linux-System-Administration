# Configuração de Infraestrutura de Rede com CentOS 7

Projeto da unidade curricular de Administração de Sistemas Linux, CTeSP em Redes e Sistemas Informáticos - ESTIG, Instituto Politécnico de Beja.

**Autor:** Manuel Engrola (nº 24154)
**Docente:** Prof. Mário Candeias
**Data:** janeiro de 2024

---

## Descrição do projeto

O objetivo deste trabalho foi montar, em ambiente virtualizado (GNS3), uma infraestrutura de servidor baseada em CentOS 7 Minimal, capaz de disponibilizar os serviços essenciais de uma rede local: resolução de nomes, atribuição automática de IPs, partilha de ficheiros, acesso remoto seguro e automação de tarefas de backup e monitorização.

## O que foi implementado

- Servidor DNS (BIND) com zona direta e inversa
- Servidor DHCP para atribuição automática de endereços
- Partilha de ficheiros via Samba (SMB), com autenticação por utilizador
- Acesso remoto via SSH
- Scripts em bash para monitorização de SFTP e backup incremental, agendados via crontab

## Topologia

```
                    INTERNET
                        |
                   MikroTik
                 192.168.8.254
                        |
        ┌───────────────┼───────────────┐
        |               |               |
  CentOS Server    Windows 10      CentOS Client
   192.168.8.1     192.168.8.2      192.168.8.3
        |
    Serviços:
    DNS, DHCP, SMB, SSH, scripts
```

## Máquinas e função de cada uma

| Máquina | SO | IP | Função |
|---|---|---|---|
| Router MikroTik | RouterOS 6.49.10 | 192.168.8.254 | Gateway / acesso à internet |
| Servidor CentOS | CentOS 7 Minimal | 192.168.8.1 | Servidor principal (DNS, DHCP, SMB, SSH) |
| Cliente Windows | Windows 10 64-bit | 192.168.8.2 | Máquina de teste |
| Cliente CentOS | CentOS 7 | 192.168.8.3 | Máquina de teste |

---

## Configuração

### 1. Preparação do ambiente

- GNS3 instalado
- VirtualBox (ou VMware)
- ISO do CentOS 7 Minimal
- Imagem do MikroTik RouterOS

### 2. Router MikroTik

```
/password old-password="" new-password="ASL2024"
/ip dhcp-client add interface=ether2 disabled=no
/ip address add address=192.168.8.254/24 interface=ether1
/ip firewall nat add chain=srcnat out-interface=ether2 action=masquerade
```

### 3. Configuração base do servidor CentOS

Atualizar o sistema:

```bash
yum update -y
```

Configurar IP estático em `/etc/sysconfig/network-scripts/ifcfg-eth0`:

```ini
BOOTPROTO=static
IPADDR=192.168.8.1
NETMASK=255.255.255.0
GATEWAY=192.168.8.254
DNS1=192.168.8.1
ONBOOT=yes
```

```bash
systemctl restart network
```

### 4. Servidor DNS (BIND)

Instalação:

```bash
yum install bind bind-utils -y
```

Configuração em `/etc/named.conf`: escutar em `192.168.8.1` e permitir consultas a partir de `192.168.8.0/24`.

Criação das zonas:

```bash
vi /var/named/named.manuel.local   # zona direta
vi /var/named/named.reverse        # zona inversa
```

Abrir porta no firewall e ativar o serviço:

```bash
firewall-cmd --permanent --add-service=dns
firewall-cmd --reload
systemctl start named
systemctl enable named
```

Teste:

```bash
nslookup manuel.local
```

### 5. Servidor DHCP

Instalação:

```bash
yum install dhcp -y
```

Configuração em `/etc/dhcp/dhcpd.conf`:

```ini
subnet 192.168.8.0 netmask 255.255.255.0 {
    range 192.168.8.2 192.168.8.253;
    option routers 192.168.8.254;
    option domain-name-servers 192.168.8.1;
    option domain-name "manuel.local";
}
```

```bash
systemctl start dhcpd
systemctl enable dhcpd
```

### 6. Samba (SMB)

Instalação:

```bash
yum install samba samba-client samba-common -y
```

Criação da pasta partilhada e permissões:

```bash
mkdir -p /home/samba/manuelengrola
groupadd samba
usermod -aG samba manuelengrola
chown manuelengrola:samba /home/samba/manuelengrola
chmod 770 /home/samba/manuelengrola
smbpasswd -a manuelengrola
```

Configuração em `/etc/samba/smb.conf`:

```ini
[manuelengrola]
path = /home/samba/manuelengrola
valid users = manuelengrola
read only = no
browsable = yes
```

Abrir porta no firewall e ativar o serviço:

```bash
firewall-cmd --permanent --add-service=samba
firewall-cmd --reload
systemctl start smb
systemctl enable smb
```

Acesso a partir do Windows:

```
\\192.168.8.1\manuelengrola
```

### 7. Servidor SSH

Instalação:

```bash
yum install openssh-server -y
```

Configuração em `/etc/ssh/sshd_config` (acesso root permitido para o âmbito deste laboratório):

```ini
PermitRootLogin yes
```

Abrir porta no firewall e ativar o serviço:

```bash
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload
systemctl restart sshd
systemctl enable sshd
```

Ligação a partir do cliente:

```bash
ssh root@192.168.8.1
```

(ou via PuTTY, no caso do Windows)

### 8. Scripts de automação

**Monitorização de SFTP** (`/root/scripts/SFTPfiles.sh`) — regista alterações na pasta SFTP:

```bash
#!/bin/bash
LOGFILE="/var/log/sftp_changes.log"
SFTP_DIR="/home/sftp"

echo "$(date): Checking SFTP directory..." >> $LOGFILE
# lógica de monitorização
```

**Backup incremental** (`/root/scripts/backup.sh`):

```bash
#!/bin/bash
SOURCE1="/home/BkpNomeApelido"
SOURCE2="/home/PartilhaDeRede"
DEST="/home/BackupFolder"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$DEST/$DATE"
rsync -av --link-dest="$DEST/latest" "$SOURCE1" "$DEST/$DATE/"
rsync -av --link-dest="$DEST/latest" "$SOURCE2" "$DEST/$DATE/"
rm -f "$DEST/latest"
ln -s "$DEST/$DATE" "$DEST/latest"

echo "Backup completed at $(date)"
```

Tornar os scripts executáveis e agendar via crontab:

```bash
chmod +x /root/scripts/SFTPfiles.sh /root/scripts/backup.sh
crontab -e
```

```bash
*/5 * * * * /root/scripts/SFTPfiles.sh
0 2 * * * /root/scripts/backup.sh
```

---

## Testes realizados

A partir dos clientes Windows e CentOS, foi confirmada a conectividade ao gateway, ao servidor e à internet, bem como a resolução correta do domínio `manuel.local` via DNS:

```bash
ping 192.168.8.254        # gateway
ping 192.168.8.1          # servidor
ping google.com           # internet
nslookup manuel.local     # DNS
```

Foram também testados o acesso à partilha Samba a partir do Windows, a ligação SSH a partir dos clientes, e a execução correta dos scripts de monitorização e backup.

## Notas de segurança

Foram abertas no firewall apenas as portas necessárias aos serviços em causa (22, 53, 67, 137-139, 445). O acesso SSH root foi mantido apenas para efeitos deste laboratório; num cenário de produção seria desativado a favor de utilizadores com sudo. O acesso à partilha Samba está limitado a utilizadores autenticados, e a rede do laboratório está isolada da rede pública.

## Estrutura do repositório

```
Linux-System-Administration/
├── README.md
├── ASL_Manuel_Engrola_24154.pdf   (relatório completo, com capturas de ecrã)
├── configs/
│   ├── named.conf
│   ├── dhcpd.conf
│   ├── smb.conf
│   └── sshd_config
├── scripts/
│   ├── SFTPfiles.sh
│   └── backup.sh
├── zones/
│   ├── named.manuel.local
│   └── named.reverse.local
└── docs/
    ├── network-diagram.png
    └── screenshots/
```

O relatório completo, com o passo-a-passo detalhado e as capturas de ecrã de todas as configurações, está no ficheiro PDF anexo.
