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

[ -z "$WINGBITS_DEVICE_ID" ] && echo "Wingbits Device ID is missing, will abort startup." && missing_variables=true || echo "Wingbits Device ID is set: $WINGBITS_DEVICE_ID"
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

# Configure Wingbits/Vector according to environment variables.
 echo "DEVICE_ID=\"${WINGBITS_DEVICE_ID}\"" >> /etc/default/vector

# Start vector and readsb and put in the background.
/usr/bin/feed-adsbx --net --net-only --debug=n --quiet --net-connector localhost,30006,json_out 2>&1 | stdbuf -o0 sed --unbuffered '/^$/d' |  awk -W interactive '{print "[feed-readsb]     " $0}' &
/usr/bin/vector --watch-config &

# Wait for any services to exit.
wait -n
