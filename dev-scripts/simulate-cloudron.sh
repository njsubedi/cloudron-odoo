if [[ -z "${CLOUDRON+x}" ]]; then
  echo "Not Cloudron. Setting testing vars..."
  export CLOUDRON_POSTGRESQL_PORT=5432
  export CLOUDRON_POSTGRESQL_HOST=172.17.0.1
  export CLOUDRON_POSTGRESQL_DATABASE=odootest
  export CLOUDRON_POSTGRESQL_USERNAME=odoo_user
  export CLOUDRON_POSTGRESQL_PASSWORD=odoo_password

  export CLOUDRON_APP_DOMAIN=odoo.localhost
  export CLOUDRON_APP_ORIGIN=https://odoo.localhost

  export CLOUDRON_MAIL_SMTP_SERVER='localhost'
  export CLOUDRON_MAIL_SMTP_PORT='25'
  export CLOUDRON_MAIL_SMTP_USERNAME='username'
  export CLOUDRON_MAIL_SMTP_PASSWORD='password'
  export CLOUDRON_MAIL_FROM='from@localhost'

  export CLOUDRON_MAIL_IMAP_SERVER='localhost'
  export CLOUDRON_MAIL_IMAP_PORT='25'
  export CLOUDRON_MAIL_IMAP_USERNAME='username'
  export CLOUDRON_MAIL_IMAP_PASSWORD='password'

  export CLOUDRON_LDAP_SERVER='172.18.0.1'
  export CLOUDRON_LDAP_PORT='3002'
  export CLOUDRON_LDAP_URL='ldap://172.18.0.1:3002'
  export CLOUDRON_LDAP_USERS_BASE_DN='ou=users,dc=cloudron'
  export CLOUDRON_LDAP_GROUPS_BASE_DN='ou=groups,dc=cloudron'
  export CLOUDRON_LDAP_BIND_DN='cn=app_id,ou=apps,dc=cloudron'
  export CLOUDRON_LDAP_BIND_PASSWORD='example_bind_password'
fi
