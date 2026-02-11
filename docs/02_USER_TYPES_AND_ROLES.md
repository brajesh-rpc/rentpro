# RentComPro - User Types & Roles

## 4 Types of Users

RentComPro में **4 level** के users होंगे, हर किसी के अलग-अलग permissions और features होंगे।

---

## 1️⃣ Super Admin (आप - Brajesh)

### कौन है?
**Business Owner** - आप खुद

### क्या कर सकते हैं? (Full Control)

#### Dashboard Access
✅ **Complete Overview** - सब कुछ देख सकते हैं
- Total devices deployed
- Active vs inactive devices
- Total revenue (monthly/yearly)
- Pending payments
- All hardware health alerts
- Staff performance metrics

#### Device Management
✅ **Add/Remove Devices** - नए systems add करना या पुराने remove करना
✅ **Device Configuration** - हर device की settings
✅ **Serial Number Tracking** - हर system का unique ID
✅ **Live Hardware Monitoring** - सभी devices का real-time health
✅ **Remote Control** - device को lock/unlock करना

#### Client Management
✅ **Add/Edit Clients** - नए customers को add करना
✅ **Client Details** - name, company, contact, address, documents
✅ **Credit Limit Setting** - कितना pending payment allow करेंगे
✅ **Blacklist Feature** - fraudulent clients को block करना
✅ **Payment History** - पूरा payment record
✅ **Contract Management** - agreements upload करना

#### Staff Management
✅ **Add/Remove Staff** - employees को add/remove करना
✅ **Role Assignment** - staff को permissions देना
✅ **Performance Tracking** - staff ने कितने deliveries/collections किये
✅ **Activity Logs** - staff की activities देखना

#### Financial Management
✅ **Payment Collection Records** - सारे payments की history
✅ **Revenue Reports** - monthly/yearly income reports
✅ **Expense Tracking** - maintenance costs, repairs, etc.
✅ **Profit/Loss Analysis** - business performance देखना
✅ **GST Reports** - tax calculations
✅ **Invoice Generation** - automatic invoices बनाना

#### Hardware Health Dashboard
✅ **All Devices Health Status** - एक जगह सब देखना
✅ **Critical Alerts** - urgent hardware issues
✅ **Maintenance Schedule** - कौन सी device कब service due है
✅ **Temperature Monitoring** - कौन सा system overheat हो रहा है
✅ **Component Life Tracking** - SSD/RAM/HDD life remaining

#### Alerts & Notifications
✅ **Payment Alerts** - overdue payments की notification
✅ **Theft Alerts** - device movement या unauthorized access
✅ **Hardware Failure Alerts** - component failure warnings
✅ **Customer Activity Alerts** - suspicious behavior detection

#### Reports & Analytics
✅ **Complete Business Reports** - सब कुछ
✅ **Client-wise Performance** - कौन सा client अच्छा है
✅ **Device Utilization** - कौन सी device ज्यादा use हो रही है
✅ **Geographic Analysis** - location-wise business data

---

## 2️⃣ Staff (आपके Employees)

### कौन हैं?
**Field Staff / Delivery Boys / Collection Agents**

### क्या कर सकते हैं? (Limited Access)

#### Mobile App Access
✅ **Login करना** - mobile app से
✅ **Today's Tasks** - आज के deliveries/collections देखना
✅ **Navigation** - customer location का GPS route

#### Device Delivery
✅ **Delivery Confirmation** - system deliver करने पर photo + signature लेना
✅ **Device Installation** - monitoring software install करना
✅ **Location Marking** - GPS से exact location save करना
✅ **Document Upload** - customer के documents की photos लेना

#### Device Pickup
✅ **Pickup Requests** - कहां से system लेना है
✅ **Pickup Confirmation** - photo + signature के साथ
✅ **Condition Report** - device की condition note करना

#### Payment Collection
✅ **Payment Recording** - cash/UPI payment लेकर app में enter करना
✅ **Receipt Generation** - customer को instant receipt देना
✅ **Payment Photo** - cash/cheque की photo upload करना

#### Customer Interaction
✅ **Customer Calls** - direct call button से contact करना
✅ **Issue Reporting** - customer complaint को note करना
✅ **Maintenance Request** - system problem होने पर report करना

#### Limited View
✅ **Assigned Clients Only** - सिर्फ अपने assigned customers देख सकते हैं
❌ **Other Staff Data** - दूसरे staff का data नहीं देख सकते
❌ **Financial Reports** - revenue/profit data नहीं देख सकते
❌ **Admin Settings** - system settings change नहीं कर सकते

---

## 3️⃣ Client (Telecalling Company Owner)

### कौन हैं?
**आपके Customers** - जिन्होंने systems rent पर लिए हैं

