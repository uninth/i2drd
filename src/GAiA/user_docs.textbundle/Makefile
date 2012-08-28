#
# Makefile for i2drd documentation -- exec on office.ssi.i2.dk
#
rev = "$Revision: 1.2 $"

css	=	assets/CSS/GitHub-ReadMe.css
css	=	assets/CSS/i2-Book.css

wkhtmltopdf = wkhtmltopdf
pdfunite	= pdfunite

VERSION = `sed '/^VERSION.*=/!d; s/.*=//; s/[ ]*//' ../Makefile`
RELEASE = `sed '/^RELEASE.*=/!d; s/.*=//; s/[ ]*//' ../Makefile`
NAME	= `sed '/^NAME.*=/!d; s/.*=//; s/[ ]*//' ../Makefile`
INST_HTML   = INSTALL-$(NAME)-$(VERSION)-$(RELEASE).html

#
# wkhtmltopdf cannot be ported to rhes3 (RHES3) but is installed on office.ssi.i2.dk, so the
# documentation should be made there
#
all: coverpage.pdf i2drd-body.pdf i2drd.pdf i2drd.html

i2drd.pdf: coverpage.pdf i2drd-body.pdf
	$(pdfunite) coverpage.pdf i2drd-body.pdf i2drd.pdf

i2drd.html: i2drd.md Makefile
	@./mk.sh $(css) i2drd.md > i2drd.html

i2drd-body.pdf: i2drd.md i2drd.html
	$(wkhtmltopdf) toc i2drd.html --footer-line --enable-internal-links --footer-spacing 2 --footer-right 'page [page] of [topage]'  i2drd-body.pdf

