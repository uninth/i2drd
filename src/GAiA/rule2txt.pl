#!/var/opt/UNItools/bin/perl
#
# Copyright (c) 2016 Niels Thomas Haugård. All Rights Reserved.
#
# perl rule2txt.pl -f $FWDIR/conf/rulebases_5_0.fws -r ${RULEBASE} | iconv  -f latin1 -t utf-8

# rule2txt printer IKKE den sidste HEADER, hvis der ikke følger regler under!
#
#

#
# Requirements
#
use English;
use FileHandle;
use Getopt::Long;
use Digest::MD5;
use sigtrap qw(die normal-signals);

# use Text::Iconv;
# my  $converter = Text::Iconv->new("latin1", "utf-8");
# ikke installeret

my $usage = "$0 -f rulebases_fws -r security_rulebase\n";

################################################################################
# MAIN
################################################################################
#
# Parse and process options
#
if (!GetOptions('rulebases_fws|f=s'		=> \$rulebases_fws,
				'rulebase|r=s'	=> \$rulebase
	)) {
	die "$usage";
}

#
# Check arguments
#
foreach ($rulebases_fws, $rulebase) {
	die "! $usage" if (! defined ($_) );
}

# my $rulebases_fws = "../conf/rulebases_5_0.fws";
# my	$rulebase		= "HNGMN";

open(RB, $rulebases_fws) || die "open $rulebases_fws failed: $!";

my	$rule_nr	= 0;
my	$rule_name		= "";
my	$rule_uid		= "";

my	$rule_src		= "";
my	$rule_dst		= "";
my	$rule_service		= "";

my	$header_text		= "";

my	$tmp_rule_uid	= "";
my	$type			= "";
my	$rule_name			= "";
my	$rule_status	= "";
my	$comments		= "";
my	$disabled		= "";

my	$in_rulebase	= 0;
my	$in_a_rule		= 0;
my	$in_a_security_rule = 0;
my	$in_a_dst = 0;
my	$in_a_src = 0;
my	$in_a_services = 0;
my	$in_a_install = 0;

my	$tmp_track	= 0;

# Rækkefølge
# rule-base
# :rule
# :chkpf_uid ("{6B978E71-7633-4BEE-892D-09D76E5D87F1}")
# :ClassName (security_rule)
# :type (reject) || :type (accept) || :type (drop)
# :name (080-0030)
# :track --> :Name(Log) :Name(None)
# :comments ("Al anden trafik til og fra Gatekeeper;forbydes (Stealth regel)")
# :disabled (false) || :disabled (true)
# :dst ... :Name (fw)
# :services ( ... :Name (FW1.Admin
# :src ( ... :Name (G_SSI.FW1-Admins
# :through (
# 	her kan printes


# print "Antal;Seneste;Regel nr;Regel navn;UUID;Type;enabled/disabled;Log;Beskrivelse\n";

