class wpdb::firewall {
  # todo this should not be hardcoded!!
  firewall::allow { "allow-mysql-from-wp":
    port => 3306,
    from => "${wpdb[DB_CLIENT_HOST]}",
    ip => "${wpdb[DB_HOST]}",
    proto => "tcp",
  }
}

class wpdb::db {
  exec { "create-wordpress-db":
      unless => inline_template("mysql \
          --defaults-extra-file=/root/.my.cnf \
          -uroot \
          -e 'SELECT TRUE;' <%= wpdb['DB_DATA'] %>"),
      command => inline_template("mysql \
          --defaults-extra-file=/root/.my.cnf \
          -uroot \
          -e 'CREATE DATABASE <%= wpdb['DB_DATA'] %>;'"),
      require => Class["mysql"],
  }

  exec { "grant-wordpress-db":
      unless => inline_template("mysql \
          --defaults-extra-file=/root/.my.cnf \
          -u<%= wpdb['DB_USER'] %> \
          -p<%= wpdb['DB_PASSWD'] %> \
          -e 'SELECT TRUE;' \
          <%= wpdb['DB_DATA'] %>"),
      command => inline_template("mysql \
          --defaults-extra-file=/root/.my.cnf \
          -uroot \
          -e \"GRANT ALL ON <%= wpdb['DB_DATA'] %>.* TO <%= wpdb['DB_USER'] %>@localhost
                       IDENTIFIED BY '<%= wpdb['DB_PASSWD'] %>';
               FLUSH PRIVILEGES;\""),
      require => [Class["mysql"], Exec["create-wordpress-db"]]
  }

  exec { "grant-wordpress-db-external":
      unless => inline_template("mysql \
          --defaults-extra-file=/root/.my.cnf \
          -uroot \
          -e \"SELECT host FROM user WHERE host='<%= wpdb['DB_CLIENT_HOST'] %>' AND user='<%= wpdb['DB_USER'] %>' AND password=PASSWORD('<%= wpdb['DB_PASSWD'] %>');\" \
          mysql \
          | grep <%= wpdb['DB_CLIENT_HOST'] %>"),
      command => inline_template("mysql \
          --defaults-extra-file=/root/.my.cnf \
          -uroot \
          -e \"GRANT ALL ON <%= wpdb['DB_DATA'] %>.* TO <%= wpdb['DB_USER'] %>@<%= wpdb['DB_CLIENT_HOST'] %>
                       IDENTIFIED BY '<%= wpdb['DB_PASSWD'] %>';
               FLUSH PRIVILEGES;\""),
      require => [Class["mysql"], Exec["create-wordpress-db"]]
  }
}

class wpdb {
  include wpdb::firewall, wpdb::db
}
