#!/bin/bash

root_password=$1
using_kubernetes=true

sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir registry auth
if [ "$using_kubernetes" = true ]; then
  kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docker-registry
  template:
    metadata:
      labels:
        app: docker-registry
    spec:
      containers:
      - name: docker-registry
        image: registry:2.7
        ports:
        - containerPort: 5000
        volumeMounts:
        - name: auth-volume
          mountPath: /auth
        - name: registry-data
          mountPath: /var/lib/registry
      volumes:
      - name: auth-volume
        hostPath:
          path: ./auth
      - name: registry-data
        hostPath:
          path: $(pwd)/registry
EOF
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: docker-registry
spec:
  selector:
    app: docker-registry
  ports:
  - protocol: TCP
    port: 5000
    targetPort: 5000
EOF
  kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-registry-ui
  namespace: registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docker-registry-ui
  template:
    metadata:
      labels:
        app: docker-registry-ui
    spec:
      containers:
      - name: docker-registry-ui
        image: konradkleine/docker-registry-frontend:v2
        ports:
        - containerPort: 80
        env:
        - name: ENV_DOCKER_REGISTRY_HOST
          value: docker-registry
        - name: ENV_DOCKER_REGISTRY_PORT
          value: "5000"
      restartPolicy: Always
EOF
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: docker-registry-ui
spec:
  selector:
    app: docker-registry-ui
  ports:
  - protocol: TCP
  port: 80
  targetPort: 80
EOF
else
  sudo docker network create registry
  sudo docker run -d -p 5000:5000 --restart=always --name docker-registry --network registry \
    -v ./auth:/auth \
    -v $(pwd)/registry:/var/lib/registry \
    registry:2.7
  sudo docker run -p 8080:80 --name docker-registry-ui --network registry \
    -d --restart=always \
    -e ENV_DOCKER_REGISTRY_HOST=docker-registry \
    -e ENV_DOCKER_REGISTRY_PORT=5000 \
    konradkleine/docker-registry-frontend:v2
fi
