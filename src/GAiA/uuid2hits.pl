#!/var/opt/UNItools/bin/perl -w
#
# Copyright (c) 2016 Niels Thomas Haugård. All Rights Reserved.
#
#
# 0) open pre-parsing && calculate field for uuid, time ...
# 1) find uuid field in line 1 (or 2)
# 2) count occurences of all different uuid 
# 3) print out uuid;hitstoday;latesthit

use strict;
use warnings;
use English;
use Fcntl;
use File::Temp qw(tempfile);
use File::Copy;
use POSIX;

# info from logfile
my @arr;
my $arr;
my %count;
my %last_hit;
my $rule_uid;

# saved info from db
my @db_arr;
my $db_uuid;
my $db_count;
my $db_last_hit;

my $fh;
my $tf;
my $i;
my $pos = 0;
my $maxl = 10;

my $uuid_db = $ARGV[0];
my $logfile = $ARGV[1];

sub logit(@)
{
	my $msg = join(' ', @_);
	my $now = strftime "%H:%M:%S (%m/%d)", localtime(time);

	print "$now $msg\n";
}

################################################################################
# Main
################################################################################

if ($#ARGV != 1) {
	die "\nUsage: $0 uuid.db logfile.txt\n";
}

my $uuid_db_tmp;
my $template = "/var/opt/i2drd/db/uuid.db-logfile-tmp.XXXXXX";

# find position for rule_uid in logfile
open ($fh, '<', $logfile) || die "open failed: '$logfile' $!";
while (<$fh>) {
	chomp $_;
	if ($INPUT_LINE_NUMBER >= $maxl)
	{
		die "max line number exceeded and no header found\n";
	}

	@arr = (split /;/, $_);
	if ($#arr != 0)
	{
		if( $arr[0] eq "num" && $arr[1] eq "date" && $arr[2] eq "time")
		{
			for ($i = 0; $i <= $#arr; $i++)
			{
				if ($arr[$i] eq "rule_uid")
				{
					$pos = $i;
				}
			}
			last;
		}
	}
	else
	{
		next;
	}
}
close($fh);

logit "found rule_uid in logfile at position $pos (feeling lucky)";

# num;date;time; ...
logit "reading $logfile ... ";
open ($fh, '<', $logfile ) || die "open failed: '$logfile' $!";
logit "Skippping past short lines, lines with no fields (export output) etc etc, and ignoring control lines";
logit "Also ignoring lines where rule_uuid doesn't match a rule_uid regex";

while (<$fh>) {
	chomp $_;
	next if ! (/.*;.*/);	
	@arr = (split /;/, $_);

	next if( $arr[0] eq "num" && $arr[1] eq "date" && $arr[2] eq "time");	# header line
	next if( $arr[4] eq "control");						# control line
	next if( ! $arr[$pos] );						# short line (implied rule?
	next if( $arr[$pos] !~ /^{.*-.*}$/);					# not a valid uuid in pos $pos

	if ($#arr != 0)	# split ok
	{
		$count{$arr[$pos]}++;					# count rule_uid's
		$last_hit{$arr[$pos]} = $arr[1] . " " . $arr[2];	# last hit on this time
	}
	else
	{
		logit "line $. ignored:'$_'";
		next;
	}
}
close($fh);

open ($tf, '>', $uuid_db) || die "open failed: '$uuid_db_tmp' $!";

logit "Rule UUID                             	hits	last seen";
foreach $arr (sort keys %count)
{
	printf $tf "%s;%s;%s\n", $arr, $count{$arr}, $last_hit{$arr};
	logit "$arr	$count{$arr}	$last_hit{$arr}";
}

close($tf);

# rest not needed as we no longer UPDATE the db

exit 0;

__DATA__


#logit "found the following rule_uuid:";
#logit "Rule UUID                             	hits	last seen";
#foreach $arr (sort keys %count)
#{
#	logit "$arr	$count{$arr}	$last_hit{$arr}";
#}

logit "updating '$uuid_db' while preserving unchanged entries ... ";
($tf, $uuid_db_tmp) = tempfile( $template, SUFFIX => ".db", UNLINK => 0);

open ($tf, '>', $uuid_db_tmp) || die "open failed: '$uuid_db_tmp' $!";

open($fh, '<', $uuid_db) || die "open failed: '$uuid_db' $!";
$i = 0;

foreach $arr (sort keys %count)
{
	while(<$fh>)
	{
		chomp;
		$db_arr[$i++] = $_;
		($db_uuid, $db_count, $db_last_hit) = (split /;/, $_);
		if ($arr eq $db_uuid)
		{
			 # Replace number of hits and the last seen date/time in db with the one from the logfile
			 $count{$arr}		= $db_count;
			 $last_hit{$arr}	= $db_last_hit;
		}
	}
	printf $tf "%s;%s;%s\n", $arr, $count{$arr}, $last_hit{$arr};
	seek $fh, 0, 0;
}

close($fh);

#my $found = 0;
#while(<$fh>)
#{
#	$found = 0;		# TODO: fix hvis den ikke findes! 
#	chomp;
#	$db_arr[$i++] = $_;
#	($db_uuid, $db_count, $db_last_hit) = (split /;/, $_);
#	foreach $arr (sort keys %count)
#	{
#		if ($arr eq $db_uuid)
#		{
#			 # Replace number of hits and the last seen date/time in db with the one from the logfile
#			 $db_count	= $count{$arr};
#			 $db_last_hit	= $last_hit{$arr};
#		}
#	}
#	printf "DEBUG: %s;%s;%s\n", $db_uuid, $db_count, $db_last_hit;
#	printf $tf "%s;%s;%s\n", $db_uuid, $db_count, $db_last_hit;
#}
#
#close($fh);

close($tf);

move("$uuid_db_tmp","$uuid_db");
logit "renamed $uuid_db_tmp to $uuid_db";

exit 0;


__DATA__
