#!/bin/bash

for i in {1..100}; do
  kubectl exec deploy/redis -- redis-cli LPUSH myqueue "job-$i"
done
