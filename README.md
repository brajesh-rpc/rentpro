# 🔐 RentComPro

**Desktop & Laptop Rental Management System for Telecalling Companies**

A comprehensive rental management system designed specifically for the Indian market, targeting telecalling companies renting computer systems.

---

## 🚀 Project Status: PRODUCTION READY (Phase 1 MVP Complete)

**Current Phase:** Phase 1 - Core Payment Enforcement & Device Monitoring ✅

### Completed Modules:
- ✅ **Module 1.1:** Project Setup & Authentication System (Feb 13, 2026)
- ✅ **Module 1.2:** Windows Agent Development with Triple-ID System (Feb 13-15, 2026)
- ✅ **Module 1.3:** Modern Dashboard UI (Feb 16, 2026)

### Production Status:
- 🟢 **Backend:** Deployed & Running
- 🟢 **Frontend:** Deployed & Live
- 🟢 **Windows Agent:** Compiled & Ready for Field Deployment
- 🟢 **Database:** Schema Complete & Tested

---

## 🔥 Major Innovation: Triple-ID Device Tracking System

Our revolutionary three-layer device identification system:

```
Layer 1: LAN MAC Address (Permanent Technical ID)
         → Integrated motherboard/laptop ethernet port
         → Survives WiFi dongle replacements
         
Layer 2: Active MAC Address (Current Connection Tracking)
         → Whatever network adapter is currently active
         → Can be LAN, WiFi, or USB Dongle
         
Layer 3: Human-Friendly Name (Business Communication)
         → Examples: "Sonu-Desktop", "Rahul-Laptop"
         → Natural for Indian business conversations
```

**Why This Matters:**
- ✅ Device tracked even when WiFi dongle replaced
- ✅ Easy phone support: "Sonu ka system restart karo"
- ✅ No technical jargon in client conversations
- ✅ Field technicians can work faster
- ✅ Professional yet friendly

---

## 📁 Project Structure

```
RentComPro/
├── Frontend/                    # Modern HTML/CSS/JS Dashboard
│   ├── index.html              # Login page
│   ├── dashboard-new.html      # Modern dashboard ⭐ NEW
│   ├── dashboard.html          # Legacy dashboard
│   ├── manage-devices.html     # Device management
│   ├── manage-clients.html     # Client management
│   ├── invoices.html           # Invoice system
│   └── [other pages...]
│
├── backend/                     # Cloudflare Workers API
│   ├── src/
│   │   ├── index.ts            # Main router
│   │   ├── auth/               # Authentication
│   │   ├── devices/            # Device APIs
│   │   ├── clients/            # Client APIs
│   │   ├── invoices/           # Invoice APIs
│   │   ├── items/              # Item Master
│   │   ├── rental-items/       # Rental management
│   │   ├── dashboard/          # Dashboard stats
│   │   ├── middleware/         # Auth middleware
│   │   └── utils/              # Utilities
│   └── wrangler.toml
│
├── windows-agent/              # C# Windows Service ⭐ NEW
│   ├── RentComProAgent/
│   │   ├── Services/
│   │   │   ├── NetworkDetectionService.cs    # Triple-ID System
│   │   │   ├── HardwareMonitorService.cs     # Hardware stats
│   │   │   ├── ApiCommunicationService.cs    # Backend API
│   │   │   ├── LockService.cs                # Remote lock
│   │   │   ├── NetworkInfoService.cs         # Network info
│   │   │   └── SystemInfoService.cs          # System info
│   │   ├── Program.cs
│   │   ├── AgentWorker.cs
│   │   └── AgentConfig.cs
│   ├── installer/
│   │   ├── FieldInstaller.bat       # Field installation ⭐
│   │   ├── SmartInstaller.bat       # Advanced installer ⭐
│   │   └── FIELD_INSTALLATION_GUIDE.md
│   ├── publish/
│   │   └── RentComProAgent.exe      # Ready to deploy! ✅
│   └── README.md
│
└── docs/                        # Complete Documentation
    ├── 01_BUSINESS_OVERVIEW.md
    ├── 02_USER_TYPES_AND_ROLES.md
    ├── 03_FEATURES_AND_MODULES.md
    ├── 04_TECHNICAL_ARCHITECTURE.md
    ├── 05_FREE_TOOLS_FINAL_STACK.md
    ├── 06_DEVELOPMENT_ROADMAP.md
    ├── 07_PHASE1_DETAILED_MODULES.md
    ├── 08_MODULE_1.1_COMPLETION.md          # Auth system
    ├── 09_MODULE_1.2_WINDOWS_AGENT_COMPLETION.md  ⭐ NEW
    ├── 10_MODULE_1.3_FRONTEND_DASHBOARD_COMPLETION.md  ⭐ NEW
    ├── database/
    │   └── [schema files]
    ├── design-guides/
    │   ├── HUMAN_FRIENDLY_DEVICE_NAMING.md  ⭐ Triple-ID docs
    │   ├── LAN_MAC_PRIMARY_KEY.md
    │   ├── WIFI_DONGLE_DETECTION.md
    │   ├── DEVICE_NAMING_GUIDE.md
    │   └── [other guides]
    └── setup-guides/
```

