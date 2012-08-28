
# Installation procedure for __TARGET__

    Package name: __TARGET__
    Version     : __VERSION__
    Release     : __RELEASE__

## Prerequisite
The package requires the packages **UNItools** as perl is needed, and **UNIfw1lr** to export the log files.

## Installation
1. Copy ``__TARGET__`` to the management station (firewall), and install the package:

		cd /lan/ssi/shared/software/internal/RPM
        td -x __TARGET__ ... 
        td ... 
        rpm -Uvh /var/tmp/__TARGET__

1. If this is an _upgrade_, the following has to be done:

   * Check the server is running with ``/etc/init.d/drd stat``        
     Errors may be found in ``/var/log/httpd2_error_log``

1. If this is a _first time installation_ then the package has to be configured. You will
   have to add the name of the **rule base** and the **ip address** the server must run on.

   * The default **ip address** is ``127.0.0.1``, change it in ``/var/opt/UNIfw1doc/etc/httpd2.conf``

   * The **rule base name** has to be added to ``/var/opt/i2drd/db/rulebasename``              
     Only one name is allowed (only one rule base is processed in version __VERSION__.__RELEASE__).          
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

## Uninstallation

Remove the package with:

	rpm -e --nodeps __NAME__

**A warning**: this document is in RCS, written in markdown and build with ``make``. Original author: Niels Thomas Haugård

## RPM info

You may view rpm content with

	rpm -q __NAME__

