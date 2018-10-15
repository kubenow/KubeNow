---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: {{claim_name}}
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: {{storage}}
{% if storageClassName is defined %}
  storageClassName: {{ storageClassName }}
{% endif %}
