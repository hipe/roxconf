= ROXGIBSON

== about

This project/folder was almost called "roxconfig".

This is a project in git that for now holds configuration files for roxanne-important stuff, like the nginx config and the motio
n config.  It might be that we keep the configs for different servers (!?) here for the roxanne family of services.

The purpose of this stuff being in version control is so that a) if we break something we can revert and b) might be easier to deploy roxanne-related services to new servers.



== making symlinks
ln -s /home/roxanne/roxgibson/nginx-conf /etc/nginx/conf
ln -s /home/roxanne/roxgibson/motion-conf /etc/motion

