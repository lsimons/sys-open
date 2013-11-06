Be careful with installing plugins.

Read the source code before installing a plugin.

Only install plugins from http://wordpress.org/extend/plugins/.

Add a README for the plugin describing why you installed it, which precise version you installed, and which site(s) are using it.

To install or update a plugin,

* download and extract it here
* check it in, and push to github
* run
    ./update-plugins.sh
    ssh wp@wp.example.org /home/wp/www/wp-install.sh

You cannot manage plugins using the wordpress web interface.
