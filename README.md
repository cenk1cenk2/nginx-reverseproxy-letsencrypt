```
name:         | nginx-reverseproxy+letsencrypt
compiler:     | docker-compose
version:      | v2.3, 201900315
```

## Description:

Reverse Proxy setup with "Nginx" in Docker Container. It has also "LetsEncrypt" SSL certification with auto-renewal integrated. `init-letsencrypt.sh` must be manually added and run outside the container for initial certification setup.

## Setup

1. `chmod +x init-env.sh && ./init-env.sh`
2. `nano .env`
3. `chmod +x init-letsencrypt.sh && ./init-letsencrypt.sh`