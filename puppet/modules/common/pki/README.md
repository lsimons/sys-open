
Steps:

New puppetmaster comes online
Get's configured to be CA
Generates ca-key.pem
Signs self to create ca.pem

New puppetclient comes online
- puppetrun fails due to not having keys.
- tell puppetmaster to generate keys.
- puppetmaster generates keys and signs them.
- puppetmaster passes both private and public key to puppetclient
(- puppetmaster adds pub key to git?)
(- puppetmaster deletes priv key from self, ensuring only puppetclient has priv
key?)
- puppetmaster can now install everything on puppetmaster

Puppetizing this:

 * http://www.rsyslog.com/doc/tls_cert_machine.html
 * http://libvirt.org/remote.html

Also reading this: 
 * www.canonical.com/sites/default/files/active/Whitepaper-CentralisedLogging-v1.pdf
 * http://www.cromwell-intl.com/security/syslog-tls-cloud.html
 * http://www.gnu.org/software/gnutls/manual/html_node/certtool-Invocation.html

