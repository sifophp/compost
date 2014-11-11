# Composer bash deploy
This is a ridiculous simple script that will download the source code of your project from a git repository and deploy it in production resolving all its composer dependencies. The script is written in `bash` so you don't have to install anything in the server other than the tools you already use (`composer` and `git`). 

**DISCALIMER: Very beta! Use with caution, I won't refund you the money if things go weird. I take no responsibility or whatsoever. This is a one *noche loca* project**


## Requirements
 - Linux, BSD, Mac or alike with a bash terminal 
 - `git` command installed
 - `composer` installed

## Installation
 - Download this source code into your production server.
 - Edit the `deploy.cfg` with your project settings

If you don't have composer install it using:

	# See: https://getcomposer.org/
	curl -sS https://getcomposer.org/installer | php
	mv composer.phar /usr/local/bin/composer

	
## Usage
Just call the script :)

**Deploy to the latest version of current branch**

	bash deploy.sh

And accept all dialogues.

**Deploy to a specific revision / branch)**

	bash deploy.sh
	
If you need to do specific things **after** the deploy then put them in the file `post-deploy.sh`.

*NOTE:* Depending on the needed permissions you might need to run the script using `sudo`:

	sudo bash deploy.sh
	
If you don't make any changes to this script, the deployment of the [SIFO.me](http://sifo.me) website will be done in the folder /var/www/production. You can test it as reference. The output looks like this:



## How does it work?
In a nutshell, the script will prepare a new folder containing the release (sha-1) you want to deploy. When everything is set the production path (which happens to be a symbolic link) will be changed and pointed to the new folder. If you added anything to the `post-deploy.sh` then it will be executed.

If a release has been already deployed in the past if you intend to deploy it again (e.g `rollback`) then only the symbolic link will be changed, because everything else is already there. The `post-deploy.sh` will be executed anyway (I left it this way in case you need to clean stuff).

A more graphical example, let's imagine you have your application under

	/var/www/myapplication
	
Remember `myapplication` is a symbolic link to a folder. And then you want to deploy your code to the latest revision in the master branch (no arguments), then you would execute:

	/path/to/deploy.sh
	
At this moment the script will create a new release folder and point the `myapplication` there:
	
	$ ls -l /var/www
	lrwxr-xr-x  ...     myapplication -> /var/www/releases/0e92998cc7
 

### Preparation of the release
What kind of magic is done to prepare this release? Not much, really.

The script clones your entire project to a `skeleton/` folder for the first time and that will be used as the template to create more releases (this is convenient for projects with a large codebase). When you deploy this skeleton is updated with the latest changes and the desired branch and revision is checked out, then composer dependencies are installed.

With the skeleton folder having all the code as expected, the whole folder is copied to a new one using as name the chosen revision. Finally, the production symbolic link is changed to point to the new folder.


## Things not covered

 - Many :)
 - Unexpected behavior and error control
 - Cleanup old releases from the releases directory (free space)
 - Multiple machine deploy has to be done using other tools. 

Test the script in a harmless environment first. If you need something more decent use Capistrano instead.

## Contributions
If you'd like to contribute, make a pull request. If you don't use composer but a different dependency management system, that script might also work for you.

The script is now interactive but it might be upgraded to non-interactive by passing the parameters too. I am open to it :)
