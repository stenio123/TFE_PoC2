# PoC Example

## Simple Deployment

Execute:
```
terraform init
terraform plan
terraform apply
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