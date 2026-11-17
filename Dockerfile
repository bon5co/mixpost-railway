# Mixpost Lite wrapper for Railway. Upstream binds nginx to port 80, trusts no proxy, and creates a public default admin
# (admin@example.com / changeme) before the web server starts. The wrapper binds nginx to Railway's PORT (IPv4 and IPv6),
# trusts the Railway edge, and creates the administrator from ADMIN_PASSWORD instead of the default account.
# upstream: inovector/mixpost
FROM inovector/mixpost:v2.6.0@sha256:89d02f4e3d27a2e1a93a108e391883afacbe81596a5d4bddcb309bc04650b22e

ENV ADMIN_EMAIL=admin@mixpost.example \
    APP_DEBUG=false \
    APP_NAME=Mixpost \
    DB_DATABASE=mixpost \
    DB_USERNAME=mixpost \
    REDIS_PREFIX=mixpost_database_

# 1. The default admin line becomes our own command; nothing else in upstream's start script changes.
# 2. Trust the Railway edge for X-Forwarded-Proto/Host so links and cookies are https.
COPY RailwayAdmin.php /var/www/app/commands/RailwayAdmin.php
RUN set -e; \
    cp /usr/local/bin/start.sh /usr/local/bin/upstream-start.sh; \
    grep -c 'php artisan mixpost-auth:create --admin' /usr/local/bin/upstream-start.sh | grep -qx 1; \
    sed -i 's#php artisan mixpost-auth:create --admin#php artisan railway:admin#' /usr/local/bin/upstream-start.sh; \
    sed -i 's#protected $proxies;#protected $proxies = "*";#' /var/www/html/app/Http/Middleware/TrustProxies.php; \
    grep -q 'proxies = "\*"' /var/www/html/app/Http/Middleware/TrustProxies.php; \
    grep -q 'listen 80;' /etc/nginx/sites-available/default

COPY railway-boot.sh /usr/local/bin/railway-boot.sh
RUN chmod +x /usr/local/bin/railway-boot.sh /usr/local/bin/upstream-start.sh

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-boot.sh"]
