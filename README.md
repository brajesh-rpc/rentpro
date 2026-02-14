# 🔐 RentComPro

**Desktop & Laptop Rental Management System for Telecalling Companies**

A comprehensive rental management system designed specifically for the Indian market, targeting telecalling companies renting computer systems.

---

## 🚀 Project Status

**Current Phase:** Phase 1 - Core Payment Enforcement & Device Monitoring (MVP)

**Completed Modules:**
- ✅ Module 1.1: Authentication & Authorization
- ✅ Module 1.2: Enhanced Dashboard with Real-time Stats
- ✅ Module 1.3: Client Management System
- ✅ Module 1.4: Asset/Rental Items Management
- ✅ Module 1.5: Invoice Generation System (GST Support)
- 🚧 Module 1.6: Payment Tracking & Notifications (In Progress)

---

## 📁 Project Structure

```
RentComPro/
├── Frontend/              # HTML/CSS/JS frontend application
├── backend/              # Cloudflare Workers API
├── windows-agent/        # Windows Service for device monitoring
├── docs/                 # Complete project documentation
│   ├── setup-guides/    # Setup and configuration guides
│   ├── database/        # Database schemas and migrations
│   └── design-guides/   # Design and naming conventions
└── README.md            # This file
```

---

## 🌐 Live URLs

- **Frontend:** https://rentpro.pages.dev
- **Backend API:** https://rentcompro-backend.brajesh-jimmc.workers.dev
- **GitHub:** https://github.com/brajesh-rpc/rentpro

---

## 🛠️ Technology Stack

### Frontend
- Pure HTML/CSS/JavaScript (No framework)
- Hosted on Cloudflare Pages

### Backend
- Cloudflare Workers (Serverless)
- Hono.js Framework
- TypeScript

### Database
- Supabase (PostgreSQL)

### Windows Agent
- .NET 8.0 Windows Service
- C#

---

## ⚡ Features

### ✅ Implemented
- User authentication & authorization (SUPER_ADMIN, STAFF, FIELD_AGENT)
- Real-time dashboard with live statistics
- Client management (CRUD operations)
- Rental items management (Mid-month additions/removals)
- Invoice generation (With/Without GST 18%)
- Payment tracking (Paid/Unpaid/Overdue/Partial)
- Asset change history
- Human-friendly device naming

### 🚧 In Progress
- Windows Service Agent (Device monitoring)
- Automated payment reminders
- SMS/WhatsApp notifications

### 📅 Upcoming
- Anti-theft features (Device lock/unlock)
- Business intelligence & analytics
- Advanced reporting

---

## 📖 Documentation

Complete documentation available in the [`docs/`](./docs/) folder:

- [Business Overview](./docs/01_BUSINESS_OVERVIEW.md)
- [Technical Architecture](./docs/04_TECHNICAL_ARCHITECTURE.md)
- [Development Roadmap](./docs/06_DEVELOPMENT_ROADMAP.md)
- [Setup Guides](./docs/setup-guides/)
- [Database Schema](./docs/database/)

---

## 🚀 Quick Start

### Frontend Development
```bash
cd Frontend
# Open index.html in browser
```

### Backend Development
```bash
cd backend
npm install
wrangler dev
```

### Windows Agent Development
```bash
cd windows-agent/RentComProAgent
dotnet build
```

---

## 🔐 Access Credentials

**Test Admin Account:**
- Email: admin@rentcompro.com
- Password: password123

_(For development/testing only)_

---

## 📊 Database

**Provider:** Supabase  
**Credentials:** See `docs/setup-guides/SUPABASE_CREDENTIALS.md`

**Tables:**
- users, clients, devices
- rental_items, rental_item_history
- invoices, invoice_items
- hardware_stats

---

## 🤝 Contributing

This is a private project. Development is currently managed by the core team.

---

## 📝 License

Proprietary - All Rights Reserved

---

## 📞 Contact

**Developer:** Brajesh Kumar  
**Email:** brajesh.smartdevice@gmail.com

---

**Last Updated:** February 14, 2026
