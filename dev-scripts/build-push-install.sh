#!/bin/sh

VERSION=15.0
DOMAIN='<domain in cloudron to install this app>'
AUTHOR='<your name>'

docker build -t $AUTHOR/cloudron-odoo:$VERSION ./ && docker push $AUTHOR/cloudron-odoo:$VERSION

cloudron install --image $AUTHOR/cloudron-odoo:$VERSION -l $DOMAIN

cloudron logs -f --app $DOMAIN
