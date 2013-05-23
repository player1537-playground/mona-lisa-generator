#!/bin/bash

SVGFILE=out.svg
POLY=poly.svg
TOP=top.svg
BOTTOM=bottom.svg
MAX_VERT=10
MIN_VERT=3
IFS=' '
INFILE="$1"

if [ -z "$INFILE" ]; then
    echo "supply a picture"
    exit
fi
TARGET=${INFILE%.*}.txt
WIDTH=$(identify -format '%w' $INFILE)
HEIGHT=$(identify -format '%h' $INFILE)
LASTCOLOR=
COLORS=()

function init() {
    >$POLY
    >$SVGFILE
    >$TOP
    >$BOTTOM
}

function pecho() {
    echo "$@" >> $SVGFILE
}

function polyecho() {
    local file
    file=${1:-$POLY}
    shift
    echo "$@" >> $file
}

function rand() {
    local min max
    min=$1
    max=$2
    if [ $min = $max ]; then
	echo 0
    else
	echo $((($RANDOM % ($max-$min)) + $min))
    fi
}

function hex() {
    printf "%02x" $(rand 0 255)
}

function polygon() {
    local file numpoints points i color temp len
    file=${1:-$POLY}
    points=""
    numpoints=$(rand $MIN_VERT $MAX_VERT)
    len=${#COLORS}
    temp=$(rand 0 $((${len:-0} * 2)))
    if [ "${#COLORS}" = 0 -o "$temp" -gt "${#COLORS}" ]; then
	color=$(hex)$(hex)$(hex)
	LASTCOLOR=$color
    else
	color=${COLORS[$temp]}
    fi
    for((i=0; i<$numpoints; i++)); do
	points+="$(rand 0 $WIDTH),$(rand 0 $HEIGHT) "
    done
    points="${points% }"
    polyecho $file "<polygon points=\"$points\" style=\"fill:#$color;opacity:0.5\" />"
}

function dellast() {
    local file
    file="$1"
    sed "$file" -i -e '$ d'
}

function createsvg() {
    convert svg: ${SVGFILE%.*}.png
}

function calcscore() {
    local file
    file=${1:-$POLY}
    cat $TOP $file $BOTTOM > $SVGFILE
    convert $SVGFILE ${SVGFILE%.*}.png
    ./pic-to-txt.sh ${SVGFILE%.*}.png | paste $TARGET - | sed '1d; $ d; s/[ \t][A-Z0-9]\{4\}/ /' > file.tmp
    ./scorecalc <file.tmp
}

init
cat > $TOP <<EOF
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg viewBox="0 0 $WIDTH $HEIGHT" version="1.1">
EOF
cat > $BOTTOM <<EOF
</svg>
EOF
polygon
score=$(calcscore)
oldscore=$score
i=0
while true; do
    echo -n "Iteration $i "
    if [ $oldscore -gt $score ]; then
	# Worse, remove old
	echo -n "Got worse $((score - oldscore))"
	dellast $POLY
	LASTCOLOR=
    else 
	COLORS+=($LASTCOLOR)
    fi
    for pic in $(seq 1 $MAXPIC); do
	cp $POLY $pic$POLY
	polygon $pic$POLY
	if [ $(rand 0 50) -lt 5 ]; then
	    sed $pic$POLY -i -e "$(rand 1 $(wc -l <$POLY)) d"
	fi
	if [ $(rand 0 50) -lt 5 ]; then
	    randpic=$(rand 1 $MAXPIC)
	    cat $pic$POLY $randpic$POLY | sort | uniq | shuf | head -n $(wc -l <$pic$POLY)
	fi
    done
    echo -n "{ ${COLORS[@]} }"
    export oldscore=$score
    export score=$(calcscore)
    export i=$((i+1))
    echo
done

