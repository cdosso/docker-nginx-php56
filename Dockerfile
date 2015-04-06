FROM phusion/baseimage:0.9.15

ENV HOME /root

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

CMD ["/sbin/my_init"]

# Nginx-PHP Installation
RUN apt-get update
RUN apt-get install -y vim curl wget build-essential python-software-properties
RUN add-apt-repository -y ppa:nginx/stable

#dotdeb
RUN wget http://www.dotdeb.org/dotdeb.gpg -O - | apt-key add -
RUN echo "deb http://packages.dotdeb.org wheezy-php56 all" >> /etc/apt/sources.list.d/dotdeb.list
RUN echo "deb-src http://packages.dotdeb.org wheezy-php56 all" >> /etc/apt/sources.list.d/dotdeb.list

#couchbase
RUN wget  http://packages.couchbase.com/ubuntu/couchbase.key -O - | apt-key add -
RUN echo "deb http://packages.couchbase.com/ubuntu wheezy wheezy/main" > /etc/apt/sources.list.d/couchbase.list

RUN apt-get update
RUN apt-get install -y --force-yes php5-cli php5-fpm php5-curl\
		       php5-mcrypt php5-imagick php5-dev

RUN apt-get install -y --force-yes libcouchbase-dev

RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/cli/php.ini

RUN pecl install couchbase
RUN echo "extension=couchbase.so" > /etc/php5/mods-available/couchbase.ini
RUN php5enmod couchbase

RUN apt-get install -y nginx

RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
 
RUN mkdir -p        /var/www
ADD config/nginx.conf   /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
RUN mkdir           /etc/service/nginx
ADD scripts/nginx.sh  /etc/service/nginx/run
RUN chmod +x        /etc/service/nginx/run
RUN mkdir           /etc/service/phpfpm
ADD scripts/phpfpm.sh /etc/service/phpfpm/run
RUN chmod +x        /etc/service/phpfpm/run

EXPOSE 80
EXPOSE 443
# End Nginx-PHP

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*