#! /bin/bash

echo "Creating MongoDB user and password for ${MONGO_INITDB_DATABASE}: ${MONGO_USERNAME}."

mongo ${MONGO_INITDB_DATABASE} \
        --host localhost \
        --port 27017 \
        -u ${MONGO_INITDB_ROOT_USERNAME} \
        -p ${MONGO_INITDB_ROOT_PASSWORD} \
        --authenticationDatabase admin \
        --eval "db.createUser({user: '${MONGO_USERNAME}', pwd: '${MONGO_PASSWORD}', roles:[{role:'dbOwner', db: '${MONGO_INITDB_DATABASE}'}]});"
