#!/bin/bash
# Deploy script for applications based on composer.


# Store where this script is stored, no matter where you invoke it from:
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# and load the configuration:
source $SCRIPTPATH/deploy.cfg

TODAY=$(date "+%Y-%b-%d")
ORIGINAL_PATH=$PWD
DEPLOY_LOG="$DEPLOY_LOGS_DIR/$TODAY.log"

# REQUISITES CHECKING
# -------------------
command -v $DEPENDENCY_BIN >/dev/null 2>&1 || { echo >&2 "Command '$DEPENDENCY_BIN' is not installed. Failed miserably :_("; exit 1; }

# Create all dirs
mkdir -p "$APP_DIR"
mkdir -p "$RELEASES_DIR"
mkdir -p "$RELEASES_SKELETON_DIR"
mkdir -p "$DEPLOY_LOGS_DIR"

# First-time only. Clone the whole thing and composer update.
if [ ! -d $RELEASES_SKELETON_DIR/.git ]; then
	git clone $GIT_REPO $RELEASES_SKELETON_DIR
	cd $RELEASES_SKELETON_DIR
	$DEPENDENCY_BIN install	
fi

# DEPLOYMENT START
# ----------------


# CURRENT APP STATUS
cd $APP_DIR
APP_BRANCH=$(git branch | awk '/^\*/ { print $2 }')
# REMOTE STATUS
APP_BASE_DIR_REMOTE_REV=`git ls-remote origin $APP_BRANCH | sed 's/\([0-9a-f]\{10\}\)\(.*\)/\1/g' | head -n 1`
APP_BASE_DIR_LOCAL_REV=`git rev-parse refs/heads/$APP_BRANCH | sed 's/\([0-9a-f]\{10\}\)\(.*\)/\1/g'`

# INTERACTIVE SHELL
echo "Author name? <$USER>:"
read AUTHOR
echo "Branch? <$APP_BRANCH>:"
read BRANCH
echo "Revision? <$APP_BASE_DIR_REMOTE_REV>:"
read REVISION

if [ "$BRANCH" == "" ] ; then
	BRANCH=$APP_BRANCH
fi
if [ "$AUTHOR" == "" ] ; then
	AUTHOR=$USER
fi
if [ "$REVISION" == "" ] ; then
	REVISION=$APP_BASE_DIR_REMOTE_REV
fi

RELEASE="$RELEASES_DIR/$REVISION"

# If release doesn't exist yet, prepare it:
if [ ! -d $RELEASE ] ; then
	
	cd $RELEASES_SKELETON_DIR 2>&1 | tee -a $DEPLOY_LOG
	# Skeleton should be always clean, but anyway let's assure.
	git reset --hard 2>&1 | tee -a $DEPLOY_LOG
	git checkout master 2>&1 | tee -a $DEPLOY_LOG
	git pull origin $APP_BRANCH 2>&1 | tee -a $DEPLOY_LOG
	$DEPENDENCY_BIN $DEPENDENCY_BIN_ARGS 2>&1 | tee -a $DEPLOY_LOG
	git checkout $BRANCH 2>&1 | tee -a $DEPLOY_LOG
	git checkout $REVISION 2>&1 | tee -a $DEPLOY_LOG

	# Prepara new release
	cp -R $RELEASES_SKELETON_DIR $RELEASE
	chmod -R 777 $RELEASE/instances/*/templates/_smarty/
	# Haurien d'estar fora del APP_DIR:
	mkdir -p $RELEASE/logs
	chmod -R 777 $RELEASE/logs
fi

# Deploy it
rm $APP_DIR && ln -s $RELEASE $APP_DIR

# Execute post-deployment actions
source $SCRIPTPATH/post-deploy.sh
	
cd $ORIGINAL_PATH