---

## 🌐 Live URLs

- **Frontend:** https://rentpro.pages.dev
- **Backend API:** https://rentcompro-backend.brajesh-jimmc.workers.dev
- **API Docs:** See `backend/src/index.ts` for endpoint list
- **GitHub:** https://github.com/brajesh-rpc/rentpro

---

## 🛠️ Technology Stack

### Frontend (Cloudflare Pages)
- **Framework:** Pure HTML/CSS/JavaScript (No dependencies)
- **Design:** Modern gradient UI with collapsible navigation
- **Responsive:** Mobile-first design
- **State:** LocalStorage for persistence
- **API:** Fetch API with JWT authentication
- **Deployment:** Cloudflare Pages (Auto-deploy on git push)

### Backend (Cloudflare Workers)
- **Runtime:** Cloudflare Workers (V8 Edge)
- **Framework:** Hono.js (Lightweight, fast)
- **Language:** TypeScript
- **Auth:** JWT (jose library)
- **Password:** SHA-256 hashing
- **CORS:** Enabled for cross-origin
- **Deployment:** Wrangler CLI

### Database (Supabase)
- **Engine:** PostgreSQL 15
- **ORM:** Supabase JS Client
- **Tables:** 15+ tables (users, devices, clients, etc.)
- **Features:** Row Level Security, Real-time subscriptions
- **Hosting:** Managed by Supabase

### Windows Agent (.NET 8.0)
- **Language:** C# 
- **Type:** Windows Service (Background)
- **Platform:** Windows 10/11, .NET 8.0 Runtime
- **Services:** 6 core services
- **Communication:** HTTPS with Cloudflare Workers
- **Deployment:** Portable EXE with installer scripts

---

## ⚡ Features Implemented

### ✅ Authentication & Authorization
- JWT-based authentication
- Role-based access control (SUPER_ADMIN, STAFF, CLIENT)
- Password hashing (SHA-256)
- Token expiry (24 hours)
- Protected routes with middleware

### ✅ Modern Dashboard
- Real-time statistics (Devices, Clients, Revenue, Pending Payments)
- Collapsible sidebar navigation
- Stats cards with trend indicators
- Responsive mobile design
- State persistence
- Recent activity section (ready for data)

### ✅ Device Management
- Add/list devices
- Triple-ID tracking (LAN MAC + Active MAC + Human Name)
- Hardware stats collection
- Online/offline status
- Connection type detection (LAN/WIFI/DONGLE)
- Remote lock/unlock capability

### ✅ Client Management
- Register clients (CRUD operations)
- Client details (name, company, contact, documents)
- Credit limit management
- Payment history
- Rental items assignment

### ✅ Rental Items Management
- Add/remove rental items
- Mid-month additions/removals
- Rental history tracking
- Client-wise rental list

### ✅ Invoice System
- Auto-generate invoices
- GST support (18%)
- Invoice numbering (sequential)
- Mark paid/unpaid
- Invoice history
- Client-wise invoices

### ✅ Item Master
- Item catalog (Desktop, Laptop, UPS, etc.)
- Pricing management
- Active/inactive toggle
- Category management

### ✅ Windows Agent (Device Monitoring)
- **Network Detection** (Triple-ID System)
  - Auto-detect integrated LAN MAC
  - Track active connection
  - Identify connection type
  - Handle WiFi dongle replacements
  
