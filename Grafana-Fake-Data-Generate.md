# Grafana Fake Datagenerate

Docker image `grafana/fake-data-gen:1d3f34ac420823deed405fd1df2ea3bd92f636a0` เป็น image สำหรับ **สร้างข้อมูลจำลอง (fake metrics/logs)** เพื่อใช้ทดสอบ Grafana, Prometheus หรือระบบ monitoring ต่าง ๆ

ด้านล่างคือวิธีใช้งานพื้นฐาน 👇

---

## 🔹 1. Pull Image

```bash
docker pull grafana/fake-data-gen:1d3f34ac420823deed405fd1df2ea3bd92f636a0
```

---

## 🔹 2. Run แบบง่ายที่สุด

```bash
docker run -d \
  --name fake-data-gen \
  -p 8080:8080 \
  grafana/fake-data-gen:1d3f34ac420823deed405fd1df2ea3bd92f636a0
```

หลังจากรันแล้ว service จะเปิดที่:

```
http://localhost:8080
```

---

## 🔹 3. ใช้ร่วมกับ Prometheus

ตัว fake-data-gen จะ expose metrics endpoint (เช่น `/metrics`) ให้ Prometheus scrape ได้

### ตัวอย่าง prometheus.yml

```yaml
scrape_configs:
  - job_name: 'fake-data'
    static_configs:
      - targets: ['fake-data-gen:8080']
```

ถ้าใช้ docker-compose ควรให้อยู่ network เดียวกัน

---

## 🔹 4. ตัวอย่าง docker-compose.yml

```yaml
version: '3.8'

services:
  fake-data:
    image: grafana/fake-data-gen:1d3f34ac420823deed405fd1df2ea3bd92f636a0
    container_name: fake-data-gen
    ports:
      - "8080:8080"
    restart: unless-stopped
```

รันด้วย:

```bash
docker-compose up -d
```

---

## 🔹 5. Environment Variables (ถ้ามี config เพิ่ม)

บางเวอร์ชันรองรับการปรับพฤติกรรมผ่าน ENV เช่น:

```bash
-e LOG_LEVEL=debug
-e METRICS_PORT=8080
```

ตรวจสอบ option เพิ่มเติมได้ด้วย:

```bash
docker run --rm grafana/fake-data-gen:1d3f34ac420823deed405fd1df2ea3bd92f636a0 --help
```

---

## 🔹 6. ตรวจสอบ Container

```bash
docker logs -f fake-data-gen
docker ps
```

---

# 🎯 Use Case ที่พบบ่อย

* ทดสอบ dashboard ใน Grafana
* ทดสอบ alert rule
* Demo ระบบ monitoring
* Load test metric pipeline

---

ถ้าคุณจะใช้กับ stack แบบไหน เช่น:

* Prometheus + Grafana
* Mimir
* Loki
* Kubernetes

บอกผมได้เลย เดี๋ยวจัดตัวอย่าง config ให้เหมาะกับ environment DevOps/SRE ของคุณ 👍
