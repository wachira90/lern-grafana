# เปิด public  แบบ specific dashboard

หากคุณไม่ต้องการเปิดให้เข้าถึงทั้งระบบ แต่ต้องการแชร์แค่ **"บาง Dashboard"** เท่านั้น ใน Grafana จะมีวิธีจัดการหลักๆ 3 วิธีที่นิยมใช้ (แนะนำวิธีที่ 1)

---

### วิธีที่ 1: ฟีเจอร์ "Public Dashboards" (แนะนำ 🌟)

*รองรับตั้งแต่ Grafana 10 ขึ้นไป (บางฟีเจอร์ทดลองมีตั้งแต่เวอร์ชัน 9)*
ฟีเจอร์นี้ถูกสร้างมาเพื่อตอบโจทย์นี้โดยเฉพาะ คุณสามารถสร้าง URL เดี่ยวๆ สำหรับแชร์ Dashboard นั้นๆ สู่สาธารณะได้เลย โดยที่ระบบหลักยังคงต้อง Login อยู่

**1. เปิดการใช้งานในไฟล์ `grafana.ini**`
เพิ่มหรือแก้ไขหัวข้อ `[public_dashboards]`

```ini
[public_dashboards]
# เปิดใช้งานฟีเจอร์ Public Dashboards
enabled = true

```

*(ถ้าใช้ Docker ให้เพิ่ม Environment: `GF_PUBLIC_DASHBOARDS_ENABLED=true`)*

**2. การสร้าง Link จากหน้า UI**

* หลังจาก Restart Grafana ให้เข้าไปที่ Dashboard ที่ต้องการแชร์
* กดปุ่ม **Share** (ไอคอนมุมขวาบน)
* จะมี Tab ใหม่ชื่อ **"Public dashboard"** ปรากฏขึ้นมา
* ติ๊กเลือกการตั้งค่า แล้วกดปุ่ม **Create public dashboard**
* คุณจะได้ Link เฉพาะกิจที่ส่งให้ใครดูก็ได้ โดยคนภายนอกจะเห็นแค่ Dashboard นี้เท่านั้น (ไม่สามารถกด Browse ไปดู Dashboard อื่นได้)

---

### วิธีที่ 2: สร้าง Organization แยกเฉพาะ (วิธีคลาสสิก)

*ใช้ได้กับ Grafana ทุกเวอร์ชัน*
ในกรณีที่คุณใช้ Grafana เวอร์ชันเก่า หรือต้องการจัดกลุ่ม Dashboard สำหรับ Public โดยเฉพาะ

**1. สร้าง Organization ใหม่**

* เข้า Grafana ด้วยสิทธิ์ Admin
* ไปที่เมนู **Administration** > **Organizations** > สร้าง Org ใหม่ เช่นตั้งชื่อว่า `Public View`
* นำเฉพาะ Dashboard ที่ต้องการให้คนนอกเห็น ไปสร้างหรือ Import ไว้ใน Organization นี้

**2. ตั้งค่า Anonymous ชี้ไปที่ Org ใหม่**
แก้ไขไฟล์ `grafana.ini` โดยเปลี่ยนชื่อ `org_name` ให้ตรงกับที่เราสร้างไว้:

```ini
[auth.anonymous]
enabled = true
org_name = Public View
org_role = Viewer

```

วิธีนี้คนภายนอกที่ไม่ได้ Login จะเข้าถึงได้เฉพาะ Dashboard ที่อยู่ในกลุ่ม `Public View` เท่านั้น จะไม่เห็นข้อมูลของ Main Org. 

---

### วิธีที่ 3: แชร์แบบ Snapshot (ข้อมูลภาพนิ่ง)

หากคุณแค่ต้องการแชร์ข้อมูล ณ **"ช่วงเวลานั้นๆ"** (ไม่ต้องอัปเดตแบบ Real-time) ไม่จำเป็นต้องแก้ไฟล์ตั้งค่าใดๆ เลย

* เข้าไปที่ Dashboard ที่ต้องการ > กดปุ่ม **Share** > เลือก Tab **Snapshot**
* เลือกว่าจะแชร์ผ่านเซิร์ฟเวอร์ของคุณเอง (Local) หรือฝากไว้ที่ `snapshots.raintank.io`
* กดปุ่ม **Publish Snapshot**
* คุณจะได้ Link สาธารณะ ส่งให้ใครดูก็ได้ (ข้อมูลจะนิ่งอยู่ที่เวลาที่คุณกดสร้าง Snapshot และจะหมดอายุตามเวลาที่คุณตั้งไว้)
