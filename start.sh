#!/bin/bash
set -eu pipefail

export LANG="C.UTF-8"
export ODOO_RC="/app/data/odoo.conf"

pg_cli() {
  PGPASSWORD=$CLOUDRON_POSTGRESQL_PASSWORD psql \
    -h $CLOUDRON_POSTGRESQL_HOST \
    -p $CLOUDRON_POSTGRESQL_PORT \
    -U $CLOUDRON_POSTGRESQL_USERNAME \
    -d $CLOUDRON_POSTGRESQL_DATABASE -c "$1"
}

# Create required directories if they don't exist
mkdir -p /app/data/extra-addons /app/data/odoo /run/odoo /run/nginx
chown -R cloudron:cloudron /run

# Check for First Run
if [[ ! -f /app/data/odoo.conf ]]; then
  echo "First run. Initializing DB..."

  # Initialize the database, and exit.
  /usr/local/bin/gosu cloudron:cloudron /app/code/odoo-bin -i base,auth_ldap,fetchmail --without-demo all --data-dir /app/data/odoo --logfile /run/odoo/runtime.log -d $CLOUDRON_POSTGRESQL_DATABASE --db_host $CLOUDRON_POSTGRESQL_HOST --db_port $CLOUDRON_POSTGRESQL_PORT --db_user $CLOUDRON_POSTGRESQL_USERNAME --db_pass $CLOUDRON_POSTGRESQL_PASSWORD --stop-after-init

  echo "Initialized successfully."

  echo "Adding required tables/relations for mail settings."
  pg_cli "INSERT INTO public.res_config_settings (create_uid, create_date, write_uid, write_date, company_id, user_default_rights, external_email_server_default, module_base_import, module_google_calendar, module_microsoft_calendar, module_mail_plugin, module_google_drive, module_google_spreadsheet, module_auth_oauth, module_auth_ldap, module_base_gengo, module_account_inter_company_rules, module_pad, module_voip, module_web_unsplash, module_partner_autocomplete, module_base_geolocalize, module_google_recaptcha, group_multi_currency, show_effect, profiling_enabled_until, module_product_images, unsplash_access_key, fail_counter, alias_domain, restrict_template_rendering, use_twilio_rtc_servers, twilio_account_sid, twilio_account_token, auth_signup_reset_password, auth_signup_uninvited, auth_signup_template_user_id) VALUES (2, 'NOW()', 2, 'NOW()', 1, false, true, true, false, false, false, false, false, false, true, false, false, false, false, true, true, false, false, false, true, NULL, false, NULL, 0, '$CLOUDRON_APP_DOMAIN', false, false, NULL, NULL, false, 'b2b', 5) ON CONFLICT (id) DO NOTHING;"

  pg_cli "INSERT INTO public.ir_config_parameter (key, value, create_uid, create_date, write_uid, write_date) VALUES ('base_setup.default_external_email_server', 'True', 2, 'NOW()', 2, 'NOW()');"
  pg_cli "INSERT INTO public.ir_config_parameter (key, value, create_uid, create_date, write_uid, write_date) VALUES ('mail.catchall.domain', '$CLOUDRON_APP_DOMAIN', 2, 'NOW()', 2, 'NOW()');"

  echo "Disabling public sign-up..."
  pg_cli "UPDATE public.ir_config_parameter SET value='b2b' WHERE key='auth_signup.invitation_scope';";

  echo "Copying default configuration file to /app/data/odoo.conf..."
  cp /app/pkg/odoo.conf.sample /app/data/odoo.conf

  echo "First run complete."
fi

# These values should be re-set to make Odoo work as expcected.
echo "Ensuring proper [options] in /app/data/odoo.conf ..."

# Custom paths
crudini --set /app/data/odoo.conf 'options' addons_path "/app/code/addons,/app/data/extra-addons"
crudini --set /app/data/odoo.conf 'options' data_dir "/app/data/odoo"

# Logging
crudini --set /app/data/odoo.conf 'options' logfile "/run/logs/odoo.log"
crudini --set /app/data/odoo.conf 'options' logrotate 'False'
crudini --set /app/data/odoo.conf 'options' log_db 'False'
crudini --set /app/data/odoo.conf 'options' syslog 'False'

# Http Server
crudini --set /app/data/odoo.conf 'options' proxy_mode "True"
crudini --set /app/data/odoo.conf 'options' secure 'False'
crudini --set /app/data/odoo.conf 'options' interface '127.0.0.1'
crudini --set /app/data/odoo.conf 'options' port '8069'
crudini --set /app/data/odoo.conf 'options' longpolling_port '8072'

# Securing Odoo
crudini --set /app/data/odoo.conf 'options' list_db "False"
crudini --set /app/data/odoo.conf 'options' test_enable "False"
crudini --set /app/data/odoo.conf 'options' test_file "False"
crudini --set /app/data/odoo.conf 'options' test_report_directory "False"
crudini --set /app/data/odoo.conf 'options' without_demo "all"
crudini --set /app/data/odoo.conf 'options' debug_mode "False"
#TODO Disable debug mode