while (<RB>)
{
	chomp($_);	# remove newline

	# Match the specific rulebase
	if ($_ =~ m/:rule-base.*##${rulebase}/)
	{
		$in_rulebase = 1;
		next;
	}

	if ($_ =~ /:rule-base.*##/)
	{
		$in_rulebase = 0;
		next;
	}

	# rulebase found
	if ($in_rulebase)
	{
		if ($_ =~ /:header_text \(/)
		{
			$_ =~  s/.*"(.*)".*/\1/;
			$header_text = $_;
			$in_a_dst = 0;
			$in_a_src = 0;
			$in_a_services = 0;

			$rule_src = ""; $rule_dst = ""; $rule_service = "";	# bliver sat i header_txt til Any

			# $_ og printer den kun, hvis headeren følger 
			next ;

		}

		if ($_ =~ /:rule \(/)
		{
			$in_a_rule = 1;
			$rule_src = ""; $rule_dst = ""; $rule_service = "";	# Fjern alt - ny regel
			if ($header_text)
			{
				print "__HEADER__;$header_text\n";
				$header_text = "";
			}
			next;
		}

		if ($_ =~ /:ClassName \(security_header_rule\)/)
		{
			# header "rule" - no rules here
			$in_a_rule = 0;
		}



		if ($_ =~ /:chkpf_uid/)
		{
			$_ =~  s/.*"(.*)".*//;
			$tmp_rule_uid = $1;
		}

		if ($_ =~ /ClassName/)
		{
			if ($_ =~ /ClassName .security_rule.$/)
			{
				$rule_uid = $tmp_rule_uid;
				$in_a_security_rule = 1;
				$rule_nr +=1 ;
			}
		}
	
		if ($_ =~ /:type/)
		{
			if ($in_a_security_rule)
			{
				$_ =~ s/:type //;
				$_ =~ s/^\t*//;
				$_ =~ tr/;"()//d;
				$type = $_;
			}
		}

		if ($_ =~ /:disabled/)
		{
			if ($in_a_security_rule)
			{
				$_ =~ s/:disabled //;
				$_ =~ s/^\t*//;
				$_ =~ tr/;"()//d;
				if ($_ eq "true")
				{
					$disabled = "disabled";

				}
				else
				{
					$disabled = "enabled";
				}
			}
		}

		if ($_ =~ /:dst/)
		{
			if ($in_a_rule == 1)
			{
				$in_a_dst = 1;
				$in_a_src = 0;
				$in_a_services = 0;
				next;
			}
		}

		if ($_ =~ /:install \(/)
		{
				$in_a_dst = 0;
				$in_a_src = 0;
				$in_a_services = 0;
				next;
		}

		if ($_ =~ /:Name / && $in_a_dst == 1)
		{
			$_ =~ s/:Name//; $_ =~ s/^\t*//; $_ =~ s/^ *//; $_ =~ tr/;"()//d;
			$rule_dst = $rule_dst . "," . $_;
			next;
		}

		if ($_ =~ /:services/)
		{
			if ($in_a_rule == 1)
			{
				$in_a_dst = 0;
				$in_a_src = 0;
				$in_a_services = 1;
				next;
			}
		}

		if ($_ =~ /:Name / && $in_a_services == 1)
		{
			$_ =~ s/:Name//; $_ =~ s/^\t*//; $_ =~ s/^ *//; $_ =~ tr/;"()//d;
			$rule_service = $rule_service . ", " . $_;
			$in_a_services = 0;
			next;
		}


		if ($_ =~ /:src/)
		{
			$in_a_dst = 0;
			$in_a_services = 0;
			$in_a_src = 1;
			next;
		}

		if ($_ =~ /:Name / && $in_a_src == 1)
		{
			$_ =~ s/:Name//; $_ =~ s/^\t*//; $_ =~ s/^ *//; $_ =~ tr/;"()//d;
			$rule_src = $rule_src . ", " . $_;

			$in_a_src = 0;
			next;
		}

# HERTIL #

		if ($_ =~ /:comments/)
		{
			if ($in_a_security_rule)
			{
				$_ =~ s/:comments //;
				$_ =~ s/^\t*//;
				$_ =~ tr/;"()//d;
				$comments = $_ ? $_ : "Beskrivelse mangler";
			}
		}

		if ($_ =~ /:Name/)
		{
			# this may/may not be the log track -we'll find out later
			$_ =~ s/:Name//;
			$_ =~ s/^\t*//;
			$_ =~ s/^ *//;
			$_ =~ tr/;"()//d;
			$tmp_track = $_;
		}

		if ($_ =~ /:Table \(tracks\)/)
		{
			$track = $tmp_track;
		}

		if ($_ =~ /:name/)
		{
			if ($in_a_security_rule)
			{
				$_ =~ s/:name//;
				$_ =~ s/^\t*//;
				$_ =~ tr/;"()//d;
				$rule_name = $_;
			}
		}

		if($_ =~ /:through/)
		# print hvis alle oplysningerne er der -- så er vi nær slutningen
		{
			if ($in_a_security_rule == 1)
			{
				if ($rule_nr != 0)
				{
					# Fjern lige foerste komma ', asdasdf' fra src, dst og service
					$rule_src =~ s/^,\s*//;
					$rule_dst =~ s/^,\s*//;
					$rule_service =~ s/^,\s*//;

					# $rule_nr
					# $rule_status
					# _ANTAL_
					# _SENESTE_
					# $rule_name
					# $rule_uid
					# $rule_src
					# $rule_dst
					# $rule_vpn
					# $rule_service
					# $type
					# track
					# installon
					# time
					# comments
					print "$rule_nr;$rule_name;$disabled;$track;_ANTAL_;_SENESTE_;$rule_uid;$rule_src;$rule_dst;$rule_service;$type;$comments\n";

					#print "_ANTAL_;_SENESTE_;$rule_nr;$rule_name;$rule_uid;$type;$disabled;$log;$comments\n";

					$rule_uid = $comments = "";
					$rule_dst = "";
					$rule_src = "";
					$rule_service = "";
				}
				$in_a_security_rule = 0;
			}
		}
	}
}

close(RB) ;
