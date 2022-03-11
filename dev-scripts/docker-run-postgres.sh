#!/bin/sh

# Run `postgres` container named `postgres` in docker network `localnet`
# Create a network, if not exists: `docker network create localnet`

docker run --name postgres -d -p 5432:5432 --network localnet \
  -e POSTGRES_USER=odoo_user \
  -e POSTGRES_PASSWORD=odoo_password \
  -e POSTGRES_DB=odoo \
  postgres:latest

# Login to pg cli
PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -p 5432

# Create user called 'odoo_user'
CREATE ROLE odoo_user with LOGIN
\password odoo_user
# Enter a password, such as: odoo_password, which is an extremely bad password btw.

# Recreate database quickly.
drop database odoo;
create database odoo with encoding 'utf-8' owner odoo_user;

# Try logging in as odoo_user
PGPASSWORD=odoo_password psql -h 172.17.0.1 -p 5432 -U odoo_user -d odoo
