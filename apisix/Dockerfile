FROM apache/apisix:3.18.0-debian

COPY config.yaml /usr/local/apisix/conf/config.yaml
COPY apisix.yaml /usr/local/apisix/conf/apisix.yaml
COPY plugins/app-auth.lua /usr/local/apisix/apisix/plugins/app-auth.lua
