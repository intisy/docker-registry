#!/bin/bash

sha=$1
using_kubernetes=$2
using_ui=$3
using_docker_ui_test=$4
gererate_password=$5
username=$6
password=$7
using_nfs=$8
local_ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1 | head -n 1)

echo2() {
  echo -e "\033[0;33m$@\033[0m"
}
generate_secure_password() {
  if ! command -v openssl &> /dev/null; then
    echo2 "Error: OpenSSL not found. Secure password generation unavailable."
    return 1
  fi
  length=20
  echo $(openssl rand -base64 $length | tr -dc 'A-Za-z0-9')
}
echo2 "Setting up using options: $@"
curl -fsSL https://raw.githubusercontent.com/WildePizza/docker-registry/HEAD/run.sh | bash -s deinstall
if [ ! -n "$password" ]; then
  if [ "$gererate_password" = true ]; then
    password=$(generate_secure_password)
  else
    password=$username
  fi
  echo2 "Using password: $password"
fi
cd /mnt/data/registry
sudo mkdir data auth config
sudo bash -c "cat > ./config/config.yml << EOF_FILE
version: 0.1
log:
  fields:
    service: registry
storage:
  delete:
    enabled: true
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
    Access-Control-Allow-Origin: ['http://$local_ip:719']
    Access-Control-Allow-Methods: ['HEAD', 'GET', 'OPTIONS', 'DELETE']
    Access-Control-Allow-Headers: ['Authorization', 'Accept']
    Access-Control-Max-Age: [1728000]
    Access-Control-Allow-Credentials: [true]
    Access-Control-Expose-Headers: ['Docker-Content-Digest']
auth:
  htpasswd:
    realm: basic-realm
    path: /registry/auth/htpasswd
EOF_FILE"
sudo docker run \
  --entrypoint htpasswd \
  httpd:2 -Bbn $username $password | sudo tee ./auth/htpasswd
if [ "$using_kubernetes" = true ]; then
  echo2 Setting up Kubernetes Docker registry!
  if [ "$using_nfs" = true ]; then
    kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: docker-registry-pv
spec:
  capacity:
    storage: 1500Gi
  persistentVolumeReclaimPolicy: Delete
  claimRef:
    namespace: default
    name: docker-registry-pv-claim
  storageClassName: local-storage
  local:
    path: "$(pwd)/data"
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.kubernetes.io/control-plane
          operator: In
          values:
          - "true"
OEF
  else
    kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: docker-registry-pv
spec:
  capacity:
    storage: 1500Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  claimRef:
    namespace: default
    name: docker-registry-pv-claim
  nfs:
    server: nfs-server
    path: /data/registry
OEF
  fi
  kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: docker-registry-pv-claim
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
        env:
        - name: REGISTRY_CONFIGURATION_PATH
          value: "/registry/config/"
        ports:
        - containerPort: 718
        volumeMounts:
        - name: docker-registry-pv
          mountPath: /registry
      volumes:
      - name: docker-registry-pv
        persistentVolumeClaim:
          claimName: docker-registry-pv-claim
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
  echo2 "waiting for registry to be ready..." >&2
  while [ $(kubectl get deployment docker-registry | grep -c "1/1") != "1" ]; do
      sleep 1
  done
  if [ "$using_ui" = true ]; then
    if [ "$using_docker_ui_test" = true ]; then
      ui=true
    else
      echo2 Setting up Kubernetes Docker registry ui!
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
          value: "http://$local_ip:718"
        - name: SINGLE_REGISTRY
          value: "true"
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
  fi
else
  echo2 Setting up Docker registry!
  sudo docker run -d -p 718:718 --restart=always --name docker-registry \
    -v ./auth:/auth \
    -v $(pwd)/registry:/var/lib/registry \
    registry:2.7
  if [ "$using_ui" = true ]; then
    ui=true
  fi
fi
if [ "$ui" = true ]; then
  echo2 Setting up Docker registry ui!
  sudo docker run -d \
  --name ui \
  -p 719:80 \
  -e REGISTRY_TITLE="Docker Registry" \
  -e REGISTRY_URL=http://$local_ip:718 \
  -e SINGLE_REGISTRY=true \
  joxit/docker-registry-ui:latest
fi
