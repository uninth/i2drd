
[![Documentation][logo]][documentation]
[logo]: src/GAiA/user_docs.textbundle/coverpage.png
[documentation]: src/GAiA/user_docs.textbundle/i2drd.pdf

# i2drd - detecting Dead Rules in Check Point firewall rule bases

**i2drd** is a simple system aiming to detect unused rules in a Check Point
firewall rule base.       
This version is compatible with GAiA and has been tested on R77.10, R77.20
and R77.30, and should work with all later R77.x versions.      
It may work with other versions: the rule base format and the log file format
is detected and the required information available from R65 and onwards, but
the web server configuration requires R77.

## Deployment

The package **UNItools** and **UNIfw1lr** are prerequisite to i2drd: the first
provides tools while the later exports the logfile.        
Using **i2drd** may require a valid support contract with [Check Point
Technologies](http://www.checkpoint.com).       

**i2drd** is installed as an [rpm package](http://en.wikipedia.org/wiki/RPM_Package_Manager)
the installation and configuration is described in ``INSTALL.md``.

The system consist of the following components:

  - A Web-server: the system uses the [apache web server](https://en.wikipedia.org/wiki/Apache_HTTP_Server)
    supplied and maintained by Check Point, as part of the base operating system
  - A collection of applications for parsing the _rule base_, extracting information from the _exported logfile_ etc.

Access to the web-server is controlled by the firewall. The server runs on **TCP
port 8088**. This may be changed in ``/var/opt/i2drd/etc/drd`` but is not
recommended.

Log files are exported on a daily basis at midnight as configured in **UNIfw1lr**.

Processing the rule base and log file in order to detect unused rules starts at 13:59. This may change in the future.

All rules has a unique _UUID_ which is logged. **i2drd** reads the log file and the rule base and counts the number
of hits for each UUID. The result is written to a database and includes the last time a rule had a hit.

The date and time of the first time **i2drd** runs is recorded.

##  Development

This is a traditional made application: use make to build new versions. Everything is written in perl/bash/sed/awk etc.

## License

Everything I've made is released under a
[modified BSD License](https://opensource.org/licenses/BSD-3-Clause).

