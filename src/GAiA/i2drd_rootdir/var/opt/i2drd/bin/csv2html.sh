#!/var/opt/UNItools/bin/bash
#
# $Header: /lan/ssi/shared/software/internal/i2drd/src/GaIA/csv2html.sh,v 1.2 2016/06/15 12:21:53 root Exp root $
#
# Copyright (c) 2016 Niels Thomas Haugård. All Rights Reserved.
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF I2/DTU, DENMARK
# The copyright notice above does not evidence  any  actual  or
# intended publication of such source code.

#
# vars
#

MY_LOGFILE=/var/opt/i2drd/log/drd.log
LOGGER="logger -t `basename $0` -p mail.crit"

datediff() {
	d1=$(date -d "$1" +%s)
	d2=$(date -d "$2" +%s)
	echo $(( (d1 - d2) / 86400 )) days
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


CSVFILE=$1
LOGFILE=$2

if [ ! -f "$LOGFILE" ]; then
	echo "log-file '$LOGFILE' not found, bye"
	exit 
fi

if [ ! -f "$CSVFILE" ]; then
	echo "csv-file '$CSVFILE' not found, bye"
	exit 
fi


REPORT=`basename $CSVFILE .csv`.html

MYDIR=/var/opt/i2drd
REPORTDIR=${MYDIR}/reports/

REPORT=${REPORTDIR}/${REPORT}

EPOCH=`cat $MYDIR/db/first_data_seen_date`

################################################################################
# Main
################################################################################

VERBOSE=TRUE

echo=/bin/echo
case ${N}$C in
"") if $echo "\c" | grep c >/dev/null 2>&1; then
	N='-n'
else
	C='\c'
fi ;;
esac

if [ -f "$REPORT" ]; then
	echo "'$REPORT' findes, bye"
	exit 0
fi

NOW=`date +%Y%m%d%H%M`

#FIRST=`head -2 $LOGFILE | tail -1 | awk -F';' '{ print $2 " " $3 }'`
FIRST=`head -20 $LOGFILE |  awk -F';' '$1 == 0 { print $2 " " $3 }'`
LAST=`tail -1 $LOGFILE | awk -F';' '{ print $2 " " $3 }'`

logit "First line: $FIRST, Last line: $LAST"
logit "Time: `datediff $FIRST $LAST`"
    
TITLE="Status for regler der ikke anvendes"
TITLE="Dead Rule Detection Report"
REPORT_TIME="`export LC_ALL=en_GB.UTF-8; export LANG=da_DK.UTF-8; /bin/date +'%d %B %Y kl %H:%M:%S'`"

logit "Report on $REPORT_TIME ... "

