= ROXGIBSON

== about

This is a project in git that for now holds configuration files for roxanne-important stuff, like the nginx config and the motion config.  It might be that we keep the configs for different servers (!?) here for the roxanne family of services.

The purpose of this stuff being in version control is so that a) if we break something we can revert and b) might be easier to deploy roxanne-related services to new servers.

As an added bonus, there is a super duper configuration script called 'roxconf' located in this directory that is a meta-script that is a hub to many other configuration scripts that could be loaded on the system.

== contents

-> roxconf/
 +-> roxconf
 +-> [other conf scripts]
 +-> servers
     +-> the-gibson
     |   +-> motion-conf/
     |   \-> nginx-conf/
     |
     \-> hipeland
         |
         +-> monit-conf/

== more info

For more information, please run roxconf.  every command is documented, and almost every command has a dry-run option.




== committing 

  no:

as a wierd experiment, we will see if we can have different users commit to the same repository.  the fixperms script is for this.  you will need sudo privileges to run it.  see more information in that script. (no. bad idea.)
