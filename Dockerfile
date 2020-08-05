FROM jboss/keycloak:11.0.0

# Install AWS CLI v2
WORKDIR /tmp
USER root
RUN microdnf update -y && microdnf install -y unzip && microdnf clean all
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip &&  ./aws/install && rm -r awscliv2.zip aws

# Install AWS cert
RUN mkdir p /opt/jboss/.postgresql && curl "https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem" -o "/opt/jboss/.postgresql/root.crt"

# Install jq
RUN curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o jq && chmod +x ./jq && cp jq /usr/bin

USER jboss

COPY --chown=jboss:root tools /opt/jboss/tools

ENTRYPOINT ["/bin/bash", "/opt/jboss/tools/aws-entrypoint.sh"]

CMD []