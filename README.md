# RentComPro - Rental Management System

> A comprehensive desktop and laptop rental management system designed for telecalling companies in India, with built-in payment enforcement, device monitoring, and anti-theft features.

---

## 🚀 Project Status

**Current Phase:** Module 1.1 ✅ COMPLETE  
**Production Status:** 🟢 LIVE  
**Last Updated:** February 13, 2026

---

## 🌐 Live URLs

- **Frontend:** https://rentpro.pages.dev
- **Backend API:** https://rentcompro-backend.brajesh-jimmc.workers.dev
- **GitHub:** https://github.com/brajesh-rpc/rentpro

**Test Credentials:**
- Email: `admin@rentcompro.com`
- Password: `password123`

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Development Roadmap](#development-roadmap)
- [Documentation](#documentation)
- [Contributing](#contributing)

---

## 🎯 Overview

RentComPro is a complete rental management solution targeting the Indian telecalling industry. Companies rent budget desktop systems (i5 2nd gen, 4GB RAM, 19" monitors with UPS) to businesses in:

- Loan recovery
- Insurance sales
- Ayurvedic medicine sales
- Credit card sales

### Core Business Problems Solved

1. **Payment Collection Automation** - Automated reminders and payment tracking
2. **Fraud Prevention** - Real-time device monitoring and location tracking
3. **Asset Recovery** - Remote device lock/unlock capabilities
4. **Maintenance Scheduling** - Automated maintenance alerts and tracking

---

## ✨ Features

### ✅ Completed (Module 1.1)

- **User Authentication**
  - Secure login/logout with JWT tokens
  - Role-based access control (Super Admin, Staff, Client)
  - Password hashing and verification
  - 24-hour session management

- **Dashboard**
  - Stats overview (Devices, Clients, Payments)
  - User profile management
  - Logout functionality

- **Backend API**
  - RESTful API with TypeScript
  - Supabase database integration
  - Protected routes with middleware
  - CORS enabled for frontend access

### 🚧 In Development (Module 1.2)

- Enhanced dashboard with live stats
- Navigation menu
- Recent activity feed
- Quick action buttons

### 📅 Planned Features

- **Device Management** (Module 1.3)
  - Device registration and tracking
  - Human-friendly naming (e.g., "Rajesh-i5")
  - Assignment to clients
  - Status management

- **Payment Tracking** (Module 1.4)
  - Payment recording and history
  - Due date management
  - Automated alerts for overdue payments
  - Receipt generation

- **Automated Notifications** (Module 1.5)
  - SMS and WhatsApp integration
  - Payment reminders
  - Custom notification templates

- **Device Monitoring** (Module 1.6)
  - Real-time hardware stats (CPU, RAM, Disk)
  - Remote lock/unlock
  - Offline device alerts
  - Location tracking

---

## 🛠️ Technology Stack

### Backend
- **Runtime:** Cloudflare Workers
- **Language:** TypeScript
- **Framework:** Hono (lightweight web framework)
- **Database:** Supabase (PostgreSQL)
- **Authentication:** JWT with jose library
- **Password Hashing:** Web Crypto API (SHA-256)

### Frontend
- **Hosting:** Cloudflare Pages
- **Framework:** HTML5, CSS3, Vanilla JavaScript
- **State Management:** localStorage
- **UI/UX:** Custom gradient design, responsive layout

### DevOps
- **Version Control:** GitHub
- **Deployment:** Automated via Cloudflare
- **CI/CD:** GitHub → Cloudflare Pages auto-deploy

### Future Stack
- **Desktop App:** Electron or Flutter
- **Windows Service:** C# (.NET)
- **Notifications:** MSG91 / TextLocal (SMS), WhatsApp Business API

---

## 📁 Project Structure

```
RentComPro/
├── backend/                    # Cloudflare Workers backend
│   ├── src/
│   │   ├── auth/              # Authentication handlers
│   │   ├── middleware/        # Auth middleware
│   │   ├── utils/             # Utility functions
│   │   ├── types/             # TypeScript types
│   │   └── index.ts           # Main router
│   ├── wrangler.jsonc         # Workers configuration
│   └── package.json           # Dependencies
│
├── docs/                       # Project documentation
│   ├── 01_BUSINESS_OVERVIEW.md
│   ├── 02_USER_TYPES_AND_ROLES.md
│   ├── 03_FEATURES_AND_MODULES.md
│   ├── 04_TECHNICAL_ARCHITECTURE.md
│   ├── 05_FREE_TOOLS_FINAL_STACK.md
│   ├── 06_DEVELOPMENT_ROADMAP.md
│   ├── 07_PHASE1_DETAILED_MODULES.md
│   └── 08_MODULE_1.1_COMPLETION.md
│
├── index.html                  # Login page
├── dashboard.html              # Dashboard page
├── database_schema.sql         # Database schema
└── README.md                   # This file
```

---

## 🚀 Getting Started

### Prerequisites

- Node.js (v20 or higher)
- npm or yarn
- Cloudflare account
- Supabase account
- GitHub account

### Local Development Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/brajesh-rpc/rentpro.git
cd rentpro
```

#### 2. Backend Setup

```bash
cd backend
npm install
```

Create `wrangler.jsonc` configuration (or update existing):

```json
{
  "account_id": "your-cloudflare-account-id",
  "name": "rentcompro-backend",
  "vars": {
    "SUPABASE_URL": "https://your-project.supabase.co",
    "SUPABASE_ANON_KEY": "your-anon-key",
    "JWT_SECRET": "your-jwt-secret"
  }
}
```

#### 3. Database Setup

Run the SQL schema in Supabase SQL Editor:

```bash
# File: database_schema.sql
```

Create test user:

```bash
# File: backend/create_test_users.sql
```

#### 4. Start Local Development

```bash
# Backend
cd backend
npm run dev
# Runs on http://localhost:8787

# Frontend
# Open index.html in browser
```

#### 5. Run Tests

```bash
# Test backend health
curl http://localhost:8787/

# Test Supabase connection
curl http://localhost:8787/api/test-connection

# Test login
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@rentcompro.com","password":"password123"}'
```

---

## 🗺️ Development Roadmap

### Phase 1: Core Payment Enforcement & Device Monitoring (MVP)
**Duration:** 6 weeks  
**Status:** In Progress (Module 1.1 ✅, Module 1.2 🚧)

- ✅ Module 1.1: Project Setup & Authentication
- 🚧 Module 1.2: Super Admin Dashboard
- 📅 Module 1.3: Device Management
- 📅 Module 1.4: Payment Tracking
- 📅 Module 1.5: Automated Notifications
- 📅 Module 1.6: Device Lock/Unlock & Monitoring

### Phase 2: Anti-Theft & Fraud Prevention
**Duration:** 3-4 weeks  
**Status:** Planned

- Advanced device tracking
- Geofencing alerts
- Screenshot capture
- Format detection and prevention

### Phase 3: Business Intelligence & Analytics
**Duration:** 3-4 weeks  
**Status:** Planned

- Advanced analytics dashboard
- Revenue forecasting
- Client behavior analysis
- Performance metrics

### Phase 4: Scaling & Advanced Features
**Duration:** 4-5 weeks  
**Status:** Planned

- Multi-branch management
- Staff performance tracking
- Mobile app (optional)
- API for third-party integrations

**Total Timeline:** 14-19 weeks (3.5-5 months)

---

## 📚 Documentation

Detailed documentation is available in the `/docs` folder:

1. [Business Overview](docs/01_BUSINESS_OVERVIEW.md) - Pain points, target market, business model
2. [User Types & Roles](docs/02_USER_TYPES_AND_ROLES.md) - User hierarchy and permissions
3. [Features & Modules](docs/03_FEATURES_AND_MODULES.md) - Complete feature list
4. [Technical Architecture](docs/04_TECHNICAL_ARCHITECTURE.md) - System design and decisions
5. [Technology Stack](docs/05_FREE_TOOLS_FINAL_STACK.md) - Tools and services used
6. [Development Roadmap](docs/06_DEVELOPMENT_ROADMAP.md) - 4-phase development plan
7. [Phase 1 Modules](docs/07_PHASE1_DETAILED_MODULES.md) - Detailed breakdown of Module 1.1-1.6
8. [Module 1.1 Completion](docs/08_MODULE_1.1_COMPLETION.md) - Module 1.1 summary and learnings

---

## 🔐 Security

- **Password Security:** SHA-256 hashing for password storage
- **JWT Tokens:** 24-hour expiry with secret key signing
- **CORS:** Configured for frontend-backend communication
- **Role-Based Access:** Different permission levels enforced
- **Environment Variables:** Sensitive data stored securely

---

## 🧪 Testing

### Manual Testing
- ✅ Local development server
- ✅ Production deployment
- ✅ End-to-end authentication flow
- ✅ Protected routes verification
- ✅ Database connectivity

### Test Credentials
- **Email:** admin@rentcompro.com
- **Password:** password123
- **Role:** SUPER_ADMIN

---

## 🤝 Contributing

This is a private project currently in active development. Contributions are not being accepted at this time.

---

## 📄 License

This project is proprietary and confidential.  
© 2026 Brajesh Kumar. All rights reserved.

---

## 👨‍💻 Developer

**Brajesh Kumar**  
Email: brajesh.jimmc@gmail.com  
GitHub: [@brajesh-rpc](https://github.com/brajesh-rpc)

---

## 🙏 Acknowledgments

- **Cloudflare** - Workers and Pages hosting
- **Supabase** - Database and backend services
- **Anthropic Claude** - Development assistance

---

## 📝 Changelog

### Version 0.1.0 (February 13, 2026)
- ✅ Initial project setup
- ✅ Authentication system implemented
- ✅ Login/Dashboard UI created
- ✅ Backend API deployed
- ✅ Frontend deployed
- ✅ Supabase integration complete
- ✅ Module 1.1 complete and production-ready

---

**Last Updated:** February 13, 2026  
**Project Status:** Active Development  
**Current Module:** 1.2 - Super Admin Dashboard
