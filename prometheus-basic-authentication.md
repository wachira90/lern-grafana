# เพื่อตั้งค่าการยืนยันตัวตนแบบพื้นฐาน (Basic Authentication) 

สำหรับ Prometheus ในสภาพแวดล้อม Docker Compose คุณต้องใช้ไฟล์กำหนดค่าเว็บ (Web Configuration) แยกต่างหากครับ ตั้งแต่เวอร์ชัน 2.24.0 เป็นต้นมา Prometheus จะไม่จัดการ basic auth โดยตรงในไฟล์ `prometheus.yml` หลักอีกต่อไป แต่จะเปลี่ยนไปใช้แฟล็ก `--web.config.file` แทน

นี่คือขั้นตอนการตั้งค่าอย่างละเอียดครับ:

### ขั้นตอนที่ 1: สร้าง Bcrypt Password Hash

Prometheus กำหนดให้รหัสผ่านต้องถูกเข้ารหัสแฮชด้วย **bcrypt** เท่านั้น (ไม่สามารถใช้ข้อความธรรมดาได้) คุณสามารถสร้างแฮช bcrypt ได้ง่ายๆ โดยใช้ Docker คอนเทนเนอร์แบบชั่วคราวร่วมกับเครื่องมือ `htpasswd`

รันคำสั่งนี้ในเทอร์มินัลของคุณ:

```bash
docker run --rm -it httpd:alpine htpasswd -nB admin

```

*ระบบจะให้คุณพิมพ์รหัสผ่านที่ต้องการ (หรือคุณสามารถระบุรหัสผ่านลงในคำสั่งได้เลย) ผลลัพธ์ที่ได้ออกมาจะมีหน้าตาประมาณนี้ครับ:*
`admin:$2y$05$xxxxxxxxxxxxxxxxxxxxxxxxxxxx`

ให้คุณคัดลอกข้อความผลลัพธ์นี้ไว้**ทั้งหมด**ครับ

### ขั้นตอนที่ 2: สร้างไฟล์ Web Config (`web-config.yml`)

สร้างไฟล์ชื่อ `web-config.yml` ในโฟลเดอร์โปรเจกต์ของคุณ ไฟล์นี้จะทำหน้าที่บอก Prometheus ว่าจะอนุญาตให้ชื่อผู้ใช้และรหัสผ่าน (ที่แฮชแล้ว) ใดบ้างเข้าใช้งานได้

```yaml
# web-config.yml
basic_auth_users:
  # ชื่อผู้ใช้คือ 'admin' ให้นำ Hash ที่ก๊อปปี้ไว้มาวางด้านล่างนี้
  admin: '$2y$05$xxxxxxxxxxxxxxxxxxxxxxxxxxxx'

```

### ขั้นตอนที่ 3: สร้างไฟล์คอนฟิกหลักของ Prometheus (`prometheus.yml`)

สร้างไฟล์ตั้งค่ามาตรฐานของ Prometheus ในโฟลเดอร์เดียวกัน นี่คือตัวอย่างพื้นฐานที่สั่งให้ Prometheus ดึงข้อมูล (Scrape) สถานะการทำงานของตัวมันเอง:

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

```

### ขั้นตอนที่ 4: สร้างไฟล์ `docker-compose.yml`

ทีนี้มาตั้งค่าไฟล์ `docker-compose.yml` กันครับ จุดสำคัญอยู่ที่การเมานท์ (Mount) ไฟล์ `web-config.yml` เข้าไป และการเพิ่มคำสั่ง `--web.config.file` ในส่วน `command` ของคอนเทนเนอร์

```yaml
# docker-compose.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      # เมานท์ไฟล์การตั้งค่าต่างๆ เข้าไปในคอนเทนเนอร์
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./web-config.yml:/etc/prometheus/web-config.yml
      # เมานท์วอลุ่มสำหรับจัดเก็บข้อมูลไม่ให้หายไปเมื่อปิดคอนเทนเนอร์
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      # เปิดใช้งานไฟล์ web config เพื่อทำ Basic Auth
      - '--web.config.file=/etc/prometheus/web-config.yml'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    restart: unless-stopped

volumes:
  prometheus_data:

```

### ขั้นตอนที่ 5: เริ่มการทำงาน Prometheus

เมื่อคุณมีไฟล์ทั้ง 3 ไฟล์ (`web-config.yml`, `prometheus.yml`, และ `docker-compose.yml`) อยู่ในโฟลเดอร์เดียวกันเรียบร้อยแล้ว ให้รันคำสั่งเพื่อเปิดใช้งานคอนเทนเนอร์:

```bash
docker-compose up -d

```

จากนั้นให้เข้าไปที่ `http://localhost:9090` ผ่านเบราว์เซอร์ของคุณ คุณจะพบกับหน้าต่างแจ้งเตือนให้กรอกชื่อผู้ใช้ (ในที่นี้คือ `admin`) และรหัสผ่านที่คุณได้สร้างไว้ในขั้นตอนที่ 1 ครับ

---

คุณต้องการให้ผมแสดงวิธีส่งค่ารหัสผ่านแฮชนี้ให้ปลอดภัยยิ่งขึ้นโดยใช้ **Docker Secrets** หรือ **Environment Variables** (ตัวแปรสภาพแวดล้อม) แทนการเขียนฝังลงไปในไฟล์ YAML ตรงๆ ไหมครับ?
