#!/var/opt/UNItools/bin/bash
#
# Copyright (c) 2016 Niels Thomas Haugård. All Rights Reserved.
#

# for perl
export LANGUAGE=C
export LC_ALL=C
export LANG=C

#
# Vars
#
MY_LOGFILE=/var/opt/i2drd/log/drd.log
LOGGER="logger -t `basename $0` -p mail.crit"
TMPFILE=`/bin/mktemp /tmp/db.XXXXXXXXXX`
EPOCH="1Jan1970 00:00:00"

export LANGUAGE=C
export LANG=C
export LC_ALL=C

#
# Functions
#

# contains(string, substring)
# print 0 if the specified string contains the specified substring,
# otherwise print 1. If you want to break your script then let it return 0
function contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        echo 0    # $substring is in $string
    else
        echo 1    # $substring is not in $string
    fi
}

datediff() {
        d1=$(date -d "$1" +%s)
        d2=$(date -d "$2" +%s)
        echo $(( (d1 - d2) / 86400 ))
}

logit() {
# purpose     : Timestamp output
# arguments   : Line og stream
# return value: None
# see also    :
	LOGIT_NOW="`/bin/date '+%H:%M:%S (%d/%m)'`"
	STRING="$*"

	if [ -n "${STRING}" ]; then
		$echo "${LOGIT_NOW} ${STRING}" >> ${MY_LOGFILE}
		${LOGGER} "${LOGIT_NOW} ${STRING}"
		if [ "$VERBOSE" = "TRUE" ]; then
			$echo "${LOGIT_NOW} ${STRING}"
		fi
	else
		while read LINE
		do
			if [ -n "${LINE}" ]; then
				$echo "${LOGIT_NOW} ${LINE}" >> ${MY_LOGFILE}
				${LOGGER} "${LOGIT_NOW} ${LINE}"
				if [ "$VERBOSE" = "TRUE" ]; then
					$echo "${LOGIT_NOW} ${STRING}"
				fi
			else
				$echo "" >> ${MY_LOGFILE}
			fi
		done
	fi
}

################################################################################
# Main
################################################################################

echo=/bin/echo
case ${N}$C in
	"") if $echo "\c" | grep c >/dev/null 2>&1; then
		N='-n'
	else
		C='\c'
	fi ;;
esac

VERBOSE=FALSE
if [ "$1" == "-v" ]; then
	VERBOSE=TRUE
fi

case `uname` in
	IPSO)		. $HOME/.profile	> /dev/null 2>&1
	;;
	Linux|Solaris)	. $HOME/.bash_profile	> /dev/null 2>&1
			. $HOME/.bashrc		> /dev/null 2>&1
	;;
	*)		. $HOME/.profile	> /dev/null 2>&1
	;;
esac

if [ -f /tmp/.CPprofile.sh ]; then
.	/tmp/.CPprofile.sh
fi

/bin/rm -f ${MY_LOGFILE}

logit "Starting '$0 $*'"

NOW=`/bin/date +%Y_%B_%d_%H%M`
DDNOW=`/bin/date '+%d%B%Y'`		# til datediff

MYDIR=/var/opt/i2drd
RULES_EXPORT=${MYDIR}/tmp/stage1.csv
REPORT=${MYDIR}/reports/report_${NOW}.csv
HTML=${MYDIR}/reports/report_${NOW}.html
DB=${MYDIR}/db/uuid.db
RULEBASEDB=${MYDIR}/db/uuid-from-rulebase.db
LOGFILEDB=${MYDIR}/db/uuid-from-logfile.db

cd $MYDIR

# R65 - R75.xx
LOGS=/var/opt/UNIfw1lr/log/oldlogs
if [ ! -d "$LOGS" ]; then
	# R77.xx 
	LOGS=/var/opt/UNIfw1lr/data/html
fi

LATESTLOGDIR=` ls -1 ${LOGS} |sort -n|tail -1`