# DB
crudini --set /app/data/odoo.conf 'options' db_host "$CLOUDRON_POSTGRESQL_HOST"
crudini --set /app/data/odoo.conf 'options' db_port "$CLOUDRON_POSTGRESQL_PORT"
crudini --set /app/data/odoo.conf 'options' db_user "$CLOUDRON_POSTGRESQL_USERNAME"
crudini --set /app/data/odoo.conf 'options' db_password "$CLOUDRON_POSTGRESQL_PASSWORD"
crudini --set /app/data/odoo.conf 'options' db_name "$CLOUDRON_POSTGRESQL_DATABASE"
crudini --set /app/data/odoo.conf 'options' db_filter "^$CLOUDRON_POSTGRESQL_DATABASE.*$"
crudini --set /app/data/odoo.conf 'options' db_sslmode 'False'

# IMAP Configuration
if [[ -z "${CLOUDRON_MAIL_IMAP_SERVER+x}" ]]; then
  echo "IMAP is disabled. Removing values from config."
  pg_cli "UPDATE public.fetchmail_server SET active='f' WHERE name LIKE 'Cloudron%';"
else
  echo "IMAP is enabled. Adding values to config."
  pg_cli "INSERT INTO public.fetchmail_server (id, name, active, state, server, port, server_type, is_ssl, attach, original, date, \"user\", password, object_id, priority, configuration, script, create_uid, create_date, write_uid, write_date) VALUES (1, 'Cloudron IMAP Service', true, 'done', '$CLOUDRON_MAIL_IMAP_SERVER', $CLOUDRON_MAIL_IMAP_PORT, 'imap', false, true, false, NULL, '$CLOUDRON_MAIL_IMAP_USERNAME', '$CLOUDRON_MAIL_IMAP_PASSWORD', 151, 5, NULL, '/mail/static/scripts/odoo-mailgate.py', 2, 'NOW()', 2, 'NOW()') ON CONFLICT (id) DO NOTHING;"
fi

# SMTP Configuration
if [[ -z "${CLOUDRON_MAIL_SMTP_SERVER+x}" ]]; then
  echo "SMTP is disabled. Removing values from config."
  pg_cli "UPDATE public.ir_mail_server SET active='f' WHERE name LIKE 'Cloudron%';"
else
  echo "SMTP is enabled. Adding values to config."
  pg_cli "INSERT INTO public.ir_mail_server (id, name, from_filter, smtp_host, smtp_port, smtp_authentication, smtp_user, smtp_pass, smtp_encryption, smtp_ssl_certificate, smtp_ssl_private_key, smtp_debug, sequence, active, create_uid, create_date, write_uid, write_date) VALUES (1, 'Cloudron SMTP Service', NULL, '$CLOUDRON_MAIL_SMTP_SERVER', $CLOUDRON_MAIL_SMTP_PORT, 'login', '$CLOUDRON_MAIL_SMTP_USERNAME', '$CLOUDRON_MAIL_SMTP_PASSWORD', 'none', NULL, NULL, false, 10, true, 2, 'NOW()', 2, 'NOW()') ON CONFLICT (id) DO NOTHING;"
fi

# LDAP Configuration
if [[ -z "${CLOUDRON_LDAP_SERVER+x}" ]]; then
  echo "LDAP is disabled. Removing values from config."
  pg_cli "DELETE FROM public.res_company_ldap WHERE id = 1 AND company = 1"
else
  echo "LDAP is enabled. Adding values to config."
  pg_cli "INSERT INTO public.res_company_ldap (id, sequence, company, ldap_server, ldap_server_port, ldap_binddn, ldap_password, ldap_filter, ldap_base, \"user\", create_user, ldap_tls, create_uid, create_date, write_uid, write_date) VALUES (1, 10, 1, '$CLOUDRON_LDAP_SERVER', $CLOUDRON_LDAP_PORT, '$CLOUDRON_LDAP_BIND_DN', '$CLOUDRON_LDAP_BIND_PASSWORD', '(&(objectclass=user)(mail=%s))', '$CLOUDRON_LDAP_USERS_BASE_DN', NULL, true, false, 2, 'NOW()', 2, 'NOW()') ON CONFLICT (id) DO NOTHING;;"
fi

# Start nginx process
sed -e "s,__REPLACE_WITH_CLOUDRON_APP_DOMAIN__,${CLOUDRON_APP_DOMAIN}," /app/pkg/nginx.conf >/run/nginx/nginx.conf

chown -R cloudron:cloudron /app/data

echo "=> Start nginx"
rm -f /run/nginx/nginx.pid

nginx -c /run/nginx/nginx.conf &
# Done nginx

echo "Resource allocation (hard limit: 100% of available memory; soft limit: 80%)"
if [[ -f /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes ]]; then
  memory_limit_hard=$(($(cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes)))
  memory_limit_soft=$((memory_limit_hard * 4 / 5))
else
  memory_limit_hard=2684354560
  memory_limit_soft=2147483648 # (memory_limit_hard * 4 / 5)
fi

worker_count=$((memory_limit_hard / 1024 / 1024 / 150)) # 1 worker for 150M
worker_count=$((worker_count > 8 ? 8 : worker_count))   # max of 8
worker_count=$((worker_count < 1 ? 1 : worker_count))   # min of 1

echo "Memory limits - hard limit: $memory_limit_hard bytes, soft limit: $memory_limit_soft bytes"

crudini --set /app/data/odoo.conf 'options' limit_memory_hard $memory_limit_hard
crudini --set /app/data/odoo.conf 'options' limit_memory_soft $memory_limit_soft
crudini --set /app/data/odoo.conf 'options' workers $worker_count

echo "Done. Starting server with $worker_count workers.."

chown -R cloudron:cloudron /app/data/

/usr/local/bin/gosu cloudron:cloudron /app/code/odoo-bin -c /app/data/odoo.conf
