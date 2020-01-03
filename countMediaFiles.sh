#!/bin/bash
#######################################################################################################################
#
# 	Count number of video, audio and photo files on a synology running DSM
#
#######################################################################################################################
#
#    Copyright (C) 2020 framp at linux-tips-and-tricks dot de
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#######################################################################################################################

VERSION="0.1.1"
me=$(basename $0)

# music
M_EXTENSION_DEFAULTS="mp3"
# photo
P_EXTENSION_DEFAULTS="jpg png jpeg tiff gif"
# video
V_EXTENSION_DEFAULTS="mpeg m2t wmv avi mp4 mov flv"
# volume
VOLUME_DEFAULT="/volume1"

declare -A TYPES=( [P]=photos [V]=videos [M]=music )

function help() {
	cat <<END
Scan Synology for and count number of music-, photo- and video files

$me [-h] [-d] [-o "VOLUME"]  [-m "MUSIC_EXTENSION_LIST"] [-p "PHOTO_EXTENSION_LIST"] [-v "VIDEO_EXTENSION_LIST"]

-d: Debug mode

Example:
$me -o "/volume1" -p "jpg jpeg" -v "mp4 avi" -m "mp3"

Defaults:
-o: $VOLUME_DEFAULT
-m: $M_EXTENSION_DEFAULTS
-p: $P_EXTENSION_DEFAULTS
-v: $V_EXTENSION_DEFAULTS

END
}

DEBUG=0

while getopts "dh?o:m:p:v:" opt; do
    case "$opt" in
    h|\?)
        help
        exit 0
        ;;
    d)  DEBUG=1
        ;;
    o)  VOLUME=$OPTARG
        ;;
    p)  P_EXTENSIONS=$OPTARG
        ;;
    v)  V_EXTENSIONS=$OPTARG
        ;;
    m)  M_EXTENSIONS=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

VOLUME="${VOLUME:-"$VOLUME_DEFAULT"}"
MOMENTS_DIR="$VOLUME/homes/*/Drive/Moments"

# photo
P_EXTENSIONS="${P_EXTENSIONS:-"$P_EXTENSION_DEFAULTS"}"
P_DIRECTORIES="$VOLUME/photo $MOMENTS_DIR" # directories to search for files
# video
V_EXTENSIONS="${V_EXTENSIONS:-"$V_EXTENSION_DEFAULTS"}"
V_DIRECTORIES="$VOLUME/video $MOMENTS_DIR" # directories to search for files
# music
M_EXTENSIONS="${M_EXTENSIONS:-"$M_EXTENSION_DEFAULTS"}"
M_DIRECTORIES="$VOLUME/music $MOMENTS_DIR" # directories to search for files

for prfx in "${!TYPES[@]}"; do

	desc="${TYPES[$prfx]}"

	e="${prfx}_EXTENSIONS"
	EXTENSIONS=${!e}
	d="${prfx}_DIRECTORIES"
	DIRECTORIES=${!d}

	echo "Scanning for $desc files with extensions $EXTENSIONS..."

	EXT_PARM=""
	set -f
	for ext in $EXTENSIONS; do
		if [[ -z "$EXT_PARM" ]]; then
			EXT_PARM="-iname *.$ext"
		else
			EXT_PARM="$EXT_PARM -o -iname *.$ext"
		fi
	done
	set +f

	SUM=0
	for dir in $DIRECTORIES; do
		(( $DEBUG )) && echo ">>> Counting number of files for $desc in $dir ..."
		(( $DEBUG )) && echo ">>> find $dir \( $EXT_PARM \) | grep -v eaDir | wc -l"
		p=$(find $dir \( $EXT_PARM \) | grep -v eaDir | wc -l)
		if (( $? )); then
			echo "??? Error executing find in $dir"
			continue
		fi
		(( $DEBUG )) && echo ">>> Found $p $desc files"
		SUM=$(( $SUM + $p ))
	done

	(( $SUM > 0 )) && echo "Found $SUM $desc files"
done
