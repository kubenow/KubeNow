---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: {{name}}
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: {{storage}}
{% if storageClassName is defined %}
  storageClassName: {{ storageClassName }}
{% endif %}