LOGFILE=$LOGS/$LATESTLOGDIR/${LATESTLOGDIR}.txt
GZLOGFILE=$LOGS/$LATESTLOGDIR/${LATESTLOGDIR}.txt.gz
RM_LOGFILE_ON_EXIT=0

test -d $MYDIR/tmp || {
	mkdir $MYDIR/tmp
}

test -d $MYDIR/data || {
	mkdir $MYDIR/data
}

test -f $DB || {
	touch $DB
	# UUID;hits;date-time-of-last-hit
}

(
	sed 's/;aldrig$/;never/' ${DB} > ${DB}.tmp
	/bin/mv ${DB}.tmp ${DB}
)

test -d $MYDIR/reports || {
	mkdir $MYDIR/reports
}

#test -d $MYDIR/oldreports || {
#	mkdir $MYDIR/oldreports
#}
#
## 0 flyt eksisterende rapporter fra reports -> oldreports, hvilket gør det lettere for hjælperenpå
## bun@i2.ssi.i2.dk at hente dagens data
#if [ "$(ls -A $MYDIR/reports)" ]; then
#	/bin/mv $MYDIR/reports/* $MYDIR/oldreports
#else
#	logit "$MYDIR/reports is empty, no report moved"
#fi

# vi ved ikke hvad rulebasen hedder. Den skal stå her: (vi er en mgmt station ... )
test -f $MYDIR/db/rulebasename || {
	echo rulebase name unknown
	echo print name eg default to $MYDIR/db/rulebasename
	exit 0
}
RULEBASE=`cat $MYDIR/db/rulebasename`

if [ ! -f $MYDIR/db/first_data_seen_date ]; then
	FIRST=`head -20 $LOGFILE |  awk -F';' '$1 == 0 { print $2 " " $3 }'`
	echo $FIRST > $MYDIR/db/first_data_seen_date
fi

logit "exec $MYDIR/bin/rule2txt.pl -f $FWDIR/conf/rulebases_5_0.fws -r ${RULEBASE} > ${RULES_EXPORT}"
$MYDIR/bin/rule2txt.pl -f $FWDIR/conf/rulebases_5_0.fws -r ${RULEBASE} > ${RULES_EXPORT}
logit "made ${RULES_EXPORT} (`wc -l < ${RULES_EXPORT}` rules/lines)"

if [ -f $GZLOGFILE ]; then
	logit "extracting $GZLOGFILE ... "
	gunzip -c $GZLOGFILE > $LOGFILE
	RM_LOGFILE_ON_EXIT=1
fi

logit "logfile: `du -hs < $LOGFILE `"

logit "creating $RULEBASEDB from ${RULES_EXPORT} ... "
awk -F';' 'NF == 12 { print $7 ";0;1Jan1970 00:00:00" }' ${RULES_EXPORT} > $RULEBASEDB

logit "creating ${LOGFILEDB} from ${LOGFILE} ..."
$MYDIR/bin/uuid2hits.pl ${LOGFILEDB} ${LOGFILE}

# sorter DB RULEBASEDB og LOGFILEDB påregel, seneste dato/tid og print kun den sidste linie. Gem i DB
# TODO: check det her er rigtigt (det virker)
# Sorter *db efter dato ($3) og print den sidste UUID - linie
cat ${RULEBASEDB} ${LOGFILEDB} ${DB} | sort -M -r -t';' -k1,1 -k3,3 |
awk -F';' '
	BEGIN { PREV_UUID = ""; LAST_UUID_LINE = "" };
	{
		if( $1 == PREV_UUID)
		{
			LAST_UUID_LINE=$0
			next;
		}
		{
			PREV_UUID=$1;
			print $LAST_UUID_LINE
		}
	}' > ${TMPFILE}

/bin/mv ${DB} ${DB}.prev
/bin/mv ${TMPFILE} ${DB}

logit "made new ${DB} ... "

logit "adding HITS and LATEST_SEEN to the report template ... (ANTAL and SENESTE)"

