Install
---------

```
sudo mkdir ~/docker-registry
cd ~/docker-registry
sudo curl -o docker-compose.yaml https://raw.githubusercontent.com/WildePizza/docker-registry/HEAD/docker-compose.yaml
sudo docker compose up -d
```

Remove
---------

```
sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=registry --format="{{.ID}}"))
sudo rm -r ~/docker-registry
cd $HOME
```
