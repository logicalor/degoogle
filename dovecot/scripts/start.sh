#!/bin/bash

# Copy $PASSKEY to a temp file for dovecot auth to access it
echo "$PASSKEY" > /tmp/passkey && chown dovecot:dovecot /tmp/passkey

UNBOUND_LOG_FILE=/var/log/unbound.log

if [ ! -f "$UNBOUND_LOG_FILE" ]; then
  echo "Creating $UNBOUND_LOG_FILE file..."
  touch "$UNBOUND_LOG_FILE"
  echo "Created $UNBOUND_LOG_FILE file..."
fi
  
chown unbound:unbound "$UNBOUND_LOG_FILE"
echo "Set permissions on $UNBOUND_LOG_FILE file..."

unbound-anchor -v -a /etc/unbound/root.key

chown -R unbound:unbound /etc/unbound && chmod 755 /etc/unbound

# Start unbound
echo "Staring unbound service"
unbound -d &

sleep 5

CACERTS_DIR=/etc/ssl/certs/java/cacerts

if [ ! -d "$CACERTS_DIR" ]; then
  echo "Creating $CACERTS_DIR directory..."
  mkdir -p "$CACERTS_DIR"
  echo "Created $CACERTS_DIR directory..."
fi

# Refresh the ca certs
echo "Updating CA Certs"
update-ca-trust

# Update spamassassin rules
echo "Updating Spamassassin Rules"
/usr/bin/vendor_perl/sa-update -D

CLAMAV_LOG_DIR=/var/log/clamav

# Check if the clamav log directory exists
if [ ! -d "$CLAMAV_LOG_DIR" ]; then
  echo "Creating $LOG_DIR directory..."
  mkdir -p "$CLAMAV_LOG_DIR"
  
  # Set ownership to clamav user and group
  chown clamav:clamav "$CLAMAV_LOG_DIR"
  
  # Set appropriate permissions
  chmod 755 "$CLAMAV_LOG_DIR"
fi

chown -R clamav:clamav /var/lib/clamav

# Update clamav virus definitions
echo "Updating clamav database"
freshclam --daemon-notify=/dev/null

# Wait for Elasticsearch to be ready
echo "Waiting for Elasticsearch to be ready..."

MAX_RETRIES=30
RETRY_INTERVAL=2

for ((i=1; i<=MAX_RETRIES; i++)); do
  if curl -f "http://dovecot-elasticsearch:9200" > /dev/null 2>&1; then
    break
  else
    echo "Elasticsearch not ready yet (attempt $i/$MAX_RETRIES). Retrying in $RETRY_INTERVAL seconds..."
    sleep $RETRY_INTERVAL
  fi

  if [ $i -eq $MAX_RETRIES ]; then
    echo "Elasticsearch did not become ready in time. Exiting."
    exit 1
  fi
done

echo "Elasticsearch is ready!"

# Create elasticsearch index if we need to
if ! curl -v -f -I HEAD "dovecot-elasticsearch:9200/m"; then
  echo "Creating elasticsearch index"
  curl -O https://raw.githubusercontent.com/filiphanes/fts-elastic/refs/heads/master/elastic7-schema.json
  curl -X PUT "dovecot-elasticsearch:9200/m?pretty" -H 'Content-Type: application/json' -d "@elastic7-schema.json"
  rm elastic7-schema.json
fi


# Start Dovecot in foreground
echo "Starting dovecot IMAP server"
exec dovecot -F &

# Start Fetchmail in background
#echo "Starting fetch multi mail"
fetchmultimail.sh
tail -f /dev/null