### क्या कर सकते हैं? (Self-Service Portal)

#### Dashboard Access
✅ **My Devices** - अपने सभी rented systems की list
✅ **Payment Status** - कितना paid है, कितना pending है
✅ **Device Status** - कौन सी device चल रही है, कौन सी नहीं
✅ **Hardware Health** - अपने devices का health देख सकते हैं

#### Payment Management
✅ **Payment History** - पिछले सभी payments देखना
✅ **Pending Amount** - कुल बकाया राशि
✅ **Online Payment** - UPI/Card से payment करना (optional feature)
✅ **Receipt Download** - previous receipts download करना
✅ **Payment Reminders** - due date notifications

#### Device Information
✅ **Device Details** - serial number, configuration देखना
✅ **Usage Statistics** - device कितने घंटे use हुआ
✅ **Performance Metrics** - system की performance देखना
✅ **Temperature Status** - अगर system overheat हो रहा है

#### Maintenance Requests
✅ **Report Issues** - system में problem होने पर complaint करना
✅ **Track Requests** - complaint का status देखना
✅ **Service History** - पिछले maintenance records

#### User Management (Terminal Users)
✅ **Add Terminal Users** - अपने employees को add करना जो system use करेंगे
✅ **Monitor Activity** - कौन सा employee कब system use कर रहा है
✅ **User Performance** - productivity metrics

#### Invoices & Documents
✅ **Monthly Invoices** - rent bills download करना
✅ **Agreement Download** - rental agreement की copy
✅ **GST Invoices** - tax invoices

#### Limited Access
❌ **Device Control** - system को lock/unlock नहीं कर सकते
❌ **Other Clients Data** - दूसरे clients का data नहीं देख सकते
❌ **Pricing Information** - rates change नहीं कर सकते
❌ **Device Location** - exact GPS location नहीं देख सकते (security)

---

## 4️⃣ Terminal Users (Telecallers)

### कौन हैं?
**Telecalling Company के Employees** - जो actually systems use करते हैं

### क्या कर सकते हैं? (Minimal Access)

#### Basic Login
✅ **Login to System** - अपने username/password से Windows login
✅ **Work on System** - normal computer use करना
✅ **Internet Access** - browsing, calling software use करना

#### Restrictions
⚠️ **Limited System Settings** - important settings change नहीं कर सकते
⚠️ **No Formatting** - disk format नहीं कर सकते
⚠️ **No Software Uninstall** - monitoring software remove नहीं कर सकते
⚠️ **No BIOS Access** - boot settings change नहीं कर सकते

#### Monitored Activities
📊 **Login/Logout Time** - कब login किया, कब logout किया
📊 **Active Hours** - कितने घंटे काम किया
📊 **Idle Time** - कितनी देर system idle रहा
📊 **Application Usage** - कौन से software use किये

#### No Dashboard Access
❌ कोई web portal access नहीं
❌ सिर्फ system use कर सकते हैं
❌ monitoring details नहीं देख सकते

---

## User Permissions Summary Table

| Feature | Super Admin | Staff | Client | Terminal User |
|---------|------------|-------|--------|---------------|
| Full Dashboard | ✅ Yes | ❌ No | ⚠️ Limited | ❌ No |
| Add/Remove Devices | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Manage Clients | ✅ Yes | ⚠️ View Only | ❌ No | ❌ No |
| Manage Staff | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Payment Collection | ✅ Yes | ✅ Yes | ⚠️ View Only | ❌ No |
| Hardware Monitoring | ✅ All Devices | ⚠️ Assigned | ⚠️ Own Devices | ❌ No |
| Financial Reports | ✅ Yes | ❌ No | ⚠️ Own Only | ❌ No |
| Device Control | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Theft Alerts | ✅ Yes | ✅ Yes | ❌ No | ❌ No |
| System Usage | ✅ Yes | ❌ No | ❌ No | ✅ Yes |

---

## Login Methods

### Super Admin
- 🖥️ **Web Dashboard** (Desktop/Laptop browser)
- 📱 **Mobile App** (Android/iOS)
- 🔐 Username + Password + 2FA (extra security)

### Staff
- 📱 **Mobile App Only** (field work के लिए)
- 🔐 Username + Password + PIN

### Client
- 🖥️ **Web Portal** (browser)
- 📱 **Mobile App** (optional)
- 🔐 Email/Phone + Password

### Terminal User
- 🖥️ **Windows Login Only** (rented system पर)
- 🔐 Username + Password (by Client company)

---

## अगला Step

अब हम **Features & Modules** की detailed list देखेंगे।

क्या यह समझ आया? आगे बढ़ें? (Yes बोलो तो next document बनाता हूं)
