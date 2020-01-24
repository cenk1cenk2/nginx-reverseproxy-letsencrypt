```
name:         | nginx-reverseproxy+letsencrypt
compiler:     | docker-compose
version:      | v2.6, 20200124
```

## Description:

Reverse Proxy setup with "Nginx" in Docker Container. It has also "LetsEncrypt" SSL certification with auto-renewal integrated. `init-letsencrypt.sh` must be manually added and run outside the container for initial certification setup. I took this script from another source but unfortunetly do not have the direct link and modified it to suit my needs.

## Setup

### Nginx Configuration
In each domain and subdomain used it must include the www-challenge path published through NGINX.

Inside the http portion of the server, the directory for the challenge of LetsEncrypt must be published as follows.
```
## ssl authentication
location /.well-known/acme-challenge {
    access_log /var/log/nginx/acme_access.log;
    error_log /var/log/nginx/acme_error.log;
    allow all;
    root /var/www/certbot;
}
```
The root folder in the configuration must match with bind mounts in NGINX and CERTBOT containers as well.

### Parameters, Initial Challenge
**Fast Deploy**
* `chmod +x init-env.sh && ./init-env.sh && nano .env`
* `chmod +x init-letsencrypt.sh && ./init-letsencrypt.sh`

> After the parameters are provided inside .env file and initial certificates are obtained through challenge, Docker compose stack can be run.

## Changelog
* v2.6, 20200124
  * Combined the certificates under the domain names. So it will issue a generic certificate with top level domain including all the subdomains and itself in the DNS aliases.
* v2.5, 20200122
  * Added `force_renewal` and `ask_renewal` flags for manual override to renewing certificates to `init-letsencrypt`.
  * Moved `init-letsencrypt` variables to `.env` file.
* v2.4, 20191224
  * Optimized for public version, re-init github.
* v2.3, 20190315
  * Moved included config files into same directory for cleaner docker-compose file.
  * Moved log files to root directory.
  * Added log and configuration files to .gitignore
  * Moved certificate files to root directory of the server for having ease of access in other applications.
  * Relocated the $data_path in init-letsencrypt.sh.
  * Domains are now read through .env file.
  * Moved ssl configuration files from online to build/
  * Created init-env.sh script to initiate .env file.
* v2.2, 20190314
  * Now tracking changes with GitHub's private repositories.
* v2.1, 20190103
  * Fixed : kb, v.2.0, 20181220, Don't forget to cancel SSL and all the required certification in nginx.conf before using the init-letsencrpyt.sh because creating dummy certification does not work as expected.
* v2.0, 20181204
  * Implemented certbot configuration and LetsEncrpyt certificates auto renewal for SSL support.
* v1.0, 20181119
  * Now maintaining changes with changelog. Prior modifications had been done without logging.
