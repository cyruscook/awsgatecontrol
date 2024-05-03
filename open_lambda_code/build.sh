#!/bin/bash

cd "$(dirname "$0")"

rm -f lambda_deployment.zip

rm -rf ./package
mkdir -p ./package

pip install --target ./package -r requirements.txt

cd package
zip -r ../lambda_deployment.zip .

cd ..
zip lambda_deployment.zip lambda_function.py
