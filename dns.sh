#!/bin/bash
# Script feito por: Igor Costa Melo
# github: igorcmelo


# [Dica] execute o script sem argumentos para ver como utilizá-lo


# exemplo: site.com
alvo="$1"

# nome do arquivo de wordlist
#	exemplo: lista.txt
wl="$2"

# serve para limpar a linha
#  exemplo: 
#    tentando: sub1.site.com
#    tentando: sub2.site.com  (linha anterior apagada)
limpar="\r\033[K"


# 'NORMAL' restaura a cor da saída do bash para o padrão
NORMAL='\033[0m'

# Autoexplicativo
NEGRITO='\033[1m'

# Cores do texto
ROXO='\033[1;35m'
CIANO='\033[1;36m'
AMARELO='\033[1;33m'
VERMELHO='\033[1;31m'



# Explica como utilizar o programa
function utilizacao() {
	echo -e "${NEGRITO}Utilize:"
	echo -e "	${NORMAL}$0 <domínio> <wordlist>${NEGRITO}"
	echo -e ""
	echo -e "	exemplos de domínio:	${NORMAL}google.com, facebook.com, yahoo.com, medium.com${NEGRITO}"
	echo -e "	wordlist sugerida:	${NORMAL}lista.txt <www.github.com/igorcmelo/dnsrecon/lista.txt>"
	echo -e ""
	exit 1
}



# caso o usuário passe um número incorreto de argumentos
if [[ "$#" != "2" ]]; then
	echo ""
	echo -e "${VERMELHO}Número de argumentos incorreto.${NORMAL}"
	utilizacao

# caso o domínio não seja encontrado
elif [[ "$(host $alvo | grep 'has address')" == "" ]]; then
	echo ""
	echo -e "${VERMELHO}Domínio '$alvo' não encontrado.${NORMAL}"
	utilizacao

# caso o arquivo de wordlist não exista
elif [[ ! -f "$wl" ]]; then
	echo ""
	echo -e "${VERMELHO}Arquvio de wordlist '$wl' não encontrado.${NORMAL}"
	utilizacao
fi



# serve para alterar a função da tecla CTRL C,
# que por padrão apenas encerrar o script
trap ctrl_c INT

# quando o usuário apertar ctrl c o script limpa o
# teste anterior, pula duas linhas e mostra a mensagem em vermelho
function ctrl_c() {
	echo -e "${limpar}\n"
	echo -e "${VERMELHO}Operação cancelada pelo usuário."
	exit 1
}


# Tamanho da wordlist
len=$(wc -l $wl | cut -d' ' -f1)

# Ponto que será adicionado entre o subdomínio e o nome de domínio
dot="."

# Caso a wordlist já tenha ponto no final da palavra, o ponto não será adicionado
if [[ "$(awk NR==1 $wl)" == *"." ]]; then
	dot=""
fi


# lê cada subdomínio da wordlist passada

# Achei que seria melhor fazer dessa forma, pois se a 
# wordlist for muito grande, o comando cat pode travar
for (( i = 1 ; i <= $len ; i++ )); do
	sub="$(awk NR==$i $wl)"
	sub="$sub$dot"

	# porcentagem do arquivo que já foi testada
	porcento=$((i * 100 / len))

	# limpa teste anterior, caso exista, e mostra o teste atual
	echo -ne "${limpar}tentando [ $porcento% ]: $sub.$alvo"

	# executa o comando host para saber se tal subdomínio existe
	# o grep seleciona a linha que diz o IP, caso exista
	resp=$(host -t A $sub$alvo | grep "has address")


	# se 'resp' não for nulo, significa que tal subdomínio existe,
	# pois o grep anterior retornou algum resultado
	if [[ "$resp" != "" ]]; then

		# limpa a linha atual, caso contenha algo
		echo -ne "${limpar}"

		# pega o IP, que é a quarta coluna da linha (separando por espaços)
		ip="$(echo $resp | cut -d' ' -f4)"

		# guarda a quantidade de caracteres do IP
		tam=${#ip}

		# é a quantidade de espaços que será adicionada após o IP
		# serve para manter a coluna de subdomínios alinhada
		# (veja o for abaixo)
		qtd=$((15-tam))

		# mostra o IP na cor ciano (sem quebrar a linha)
		echo -ne " ${CIANO}$ip"

		# adiciona 'qtd' espaços após o IP
		for ((j=0; j<$qtd; j++)); do
			echo -n " "
		done

		# adiciona mais 4 espaços e em seguida o subdomínio.domínio encontrado
		# utilizei 4 espaços pois o tab tem tamanho variável
		# poderia ter utilizado também a função 'tabs' para fixar o valor
		# no final, reseta a cor do bash para o normal
		echo -e "    ${ROXO}$sub$alvo ${NORMAL}"
	fi
done



# caso o código seja executado sem interrupções até o final,
# a última tentantiva é limpada e mostra uma mensagem de fim do arquivo,
# pois percorreu a wordlist inteira
echo -e "${limpar}\n"
echo -e "${AMARELO}Fim do arquivo :)"
exit 0