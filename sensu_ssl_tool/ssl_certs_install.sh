echo "Install RabbitMQ SSL Certs"
mkdir -p ../rmq/files/ssl/
cp sensu_ca/cacert.pem ../rmq/files/ssl/
cp server/cert.pem ../rmq/files/ssl/
cp server/key.pem ../rmq/files/ssl/

echo "Install Sensu Server SSL Certs"
mkdir -p ../sensu-server/files/ssl/ ../sensu-api/files/ssl/ ../sensu-client/files/ssl/
cp client/cert.pem ../sensu-server/files/ssl/
cp client/key.pem ../sensu-server/files/ssl/

echo "Install Sensu API SSL Certs"
cp client/cert.pem ../sensu-api/files/ssl/
cp client/key.pem ../sensu-api/files/ssl/

echo "Install Sensu Client SSL Certs"
cp client/cert.pem ../sensu-client/files/ssl/
cp client/key.pem ../sensu-client/files/ssl/

