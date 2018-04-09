FROM ubuntu:16.04

LABEL maintainer Leonardo Damasceno

RUN apt-get update
RUN apt-get install -y nginx
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

COPY . /var/www/html

EXPOSE 80
CMD ["nginx"]
