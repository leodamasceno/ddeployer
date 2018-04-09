
# ddeployer

Ruby application to deploy and run your code locally via Docker. This
application retrieves and manages images and credentials from the Docker registry.

## Dependencies

To start, you need ruby 2.x installed. Then, check the dependencies below.

### Gems

You will also need to install the following gems:

* yajl-ruby
* docker-api

Type the following command to install it:

```
gem install yajl-ruby docker-api
```

Or use bundler:

```
bundle install
```

### Software

You will need to install Docker, access the following page for more information:
https://www.docker.com/get-docker

### Generate RSA keys

You will need RSA keys (private and public) to encrypt and decrypt passwords.
All the passwords in the configuration file should be encrypted. Generate the
private key using the following command:

```
openssl genrsa -out private.pem 2048
```

Now, create the public key:

```
openssl rsa -in private.pem -out public.pem -outform PEM -pubout
```

You should not type a password when requested.

## Configuration file

With all the dependencies installed, it's time to create the configuration file.
The application will look for two files in your project directory: Dockerfile
and ddeployer.yaml. Check the examples below:

```
keys:
    private_key: /Users/leonardo.damasceno/Documents/Ruby/lib/private.pem
    public_key: /Users/leonardo.damasceno/Documents/Ruby/lib/public.pem

config:
    docker_image_name: prod-nginx
    docker_url: https://registry-1.docker.io/v2/
    docker_login: leodamasceno
    docker_password: C2120dPGF8Vk7MXcVb5vgCRRHSQH3gq4GAFv7lpOgejQl5waqZC0hXcR7rCT37c+Ht7MXbgD+pq4+ieoRl/mVx8PdpvBfd2Rk2c2PkJREZ1QKz5u1uHa/KIFI4yBvJk/KTWGIWOd8ibpOM3g9iUEPK7wnkcDLVwJ5VvcOOZhnnLzY8HwvIclEbtsKnHrGZDNvUQCzCKk0sXHEiZi8zkhtMBFgoDC+qZ1sUW8E6x2h8BpCZUnU03yRgu6yxXoe/w1pdeS5dhow3aWmlbay0kaHxNF32znTzN0m8LbuEgezv4q7DPxgp4oSLcsiEJytLGzN5sYAX3bypkwsGqCPD1UEE==
```

In this above configuration file has the credentials of Docker's registry,
a.k.a. Docker Hub,

The Dockerfile, has the deploy commands for development environment, modify by your necessity:

```
FROM ubuntu:16.04
MAINTAINER Leonardo Damasceno

RUN apt-get update \
    && apt-get install -y nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "daemon off;" >> /etc/nginx/nginx.conf

COPY . /var/www/

EXPOSE 80
CMD ["nginx"]
```

The two files above need to be in the same directory where your code is for the
ddeployer application to work.

## Executing the application

The application can be used to create and store backups but you can also encrypt
and decrypt strings with the RSA keys. So, use the application to encrypt your
password before putting it into the configuration file:

```
ruby ddeployer -e "hello"
fwPUwUGubT219lekFNYgPU4Sx5148udiaxIEXEwrpn6WzTtG+2dE3cLYsi2gm7HE1EIq5vxJ5bKuu77oGl6WVjSNgVew5CZ9BW2iR9YzIAcUvpB1P37CiBaizMtdQ4z5/rqNytybwf8ZhoOt2RGYznxKOPSR0ul1hl782JOwPzuLn+H+n2EO44//xq13fc1veS/1DhU+uQjZkjBre2Vq3a57roS24JAaJKywSGZ9T9GMUpQ2EjCuJ0YNi2euevHiFzltxRNI2RZQ/7F9pnHSoTakwgz5mIfN1kIsDmsu34HvOe18vCT8vswGSQ4xx7g6G3vza1mxG/Ctnj+j0KBvDg==
```

As you can see in the example above, the application created the encrypted
version of the text password "hello". You should now copy it and add to your
configuration. We do not intend to allow clear text passwords in the
configuration file, because it's a dangerous world out there.

You can also decrypt these encrypted passwords if the same public and private
keys were used to create it previously:

```
ruby ddeployer -d "fwPUwUGubT219lekFNYgPU4Sx5148udiaxIEXEwrpn6WzTtG+2dE3cLYsi2gm7HE1EIq5vxJ5bKuu77oGl6WVjSNgVew5CZ9BW2iR9YzIAcUvpB1P37CiBaizMtdQ4z5/rqNytybwf8ZhoOt2RGYznxKOPSR0ul1hl782JOwPzuLn+H+n2EO44//xq13fc1veS/1DhU+uQjZkjBre2Vq3a57roS24JAaJKywSGZ9T9GMUpQ2EjCuJ0YNi2euevHiFzltxRNI2RZQ/7F9pnHSoTakwgz5mIfN1kIsDmsu34HvOe18vCT8vswGSQ4xx7g6G3vza1mxG/Ctnj+j0KBvDg=="
hello
```

The string "hello" was returned by the application.

Finally, you can run the application to deploy your code locally, you will have
to specify a tag for the docker image:

```
ruby ddeployer -t 0.1.1
```
