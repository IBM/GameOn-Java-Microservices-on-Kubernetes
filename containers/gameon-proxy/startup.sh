#!/bin/bash

# Configure our link to etcd based on shared volume with secret
if [ ! -z "$ETCD_SECRET" ]; then
  . /data/primordial/setup.etcd.sh /data/primordial $ETCD_SECRET
fi

export A8_SERVICE=proxy

if [ "$ETCDCTL_ENDPOINT" != "" ]; then
  if [ "$PROXY_CONFIG" == "" ]; then
    PROXY_CONFIG=/etc/haproxy/haproxy.cfg
  fi
  echo Setting up etcd...
  echo "** Testing etcd is accessible"
  etcdctl --debug ls
  RC=$?

  while [ $RC -ne 0 ]; do
      sleep 15

      # recheck condition
      echo "** Re-testing etcd connection"
      etcdctl --debug ls
      RC=$?
  done
  echo "etcdctl returned sucessfully, continuing"

  echo "Using config file $PROXY_CONFIG"

  etcdctl get /proxy/third-party-ssl-cert > /etc/ssl/proxy.pem
  sed -i s/PLACEHOLDER_PASSWORD/$(etcdctl get /passwords/admin-password)/g /etc/haproxy/haproxy.cfg
  sed -i s/PLACEHOLDER_DOCKERHOST/$(etcdctl get /proxy/docker-host)/g /etc/haproxy/haproxy.cfg
  sed -i s/PLACEHOLDER_LOGHOST/$(etcdctl get /logstash/endpoint)/g /etc/haproxy/haproxy.cfg

  export AUTH_ENDPOINT=$(etcdctl get /endpoints/auth)
  export ROOM_ENDPOINT=$(etcdctl get /endpoints/room)
  export MAP_ENDPOINT=$(etcdctl get /endpoints/map)
  export MEDIATOR_ENDPOINT=$(etcdctl get /endpoints/mediator)
  export PLAYER_ENDPOINT=$(etcdctl get /endpoints/player)
  export WEBAPP_ENDPOINT=$(etcdctl get /endpoints/webapp)
  export SWAGGER_ENDPOINT=$(etcdctl get /endpoints/swagger)
  export SLACKIN_ENDPOINT=$(etcdctl get /endpoints/slackin)
  export A8_REGISTRY_URL=$(etcdctl get /amalgam8/registryUrl)
  export A8_CONTROLLER_URL=$(etcdctl get /amalgam8/controllerUrl)
  export A8_CONTROLLER_POLL=$(etcdctl get /amalgam8/controllerPoll)
  JWT=$(etcdctl get /amalgam8/jwt)

  sudo service rsyslog start

  echo Starting haproxy...
  if [ -z "$A8_REGISTRY_URL" ]; then
    #no a8, just run haproxy.
    haproxy -f $PROXY_CONFIG
  else
    #a8, configure security, and run via sidecar.
    if [ ! -z "$JWT" ]; then
      export A8_REGISTRY_TOKEN=$JWT
      export A8_CONTROLLER_TOKEN=$JWT
    fi
    exec a8sidecar --proxy haproxy -f $PROXY_CONFIG
  fi
  echo HAProxy shut down
else
  echo HAProxy will log to STDOUT--this is dev environment.
  sed -i s/PLACEHOLDER_PASSWORD/$ADMIN_PASSWORD/g /etc/haproxy/haproxy-dev.cfg
  exec a8sidecar --proxy haproxy -f /etc/haproxy/haproxy-dev.cfg
fi
