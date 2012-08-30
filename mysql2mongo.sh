#!/bin/sh
# $Id: mysql2mongo.sh 1997 2012-08-21 06:49:50Z shlomin $

#TEMP=`getopt -n './mysql2mongo.sh' --long myhost:,myuser:,mypass:,mydb:,mytbl:,mohost:,modb:,mocoll:: -- "$@"`
#eval set -- "$TEMP"

dumpfile='/tmp/dump.csv'
# Впишите сюда путь к программе mongoimport в вашей системе
mongoimport='/usr/bin/mongoimport'
# Установите в нужное значение для считывания строк пачками
# Или в 0 для считывания всего сразу
limit=0

if ! test -x "$mongoimport"
then
    echo "Не найдена программа $mongoimport"
    exit 1
fi

while getopts "h:u:p:d:t:m:b:c:" Opts;
do
    case "$Opts" in
        h) echo "MySQL host = $OPTARG"; MySQLhost="$OPTARG";;
        u) echo "MySQL user = $OPTARG"; MySQLuser="$OPTARG";;
        p) echo "MySQL pass = *******"; MySQLpass="$OPTARG";;
        d) echo "MySQL name = $OPTARG"; MySQLDBname="$OPTARG";;
        t) echo "MySQL table= $OPTARG"; MySQLtable="$OPTARG";;
        m) echo "Mongo host = $OPTARG"; MongoDBhost="$OPTARG";;
        b) echo "Mongo name = $OPTARG"; MongoDBname="$OPTARG";;
        c) echo "Mongo coll = $OPTARG"; MongoDBcollection="$OPTARG";;
        ?) echo "usage: ./mysql2mongo.sh -h 192.168.77.80 -u vcard -p qwe3321 -d vcard -t DefCode -m 127.0.0.1 -b appapi -c DefCode"; exit 1 ;;
    esac
done

count=`mysql -h $MySQLhost -u $MySQLuser -p$MySQLpass $MySQLDBname -e "SELECT COUNT(*) FROM $MySQLtable;" | sed 1d`
echo "Будет импортировано $count строк"

:>$dumpfile

if [ ! $limit -eq 0 ]
then
    point=0
    while [ $point -lt $count ]
    do
        `mysql -h $MySQLhost -u $MySQLuser -p$MySQLpass $MySQLDBname -e "SELECT * FROM $MySQLtable limit $point,$limit" | tr "\t" "," >> $dumpfile`
        let point=point+$limit
    done
else
    `mysql -h $MySQLhost -u $MySQLuser -p$MySQLpass $MySQLDBname -e "SELECT * FROM $MySQLtable" | tr "\t" "," >> $dumpfile`
fi

echo `$mongoimport -d $MongoDBname -c $MongoDBcollection --type csv --file $dumpfile --headerline --drop -f ','`

rm $dumpfile
