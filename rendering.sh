#!/bin/bash

RM="/bin/rm"
MV="/bin/mv"
GS="/usr/bin/gs"
PDFINFO="/usr/bin/pdfinfo"
PDFTOTEXT="/usr/bin/pdftotext"
RENDERING="/app/rendering/counter.ps"

while getopts i: options; do
   case ${options} in
      i) PDF=${OPTARG} ;;
   esac
done

if ! [ -f $PDF ] || ! [ -v PDF ] ; then
    echo "-i: Specifies the input PDF file."
    exit 0
fi

BOOKMARKS=$(mktemp)

render () {
    local temporary=$(mktemp)

    if [ ! -s $BOOKMARKS ] ; then
        echo "$BOOKMARKS does not exist."
        unset BOOKMARKS
    fi

    echo "Start rendering $1 to ${temporary}."

    $GS -o $temporary -dCompatibilityLevel=1.6 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sDEVICE=pdfwrite $BOOKMARKS $RENDERING -f $1

    if [ -s $temporary ] ; then
        $MV $temporary $1
    fi
}

pages=$($PDFINFO "$PDF" | sed -nre 's/^Pages: +([0-9]+)$/\1/p')
for ((i=1; i <= $pages; i++)) ; do
    $PDFTOTEXT -f $i -l $i -layout "$PDF" - | while read -r line; do
        if [[ $line =~ ^([0-9]+\.?)+\.[[:space:]] ]] ; then
            echo "[/Page $i /View [/XYZ null null null] /Title ($line) /OUT pdfmark" >> $BOOKMARKS
        fi
    done
done

render $PDF

echo "Process complete to $PDF."
exit 0;
