# TFE PoC

## Description
This demo deploys two servers in AWS, with a load balancer and certain ports open. There is a webserver listening for requests on port 2299.

### Simple Deployment

- Open TFE
- Create workspace
- Set env variables:
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION
```

Afterwards:

```
curl PUBLIC_IP:2299
ssh -i KEY_NAME ubuntu@PUBLIC_IP
curl LOAD_BALANCER:2299
exit
# Might take some time for load balancer dns to propagate
curl LOAD_BALANCER:299
```

### Sentinel
Open Sentinel folder in this repository for instructions