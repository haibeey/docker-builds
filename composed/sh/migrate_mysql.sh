#!/bin/bash

# Import data

MYSQL_HOST=mysql
MYSQL_PORT=3306

echo "wait for mysql to be ready"

while ! nc -q 1 ${MYSQL_HOST} ${MYSQL_PORT} </dev/null;
do
  echo "Waiting for database"
  sleep 10;
done

if [ ! -f /etc/migrations/.mysql_migrations_complete ]; then
	
	echo "Importing mysql data from backups"
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" -e "CREATE DATABASE IF NOT EXISTS  $MYSQL_OPENMRS_DATABASE /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" -e "CREATE DATABASE $MYSQL_OPENSRP_DATABASE /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" -e "CREATE DATABASE $MYSQL_MOTECH_DATABASE /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" -e "CREATE DATABASE $MYSQL_REPORTING_DATABASE /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" -e "CREATE DATABASE $MYSQL_ANM_DATABASE /*\!40100 DEFAULT CHARACTER SET utf8 */;"

	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" -e "CREATE USER '$MYSQL_OPENSRP_USER'@'%' IDENTIFIED BY '$MYSQL_OPENSRP_PASSWORD';"
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" -e "GRANT ALL ON \`$MYSQL_OPENMRS_DATABASE\`.* TO '$MYSQL_OPENMRS_USER'@'%' IDENTIFIED BY '$MYSQL_OPENMRS_PASSWORD';"
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" -e "GRANT ALL ON \`$MYSQL_OPENSRP_DATABASE\`.* TO '$MYSQL_OPENSRP_USER'@'%';"
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" -e "GRANT ALL ON \`$MYSQL_MOTECH_DATABASE\`.* TO '$MYSQL_OPENSRP_USER'@'%' ;"
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" -e "GRANT ALL ON \`$MYSQL_REPORTING_DATABASE\`.* TO '$MYSQL_OPENSRP_USER'@'%' ;"
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" -e "GRANT ALL ON \`$MYSQL_ANM_DATABASE\`.* TO '$MYSQL_OPENSRP_USER'@'%' ;"
	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" -e "FLUSH PRIVILEGES;"

	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" "$MYSQL_MOTECH_DATABASE" < "/opt/sql/tables_quartz_mysql.sql"
		
	if [[ -n $DEMO_DATA_TAG ]];then
		wget --quiet --no-cookies https://s3-eu-west-1.amazonaws.com/opensrp-stage/demo/${DEMO_DATA_TAG}/sql/openmrs.sql.gz -O /tmp/openmrs.sql.gz
		if [[ -f /tmp/openmrs.sql.gz ]]; then
			gunzip /tmp/openmrs.sql.gz
			mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" "$MYSQL_OPENMRS_DATABASE" < "/tmp/openmrs.sql"
		fi
	fi
	#import demo data if demo data tag was not passed it was possible to extract the demo data 		
	if [[ ! -f /tmp/openmrs.sql ]]; then
	 	mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" "$MYSQL_OPENMRS_DATABASE" < "/opt/sql/openmrs.sql"
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" "$MYSQL_OPENMRS_DATABASE" < "/opt/sql/locations.sql"
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" "$MYSQL_OPENMRS_DATABASE" < "/opt/sql/person_attribute_type.sql"
		mysql -u root -p"$MYSQL_ROOT_PASSWORD" -h "$MYSQL_HOST" "$MYSQL_OPENMRS_DATABASE" < "/opt/sql/openmrs_user_property_trigger.sql"

	fi
	echo "Do not remove!!!. This file is generated by Docker. Removing this file will reset mysql database" > /etc/migrations/.mysql_migrations_complete

	echo "Finished importing mysql data"

fi
