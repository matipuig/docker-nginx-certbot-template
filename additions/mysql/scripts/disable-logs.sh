#! /bin/bash

# DISABLE LOGS
# Script to disable logs in a mysql container.

# Kill process if needed.
trap "exit" INT TERM
trap "kill 0" EXIT

# Get container and password.
echo "Please, insert the mysql container you want to use:"
read container
if [ -z $container ]; then
  return 0
fi
echo "Please, insert the root user password:"
read -s password
if [ -z $password ]; then
  return 0
fi

# Enter to docker mysql.
docker exec -i ${container} mysql -uroot -p${password} <<< "SET global log_output='NONE'; SET global general_log = 'OFF'; SET slow_query_log = 'OFF';;"
if [ $? != "0" ]; then  
  return $?
fi

# Leaving.
echo "Logs for ${container} disabled."
return 0