- **Hardware Monitoring**
  - CPU usage
  - RAM usage
  - Disk usage
  - Temperature (if sensors available)
  
- **API Communication**
  - Heartbeat every 5 minutes
  - Stats upload every 15 minutes
  - Receives lock/unlock commands
  
- **Remote Control**
  - Lock device remotely
  - Unlock on command
  - Payment enforcement

- **Smart Installation**
  - 2-3 minute installation
  - Auto-detect everything
  - Just ask device name
  - Field-technician friendly

---

## 📊 Database Schema

### Core Tables (15 tables)
```sql
users              # Super Admin, Staff, Clients
devices            # Rental devices with Triple-ID
clients            # Telecalling companies
payments           # Payment records
hardware_stats     # Device monitoring data
alerts             # System alerts
maintenance        # Maintenance schedule
rental_items       # Items rented to clients
rental_item_history # Mid-month changes
invoices           # Invoice headers
invoice_items      # Invoice line items
items              # Item master (catalog)
```

**See:** `docs/database/` for complete schema

---

## 🎯 Business Problems Solved

### 1. Payment Collection ✅
- Auto-track payments
- Overdue alerts
- Payment enforcement (reminder → warning → lock)
- GST-compliant invoicing

### 2. Theft & Fraud Prevention ✅
- Real-time device monitoring
- Location tracking (WiFi/IP based)
- Immediate offline alerts
- Remote lock capability
- Triple-ID tracking (survives hardware changes)

### 3. Hardware Health Monitoring ✅
- CPU/RAM/Disk stats
- Temperature tracking
- Predictive failure alerts
- Maintenance scheduling

### 4. Device Tracking ✅
- Online/offline status
- Usage statistics
- Format detection
- Network change tracking
- Human-friendly naming

---

## 🚀 Quick Start

### Frontend Development
```bash
# Local development
cd Frontend
# Open index.html in browser
# Or use: python -m http.server 8000

# Production URL
https://rentpro.pages.dev
```

### Backend Development
```bash
cd backend
npm install
wrangler dev  # Local testing
wrangler deploy  # Deploy to Cloudflare
```

### Windows Agent Development
```bash
cd windows-agent/RentComProAgent
dotnet build --configuration Release
dotnet publish --runtime win-x64 --self-contained true

# Output: bin/Release/net8.0-windows/win-x64/publish/
```

### Windows Agent Deployment
```bash
# Copy installer folder to USB
# At client site:
1. Run FieldInstaller.bat as Administrator
2. Enter device name (e.g., "Sonu")
3. Wait 2-3 minutes
4. Verify in dashboard

# Device appears ONLINE with:
✅ LAN MAC populated
✅ Active MAC populated
✅ Connection type detected
✅ Device name: "Sonu-Desktop"
```

---

## 🔐 Access Credentials

### Test Admin Account
- **Email:** admin@rentcompro.com
- **Password:** password123
- **Role:** SUPER_ADMIN

### Supabase Database
- **URL:** https://rkgrmcrsnrohfxmtwfnf.supabase.co
- **See:** `docs/setup-guides/SUPABASE_CREDENTIALS.md`

### Cloudflare
- **Account:** brajesh.jimmc@gmail.com
- **Workers:** rentcompro-backend
- **Pages:** rentpro

---

## 📖 Complete Documentation

All documentation available in [`docs/`](./docs/):

### Business & Planning
- [01_BUSINESS_OVERVIEW.md](./docs/01_BUSINESS_OVERVIEW.md) - Business model
- [02_USER_TYPES_AND_ROLES.md](./docs/02_USER_TYPES_AND_ROLES.md) - User hierarchy
- [03_FEATURES_AND_MODULES.md](./docs/03_FEATURES_AND_MODULES.md) - Feature list

### Technical Architecture
- [04_TECHNICAL_ARCHITECTURE.md](./docs/04_TECHNICAL_ARCHITECTURE.md) - Tech stack
- [05_FREE_TOOLS_FINAL_STACK.md](./docs/05_FREE_TOOLS_FINAL_STACK.md) - Cost analysis

### Development
- [06_DEVELOPMENT_ROADMAP.md](./docs/06_DEVELOPMENT_ROADMAP.md) - 12-month plan
- [07_PHASE1_DETAILED_MODULES.md](./docs/07_PHASE1_DETAILED_MODULES.md) - Phase 1 details

