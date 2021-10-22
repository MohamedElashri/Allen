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

# remove all lines but the first one from commit message, docker does not like multiple lines in environment variables
sed -i '/^CI_COMMIT_MESSAGE/,/^DOCKER_PORT/{/^CI_COMMIT_MESSAGE/!{/^DOCKER_PORT/!d}}' $ENV_FILE 
sed -i '/^DOCKER_ENV_CI_COMMIT_MESSAGE/,/^DOCKER_ENV_GIT_SUBMODULE_STRATEGY/{/^DOCKER_ENV_CI_COMMIT_MESSAGE/!{/^DOCKER_ENV_GIT_SUBMODULE_STRATEGY/!d}}' $ENV_FILE

sed -i '/^DOCKER_ENV_CI_COMMIT_DESCRIPTION/,/^DOCKER_ENV_GITLAB_USER_NAME/{/^DOCKER_ENV_CI_COMMIT_DESCRIPTION/!{/^DOCKER_ENV_GITLAB_USER_NAME/!d}}' $ENV_FILE 
sed -i '/^CI_COMMIT_DESCRIPTION/,/^MATTERMOST_KEY/{/^CI_COMMIT_DESCRIPTION/!{/^MATTERMOST_KEY/!d}}' $ENV_FILE 


cat $ENV_FILE