#_ _ANTAL_;_SENESTE_;1; 010-0010;{A997F45B-A751-402A-A6FA-D342ED0CD482};accept;enabled;Log;Tillad al trafik mellem firewall enforcement moduler og management station
#_echo "AntalIdag;Seneste;Regel nr;Regel navn;UUID;Type;enabled/disabled;Log;Beskrivelse" > ${REPORT}

# "Nr;Navn;Enabled/Disabled;Log;AntalIdag;Seneste;UUID;Source;Destignation;Service;Action;Beskrivelse"
# $rule_nr;$rule_name;$disabled;$track;_ANTAL_;_SENESTE_;$rule_uid;$rule_src;$rule_dst;$rule_service;$type;$comment\n";
#  1        2          3         4     5       6          7         8         9         10            11    12

echo "Nr;Navn;Enabled/Disabled;Log;AntalIdag;Seneste;Source;Destignation;Service;Action;Beskrivelse" >> ${REPORT}

cat ${RULES_EXPORT} |while read LINE
do
	# contains "abcd" "e" || echo "abcd does not contain e"
	# contains "abcd" "ab" && echo "abcd contains ab"
	rtn=`contains "${LINE}" "__HEADER__"`
	case $rtn in
	0)	echo $LINE >> ${REPORT}					# Header linie
	;;
	*)	UUID=`echo $LINE | awk -F';' '{ print $7 }' `
		ANTAL=`awk -F';' 'BEGIN { a=0; } $0 ~ /'$UUID'/ { a=$2; next } END { print a }' $DB`
		SENESTE=`grep $UUID $DB | awk -F';' '{ print $3 }'`

		# change ${EPOCH} to 'never'

		case "${SENESTE}" in
			""|${EPOCH})	ANTAL=0; SENESTE="never"
			;;
			*)	:
			;;
		esac
		logit "UUID=$UUID, ANTAL=$ANTAL, SENESTE=$SENESTE"

		if [ "$SENESTE" != "never" ]; then
			DAYSAGO=`datediff "$DDNOW" "$SENESTE"`
			if [ "${ANTAL}" -eq 0 ]; then
				echo $LINE | sed "s/_ANTAL_/$ANTAL/; s/_SENESTE_/$SENESTE <br>[$DAYSAGO dage siden]/" >> ${REPORT}
			else
				echo $LINE | sed "s/_ANTAL_/$ANTAL/; s/_SENESTE_/$SENESTE/" >> ${REPORT}
			fi
		else
			echo $LINE | sed "s/_ANTAL_/$ANTAL/; s/_SENESTE_/$SENESTE/" >> ${REPORT}
		fi
	;;
	esac
done

logit "done. Rulebase export with //hits// and //latest seen// saved as ${REPORT}"

logit "Building csv and HTML report .... "
$MYDIR/bin/csv2html.sh ${REPORT} ${LOGFILE}

HTMLFILE=`echo ${REPORT}  | sed 's/.csv/.html/g'`
logit "Done, csv saved as ${REPORT}, html as ${HTMLFILE}"

if [ "${RM_LOGFILE_ON_EXIT}" -eq 1 ]; then
	logit "Removing $LOGFILE made by me"
	/bin/rm $LOGFILE
fi

HTMLDIR=/var/opt/i2drd/data/html/
mkdir -p $HTMLDIR
/bin/mv ${HTMLFILE} $HTMLDIR/rapport.html
/bin/mv ${REPORT} $HTMLDIR/rapport.csv
#( cd $HTMLDIR; rm -f index.html; ln -s rapport.html index.html; iconv -t latin1 -f utf-8 rapport.html > i; /bin/mv i rapport.html )
( cd $HTMLDIR; rm -f index.html; ln -s rapport.html index.html )
chmod 555 `find $HTMLDIR -type d`
chmod 444 `find $HTMLDIR -type f`

logit made $HTMLDIR/${HTMLFILE}

logit "all done"
