#!/bin/bash
set -e

# AWS RDS credentials
export DB_VENDOR=postgres
export DB_REGION="${DB_REGION:-us-east-1}"
export DB_PORT="${DB_PORT:-5432}"
if [ "x$DB_PASSWORD" = "x" ]; then
    export DB_PASSWORD="$(aws rds generate-db-auth-token --hostname $DB_ADDR --port $DB_PORT --region $DB_REGION --username $DB_USER)"
fi
export JDBC_PARAMS="sslmode=verify-ca"

# default admin account from Secrets Manager
if [ "$KEYCLOAK_ADMIN_USER_SECRET" ]; then
    SECRET=$(aws secretsmanager get-secret-value --secret-id $KEYCLOAK_ADMIN_USER_SECRET --query 'SecretString' --region $DB_REGION --output text)
    echo $SECRET
    export KEYCLOAK_USER=$(echo $SECRET | jq .username -r)
    export KEYCLOAK_PASSWORD=$(echo $SECRET | jq .password -r)
fi

if [ "x$KEYCLOAK_FRONTEND_URL" = "x" ]; then
    export KEYCLOAK_FRONTEND_URL="https://${KEYCLOAK_HOSTNAME}/auth"
fi

# clustering
export JGROUPS_DISCOVERY_PROTOCOL=JDBC_PING
# to be able to communicate via JGroups in EC2 Dockerized environment
# (e.g. ElasticBeanstalk, we need the hostname from the running instance, see
# also JDBC_PING.cli, we do this via the EC2 meta-data service, available in
# every EC2 instance)
export EC2_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
export SYS_PROPS=" -Djboss.node.name=$EC2_HOSTNAME"

export PROXY_ADDRESS_FORWARDING=true

exec /opt/jboss/tools/docker-entrypoint.sh $SYS_PROPS $@
exit $?
