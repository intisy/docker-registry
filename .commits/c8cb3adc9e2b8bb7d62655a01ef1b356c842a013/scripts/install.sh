#!/bin/bash

sha=$1
root_password=$2
using_kubernetes=true
using_ui=true
gererate_password=false

generate_secure_password() {
  if ! command -v openssl &> /dev/null; then
    echo "Error: OpenSSL not found. Secure password generation unavailable."
    return 1
  fi
  length=20
  password=$(openssl rand -base64 $length | tr -dc 'A-Za-z0-9')
}
wait_until_ready() {
  url=$1
  substring1="The requested URL returned error"
  substring2="Could not resolve host: raw.githubusercontent.com"
  echo "Executing: $url"
  output=$(curl -fsSL $url 2>&1)
  if [[ $output =~ $substring1 || $output =~ $substring2 ]]; then
    sleep 1
    wait_until_ready
  fi
}
wait_until_ready https://raw.githubusercontent.com/WildePizza/docker-registry/HEAD/.commits/$sha/scripts/deinstall.sh
curl -fsSL https://raw.githubusercontent.com/WildePizza/docker-registry/HEAD/.commits/$sha/scripts/deinstall.sh | bash -s
if [ ! -n "$root_password" ]; then
  if [ "$gererate_password" = true ]; then
    generate_secure_password
    root_password=$password
  else
    root_password=root
  fi
fi
echo "|-- User info: --|"
echo "  Username: root"
echo "  Password: $root_password"
echo "|----------------|"
sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo mkdir data auth
sudo docker run \
  --entrypoint htpasswd \
  httpd:2 -Bbn root $root_password | sudo tee ./auth/htpasswd
if [ "$using_kubernetes" = true ]; then
  kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: docker-registry-data-pv
spec:
  capacity:
    storage: 1500Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  claimRef:
    namespace: default
    name: docker-registry-data-pv-claim
  storageClassName: local-storage
  local:
    path: "$(pwd)/data"
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - blizzity2
OEF
  kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: docker-registry-auth-pv
spec:
  capacity:
    storage: 1500Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  claimRef:
    namespace: default
    name: docker-registry-auth-pv-claim
  storageClassName: local-storage
  local:
    path: "$(pwd)/auth"
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - blizzity2
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
      restartPolicy: Always
      containers:
      - name: docker-registry
        image: registry:latest
        ports:
        - containerPort: 718
        env:
        - name: REGISTRY_HTTP_HEADERS_Access-Control-Allow-Origin
          value: "http://docker-registry-ui:719"
        - name: REGISTRY_HTTP_HEADERS_Access-Control-Allow-Methods
          value: "HEAD,GET,OPTIONS,DELETE"
        - name: REGISTRY_HTTP_HEADERS_Access-Control-Allow-Credentials
          value: "true"
        - name: REGISTRY_HTTP_HEADERS_Access-Control-Allow-Headers
          value: "Authorization,Accept,Cache-Control"
        - name: REGISTRY_HTTP_HEADERS_Access-Control-Expose-Headers
          value: "Docker-Content-Digest"
        - name: REGISTRY_STORAGE_DELETE_ENABLED
          value: "true"
        - name: REGISTRY_AUTH
          value: "htpasswd"
        - name: REGISTRY_AUTH_HTPASSWD_REALM
          value: "Registry Realm"
        - name: REGISTRY_AUTH_HTPASSWD_PATH
          value: "/auth/htpasswd"
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
  type: LoadBalancer
  selector:
    app: docker-registry
  ports:
  - protocol: TCP
    port: 718
    targetPort: 5000
EOF
  
  if [ "$using_ui" = true ]; then
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-registry-ui
  labels:
    app: docker-registry-ui
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
        image: joxit/docker-registry-ui:main
        ports:
        - containerPort: 80
        env:
        - name: REGISTRY_URL
          value: "http://docker-registry:718"
      restartPolicy: Always
EOF
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: docker-registry-ui
  labels:
    app: docker-registry-ui
spec:
  type: LoadBalancer
  selector:
    app: docker-registry-ui
  ports:
  - protocol: TCP
    port: 719
    targetPort: 80
EOF
  fi
  echo "waiting for registry to be ready..." >&2
  while [ $(kubectl get deployment docker-registry | grep -c "1/1") != "1" ]; do
      sleep 1
  done
else
  sudo docker network create registry
  sudo docker run -d -p 718:718 --restart=always --name docker-registry --network registry \
    -v ./auth:/auth \
    -v $(pwd)/registry:/var/lib/registry \
    registry:2.7
  if [ "$using_ui" = true ]; then
    sudo docker run -p 8080:80 --name docker-registry-ui --network registry \
      -d --restart=always \
      -e ENV_DOCKER_REGISTRY_HOST=docker-registry \
      -e ENV_DOCKER_REGISTRY_PORT=718 \
      konradkleine/docker-registry-frontend:v2
  fi
fi