cat $CSVFILE | iconv -f latin1 -t utf-8 | (

cat << EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">
<HTML>
    <HEAD>
		<meta charset="UTF-8">
        <TITLE>$TITLE</TITLE>
<STYLE TYPE="text/css"> <!-- BODY,DIV,TABLE,THEAD,TBODY,TFOOT,TR,TH,TD,P { font-family:"Arial"; font-size:x-small } --> </STYLE>
<STYLE TYPE="text/css">
body { color: #000000; } span.c1 {color: #FFFFFF; }
table { width: 100%; border: 0; }
th,td{ vertical-align: top; border-spacing: 0; border: 0; border-collapse: collapse; padding: 0.6em; }
.copyright { border-top: 1px solid #999; font-family:verdana, arial, sans-serif; font-size:x-small; color:#999; }
</STYLE>
    </HEAD>
    <BODY>
        <TABLE FRAME="VOID" CELLSPACING="10" COLS="1" RULES="NONE" BORDER="0"><TBODY><TR><TD>
		<H1>$TITLE</H1>
		<P>
		This is a report showing hit counts for each rule in the active rulebase between <em>begin</em> and <em>end</em>.<br><br>
		The report is made with <em>i2drd</em>, which is described <a href="/i2drd.pdf" target="_blank">here</a>.<br><br>
		
		
		<H2>Rapport info</H2>
		<ul>
		<li>Begin: <strong>$FIRST</strong>
		<li>End:  <strong>$LAST</strong>
		<li>First log information recorded is <strong>$EPOCH</strong>
		<li>Report made on <strong>$REPORT_TIME</strong>
		<li>A csv version of the report is <a href="/rapport.csv" hdownload="rapport.csv">here</a>
		</ul>
		<H2>Color codes</H2>
		<ul>
		<li>Disabled rules are marked with <span style="background-color:FF9966;">this color</span>. They server no security purpose amd may be deleted
		<li>Rules without hits are marked with <span style="background-color:FFD6FF;">this color </span> amd may be deleted, <em>only if logging is enabled</em>. Other wise they are just rules with no logging and the number of hits is actually unknown so the label <em>never</em> in the column is used in lack of something better
		<li>Rules without hits <em>today</em> are marked with <span style="background-color:#FFFFEE;">this color</span> and should be evaluated. The date and time of the last hit is printed with the number of days since then in parantheses.
		</ul>
		<H2>Rapport</H2>
		<P>
Column labels:
<UL>
	<li><b>Enabled-Disabled</b>: The rule is active/inactive
	<li><b>Nr.</b>: Rule number (continuous)
	<li><b>Rule name</b>: Rule name (may be empty)
	<li><b>Hits</b>: Number of hits for today for this rule
	<li><b>Seneste</b>: Latest date/time with hits on the rule if not today
	<li><b>uuid</b>: Rule UUID - not shown in the policy editor. Unique across different policies
	<li><b>Source</b>: IP Source info 
	<li><b>Destignation</b>: IP destignation info
	<li><b>Service</b>: Service info
	<li><b>Action</b>: Action upon rule match (accept, reject, drop etc)
	<li><b>Log</b>: Log enabled/disabled: notice that if logging is disabled the numbe of hits is actually unknown
	<li><b>Beskrivelse</b>: Comment
</ul></p>
The number of hits is calculated for one log-file / one day and is not accumulated between the reports. The time and date
for the last seen hit is saved across reports. The rule UUID is shown for debug purposes only. It may be used in queries on
the logview'er.<br>

</P>
		<TABLE FRAME="VOID" CELLSPACING="1" COLS="9" RULES="NONE" BORDER="1" WIDTH="100%">
            <TBODY>
                <TR>
		    <!-- burde være #80E2FA | 0066CC -->
                    <TD style="width:5%" ALIGN="center" BGCOLOR="#0080FF"><SPAN CLASS="c1">Enabled-Disabled</SPAN></TD> 
                    <TD style="width:5%" ALIGN="center" BGCOLOR="#0080FF"><SPAN CLASS="c1">Nr.</SPAN></TD> 
                    <TD style="width:5%" ALIGN="center" BGCOLOR="#0080FF"><SPAN CLASS="c1">Rule name</SPAN></TD> 
                    <TD style="width:5%" ALIGN="center" BGCOLOR="#0080FF"><SPAN CLASS="c1">Hits</SPAN></TD>
                    <TD style="width:5%" ALIGN="center" BGCOLOR="#0080FF"><SPAN CLASS="c1">Latest</SPAN></TD>
                    <TD style="width:10%" ALIGN="center" BGCOLOR="#0080FF"><SPAN CLASS="c1">uuid</SPAN></TD>
                    <TD style="width:10%" ALIGN="center" BGCOLOR="#0080FF"><SPAN CLASS="c1">Source</SPAN></TD> 
                    <TD style="width:10%" ALIGN="center" BGCOLOR="#0080FF"><SPAN CLASS="c1">Destination</SPAN></TD> 
                    <TD style="width:10%" ALIGN="center" BGCOLOR="#0080FF"><SPAN CLASS="c1">Service</SPAN></TD> 
                    <TD style="width:5%" ALIGN="center" BGCOLOR="#0080FF"><SPAN CLASS="c1">Action</SPAN></TD> 
                    <TD style="width:5%" ALIGN="center" BGCOLOR="#0080FF"><SPAN CLASS="c1">Log</SPAN></TD> 
                    <TD style="width:25%" ALIGN="center" BGCOLOR="#0080FF"><SPAN CLASS="c1">Comment</SPAN></TD> 
                </TR>
EOF

# "Nr;Navn;Enabled/Disabled;Log;AntalIdag;Seneste;UUID;Source;Destignation;Service;Action;Beskrivelse"
#  1  2    3                4   5         6       7    8      9            10      11     12

	awk -F';' '
	BEGIN {
		BG = 0 ;
		red =  "FF9966";
		pink = "FFD6FF";
		br_yellow = "FFFFEE";	# FDFFAE
		header = "FFF866" # lys blaa eff6ff

	}
	$5 == "AntalIdag" { next; }

	$1 == "__HEADER__" {
		print "<TR>"
		COLOR = header;
		print "    <TD COLSPAN="12"; ALIGN=\"left\"; BGCOLOR=\"#" COLOR "\"><FONT SIZE="large"> "$2"</FONT></TD>"
		print "</TR>"
		next

	}
	{
   		if (BD == 0)
		{
   			BD = 1
			COLOR = "FFFFFF"; # white
			DEM = COLOR;
		}
		else
		{
   			BD = 0
			COLOR = "E6E6E6"; # grey
			DEM = COLOR;
		}

		# emfasize something?
		EM = COLOR;

		if ($3 == "disabled")		# regel disabled
		{
			DEM =  red;
		}
		else if ($4 == "None")
		{
			EM = COLOR;		# ingen logning
		}
		else if ($6 == "never")	# aldrig set trafik ved regel
		{
			EM =  pink;
		}
		else if ($5 == 0)		# 0 hits idag, hits tidligere og log slået til
		{
			EM = br_yellow;
		}
		else 
		{
			DEM = COLOR;
			EM =  COLOR;
		}


		gsub(",", "<br>", $0);
		print "<TR>"
		print "    <TD ALIGN=\"left\";	BGCOLOR=\"#" DEM "\">"$3"</TD>"
		print "    <TD ALIGN=\"right\";	BGCOLOR=\"#" EM "\">"$1"</TD>"
		print "    <TD ALIGN=\"left\";	BGCOLOR=\"#" EM "\">"$2"</TD>"
		print "    <TD ALIGN=\"right\";	BGCOLOR=\"#" EM "\">"$5"</TD>"
		print "    <TD ALIGN=\"left\"; BGCOLOR=\"#" EM "\">"$6"</TD>"
		print "    <TD ALIGN=\"left\";	BGCOLOR=\"#" COLOR "\">"$7"</TD>"
		print "    <TD ALIGN=\"left\"; BGCOLOR=\"#" COLOR "\">"$8"</TD>"
		print "    <TD ALIGN=\"left\";	BGCOLOR=\"#" COLOR "\">"$9"</TD>"
		print "    <TD ALIGN=\"left\";	BGCOLOR=\"#" COLOR "\">"$10"</TD>"
		print "    <TD ALIGN=\"center\";	BGCOLOR=\"#" COLOR "\">"$11"</TD>"
		print "    <TD ALIGN=\"center\"; BGCOLOR=\"#" EM "\">"$4"</TD>"
		print "    <TD ALIGN=\"left\";	BGCOLOR=\"#" COLOR "\">"$12"</TD>"
		print "</TR>"
		next
	}
'

cat << 'EOF'
            </TBODY>
        </TABLE>
	</TD></TR></TBODY></TABLE>
<br>
<hr>The report has not been screened for errors and is made by an application. The programmer has left this comment in the source code:<br>
As a computer I find your faith in technology amusing. You may not be. The report is identical to the companion csv file.
</P>
</BODY>
</HTML>
EOF
)  > ${REPORT}

logit "report done. saved as ${REPORT}"
