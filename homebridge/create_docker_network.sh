
# Create docker network which services which want to be discovered by traefik should be a member of
docker network create --driver bridge --subnet=172.32.0.0/16 traefik-backend