FROM eclipse-temurin:8-jdk AS javadoc_builder

WORKDIR /build/java
COPY java/ /build/java
RUN chmod +x ./gradlew \
    && ./gradlew --no-daemon javadoc

FROM php:8.0-apache
LABEL maintainer="You <admin@bgkalendar.com>"

ENV APACHE_SERVER_NAME=localhost

RUN a2enmod rewrite \
    && echo "ServerName ${APACHE_SERVER_NAME}" > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername \
    && printf '<Directory /var/www/>\n    AllowOverride All\n</Directory>\n' > /etc/apache2/conf-available/bgcalendar-override.conf \
    && a2enconf bgcalendar-override

RUN docker-php-ext-install bcmath

COPY --chown=www-data:www-data phpsite/ /app/public
COPY --chown=www-data:www-data java/ /app/public/java
WORKDIR /app/public/java

COPY --from=javadoc_builder /build/java/build/docs/javadoc /app/public/javadoc

RUN chmod +x /app/public/java/gradlew \
    && echo "Wallet Address May Be Specified In /app/public/bitcoinwallet.php" > /app/public/bitcoinwallet.php \
    && rm -rf /var/www/html \
    && ln -s /app/public /var/www/html
