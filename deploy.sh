#!/bin/bash
# Deploy script for applications based on composer.


# Store where this script is stored, no matter where you invoke it from:
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# and load the configuration:
source $SCRIPTPATH/deploy.cfg

TODAY=$(date "+%Y-%b-%d")
ORIGINAL_PATH=$PWD
DEPLOY_LOG="$DEPLOY_LOGS_DIR/$TODAY.log"

echo "Deploy started on $TODAY..." | tee -a $DEPLOY_LOG	
echo "Checking requisites..." | tee -a $DEPLOY_LOG	
# REQUISITES CHECKING
# -------------------
command -v $DEPENDENCY_BIN >/dev/null 2>&1 || { echo >&2 "Command '$DEPENDENCY_BIN' is not installed. Failed miserably :_(" | tee -a $DEPLOY_LOG; exit 1; }

# Create all dirs
mkdir -p "$APP_DIR"
mkdir -p "$RELEASES_DIR"
mkdir -p "$RELEASES_SKELETON_DIR"
mkdir -p "$DEPLOY_LOGS_DIR"

# First-time only. Clone the whole thing and composer update.
if [ ! -d $RELEASES_SKELETON_DIR/.git ]; then
	echo "Cloning the skeleton dir..." | tee -a $DEPLOY_LOG	
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
echo "Getting remote git information..." | tee -a $DEPLOY_LOG	
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

echo "********************SUMMARY********************" &&
echo -e "From revision:\t$APP_BASE_DIR_LOCAL_REV" &&
echo -e "To revision:\t$REVISION"  &&
echo "BRANCH: $BRANCH" &&
echo "Owner: $AUTHOR" &&
echo "************************************************" | tee -a $DEPLOY_LOG

# If release doesn't exist yet, prepare it:
if [ ! -d $RELEASE ] ; then
	echo "Preparing release..." | tee -a $DEPLOY_LOG	
	echo "Cleaning skeleton..." | tee -a $DEPLOY_LOG	
	cd $RELEASES_SKELETON_DIR 2>&1 | tee -a $DEPLOY_LOG
	# Skeleton should be always clean, but anyway let's assure.
	git reset --hard 2>&1 | tee -a $DEPLOY_LOG
	git checkout master 2>&1 | tee -a $DEPLOY_LOG
	echo "Pulling remote changes..." | tee -a $DEPLOY_LOG	
	git pull origin $APP_BRANCH 2>&1 | tee -a $DEPLOY_LOG
	echo "Installing dependencies with '$DEPENDENCY_BIN $DEPENDENCY_BIN_ARGS'..." | tee -a $DEPLOY_LOG	
	$DEPENDENCY_BIN $DEPENDENCY_BIN_ARGS 2>&1 | tee -a $DEPLOY_LOG
	git checkout $BRANCH 2>&1 | tee -a $DEPLOY_LOG
	git checkout $REVISION 2>&1 | tee -a $DEPLOY_LOG

	echo "Creating release folder..." | tee -a $DEPLOY_LOG	
	cp -R $RELEASES_SKELETON_DIR $RELEASE
fi

# Deploy it
echo "Deploying $RELEASE..." | tee -a $DEPLOY_LOG	
rm $APP_DIR && ln -s $RELEASE $APP_DIR

echo "Executing post-deploy scripts..." | tee -a $DEPLOY_LOG	
# Execute post-deployment actions
source $SCRIPTPATH/post-deploy.sh | tee -a $DEPLOY_LOG

echo "Log file in $DEPLOY_LOG"	
cd $ORIGINAL_PATH
