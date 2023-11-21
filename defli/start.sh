#!/usr/bin/env bash
set -e

# Check if service has been disabled through the DISABLED_SERVICES environment variable.

if [[ ",$(echo -e "${DISABLED_SERVICES}" | tr -d '[:space:]')," = *",$BALENA_SERVICE_NAME,"* ]]; then
        echo "$BALENA_SERVICE_NAME is manually disabled."
        sleep infinity
fi

# Verify that all the required varibles are set before starting up the application.

echo "Verifying settings..."
echo " "
sleep 2

missing_variables=false
        
# Begin defining all the required configuration variables.

[ -z "$DEFLI_UUID" ] && echo "DeFli UUID is missing, will abort startup." && missing_variables=true || echo "DeFli UUID is set: $DEFLI_UUID"
[ -z "$LAT" ] && echo "Receiver latitude is missing, will abort startup." && missing_variables=true || echo "Receiver latitude is set: $LAT"
[ -z "$LON" ] && echo "Receiver longitude is missing, will abort startup." && missing_variables=true || echo "Receiver longitude is set: $LON"
[ -z "$ALT" ] && echo "Receiver altitude is missing, will abort startup." && missing_variables=true || echo "Receiver altitude is set: $ALT"
[ -z "$RECEIVER_HOST" ] && echo "Receiver host is missing, will abort startup." && missing_variables=true || echo "Receiver host is set: $RECEIVER_HOST"
[ -z "$RECEIVER_PORT" ] && echo "Receiver port is missing, will abort startup." && missing_variables=true || echo "Receiver port is set: $RECEIVER_PORT"

# End defining all the required configuration variables.

echo " "

if [ "$missing_variables" = true ]
then
        echo "Settings missing, aborting..."
        echo " "
        sleep infinity
fi

echo "Settings verified, proceeding with startup."
echo " "

# Variables are verified – continue with startup procedure.

# Create UUID file
echo "$DEFLI_UUID" > /run/defli-feed/uuid

# Start readsb and put in the background.
/usr/bin/feed-defli --net --net-only --debug=n --quiet --net-connector feed.defli.org,31090,beast_reduce_plus_out,feed.defli.org,39000 --net-connector feed.defli.org,64006,beast_reduce_plus_out,feed.defli.org,39001 --write-json /run/defli-feed --uuid-file /run/defli-feed/uuid --net-beast-reduce-interval 0.5 --net-heartbeat 60 --net-ro-size 1280 --net-ro-interval 0.2 --net-ro-port 0 --net-sbs-port 0 --net-bi-port 30154 --net-bo-port 0 --net-ri-port 0 --net-connector "$RECEIVER_HOST","$RECEIVER_PORT",beast_in --lat "$LAT" --lon "$LON" 2>&1 | stdbuf -o0 sed --unbuffered '/^$/d' |  awk -W interactive '{print "[readsb-defli]     " $0}' &
/usr/local/share/defli/venv/bin/mlat-client --input-type dump1090 --no-udp --input-connect "$RECEIVER_HOST":"$RECEIVER_PORT" --server feed.defli.org:31090 --user "$DEFLI_UUID" --lat "$LAT" --lon "$LON" --alt "$ALT" --results beast,connect,"$RECEIVER_HOST":30104 --results beast,listen,39000 2>&1 | stdbuf -o0 sed --unbuffered '/^$/d' | awk -W interactive '{print "[mlat-client1]    "  $0}' &
/usr/local/share/defli/venv/bin/mlat-client --input-type dump1090 --no-udp --input-connect "$RECEIVER_HOST":"$RECEIVER_PORT" --server feed.defli.org:64006 --user "$DEFLI_UUID" --lat "$LAT" --lon "$LON" --alt "$ALT" --results beast,connect,"$RECEIVER_HOST":30104 --results beast,listen,39001 2>&1 | stdbuf -o0 sed --unbuffered '/^$/d' | awk -W interactive '{print "[mlat-client2]    "  $0}' &

# Wait for any services to exit.
wait -n
