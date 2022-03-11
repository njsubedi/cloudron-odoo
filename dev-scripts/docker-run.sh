#!/bin/sh

docker rm -f odoo_container && rm -rf ./.docker/* && mkdir -p ./.docker/run/nginx ./.docker/run/odoo ./.docker/app/data ./.docker/tmp && \
BUILDKIT_PROGRESS=plain docker build -t odoo_custom . && docker run --read-only \
    -v "$(pwd)"/.docker/app/data:/app/data:rw \
    -v "$(pwd)"/.docker/tmp:/tmp:rw \
    -v "$(pwd)"/.docker/run:/run:rw \
    -p 8000:8000 \
    --network localnet \
    --name odoo_container \
    odoo_custom
