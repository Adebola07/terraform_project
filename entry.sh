#!/bin/bash
sudo apt-get update && sudo apt  install docker.io && sudo chown root:ubuntu /var/run/docker.sock
docker run -p 8080:80 nginx