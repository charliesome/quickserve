# directory listing http server
# one liner ;)

port=8080

fifo=`mktemp /tmp/XXXXXX`
tmp=`mktemp /tmp/XXXXXX`

rm -f "$fifo"
mkfifo "$fifo"

echo "Listening on $port" >&2

trap 'echo -e "\rGoodbye."; rm -f "$fifo"; rm -f "$tmp"; exit' 2

while true; do
    nc -l -p "$port" < "$fifo" |
        head -n 1 |
        cut -d' ' -f2 | (
            read uri
            echo "[$(date)] $uri" >&2
            if [ -d "$uri" ]; then
                echo "<h2>Directory listing for $uri</h2>" > $tmp
                echo "<ul>" >> $tmp
                ls "$uri" | sed -e "s!\(.*\)!<li><a href='$uri\1'>\1</a></li>!" >> $tmp
                echo "</ul>" >> $tmp
                echo "HTTP/1.1 200 OK"
                echo "Connection: close"
                echo "Content-Type: text/html"
                echo "Content-Length: $(stat $tmp | cut -d' ' -f8)"
                echo
                cat $tmp
            else
                mime="$(file --mime-type "$uri" | sed -e 's/^.*: \(.*\)/\1/')"
                echo "HTTP/1.1 200 OK"
                echo "Connection: close"
                echo "Content-Type: $mime"
                echo "Content-Length: $(stat "$uri" | cut -d' ' -f8)"
                echo
                cat "$uri"
            fi
        ) > "$fifo"
done
