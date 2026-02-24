FROM php:8.0-apache
LABEL maintainer="You <admin@bgkalendar.com>"

ENV APACHE_SERVER_NAME=bgkalendar.com

RUN a2enmod rewrite \
    && echo "ServerName ${APACHE_SERVER_NAME}" > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername \
    && printf '<Directory /var/www/>\n    AllowOverride All\n</Directory>\n' > /etc/apache2/conf-available/bgcalendar-override.conf \
    && a2enconf bgcalendar-override

RUN docker-php-ext-install bcmath

ADD phpsite/ /app/public
ADD java/ /app/public/java
WORKDIR /app/public/java

RUN echo "Wallet Address May Be Specified In /app/public/bitcoinwallet.php" > /app/public/bitcoinwallet.php \
    && rm -rf /var/www/html \
    && ln -s /app/public /var/www/html \
    && chown -R www-data:www-data /app
