= ROXGIBSON

== about

This is a project in git that for now holds configuration files for roxanne-important stuff, like the nginx config and the motion config.  It might be that we keep the configs for different servers (!?) here for the roxanne family of services.

Additionally it has become a dispatching hub for *all* the important configuration and build scripts (related to roxanne services) that might be (or should be) on the system.

The purpose of this stuff being in version control is so that a) if we break something we can revert and b) might be easier to deploy roxanne-related services to new servers.

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

 @todo: erase this whole section.

  no:

as a wierd experiment, we will see if we can have different users commit to the same repository.  the fixperms script is for this.  you will need sudo privileges to run it.  see more information in that script. (no. bad idea.)
