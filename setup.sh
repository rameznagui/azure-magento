#!/bin/sh

# set these parameters before doing anything else!
APP_SKU=S1
DB_USER=app
DB_PASS=Pa55W0rd!
DB_SKU=B_Gen5_1
GIT_REPO=https://github.com/cawilliamson/azure-magento.git # HTTPS Repo URL
LOCATION=uksouth # azure location
NAME=magentoecs # site name
PHP_VER=7.0 # PHP version

# check for github token
if [ -z "${GIT_TOKEN}" ]; then
  echo
  echo "Please set an environment variable of GIT_TOKEN with your GitHub token to proceed."
  echo "For example: export GIT_TOKEN=123456"
  echo
  exit 1
fi

# check for resource group
if [ -z "${RES_GRP}" ]; then
  echo
  echo "Please set an environment variable of RES_GRP with your desired resource group."
  echo "For example: export RES_GRP=sandpit-123"
  echo
  exit 1
fi

###
### BEGIN - macos specific
###

# install homebrew
echo "install homebrew (if needed)"
brew --version >/dev/null || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
echo

# install azure-cli
echo "install azure-cli (if needed)"
az --version >/dev/null || brew install azure-cli
echo

###
### END - macos specific
###

# login to azure
echo "logging in to azure"
az login
echo

# create resource group
echo "create resource group"
az group create --name ${RES_GRP} --location ${LOCATION}
echo

# create app service plan
echo "create app service plan"
az appservice plan create --name "${NAME}sp" --resource-group ${RES_GRP} --sku ${APP_SKU} --is-linux
echo

# create mysql server
echo "create mysql server"
az mysql server create --name "${NAME}sql" --resource-group ${RES_GRP} --admin-user ${DB_USER} \
  --admin-pass ${DB_PASS} --sku-name ${DB_SKU} --location ${LOCATION} --ssl-enforcement Disabled
echo

# create mysql firewall rule
echo "create mysql firewall rule"
az mysql server firewall-rule create --server "${NAME}sql" --resource-group ${RES_GRP} \
  --name "${NAME}fw" --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255
echo

# create mysql database
echo "create mysql database"
az mysql db create --server-name "${NAME}sql" --resource-group ${RES_GRP} --name "${NAME}db"
echo

# create webapp
echo "create webapp"
az webapp create --name ${NAME} --plan "${NAME}sp" --resource-group ${RES_GRP} \
  --runtime "php|${PHP_VER}"
echo

# setup continuous deployments
echo "setup continuous deployments (takes around 20mins)"
az webapp deployment source config --name ${NAME} --resource-group ${RES_GRP} \
  --repo-url ${GIT_REPO} --branch master --git-token ${GIT_TOKEN}
echo