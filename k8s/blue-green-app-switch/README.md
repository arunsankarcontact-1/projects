# Blue/Green Helm Chart

This chart deploys two versions of the app (`blue`, `green`) and switches traffic using a single Service controlled by `activeColor`.

---

## Build & Push Images

```bash
docker build -t aruns14/appbluegreen:blue-1.0.0 --build-arg COLOR=blue .
docker push aruns14/appbluegreen:blue-1.0.0

docker build -t aruns14/appbluegreen:green-1.0.0 --build-arg COLOR=green .
docker push aruns14/appbluegreen:green-1.0.0

## Blue/Green deployment and verification

# Deploy with activeColor blue

```bash
helm upgrade --install app ./chart -n demo --create-namespace --set activeColor=blue

#verification
curl http://10.43.238.11/version

#Switch to activeColor green

helm upgrade app ./chart -n demo --set activeColor=green

#verification
curl http://10.43.238.11/version

#Switch back to activeColor blue
helm upgrade app ./chart -n demo --set activeColor=blue


##Readiness and Liveness probe failure steps

helm upgrade app -n demo ./chart   --set readinessProbe.httpGet.path=/Wronghealth   --set livenessProbe.httpGet.path=/Wronghealth

#The new pods created will fail, old pods remain unaffected due to rolling update mechanism.Hence, these replica sets needs to be reduced to 0 to test the health check failures.

sudo kubectl scale rs app-blue-86d5df5d9b -n demo --replicas=0
sudo kubectl scale rs app-green-577cd4ff6b -n demo --replicas=0


#verification
curl http://10.43.238.11/health

#Revert health check path and verify

helm upgrade app -n demo ./chart   --set readinessProbe.httpGet.path=/health   --set livenessProbe.httpGet.path=/health
