We are using puppet to set up a safe environment for wordpress.

Contrary to popular belief, (responsible) wordpress administration is hard. If you have no experience setting wordpress up from scratch safely, expect to spend a day or two before making your first config change.


Some unsafe admin features are disabled. This includes:
* Updating wordpress itself
* Installing or customizing themes
* Installing or customizing plugins


To install wordpress from scratch:
* create wpdb machine for mysql hosting
* create wp machine for wordpress hosting
* add machines to puppet as normal using the 'base' profile
* get the backend interface IPs for the new machines
* update systems.yml with details for the new machines
* change the puppet profiles to wpdb and wp
* rerun puppet on the machines
* update DNS so that wp.example.org points at the wp machine

To update wordpress to a new version:
* ssh wp@wp.example.org /home/wp/www/wp-install.sh 3.4.1


Recovery with data:
* if you have a database backup, restore from that backup
* if you have a filesystem backup, restore /home/wp/www/uploads and /home/wp/www/multi_uploads
** if you have database but not filesystem, all attachments will have been lost...

Recovery without data:

If you don't have a backup, you have to do a bunch of work again. In particular,
the wordpress install process for multisite assumes you configure it partially
through the web interface (changing the database), and partially through
wp-config.php. This means that you have to disable multisite so that you can enable
multisite...

* visit https://wp.example.org/wp-admin/
** if the mysql database is empty, you'll be prompted to create an admin user
** set username 'admin' and password from the password safe
** disable multisite in the wp-config.php, commenting out this block:
{noformat}
define('MULTISITE', true);
define('SUBDOMAIN_INSTALL', true);
$base = '/';
define('DOMAIN_CURRENT_SITE', 'wp.example.org');
define('PATH_CURRENT_SITE', '/');
define('SITE_ID_CURRENT_SITE', 1);
define('BLOG_ID_CURRENT_SITE', 1);
{noformat}
** visit https://wp.example.org/wp-admin/options-discussion.php
*** disable all comments
** visit https://wp.example.org/wp-admin/options-permalink.php
*** set to use "month and name" for permalinks
** visit https://wp.example.org/wp-admin/network.php
*** set to use sub-domains
*** click install
** re-enable multi site by changing the block in wp-config.php
** visit https://wp.example.org/wp-admin/network/settings.php
*** check "Allow site administrators to add new users to their site via the "Users → Add New" page."
*** uncheck "limit total size of files uploaded to"
*** change "Max upload file size" to 32000 KB
** visit https://wp.example.org/wp-admin/network/plugins.php
*** network-activate wordpress-mu-domain-mapping plugin
** visit https://wp.example.org/wp-admin/network/settings.php?page=dm_admin_page
*** set server CNAME domain to wp.example.org
*** enable Remote Login, Permanent redirect, User domain mapping page,Redirect administration pages to site's original domain
** visit https://wp.example.org/wp-admin/network/plugins.php
*** network-activate:
    Geo Mashup
    Magic-fields
    Wordpress Importer
    Wordpress MU Domain Mapping
    WP Super Cache

To map a domain to a site:
* first add the site as normal using the multisite features
* then, visit <site-name>.wp.example.org/wp-admin/tools.php?page=domainmapping
* add the new name for the site
* only if you want to set this domain as the default, next
** visit https://wp.example.org/wp-admin/network/sites.php
** click the site to edit
** change the domain and save
** go to the settings page, and make sure all urls are ok, in particular
*** make sure FileUpload url makes sense

