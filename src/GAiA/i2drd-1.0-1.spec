#
# Proto spec for i2drd
#
# $Header$
#

AutoReqProv: no

Requires: UNItools

%define defaultbuildroot /
# Do not try autogenerate prereq/conflicts/obsoletes and check files
%undefine __check_files
%undefine __find_prereq
%undefine __find_conflicts
%undefine __find_obsoletes
# Be sure buildpolicy set to do nothing
%define __spec_install_post %{nil}
# Something that need for rpm-4.1
%define _missing_doc_files_terminate_build 0

%define name    i2drd
%define version 1.0
%define release 1

Summary: Utility for check firewall firewall and nat rule
Name: %{name}
Version: %{version}
Release: %{release}
License: GPL
Group: root
Packager: Niels Thomas Haugaard, nth@i2.dk

%description
Check and visualize changes to firewall and NAT rules in for GaIA, R76 and R77*

# Everything is installed 'by hand' below i2drd_rootdir
%prep
ln -s /lan/ssi/shared/software/internal/i2drd/src/GAiA/i2drd_rootdir /tmp/i2drd_rootdir

%clean
rm /tmp/i2drd_rootdir

################################################################################

%pre
# Just before the upgrade/install
if [ "$1" = "1" ]; then
	echo "pre: Performing tasks to prepare for the initial installation ... "

	if [ -e /bin/clish ]; then
		echo "OS is GAiA ... good"
		CPOSVER=GAIA
	else
		echo "OS is Secure Platform ... ok"
		CPOSVER=SPLAT
	fi

	if [ -e /etc/init.d/drd ]; then
		echo "stopping existing drd ... "
		/etc/init.d/drd stop
		chkconfig --del drd
	fi
	if [ -e /etc/cron.d/i2drd ]; then
		echo "removing existing cron entry for i2drd ... "
		/bin/rm -f /etc/cron.d/drd
		/etc/init.d/crond restart >/dev/null 2>&1
	fi

elif [ "$1" = "2" ]; then
	echo "pre: Perform whatever maintenance must occur before the upgrade begins ... "
	NOW=`/bin/date +%Y-%m-%d`
	mkdir /var/tmp/${NOW}
	cp /var/opt/i2drd/etc/*					/var/tmp/${NOW}/
	cp /var/opt/i2drd/etc/.listen_ip.txt	/var/tmp/${NOW}/
	echo "Old config files saved in /var/tmp/${NOW}/"

	if [ -e /etc/init.d/drd ]; then
		echo "stopping existing i2drd ... "
		/etc/init.d/drd stop
	fi
	if [ -e /etc/cron.d/drd ]; then
		echo "removing existing cron entry for i2drd ... "
		/bin/rm -f /etc/cron.d/drd
		/etc/init.d/crond restart >/dev/null 2>&1
	fi
fi

# post install script -- just before %files
%post
# Just after the upgrade/install
if [ "$1" = "1" ]; then
	echo "post: Perform tasks for for the initial installation ... "
	/var/opt/i2drd/etc/drd setup
elif [ "$1" = "2" ]; then
	echo "post: Perform whatever maintenance must occur after the upgrade has ended ... "
	NOW=`/bin/date +%Y-%m-%d`
	/bin/mv /var/tmp/${NOW}/ /var/opt/i2drd/etc/${NOW}/
	for CFG in .listen_ip.txt first_data_seen_date
	do
		/bin/cp  /var/opt/i2drd/etc/${NOW}/${CFG} /var/opt/i2drd/etc/
	done
	echo "post: Please compare with the new ones"
	echo "post: updating config files ... "
	/var/opt/i2drd/etc/drd setup
	/etc/init.d/drd start
fi

# pre uninstall script
%preun
if [ "$1" = "1" ]; then
	# upgrade
	echo "pre uninstall: upgradeing ... "

elif [ "$1" = "0" ]; then
	# remove
	echo "pre uninstall: removing ... "

	if [ -e /etc/init.d/drd ]; then
		echo "stopping existing i2drd ... "
		/etc/init.d/drd stop
		chkconfig --del drd
		/bin/rm /etc/init.d/drd
	fi
	if [ -e /etc/cron.d/drd ]; then
		echo "removing existing cron entry for i2drd ... "
		/bin/rm -f /etc/cron.d/drd
		/etc/init.d/crond restart >/dev/null 2>&1
	fi
fi

# All files below here - special care regarding upgrade for the config files
%files
/var/opt/i2drd

# config files deliberately not added here. They will not be wiped upon un-installation
# as they are not part of the installation package
#%config /etc/cron.d/i2drd
#%config /var/opt/i2drd/etc/httpd2.conf
#%config /var/opt/i2drd/etc/.listen_ip.txt
