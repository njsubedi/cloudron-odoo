FROM cloudron/base:3.2.0@sha256:ba1d566164a67c266782545ea9809dc611c4152e27686fd14060332dd88263ea
# Reference: https://github.com/odoo/docker/blob/master/15.0/Dockerfile

RUN mkdir -p /app/code /app/pkg /app/data
WORKDIR /app/code

RUN apt-get update && \
    apt-get install -y \
    python3-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev \
    libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev \
    liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libpq-dev

RUN curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.focal_amd64.deb && \
    echo 'ae4e85641f004a2097621787bf4381e962fb91e1 wkhtmltox.deb' | sha1sum -c - && \
    apt-get install -y --no-install-recommends ./wkhtmltox.deb && \
    rm -f ./wkhtmltox.deb && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt

RUN npm install -g rtlcss

# Install Odoo
ENV ODOO_VERSION 15.0

RUN curl -L https://github.com/odoo/odoo/archive/refs/heads/$ODOO_VERSION.tar.gz | tar zx --strip-components 1 -C /app/code && \
    pip3 install wheel && \
    pip3 install -r requirements.txt

RUN rm -rf /var/log/nginx && mkdir /run/nginx && ln -s /run/nginx /var/log/nginx

# Copy entrypoint script and Odoo configuration file
ADD start.sh odoo.conf.sample nginx.conf /app/pkg/

RUN mkdir -p /app/data/odoo/filestore /app/data/odoo/addons && \
    chown -R cloudron:cloudron /app/data

CMD [ "/app/pkg/start.sh" ]