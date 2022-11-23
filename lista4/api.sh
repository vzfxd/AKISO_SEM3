#!/bin/bash

joke=$(curl https://api.chucknorris.io/jokes/random | jq -r '.value')
url=$(curl https://api.thecatapi.com/v1/images/search | jq -r '.[].url')
curl ${url} > ~/Obrazy/image.png

echo "$(catimg -H 100 ~/Obrazy/image.png)"
echo "${joke}"
