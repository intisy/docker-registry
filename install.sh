#!/bin/bash

root_password=$1
using_kubernetes=true

sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir registry auth
if [ "$using_kubernetes" = true ]; then
  kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: docker-registry-data-pv
spec:
  capacity:
    storage: 1500Gi
  accessModes:
    - ReadWriteOnce
  nfs:
    server: $(hostname -I | awk {'print $1'})
    path: /exports/documents
  persistentVolumeReclaimPolicy: Recycle
OEF
  kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: docker-registry-auth-pv
spec:
  capacity:
    storage: 1500Gi
  accessModes:
    - ReadWriteOnce
  nfs:
    server: $(hostname -I | awk {'print $1'})
    path: /exports/documents
  persistentVolumeReclaimPolicy: Recycle
OEF
  kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: docker-registry-data-pv-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1500Gi
EOF
  kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: docker-registry-auth-pv-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1500Gi
EOF
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
        - name: docker-registry-auth-pv
          mountPath: /auth
        - name: docker-registry-data-pv
          mountPath: /var/lib/registry
      volumes:
      - name: docker-registry-auth-pv
        persistentVolumeClaim:
          claimName: docker-registry-auth-pv-claim
      - name: docker-registry-data-pv
        persistentVolumeClaim:
          claimName: docker-registry-data-pv-claim
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
