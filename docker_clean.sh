#!/bin/sh

docker container prune -f ; docker image prune -f ; docker volume prune -f
