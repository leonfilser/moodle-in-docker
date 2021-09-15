#!/bin/bash

set -e

chown -R ${AP2USER} ${DATADIR}


#Creates the config.php required by moodle, if it not already exists
if [ ! -f ${DIR}/config.php ]; then

	echo "Could not detect Moodle. Installing ${VERSION}"

	git clone --progress -b $VERSION git://git.moodle.org/moodle.git $DIR \
	&& chown -R ${AP2USER} ${DIR}

	php ${DIR}/admin/cli/install.php \
	--non-interactive \
	--agree-license \
	--skip-database \
	--dataroot=/var/www/moodledata \
	--lang="${MOODLELANG}" \
	--wwwroot="${WWWROOT}" \
	--dbtype="${DBTYPE}" \
	--dbhost="${DBHOST}" \
	--dbname="${DBNAME}" \
	--dbuser="${DBUSER}" \
	--dbpass="${DBPASS}" \
	--fullname="${FULLNAME}" \
	--shortname="${SHORTNAME}" \
	--adminpass="${ADMINPASS}" \
	--adminemail="${ADMINMAIL}" \
	|| true

	if [ ${USESSL} = true ]; then

		sed -i '25a $CFG->sslproxy = true;' ${DIR}/config.php

	fi

	chown -R ${AP2USER} ${DIR}/config.php


	#Creates the moodle database
	php ${DIR}/admin/cli/install_database.php \
	--agree-license \
	--lang="${MOODLELANG}" \
	--adminpass="${ADMINPASS}" \
	--adminemail="${ADMINMAIL}" \
	--fullname="${FULLNAME}" \
	--shortname="${SHORTNAME}" \
	--agree-license \
	|| true


elif [ -f ${DIR}/config.php ]; then

	cd ${DIR}
#	git pull
	current_branch="$(git rev-parse --abbrev-ref HEAD)"

	if [ ${current_branch} != ${VERSION} ]; then

		echo "${current_branch} detected. Upgrading to ${VERSION}"
		git branch --track ${VERSION} origin/${VERSION}
		git checkout ${VERSION}
		chown -R ${AP2USER} ${DIR}
	else
		echo "The current Branch is up to date"
	fi

else

	echo "Unknown Error. Please open an issue on GitHub"

fi


echo -e "SHELL=/bin/bash \nPATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \n* * * * * php /var/www/moodle/admin/cli/cron.php >> /var/log/cron.log 2>&1" | crontab
service cron start


apachectl -D FOREGROUND
