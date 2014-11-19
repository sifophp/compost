# COMPOST: A bash deployment script with Composer installation
This is a ridiculous simple script that will download the source code of your project from a git repository and deploy it in production resolving all its dependencies (using **composer** by default, but you can change the command to bower or anything else). The script is written in `bash` so you don't have to install anything in the server other than the tools you already use. 

**DISCLAIMER: Very beta! Use with caution, I won't refund you the money if things go weird. I take no responsibility or whatsoever. Developed in one late afterwork night. My skills in Bash are so advanced as the ones of a Spanish prime minister related to rule a country. All being said, enjoy the masterpiece.**


## Requirements
 - Linux, BSD, Mac or alike with a bash terminal 
 - `git` command installed
 - `composer` installed, or any other dependency system you choose.
 - A remotely cloned git repo where the production path points to.

## Installation
 - Download this source code into your production server. Ensure `$APP_DIR_SYMLINK` doesn't exist yet.
 - Edit the `deploy.cfg` with your project settings
 - After you have deployed for the first time, change your DocumentRoot to point to `$APP_DIR_SYMLINK`


### Dependency management
If you don't have composer or similar installed, now is the moment. Composer works like this:

	# See: https://getcomposer.org/
	curl -sS https://getcomposer.org/installer | php
	mv composer.phar /usr/local/bin/composer

	
## Usage

Just call the script, it is interactive and will offer to deploy to the latest revision found in the origin (remote connection needed). You can specify any other branch and revision at your will.

**Deploy to the latest version of current branch**

	bash deploy.sh

And accept all dialogues.

**Deploy to a specific revision / branch)**

	bash deploy.sh
	
Then write the branch you want to use and the SHA commit you want to checkout.

*NOTE:* Depending on the needed permissions you might need to run the script using `sudo`:

	sudo bash deploy.sh

To run the script in debug mode and see every line what is doing type:

	bash -x deploy.sh

You can see the list of revisions you can deploy to by executing a `git log`
### Script Output

If you don't make any changes to this script, the deployment of the [SIFO.me](http://sifo.me) website will be done in the folder /var/www/production. You can test it as reference. The full output could look more or less like this:

	$ bash deploy.sh 
	Deploy started on 2014-Nov-20...
	Checking requisites...
	Deploy data. Press ENTER to accept default values.
	Which Branch? <master>:

	Retrieving latest SHA from remote repository...
	Target <fa938355be>?:

	********************SUMMARY********************
	From revision:  a5263b8473
	To revision:    fa938355be
	BRANCH: master
	************************************************
	Preparing release...
	Cleaning skeleton...
	HEAD is now at a5263b8 Update README.md
	Previous HEAD position was a5263b8... Update README.md
	Switched to branch 'master'
	Your branch is up-to-date with 'origin/master'.
	Pulling remote changes...
	From https://github.com/sifophp/sifo-app
	 * branch            master     -> FETCH_HEAD
	Already up-to-date.
	Installing dependencies with '/usr/bin/composer install'...
	Loading composer repositories with package information
	Installing dependencies (including require-dev)                                      
	  - Installing sifophp/sifo-instance-installer (v0.3.0)
	    Loading from cache
	
	  - Installing sifophp/sifo-common-instance (dev-master 4c1ec82)
	    Cloning 4c1ec826f65cb5bedad923f958948db4ced5014a
	
	  - Installing sifophp/sifo (v3.0.0-beta.1)
	    Cloning 9681062c08dde9f1b4ca90af4f5b3ca13efb3426
	
	  - Installing sifophp/sifoweb (dev-master 872c9a8)
	    Cloning 872c9a89c3c90d02f22eb3df84e3f4cd8460d7db
	
	Writing lock file
	Installing dependencies (including require-dev) from lock file
	Nothing to install or update
	
	Generating autoload files
	Already on 'master'
	Your branch is up-to-date with 'origin/master'.
	Note: checking out 'fa938355be'.

	You are in 'detached HEAD' state. You can look around, make experimental
	changes and commit them, and you can discard any commits you make in this
	state without impacting any branches by performing another checkout.

	If you want to create a new branch to retain commits you create, you may
	do so (now or later) by using -b with the checkout command again. Example:

	  git checkout -b new_branch_name

	HEAD is now at fa93835... Minor update on documentation
	Creating release folder...
	Ready to deploy /var/www/releases/fa938355be...
	If anything failed it's time to abort now (Ctrl+C)
	Continue? [y/N]: y
	Executing post-deploy scripts...
	Deployment finished! Using /var/www/releases/fa938355be as production folder
	Log file in /var/www/deploys/2014-Nov-20.log

If you deploy the same revision this is what you get:

	$ bash deploy.sh 
	Deploy started on 2014-Nov-20...
	Checking requisites...
	Deploy data. Press ENTER to accept default values.
	Which Branch? <master>:

	Retrieving latest SHA from remote repository...

	Target <fa938355be>?:
	Already at requested revision fa938355be, nothing to do.
	

### Post-deploy
If you need to do specific things **after** the deploy then put them in the file `post-deploy.sh`.


## How does it work?
In a nutshell, the script will prepare a new folder containing the release (sha-1) you want to deploy. When everything is set the production path (which happens to be a symbolic link) will be changed and pointed to the new folder. If you added anything to the `post-deploy.sh` then it will be executed.

If a release has been already deployed in the past if you intend to deploy it again (e.g `rollback`) then only the symbolic link will be changed, because everything else is already there. The `post-deploy.sh` will be executed anyway (I left it this way in case you need to clean stuff).

A more graphical example, let's imagine you have you installed your application (`APP_DIR_SYMLINK`) under:

	/var/www/myapp
	
And then you want to deploy your code to the latest revision in the current branch, then you would execute:

	bash deploy.sh
	
At this moment the script will create a new release folder and point the `myapp` there:
	
	$ ls -l /var/www
	total 8
	drwxr-xr-x  2 alombarte  staff   68 Nov 12 00:31 deploys
	lrwxr-xr-x  1 alombarte  staff   45 Nov 12 01:08 myapp -> /var/www/releases/fa938355be
	drwxr-xr-x  5 alombarte  staff  170 Nov 12 01:08 releases


 

### Preparation of the release
What kind of magic is done to prepare this release? Not much, really.

The script clones your entire project to a `skeleton/` folder for the first time and that will be used as the template to create more releases (this is convenient for projects with a large codebase). When you deploy this skeleton is updated with the latest changes and the desired branch and revision is checked out, then composer dependencies are installed.

With the skeleton folder having all the code as expected, the whole folder is copied to a new one using as name the chosen revision. Finally, the production symbolic link is changed to point to the new folder.


## Things not covered

 - Many :)
 - Unexpected behavior is not controlled.
 - No checks, just executes as a monkey (OMG!)
 - You cannot deploy if you haven't cloned the project for the first time.
 - Cleanup old releases from the releases directory (free space)
 - Multiple machine deploy has to be done using other tools. 

Test the script in a harmless environment first. If you need something more decent use Capistrano instead.

## Contributions
If you'd like to contribute, make a pull request. If you don't use composer but a different dependency management system, that script might also work for you.

The script is now interactive but it might be upgraded to non-interactive by passing the parameters too. I am open to it :)
