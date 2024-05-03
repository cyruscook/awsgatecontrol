#!/bin/bash

cd "$(dirname "$0")"

rm -f lambda_deployment.zip

zip lambda_deployment.zip lambda_function.py
