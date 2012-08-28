
$Header: /lan/ssi/shared/software/internal/i2drd/src/GaIA/INSTALL.md,v 1.3 2016/06/21 11:17:39 root Exp $

# Installation procedure for i2drd-1.0-1.i386.rpm

    Package name: i2drd-1.0-1.i386.rpm
    Version     : 1.0
    Release     : 1

## Prerequisite
The package requires the packages **UNItools** as perl is needed, and **UNIfw1lr** to export the log files.

## Installation
1. Copy ``i2drd-1.0-1.i386.rpm`` to the management station (firewall), and install the package:

		cd /lan/ssi/shared/software/internal/RPM
        td -x i2drd-1.0-1.i386.rpm ... 
        td ... 
        rpm -Uvh /var/tmp/i2drd-1.0-1.i386.rpm

1. If this is an _upgrade_, the following has to be done:

   * Check the server is running with ``/etc/init.d/drd stat``        
     Errors may be found in ``/var/log/httpd2_error_log``

1. If this is a _first time installation_ then the package has to be configured. You will
   have to add the name of the **rule base** and the **ip address** the server must run on.

   * The default **ip address** is ``127.0.0.1``, change it in ``/var/opt/UNIfw1doc/etc/httpd2.conf``

   * The **rule base name** has to be added to ``/var/opt/i2drd/db/rulebasename``              
     Only one name is allowed (only one rule base is processed in version 1.0.1).          
	 If the output from           

	     fw stat | awk '$1 == "localhost" { print $2 }'                  

	 is not null, then execute             

	     fw stat | awk '$1 == "localhost" { print $2 }' > /var/opt/i2drd/db/rulebasename      

   * Check everything with the command

         /var/opt/i2drd/etc/drd setup

   * Restart the web-server with

         /etc/init.d/drd restart

1.  Generate a report with the command

        /var/opt/i2drd/bin/runme.sh -v

    Watch for errors.       
	The port **8088** must be open in the firewall for the administrative addresses. Open the URL ``https://a.b.c.d:8088``
	(where a.b.c.d is the address the server is listening on) and check everything looks good.

	Notice that the certificate is the one used by the firewall (usually a self signed certificate).

Uninstallation
==============
Remove the package with:

	rpm -e --nodeps i2drd

**A warning**: this document is in RCS, written in markdown and build with ``make``. Original author: Niels Thomas Haugård

RPM info
========
You may view rpm content with

	rpm -q i2drd

