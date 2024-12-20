FROM didstopia/base:nodejs-12-steamcmd-ubuntu-18.04

LABEL maintainer="Didstopia <support@didstopia.com>"

# Fix apt-get warnings
ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        expect \
        tcl \
	libsdl2-2.0-0:i386 \
        libgdiplus && \
    rm -rf /var/lib/apt/lists/*

# Remove default nginx stuff
RUN rm -fr /usr/share/nginx/html/* && \
	rm -fr /etc/nginx/sites-available/* && \
	rm -fr /etc/nginx/sites-enabled/*

# Install webrcon (specific commit)
COPY nginx_rcon.conf /etc/nginx/nginx.conf
RUN curl -sL https://github.com/Facepunch/webrcon/archive/24b0898d86706723d52bb4db8559d90f7c9e069b.zip | bsdtar -xvf- -C /tmp && \
	mv /tmp/webrcon-24b0898d86706723d52bb4db8559d90f7c9e069b/* /usr/share/nginx/html/ && \
	rm -fr /tmp/webrcon-24b0898d86706723d52bb4db8559d90f7c9e069b

# Customize the webrcon package to fit our needs
ADD fix_conn.sh /tmp/fix_conn.sh

# Create the volume directories
RUN mkdir -p /data/steamcmd/rust /data/usr/share/nginx/html /data/var/log/nginx

# Setup proper shutdown support
ADD shutdown_app/ /app/shutdown_app/
WORKDIR /app/shutdown_app
RUN npm install

# Setup restart support (for update automation)
ADD restart_app/ /app/restart_app/
WORKDIR /app/restart_app
RUN npm install

# Setup scheduling support
ADD scheduler_app/ /app/scheduler_app/
WORKDIR /app/scheduler_app
RUN npm install

# Setup scheduling support
ADD heartbeat_app/ /app/heartbeat_app/
WORKDIR /app/heartbeat_app
RUN npm install

# Setup rcon command relay app
ADD rcon_app/ /app/rcon_app/
WORKDIR /app/rcon_app
RUN npm install
RUN ln -s /app/rcon_app/app.js /usr/bin/rcon

# Add the steamcmd installation script
ADD install.txt /app/install.txt

# Copy the Rust startup script
ADD start_rust.sh /app/start.sh

# Copy the Rust update check script
ADD update_check.sh /app/update_check.sh

# Copy extra files
COPY README.md LICENSE.md /app/

# Set the current working directory
WORKDIR /

# Fix permissions
RUN chown -R 1000:1000 \
    /data/steamcmd \
    /data/usr/share/nginx/html \
    /data/var/log/nginx

# Run as a non-root user by default
ENV PGID 1000
ENV PUID 1000

# Define directories to take ownership of
ENV CHOWN_DIRS "/data"

# Expose the volumes
# VOLUME [ "/steamcmd/rust" ]
# VOLUME [ "/app" ]

# Start the server
CMD [ "bash", "/app/start.sh"]
