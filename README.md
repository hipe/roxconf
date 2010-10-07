= ROXGIBSON

== about

This project/folder was almost called "roxconfig", probably should have been.

This is a project in git that for now holds configuration files for roxanne-important stuff, like the nginx config and the motion config.  It might be that we keep the configs for different servers (!?) here for the roxanne family of services.

The purpose of this stuff being in version control is so that a) if we break something we can revert and b) might be easier to deploy roxanne-related services to new servers.


== contents

-> roxgibson
 +-> the-gibson
 | +-> motion-conf/
 | \-> nginx-conf/
 |
 \-> hipeland
   |
   --> monit-conf/



== making symlinks

  see ./flizz


== committing 

as a wierd experiment, we will see if we can have different users commit to the same repository.  the fixperms script is for this.  you will need sudo privileges to run it.  see more information in that script.
