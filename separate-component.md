## ASK:

การตั้งค่าใน prometheus และ node_exporter เพื่อเก็บค่า ใน namespace "myapp" และ จะมีค่าย่อย  เช่น  "backend"  , "frontend", "database"  ต้อง ตั้งค่า ใน prometheus และ node_exporter อย่างไร


สรุปสั้น ๆ: “namespace / component” แบบที่ต้องการ ควรใส่เป็น **labels ตอนสcrapeฝั่ง Prometheus** (ไม่ใช่ไปปรับใน node\_exporter) แล้วทุก metric ที่ดึงจาก target นั้นจะติด labels เหล่านั้นมาอัตโนมัติ

ต่อไปนี้คือวิธีทำในสถานการณ์ยอดนิยม 3 แบบ

---

# 1) Static targets (VM/เบอร์โลหะ/บนเครื่องธรรมดา)

`prometheus.yml`

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: node_exporter
    static_configs:
      - targets: ['10.0.1.10:9100']   # backend
        labels:
          namespace: myapp
          component: backend
          env: prod
      - targets: ['10.0.1.11:9100']   # frontend
        labels:
          namespace: myapp
          component: frontend
          env: prod
      - targets: ['10.0.1.12:9100']   # database
        labels:
          namespace: myapp
          component: database
          env: prod
```

> ไม่ต้องทำอะไรเพิ่มใน `node_exporter` แค่รันปกติ เช่น `node_exporter --web.listen-address=:9100` ก็พอแล้ว

**ตัวอย่าง Query**

```promql
# CPU ไม่รวม idle ของ myapp แยกตาม component
sum by (component) (rate(node_cpu_seconds_total{namespace="myapp",mode!="idle"}[5m]))
```

---

# 2) ใช้ relabeling เพื่อ "จับ" component จากชื่อโฮสต์/โดเมน

ถ้าตั้งชื่อ DNS ไว้ดี เช่น `backend-1.myapp.example.com:9100`, `frontend-1.myapp.example.com:9100` ฯลฯ

```yaml
scrape_configs:
  - job_name: node_exporter
    static_configs:
      - targets:
          - 'backend-1.myapp.example.com:9100'
          - 'frontend-1.myapp.example.com:9100'
          - 'database-1.myapp.example.com:9100'
    relabel_configs:
      # ใส่ namespace คงที่
      - target_label: namespace
        replacement: myapp
      # ดึงคำว่า backend/frontend/database จากชื่อโฮสต์ด้านหน้า
      - source_labels: [__address__]
        regex: '([^\.]+)-\d+\.myapp\.example\.com:9100'
        target_label: component
        replacement: '$1'
```

---

# 3) บน Kubernetes (แนะนำให้ติด labels ที่ Pod/Service แล้ว map มาเป็น metric labels)

แนวคิด: ให้ Workload ติด labels เช่น:

```yaml
labels:
  app: myapp
  component: backend|frontend|database
```

### 3.1 ถ้าใช้ Prometheus Operator + ServiceMonitor

ตัวอย่าง ServiceMonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp-nodeexporter
  labels:
    release: kube-prometheus-stack
spec:
  selector:
    matchLabels:
      app: node-exporter
  namespaceSelector:
    any: true
  endpoints:
    - port: metrics
      interval: 15s
      relabelings:
        - action: replace
          targetLabel: namespace
          replacement: myapp
        - action: replace
          sourceLabels: [__meta_kubernetes_pod_label_component]
          targetLabel: component
```

> หมายเหตุ: ปกติ `node-exporter` เป็น DaemonSet ของ infra ไม่ผูกกับ “backend/frontend/database” โดยตรง ถ้าอยากได้ component แบบแอปจริง ๆ ให้ติด labels ที่ **Pods/Services ของแอป** แล้ว scrape ตรงนั้น (เช่น exporter หรือ app metrics เอง) ส่วน `node_exporter` มักใช้ label เป็น `role=node` หรือ `cluster` มากกว่า

### 3.2 ถ้าไม่ใช้ Operator (prometheus vanilla + kubernetes\_sd\_configs)

```yaml
scrape_configs:
  - job_name: 'k8s-node-exporter'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - action: keep
        source_labels: [__meta_kubernetes_pod_label_app]
        regex: node-exporter
      - target_label: namespace
        replacement: myapp
      - action: replace
        source_labels: [__meta_kubernetes_pod_label_component]
        target_label: component
```

---

# แล้วต้องทำอะไรใน `node_exporter` ไหม?

* **ส่วนใหญ่ไม่ต้อง**: metric ของ `node_exporter` จะติด labels ที่ Prometheus ใส่ให้ตอนสcrape ตามตัวอย่างด้านบน
* ทางเลือกขั้นสูง: ถ้าอยาก “ฝัง” label จากฝั่ง agent เองกับ metric เฉพาะบางตัว สามารถใช้ **textfile collector** ของ `node_exporter` สร้าง metric เล็ก ๆ สำหรับบอก context ได้ เช่น

บนเครื่อง target สร้างไฟล์:

```
/var/lib/node_exporter/textfile/myapp_info.prom
```

ภายใน:

```
myapp_target_info{namespace="myapp",component="backend"} 1
```

แล้วรัน `node_exporter --collector.textfile.directory=/var/lib/node_exporter/textfile`

> ข้อดี: มี metric สำหรับ join/อ้างอิง แต่ **metric อื่น ๆ** ของ `node_exporter` ก็ยังพึ่ง labels ฝั่ง Prometheus อยู่ดี

---

# ตัวอย่าง PromQL เพิ่มเติม

รวม RAM ใช้จริงต่อ component:

```promql
sum by (component) (
  node_memory_MemTotal_bytes{namespace="myapp"}
- node_memory_MemAvailable_bytes{namespace="myapp"}
)
```

ดูกี่เครื่องต่อ component:

```promql
count by (component) (up{job="node_exporter", namespace="myapp"})
```

---

# สรุปแนวปฏิบัติที่แนะนำ

1. กำหนด `namespace=myapp` และ `component=backend|frontend|database` เป็น **labels ใน `scrape_configs`** (static หรือผ่าน relabel)
2. ถ้าเป็น Kubernetes ให้ใช้ labels ของ Pod/Service แล้ว map มาเป็น metric labels ด้วย `relabelings`/`ServiceMonitor`
3. `node_exporter` ไม่ต้องแก้ config เป็นพิเศษ เว้นแต่ต้องการเสริม context ผ่าน **textfile collector**

ถ้าบอกสภาพแวดล้อมที่ใช้อยู่ (VM, Docker, K8s, Operator/ไม่ใช้ Operator) ผมจะจัดให้เป็นไฟล์ config ที่พร้อมใช้ได้ทันทีครับ ✅
