#!/bin/bash 

################################################################
##  Script para enviar e-mail aos clientes do Bacula           #
##  contendo a unidade, seus jobs e filesets respectivos.      #
##  Data de criacao em 26 de Outubro de 2016.                  #
##  Escrito por: Rodrigo                                       #
################################################################


# Remove os arquivos antigos gerados na ultima execucao

rm -f fileset-*
rm -f texto-*
rm -f textlist
rm -f joblist*
rm -f unilist*
rm -f sent


# Variavel $bacula contendo o caminho do diretorio do bacula
# Variavel $dir contendo o caminho do diretorio de trabalho do script mailbacula

dir="/home/service/scripts/mailbacula"
bacdir="/etc/bacula/clients"


# Lista as unidades em um arquivo unilist

ls $bacdir > $dir/unilist

# Retira do arquivo unilist o registro do diretor ex: versa, defender...
cat unilist | sed '/client_/d' > unilist1


# While para ler o arquivo unilist1 contendo as unidades

INPUTFILE=unilist1
cat $INPUTFILE | while read unidade ; do


# Armazena na variavel $listajob todos os jobs de cada unidade 

listajob=`ls $bacdir/$unidade`


# If para salvar todos os jobs em um arquivo joblist

if [ "$?" = 1 ]
        then
echo $listajob > joblist
        else
echo $listajob >> joblist
fi
done


# Separa os jobs um em cada linha e salva em um arquivo joblist1

cat joblist | sed 's/ /\n/g' > joblist1


# Retira a tag "client_" do nome de cada job
# e salva em um arquivo joblist2


cat joblist1 | sed 's/client_//g' > joblist2


# While para ler o arquivo unilist1 contendo as unidades

INPUTFILE=unilist1
cat $INPUTFILE | while read unidade ; do


# While para leitura de cada job do arquivo joblist2

INPUTFILE=joblist2
cat $INPUTFILE | while read job ; do


# Armazena na variavel $job o nome do job sem a extensao -fd.conf

job=`echo $job | awk -F-fd.conf '{print$1 }'`


# If para criar para cada unidade seu arquivo joblist-$unidade

if [ "$?" = 1 ]
        then
echo $job | sed -n '/'$unidade'/p' > joblist-$unidade
        else
echo $job | sed -n '/'$unidade'/p' >> joblist-$unidade
fi
done
done


# While para ler o arquivo unilist1 contendo as unidades

INPUTFILE=unilist1
cat $INPUTFILE | while read unidade ; do


# While para ler cada arquivo joblist-$unidade contendo os jobs da unidade respectiva

INPUTFILE=joblist-$unidade
cat $INPUTFILE | while read job ; do


# Armazena na variavel $fileset o comando grep que procura o fileset de cada job 

fileset=`grep "File = " $bacdir/$unidade/client_$job-fd.conf | tr -d ' '`


# If para salvar o fileset de cada job gerando um arquivo fileset-$unidade-$job para cada unidade

if [ "$?" = 1 ]
       then
echo -e "Maquina: $job \n\nFileset:\n\n$fileset\n\n----------------------------------------\n"  > fileset-$unidade-$job
       else
echo -e "Maquina: $job \n\nFileset:\n\n$fileset\n\n----------------------------------------\n" >> fileset-$unidade-$job
fi
done
done


# While para ler o arquivo unilist1 contendo as unidades
# gera um arquivo texto para cada unidade

INPUTFILE=unilist1
cat $INPUTFILE | while read unidade ; do


# Armazena na variavel $listafileset a lista de fileset de cada unidade

listafileset=`cat fileset-$unidade* | tr 'a-z' 'A-Z' | sed 's/'$unidade'//g'`

# Comando echo para cada unidade contendo o corpo do E-mail, a lista de jobs e fileset
# salvando saida texto-$unidade

echo "À unidade: $unidade



Comunicado de conformidade



Prezado(a) administrador(a)/usuário(a),

Segue a relação das máquinas que realizam backup de dados na estrutura de armazenamento administrada pelo Centro de Computação. 

Solicitamos que essas informações sejam validadas e havendo qualquer divergência, o Centro de Computação deve ser informado imediatamente.


Contamos com sua colaboração,

Atenciosamente,

Diretoria de Produção
Centro de Computação - Unicamp


$listafileset" > texto-$unidade

done



# Lista todos os arquivos texto de cada unidade em um arquivo textlist

ls texto-* > textlist


# For que executa o Mutt para enviar o E-mail

for unidade in `cat textlist`

                                do
# Busca na tabela listmail o nome, E-mail e arquivo de cada unidade

unidade=`cat listmail | grep $unidade | awk '{print $1}'`
email=`cat listmail | grep $unidade | awk '{print $2}'`
arquivo=`cat listmail | grep $unidade | awk '{print $3}'`

echo "" | /usr/bin/mutt -s "Auditoria Bacula" $email -a $arquivo
done


# Remove os arquivos gerados na execucao do script

rm -f fileset-*
rm -f texto-*
rm -f textlist
rm -f joblist*
rm -f unilist*
rm -f sent

# FIM
