#! /bin/bash

# ENABLE LOGS
# Script to enable logs in a mysql container.

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

# Establishing permissions.
docker exec ${container} bash -c "chmod -R 777 /var/log/mysql"
if [ $? != "0" ]; then  
  return $?
fi

# Enter to docker mysql.
docker exec -i ${container} mysql -uroot -p${password} <<< "SET global log_output='FILE'; SET global general_log = 'ON'; SET slow_query_log = 'ON'; SET global general_log_file = '/var/log/mysql/general.log'; SET global slow_query_log_file = '/var/log/mysql/slow.log';"
if [ $? != "0" ]; then  
  return $?
fi

# Leaving.
echo "Logs for ${container} enabled."
return 0
