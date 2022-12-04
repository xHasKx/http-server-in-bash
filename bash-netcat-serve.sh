#!/usr/bin/env bash

PORT="${1:-8888}"

NCPROG=nc
FINDPROG=find
STATPROG=stat
FILEPROG=file

RE='^(GET|HEAD) /(\S*)'
ROOT="$(pwd)"

echo "Listening on port $PORT"

while true; do
	coproc NC { $NCPROG -l -k -p $PORT; }
	while IFS= read -r line <&"${NC[0]}" ; do
		line="$(echo "$line" | tr -d '\r' | tr -d '\n')"
		if [[ -z $METHOD && "$line" =~ $RE ]]; then
			METHOD="${BASH_REMATCH[1]}"
			FPATH="${BASH_REMATCH[2]}"
			FPATH="$(echo -e ${FPATH//%/\\x})"
			FPATH="$ROOT/$FPATH"
		elif [[ "$line" == "" ]]; then
			if [ -d "$FPATH" ]; then
				echo "$METHOD (list dir) '$FPATH'"
				FILES=""
				if [[ $FPATH != "$ROOT/" ]]; then
					FILES="$FILES<li><a href=\"..\">[ .. ]</a></li>"
				fi
				while IFS= read -r fn; do
					if [[ $fn == "" ]]; then
						continue
					fi
					FILES="$FILES<li><a href=\"$fn/\">[ $fn / ]</a></li>"
				done <<< "$(cd "$FPATH"; $FINDPROG -maxdepth 1 -mindepth 1 -type d)"
				while IFS= read -r fn; do
					if [[ $fn == "" ]]; then
						continue
					fi
					FILES="$FILES<li><a href=\"$fn\">$fn</a></li>"
				done <<< "$(cd "$FPATH"; $FINDPROG -maxdepth 1 -mindepth 1 -type f)"
				LIST="<h1>${FPATH#$ROOT}</h1><ul>$FILES</ul>"
				LEN=$(echo "$LIST" | wc -c)
				echo "HTTP/1.0 200 OK" >&"${NC[1]}"
				echo "Content-Type: text/html; charset=utf-8" >&"${NC[1]}"
				echo "Content-Length: $LEN" >&"${NC[1]}"
				echo "Connection: close" >&"${NC[1]}"
				echo "" >&"${NC[1]}"
				echo "$LIST" >&"${NC[1]}"
			elif [ -f "$FPATH" ]; then
				echo "$METHOD (sendfile) '$FPATH'"
				SIZE=$($STATPROG -c %s "$FPATH")
				echo "HTTP/1.0 200 OK" >&"${NC[1]}"
				case "$FPATH" in # for modern browsers to work
					*.css)		CT="text/css"								;;
					*.js)		CT="text/javascript"						;;
					*)			CT="$($FILEPROG -b --mime-type "$FPATH")"	;;
				esac
				echo "Content-Type: $CT" >&"${NC[1]}"
				if [[ $METHOD == "GET" ]]; then
					echo "Content-Length: $SIZE" >&"${NC[1]}"
				fi
				echo "Connection: close" >&"${NC[1]}"
				echo "" >&"${NC[1]}"
				if [[ $METHOD == "GET" ]]; then
					cat "$FPATH" >&"${NC[1]}"
				fi
			else
				echo "$METHOD (notfound) '$FPATH'"
				echo "HTTP/1.0 404 Not Found" >&"${NC[1]}"
				echo "Content-Length: 0" >&"${NC[1]}"
				echo "Connection: close" >&"${NC[1]}"
				echo "" >&"${NC[1]}"
			fi
			FPATH=""
			METHOD=""
		fi
	done
done
