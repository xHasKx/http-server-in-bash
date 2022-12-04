#!/usr/bin/env bash

PORT="${1:-8888}"

NCPROG=nc
FINDPROG=find
STATPROG=stat
FILEPROG=file

RE='^GET /(\S*)'
ROOT="$(pwd)"

echo "Listening on port $PORT"

while true; do
	coproc NC { $NCPROG -l -p $PORT; }
	while IFS= read -r line <&"${NC[0]}" ; do
		line="$(echo "$line" | tr -d '\r' | tr -d '\n')"
		if [[ "$line" =~ $RE ]]; then
			FPATH="${BASH_REMATCH[1]}"
			FPATH="$(echo -e ${FPATH//%/\\x})"
			FPATH="$ROOT/$FPATH"
		elif [[ "$line" == "" ]]; then
			if [ -d "$FPATH" ]; then
				echo "GET (list dir) '$FPATH'"
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
				echo "GET (sendfile) '$FPATH'"
				SIZE=$($STATPROG -c %s "$FPATH")
				echo "HTTP/1.0 200 OK" >&"${NC[1]}"
				CT="$($FILEPROG -b -i "$FPATH")"
				echo "Content-Type: $CT" >&"${NC[1]}"
				echo "Content-Length: $SIZE" >&"${NC[1]}"
				echo "Connection: close" >&"${NC[1]}"
				echo "" >&"${NC[1]}"
				cat "$FPATH" >&"${NC[1]}"
				kill $NC_PID
			else
				echo "GET (notfound) '$FPATH'"
				echo "HTTP/1.0 404 Not Found" >&"${NC[1]}"
				echo "Content-Length: 0" >&"${NC[1]}"
				echo "Connection: close" >&"${NC[1]}"
				echo "" >&"${NC[1]}"
			fi
			FPATH=""
		fi
	done
done
