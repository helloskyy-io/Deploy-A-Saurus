#!/bin/bash

echo "🚀 Starting Uptime Kuma Passive Monitor..." | tee -a /tmp/uptime-monitor.log

while true; do
    echo "🕒 Checking connectivity to main container at $(date)" | tee -a /tmp/uptime-monitor.log
    
    MAIN_CONTAINER_IP="127.0.0.1"  # This will work inside the Pod
    MAX_RETRIES=3
    SUCCESS=false
    
    if [ "$UPTIME_KUMA_WEBSERVER" = "true" ]; then
        for i in $(seq 1 $MAX_RETRIES); do
            HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://$MAIN_CONTAINER_IP:$UPTIME_KUMA_WEBSERVER_PORT)
            if [[ "$HTTP_RESPONSE" -eq 200 ]]; then
                SUCCESS=true
                echo "✅ HTTP check successful. Service is responding on port $UPTIME_KUMA_WEBSERVER_PORT." | tee -a /tmp/uptime-monitor.log
                break
            else
                echo "⚠️ HTTP check failed (attempt $i/$MAX_RETRIES) [Status: $HTTP_RESPONSE]" | tee -a /tmp/uptime-monitor.log
                sleep 5
            fi
        done
    else
        for i in $(seq 1 $MAX_RETRIES); do
            if ping -c 1 $MAIN_CONTAINER_IP &> /dev/null; then
                SUCCESS=true
                echo "✅ Ping check successful. Main container is reachable." | tee -a /tmp/uptime-monitor.log
                break
            else
                echo "⚠️ Ping check failed (attempt $i/$MAX_RETRIES)" | tee -a /tmp/uptime-monitor.log
                sleep 5
            fi
        done
    fi
    
    if [ "$SUCCESS" = true ] && [ "$UPTIME_KUMA_PING" = "true" ]; then
        echo "✅ Main container is responsive. Sending Uptime Kuma heartbeat..." | tee -a /tmp/uptime-monitor.log
        for i in $(seq 1 $MAX_RETRIES); do
            RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$UPTIME_KUMA_URL")
            if [[ "$RESPONSE" -eq 200 ]]; then
                echo "✅ Heartbeat sent at $(date) [Status: $RESPONSE]" | tee -a /tmp/uptime-monitor.log
                break
            else
                echo "❌ Failed to send heartbeat (attempt $i/$MAX_RETRIES) [Status: $RESPONSE]" | tee -a /tmp/uptime-monitor.log
                sleep 5
            fi
        done
    else
        echo "❌ Main container is unreachable after $MAX_RETRIES attempts. Skipping Uptime Kuma ping." | tee -a /tmp/uptime-monitor.log
    fi
    
    sleep 60
done
