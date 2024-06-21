Install
---------

```
sudo mkdir cd ~/docker-registry
cd ~/docker-registry
sudo curl -o docker-compose.yaml https://raw.githubusercontent.com/WildePizza/docker-registry/HEAD/docker-compose.yaml
sudo docker compose up -d
```

Stop
---------

```
sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=registry --format="{{.ID}}"))
```
