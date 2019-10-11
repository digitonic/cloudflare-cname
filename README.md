This Docker image is being used by the Codefresh Helm step.

To purpose of this step is to get the service load balancer and create a cname with the name of the branch in cloudflare.


Locally you can run ```bash pipeline``` to build the new image.

Or singularly the commands:
```bash build```
```bash push```

Note that to deploy to codefresh you need to have 
codefresh cli installed
```bash deploy```