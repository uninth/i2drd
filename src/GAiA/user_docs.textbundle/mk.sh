:

# $1 = css
# $2 = md

test -f $1 || {
	ehho "css not found (first arg)"; exit 1
}

test -f $2 || {
	ehho "md file not found (second arg)"; exit 1
}

# markdown places TOC at the beginning of the text, while
# I'd like to have a cover first. This could be solved by
# placing the image in the here text below, but I don't 
# but I'd like to keep the md file(s) clean.
# So instead I'd add a marker in the md where I'd like the
# toc to be injected and create it with
#	markdown -T -f html -f toc -n UNIha.md
# It's an ugly hack.

cat << EOF
<!doctype html public "-//W3C//DTD HTML 4.0 Transitional //EN">
<html>
<head>
  <meta name="GENERATOR" content="mkd2html 2.1.8 DL=DISCOUNT">
  <meta http-equiv="Content-Type"
        content="text/html; charset=utf-8">  <link rel="stylesheet"
        type="text/css"
        href="$1" />
</head>
<body>
EOF

markdown -f html $2 | while read LINE
do
	case $LINE in
		"<!-- TOC-HERE -->")
			echo "<!-- TOC begin -->"
			markdown -n -T -f html -f toc $2
			echo "<!-- TOC end -->"
		;;
		*)	echo $LINE
		;;
	esac
done

cat << EOF
</body>
</html>
EOF