### Completion Reports
- [08_MODULE_1.1_COMPLETION.md](./docs/08_MODULE_1.1_COMPLETION.md) - Authentication
- [09_MODULE_1.2_WINDOWS_AGENT_COMPLETION.md](./docs/09_MODULE_1.2_WINDOWS_AGENT_COMPLETION.md) - Windows Agent ⭐
- [10_MODULE_1.3_FRONTEND_DASHBOARD_COMPLETION.md](./docs/10_MODULE_1.3_FRONTEND_DASHBOARD_COMPLETION.md) - Dashboard UI ⭐

### Design Guides
- [HUMAN_FRIENDLY_DEVICE_NAMING.md](./docs/design-guides/HUMAN_FRIENDLY_DEVICE_NAMING.md) - Triple-ID System ⭐
- [LAN_MAC_PRIMARY_KEY.md](./docs/design-guides/LAN_MAC_PRIMARY_KEY.md)
- [WIFI_DONGLE_DETECTION.md](./docs/design-guides/WIFI_DONGLE_DETECTION.md)

---

## 📈 Project Statistics

### Development Timeline
- **Start Date:** February 8, 2026
- **Module 1.1 Complete:** February 13, 2026
- **Module 1.2 Complete:** February 15, 2026
- **Module 1.3 Complete:** February 16, 2026
- **Current Status:** Production Ready (Phase 1 MVP)

### Code Metrics
- **Backend:** ~3,000 lines (TypeScript)
- **Frontend:** ~1,500 lines (HTML/CSS/JS)
- **Windows Agent:** ~1,500 lines (C#)
- **Total Documentation:** 10 detailed files
- **API Endpoints:** 30+
- **Database Tables:** 15

### Deployment Status
- ✅ Backend: Deployed on Cloudflare Workers
- ✅ Frontend: Deployed on Cloudflare Pages
- ✅ Database: Running on Supabase
- ✅ Windows Agent: Compiled EXE ready
- ✅ Installers: Field-ready scripts

---

## 🎓 Key Learnings & Innovations

### What Makes This Project Special

1. **Triple-ID System** - Solves real-world device tracking problems
2. **Human-Friendly Naming** - Natural for Indian business context
3. **Smart Installation** - 2-3 minute deployment time
4. **WiFi Dongle Handling** - Survives hardware replacements
5. **Edge Computing** - Cloudflare Workers for 50ms latency
6. **Free to Start** - Can handle 50-100 devices on free tier
7. **Production Ready** - Real code, not prototypes

### Technologies Mastered
- Cloudflare Workers (Serverless)
- Supabase (PostgreSQL)
- C# Windows Services
- JWT Authentication
- Network Detection Algorithms
- Modern UI/UX Design
- Field Deployment Strategies

---

## 🔮 Next Steps (Module 1.4+)

### Short Term (Week 1-2)
1. Device list page with Triple-ID display
2. Client list page with rental items
3. Recent activity feed implementation
4. Real-time notifications

### Medium Term (Month 1-2)
1. Payment enforcement automation
2. SMS/WhatsApp integration
3. Advanced reporting
4. Bulk device deployment tools

### Long Term (Month 3+)
1. Mobile app (React Native/Flutter)
2. Advanced analytics
3. Multi-tenant support
4. API for third-party integrations

---

## 🤝 Team

**Lead Developer & Architect:** Brajesh Kumar  
**AI Assistant:** Claude (Anthropic)  
**Contact:** brajesh.jimmc@gmail.com

---

## 📝 License

**Proprietary** - All Rights Reserved  
© 2026 Brajesh Kumar

---

## 🎯 Success Metrics

### Target (6 Months)
- 100+ devices deployed
- 20+ clients active
- ₹1,00,000+ monthly revenue
- 95%+ uptime
- <24 hour fraud detection

### Current (Phase 1)
- ✅ Production-ready system
- ✅ All core features working
- ✅ Field deployment ready
- ✅ Zero cost to start
- ✅ Scalable architecture

---

**Last Updated:** February 16, 2026  
**Version:** 1.3.0 (Phase 1 MVP Complete)  
**Status:** 🟢 Production Ready
