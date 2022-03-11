Run Odoo on Cloudron.

Features
---

- Uses Cloudron LDAP for user federation
- Uses Cloudron SMTP for sending emails
- Uses Cloudron IMAP for incoming emails
- Hardened to disable database selection, debug mode, etc.
- Supports custom addons installed at `/app/data/extra-addons`
- Supports customization using `/app/data/odoo.conf`
- Supports long-polling actions like chat using custom `/run/nginx/nginx.conf` file