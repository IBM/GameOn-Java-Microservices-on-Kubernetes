# Generate Keystore
Dockerfile pulls from ibmjava image.
```
FROM ibmjava
COPY gen-keystore.sh /tmp/gen-keystore.sh
WORKDIR /tmp
CMD bash ./gen-keystore.sh ${IP}
```

The provided script `gen-keystore.sh` generates a certificate for the app and requires an IP address as input. You will need to set an environment variable `IP` in your yaml file for creating the Pod.

Example:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: setup
  labels:
    app: gameon
    tier: setup
spec:
  restartPolicy: Never
  containers:
  - name: setup
    image: anthonyamanse/keystore # Replace this to your image name
    env:
      - name: IP
        value: '169.47.241.213' # Replace this to your cluster's IP address
    volumeMounts:
    - name: keystore
      mountPath: /tmp/keystore/
  volumes:
  - name: keystore
    persistentVolumeClaim:
      claimName: keystore-claim
```