#!/bin/bash -x
IMAGE=$(grep IMAGE Dockerfile | awk '{print $3}')
docker build -t ${IMAGE} .
