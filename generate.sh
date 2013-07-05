#!/bin/bash

WORK=$PWD/work
SVG_HEADER=$WORK/header.svg
SVG_FOOTER=$WORK/footer.svg
## $MAX_VERT
# This is the maximum number of vertices each new
#+ polygon will use.
MAX_VERT=10
## $MIN_VERT
# Likewise, this is the minimum number of vertices.
MIN_VERT=3
## $BASE_SVG
# This is the current file as determined by the best 
#+ image in each iteration.  As the program goes on, 
#+ $BASE_SVG will be updated to match what the 
#+ current image looks like.  Each subsequent image
#+ that gets created will use this as its base.
BASE_SVG=$WORK/base.svg
## $TARGET
# This is the image that the program will strive to
#+ recreate.
TARGET=
## $THREADS
# This is the number of threads that will be executed.
THREADS=${THREADS:-1}

## init
#` init targetimg
# Saves the image to recreate as $TARGET, and generates
#+ the header and footer for each SVG file.
function init() {
    local targetimg
    targetimg=$1
    TARGET=${targetimg:?Must supply an image to recreate}
    mkdir -p $WORK
    cat > $SVG_HEADER <<EOF
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg viewBox="0 0 $WIDTH $HEIGHT" version="1.1">
EOF
    cat > $SVG_FOOTER <<EOF
</svg>
EOF
}

## rand
#` rand min max
# Generates a random number between min and max. If min
#+ equals max, then it simply returns 0.
function rand() {
    local min max
    min=$1
    max=$2
    if [[ $min == $max ]]; then
	echo 0
    else
	echo $((($RANDOM % ($max-$min)) + $min))
    fi
}

## rand-hex
#` rand-hex {no-args}
# Returns a random hexadecimal number between 0 and 255.
#+ Useful for generating random colors (and, in fact, 
#+ what this program uses it for).
function rand-hex() {
    printf "%02x" $(rand 0 255)
}

## polygon
#` polygon {no-args}
# Returns an appropriate SVG line for a polygon with a 
#+ random number of vertices between $MIN_VERT and
#+ $MAX_VERT with a randomly chosen color. The opacity
#+ is set to 0.5.
function polygon() {
    local numpoints points i color IFS
    points=( )
    numpoints=$(rand $MIN_VERT $MAX_VERT)
    color=$(rand-hex)$(rand-hex)$(rand-hex)
    for((i=0; i<$numpoints; i++)); do
	points+=( $(rand 0 $WIDTH),$(rand 0 $HEIGHT) )
    done
    IFS=' '
    echo "<polygon points=\"$points\" style=\"fill:#$color;opacity:0.5\" />"
}

## delete-last-line
#` delete-last-line file
# Simply deletes the last line in the file. If this
#+ function is called several times at once, then it
#+ may corrupt the file.
function delete-last-line() {
    local file
    file="$1"
    sed "$file" -i -e '$ d'
}

function create-svg() {
    local file
    file=$1
    convert svg: $file
}

## text-to-pixel-data
#` text-to-pixel-data
# Uses stdin as input, formatted from the 
#` convert file txt:
#+ command and outputs a hexadecimal string of
#+ characters for that pixels location. This outputs
#+ as one long list, where each row directly follows
#+ the next.
function text-to-pixel-data() {
    sed -e 's/.*#//; s/ .*//'
}

function svg-to-text() {
    convert svg: txt:
}

## get-differences-as-text
#` get-differences-as-text {no-args}
# Takes an SVG file as input through stdin and 
#+ generates the difference between the it and the
#+ target image as text.
function get-differences-as-text() {
    convert svg: $TARGET -compose difference -composite -colorspace Gray txt:
}

## calculate-score
#` calculate-score
# Takes the inside part of an SVG file (no header
#+ or footer) and calculates the score for it.
#+ The score should be an integer, although it
#+ may be very large.
function calcscore() {
    cat $SVG_HEADER - $SVG_FOOTER \
	| get-differences-as-text \
	| text-to-pixel-data \
	| ./scorecalc
}

function generate-one-image() {
    :
}

function generate-and-update-best() {
    local i
    for ((i=0; i<$THREADS; i++)); do
	spawn-thread gen-images generate-one-image $WORK/image-$i.svg
    done
    join-pool gen-images
}

function main {
    while true; do
	generate-and-update-best
    done
}

init "$@"
main "$@"
