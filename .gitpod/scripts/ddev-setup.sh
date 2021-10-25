#!/usr/bin/env bash
# Set up ddev for use on gitpod

set -eu -o pipefail

DDEV_DIR="${GITPOD_REPO_ROOT}/contenta/.ddev"
mkdir -p "$DDEV_DIR"

cat <<CONFIGEND > "${DDEV_DIR}"/config.yaml
#gitpod-generated
name: quickstart-druxt-site-contenta
type: drupal9
docroot: web
php_version: "7.4"
webserver_type: nginx-fpm
router_http_port: "80"
router_https_port: "443"
xdebug_enabled: false
additional_hostnames: []
additional_fqdns: []
mariadb_version: "10.3"
mysql_version: ""
use_dns_when_possible: true
composer_version: ""
web_environment: []
CONFIGEND

# Generate a config.gitpod.yaml that adds the gitpod
# proxied ports so they're known to ddev.
shortgpurl="${GITPOD_WORKSPACE_URL#'https://'}"

cat <<CONFIGEND > "${DDEV_DIR}"/config.gitpod.yaml
#ddev-gitpod-generated
php_version: "7.4"
bind_all_interfaces: true
host_webserver_port: 8080
# Will ignore the direct-bind https port, which will land on 2222
host_https_port: 2222
# Allows local db clients to run
host_db_port: 3306
# Assign MailHog port
host_mailhog_port: 8025
# Assign phpMyAdmin port
host_phpmyadmin_port: 8036
CONFIGEND

# We need host.docker.internal inside the container,
# So add it via docker-compose.host-docker-internal.yaml
hostip=$(awk "\$2 == \"$HOSTNAME\" { print \$1; }" /etc/hosts)

cat <<COMPOSEEND >"${DDEV_DIR}"/docker-compose.host-docker-internal.yaml
#ddev-gitpod-generated
version: "3.6"
services:
  web:
    environment:
      - DRUSH_OPTIONS_URI=$(gp url 8080)
    extra_hosts:
    - "host.docker.internal:${hostip}"
COMPOSEEND

# Misc housekeeping before start
ddev config global --instrumentation-opt-in=true --omit-containers=ddev-router

cd "$DDEV_DIR" && ddev start
