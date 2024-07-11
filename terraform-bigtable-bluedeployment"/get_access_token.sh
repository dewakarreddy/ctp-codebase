#!/bin/bash
# Fetch the access token
token=$(gcloud auth application-default print-access-token)

# Output the token in JSON format
echo "{\"token\": \"$token\"}"
