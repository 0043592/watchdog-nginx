# this is nginx with automatical monitoring if conf.d has been changed and auto master restart
# Pull base image
FROM python:3.10.4-buster
COPY install-nginx-debian.sh /
RUN bash /install-nginx-debian.sh

EXPOSE 80
# Expose 443, in case of LTS / HTTPS
EXPOSE 443

# Set environment varibles
# If this is set to a non-empty string,
# Python won’t try to write .pyc files on the import of source modules.
# This is equivalent to specifying the -B option.
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PIP_NO_CACHE_DIR 0

RUN set -ex &&  pip3 install --no-cache-dir --upgrade pip watchdog && mkdir -p /app

# Remove default configuration from Nginx
RUN rm -rf /etc/nginx/conf.d/default.conf


# Install Supervisord
RUN apt-get update && apt-get install -y supervisor \
&& rm -rf /var/lib/apt/lists/*
# Custom Supervisord config
COPY supervisord-debian.conf /etc/supervisor/conf.d/supervisord.conf


COPY templates/default.conf /etc/nginx/sites-enabled/default
COPY templates/nginx.conf /etc/nginx/nginx.conf
COPY templates/proxy.conf /etc/nginx/proxy.conf

#By default, Nginx will run a single worker process, setting it to auto
# will create a worker for each CPU core
ENV NGINX_WORKER_PROCESSES 1

# By default, Nginx listens on port 80.
# To modify this, change LISTEN_PORT environment variable.
# (in a Dockerfile or with an option for `docker run`)
ENV LISTEN_PORT 80
# Copy start.sh script that will check for a /app/prestart.sh script and run it before starting the app
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Copy the entrypoint that will generate Nginx additional configs
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /app
COPY watchdog_reload.py /watchdog_reload.py
RUN chmod +x /watchdog_reload.py

ENTRYPOINT ["/entrypoint.sh"]

# Run the start script, it will check for an /app/prestart.sh script (e.g. for migrations)
# And then will start Supervisor, which in turn will start Nginx and uWSGI
CMD ["/start.sh"]
