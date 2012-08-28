#
# Makefile for i2drd
#

VERSION		= 1.0
RELEASE		= 1

COMPILEHOST	= fedora6
HOSTNAME	= `hostname`

TARGETDIR	= /lan/ssi/shared/software/internal/i2drd
WORKDIR		= $(TARGETDIR)/src/GAiA

ROOTDIR		= $(WORKDIR)/i2drd_rootdir
GROUP		= root
NAME		= i2drd

ARCH		= i386
REDHAT		= /usr/src/redhat
BUILDDIR	= $(REDHAT)/RPMS/$(ARCH)/
SPFILE		= i2drd-$(VERSION)-$(RELEASE).spec
SPTEMPLATE	= i2drd.spec.template
SPECFILE	= $(REDHAT)/SPECS/$(SPFILE)
RPMBR		= /tmp/i2drd_rootdir

TARGET		= $(NAME)-$(VERSION)-$(RELEASE).$(ARCH).rpm
INSTALL		= INSTALL-$(NAME)-$(VERSION)-$(RELEASE).md
INST_HTML   = INSTALL-$(NAME)-$(VERSION)-$(RELEASE).html

RPMDIR		= ../../RPM

BR			= i2drd_rootdir
PREFIX		= $(BR)/var/opt/i2drd
DIRS		= $(BR)/etc/cron.d $(PREFIX)/log $(PREFIX)/tmp $(PREFIX)/db $(PREFIX)/bin $(PREFIX)/etc $(PREFIX)/docs $(PREFIX)/data/html/assets/CSS

binfiles	= csv2html.sh rule2txt.pl runme.sh uuid2hits.pl
etcfiles	= drd htmlhead.txt httpd2.conf.tmpl version.SH

files		= $(binfiles) $(etcfiles)

all: $(TARGET)
	@echo "RPM: $(RPMDIR)/$(TARGET)"
	@echo "rpm content: rpm -lpq $(NAME)-$(VERSION)-$(RELEASE).$(ARCH).rpm"
	@echo "rpm install: rpm -Uvh $(NAME)-$(VERSION)-$(RELEASE).$(ARCH).rpm"
	@echo "made $@"

$(TARGET): $(INSTALL) $(SPECFILE) Makefile $(files) 
	$(MAKE) setup
	$(MAKE) user_docs
	@rpmbuild -bb --buildroot=$(RPMBR) $(SPFILE)
	@mv $(BUILDDIR)/$(NAME)-$(VERSION)-$(RELEASE).$(ARCH).rpm .
	@/bin/rm -f $(TARGETDIR)/$(TARGET) $(TARGETDIR)/$(INSTALL)
	@/bin/rm -f $(RPMDIR)/$(TARGET) $(RPMDIR)/$(INSTALL)
	mv $(INSTALL) $(RPMDIR)/
	mv $(TARGET) $(RPMDIR)/

setup: $(files) $(INSTALL)
	@mkdir -p $(DIRS)
	@chmod 0755 `find $(BR) -type d`
	@install -g root -o root -m 766 $(etcfiles)     $(PREFIX)/etc/
	@install -g root -o root -m 555 $(binfiles)     $(PREFIX)/bin/
	@install -g root -o root -m 555 $(INSTALL)     $(PREFIX)/docs/
	@echo "made $@"

$(INSTALL): INSTALL.md
	@sed "									\
		s/__VERSION__/$(VERSION)/g;			\
		s/__RELEASE__/$(RELEASE)/g;			\
		s%__TARGET__%$(TARGET)%g;			\
		s%__NAME__%$(NAME)%g;			\
		" < INSTALL.md > $(INSTALL)

$(INST_HTML): $(INSTALL)
	mkd2html -css /volatile/software/i2drd/i2drd.textbundle/assets/CSS/i2-Book.css $(INSTALL)

version.SH:
	@echo "version=$(VERSION)" > version.SH
	@echo "release=$(RELEASE)" >> version.SH
	@echo "made $@"

# user_docs: $(SPECFILE) $(INSTALL) $(INST_HTML)
user_docs: $(SPECFILE) $(INSTALL)
	cd user_docs.textbundle && mkd2html -css assets/CSS/i2-Book.css i2drd.md
	install -g root -o root -m 644  user_docs.textbundle/assets/CSS/i2-Book.css	$(PREFIX)/data/html/assets/CSS
	install -g root -o root -m 644  user_docs.textbundle/user_docs.html			$(PREFIX)/data/html/i2drd.html
	install -g root -o root -m 644  user_docs.textbundle/i2drd.pdf				$(PREFIX)/data/html/i2drd.pdf

check:
	@if [ $(HOSTNAME) == $(COMPILEHOST) ];	then echo compile host ok; else echo not compile host; exit 1; fi
	@if [ -d $(WORKDIR) ]; then echo wokdir ok; else echo workdir not found; exit 1; fi
	@echo $@ done

$(SPECFILE): check 
	@sed "									\
		s/__VERSION__/$(VERSION)/g;			\
		s/__RELEASE__/$(RELEASE)/g;			\
		s%__ROOTDIR__%$(ROOTDIR)%g;			\
		" < $(SPTEMPLATE)  > $(SPFILE)
	@echo $@ done
	

