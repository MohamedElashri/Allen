#!/bin/bash
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################



ENV_FILE=ci.env

env > $ENV_FILE
L=$(grep -n "^-----END CERTIFICATE-----" $ENV_FILE | tail -n1 | cut -f1 -d':')

sed -i "$L s/^-----END CERTIFICATE-----/-----END CERTIFICATE-----\"/" $ENV_FILE

sed -i 's/^DOCKER_ENV_CI_SERVER_TLS_CA_FILE=/DOCKER_ENV_CI_SERVER_TLS_CA_FILE="/' $ENV_FILE
sed -i "s/^-----END CERTIFICATE-----/-----END_CERTIFICATE-----\"/g" $ENV_FILE
sed -i "s/^-----BEGIN CERTIFICATE-----/-----BEGIN_CERTIFICATE-----\"/g" $ENV_FILE



cat $ENV_FILE
