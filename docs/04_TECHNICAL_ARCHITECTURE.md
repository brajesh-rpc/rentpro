# RentComPro - Technical Architecture (100xCRM Stack)

## Complete Technical Implementation Guide

**Tech Stack:** Same as 100xCRM - Proven & Production-Ready

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    USERS / CLIENTS                          │
│  (Super Admin, Staff, Client, Terminal User)                │
└──────────────────┬──────────────────────────────────────────┘
                   │
    ┌──────────────┼──────────────┐
    │              │              │
    ▼              ▼              ▼
┌─────────┐  ┌──────────┐  ┌──────────────┐
│   Web   │  │  Mobile  │  │Desktop Agent │
│Dashboard│  │   App    │  │  (C# Win     │
│  React  │  │ Flutter/ │  │   Service)   │
│         │  │  React   │  │              │
│         │  │  Native  │  │              │
└────┬────┘  └────┬─────┘  └──────┬───────┘
     │            │               │
     └────────────┼───────────────┘
                  │
    ┌─────────────┴─────────────┐
    │                           │
    ▼                           ▼
┌─────────────────┐    ┌────────────────┐
│ Cloudflare      │    │   Supabase     │
│ Pages           │    │   (Direct)     │
│ (Frontend)      │    │                │
└────────┬────────┘    └────────┬───────┘
         │                      │
         ▼                      │
┌─────────────────┐            │
│ Cloudflare      │            │
│ Workers         │◄───────────┘
│ (API/Backend)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Supabase      │
│  - PostgreSQL   │
│  - Auth         │
│  - Storage      │
│  - Realtime     │
└─────────────────┘
```

---

## Technology Stack (100xCRM Proven)

### 1. Frontend - React.js (Web Dashboard)

#### Technology
- **Framework**: React.js 18+ with TypeScript
- **Build Tool**: Vite (faster than CRA)
- **UI Library**: Shadcn/ui + Tailwind CSS
- **State Management**: Zustand (lighter than Redux)
- **API Client**: Axios + React Query (caching)
- **Forms**: React Hook Form + Zod validation
- **Charts**: Recharts
- **Maps**: Google Maps JavaScript API
- **Routing**: React Router v6

#### Why React?
✅ Fast development
✅ Large community
✅ TypeScript support
✅ Component reusability
✅ Works perfectly with Cloudflare Pages

#### Project Structure
```
frontend/
├── src/
│   ├── components/
│   │   ├── ui/              # Shadcn components
│   │   ├── dashboard/       # Dashboard widgets
│   │   ├── devices/         # Device components
│   │   ├── clients/         # Client components
│   │   └── layout/          # Header, Sidebar, etc.
│   │
│   ├── pages/
│   │   ├── Dashboard.tsx
│   │   ├── Devices.tsx
│   │   ├── Clients.tsx
│   │   ├── Payments.tsx
│   │   └── Settings.tsx
│   │
│   ├── hooks/               # Custom hooks
│   ├── lib/
│   │   ├── supabase.ts      # Supabase client
│   │   └── utils.ts
│   │
│   ├── types/               # TypeScript types
│   └── App.tsx
│
├── package.json
├── vite.config.ts
└── tailwind.config.js
```

---

### 2. Backend - Cloudflare Workers (Serverless)

#### Technology
- **Platform**: Cloudflare Workers
- **Runtime**: V8 JavaScript Engine
- **Language**: TypeScript
- **Framework**: Hono (lightweight, fast)
- **Database Client**: Supabase JS Client
- **Edge Network**: 200+ locations worldwide

#### Why Cloudflare Workers?
✅ **FREE tier generous** - 100,000 requests/day
✅ **Ultra-fast** - Edge computing, <50ms latency
✅ **Serverless** - No server management
✅ **Auto-scaling** - Handles traffic spikes
✅ **Global** - 200+ data centers
✅ **Integrates with Cloudflare Pages** - Same ecosystem

#### Project Structure
```
backend/
├── src/
│   ├── index.ts             # Main entry point
│   ├── routes/
│   │   ├── auth.ts          # Authentication
│   │   ├── devices.ts       # Device APIs
│   │   ├── clients.ts       # Client APIs
│   │   ├── payments.ts      # Payment APIs
│   │   └── agent.ts         # Desktop agent APIs
│   │
│   ├── middleware/
│   │   ├── auth.ts          # JWT verification
│   │   └── cors.ts          # CORS handling
│   │
│   ├── lib/
│   │   ├── supabase.ts      # Supabase client
│   │   └── jwt.ts           # JWT utils
│   │
│   └── types/
│       └── index.ts
│
├── wrangler.toml            # Cloudflare config
└── package.json
```

#### API Endpoints (Cloudflare Workers)

**Authentication**
```typescript
POST /api/auth/login       # Login
POST /api/auth/register    # Register
GET  /api/auth/me          # Current user
```

**Devices**
```typescript
GET    /api/devices           # List devices
GET    /api/devices/:id       # Get device
POST   /api/devices           # Add device
PUT    /api/devices/:id       # Update device
DELETE /api/devices/:id       # Delete device
```

**Clients**
```typescript
GET    /api/clients           # List clients
GET    /api/clients/:id       # Get client
POST   /api/clients           # Add client
PUT    /api/clients/:id       # Update client
```

**Payments**
```typescript
GET    /api/payments          # List payments
POST   /api/payments          # Record payment
GET    /api/payments/pending  # Pending payments
```

**Device Agent**
```typescript
POST   /api/agent/heartbeat   # Device heartbeat
POST   /api/agent/hardware    # Hardware stats
POST   /api/agent/location    # GPS location
GET    /api/agent/commands    # Get commands (lock/unlock)
```

#### Example Worker Code
```typescript
// src/index.ts
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { createClient } from '@supabase/supabase-js'

const app = new Hono()

app.use('*', cors())

// Supabase client
const supabase = createClient(
  env.SUPABASE_URL,
  env.SUPABASE_ANON_KEY
)

// Routes
app.get('/api/devices', async (c) => {
  const { data, error } = await supabase
    .from('devices')
    .select('*')
    .order('created_at', { ascending: false })
  
  if (error) return c.json({ error: error.message }, 500)
  return c.json(data)
})

app.post('/api/devices', async (c) => {
  const body = await c.req.json()
  
  const { data, error } = await supabase
    .from('devices')
    .insert(body)
    .select()
    .single()
  
  if (error) return c.json({ error: error.message }, 500)
  return c.json(data)
})

export default app
```

---

### 3. Database - Supabase (PostgreSQL)

#### Why Supabase?
✅ **FREE tier** - 500MB database, 2GB bandwidth
✅ **PostgreSQL** - Reliable, powerful
✅ **Auto APIs** - REST + GraphQL automatically generated
✅ **Real-time** - Live database changes
✅ **Auth built-in** - JWT, Row Level Security
✅ **Storage included** - 1GB file storage free
✅ **Hosted** - No server management

#### Database Schema (Same as before - already defined in doc 04)

```prisma
// Key tables from previous definition
- users
- devices
- clients
- payments
- hardware_stats
- maintenance
- alerts
```

---

### 4. Desktop Agent - C# Windows Service

#### Technology
- **Language**: C# .NET 6.0
- **Type**: Windows Service (background)
- **Hardware Monitoring**: OpenHardwareMonitor
- **HTTP Client**: HttpClient
- **Database**: Supabase REST API (direct calls)

#### Why C# Windows Service?
✅ Runs at boot (before user login)
✅ Administrator privileges
✅ Hidden from Task Manager
✅ Auto-restart on crash
✅ Deep Windows integration
✅ Hardware access

#### Agent Components

**1. Core Service**
```csharp
// Runs 24/7 in background
public class RentComProService : ServiceBase
{
    private Timer heartbeatTimer;
    private Timer hardwareTimer;
    
    protected override void OnStart(string[] args)
    {
        // Send heartbeat every 5 minutes
        heartbeatTimer = new Timer(SendHeartbeat, null, 0, 300000);
        
        // Collect hardware stats every 15 minutes
        hardwareTimer = new Timer(CollectHardware, null, 0, 900000);
    }
    
    private async void SendHeartbeat(object state)
    {
        var data = new {
            deviceId = GetDeviceId(),
            timestamp = DateTime.UtcNow,
            isOnline = true
        };
        
        await SendToSupabase("agent/heartbeat", data);
    }
}
```

**2. Hardware Monitor**
```csharp
using OpenHardwareMonitor.Hardware;

public class HardwareMonitor
{
    private Computer computer;
    
    public HardwareStats CollectStats()
    {
        computer.Accept(new UpdateVisitor());
        
        return new HardwareStats
        {
            CpuTemp = GetCpuTemperature(),
            CpuUsage = GetCpuUsage(),
            RamUsed = GetRamUsage(),
            RamTotal = GetTotalRam(),
            DiskHealth = GetDiskSmartData(),
            // ... more stats
        };
    }
}
```

**3. Payment Enforcement**
```csharp
public class PaymentEnforcer
{
    public async Task<PaymentStatus> CheckPaymentStatus()
    {
        var response = await GetFromSupabase($"devices/{deviceId}/payment-status");
        return JsonSerializer.Deserialize<PaymentStatus>(response);
    }
    
    public void EnforceRestrictions(PaymentStatus status)
    {
        switch(status.Level)
        {
            case 0: // All good
                RemoveAllRestrictions();
                break;
            case 1: // Reminder
                ShowPaymentReminder();
                break;
            case 2: // Warning
                ShowWarningScreen();
                LimitUsageTime(4); // 4 hours
                break;
            case 3: // Critical
                ShowCriticalWarning();
                LimitUsageTime(2); // 2 hours
                break;
            case 4: // Locked
                LockDevice();
                break;
        }
    }
}
```

**4. Anti-Theft Module**
```csharp
public class TheftProtection
{
    public async Task<Location> GetLocation()
    {
        // Try WiFi-based location first
        var wifiLocation = await GetWiFiLocation();
        
        // Fallback to IP geolocation
        if (wifiLocation == null)
            return await GetIPLocation();
            
        return wifiLocation;
    }
    
    public void ProtectFromFormatting()
    {
        // Disable format commands
        DisableDiskManagement();
        
        // Prevent USB boot
        SetBiosBootOrder();
        
        // Registry protection
        ProtectRegistryKeys();
    }
}
```

**5. Supabase API Communication**
```csharp
public class SupabaseClient
{
    private readonly HttpClient httpClient;
    private readonly string apiKey;
    private readonly string baseUrl;
    
    public async Task<T> Get<T>(string endpoint)
    {
        var request = new HttpRequestMessage(HttpMethod.Get, 
            $"{baseUrl}/rest/v1/{endpoint}");
        request.Headers.Add("apikey", apiKey);
        request.Headers.Add("Authorization", $"Bearer {apiKey}");
        
        var response = await httpClient.SendAsync(request);
        var json = await response.Content.ReadAsStringAsync();
        
        return JsonSerializer.Deserialize<T>(json);
    }
    
    public async Task Post(string endpoint, object data)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, 
            $"{baseUrl}/rest/v1/{endpoint}");
        request.Headers.Add("apikey", apiKey);
        request.Content = JsonContent.Create(data);
        
        await httpClient.SendAsync(request);
    }
}
```

---

### 5. Deployment Setup

#### Frontend Deployment (Cloudflare Pages)

**Step 1: Connect GitHub**
```bash
# Push code to GitHub
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourusername/rentcompro-frontend.git
git push -u origin main
```

**Step 2: Cloudflare Pages Setup**
```
1. Login to Cloudflare Dashboard
2. Pages → Create a project
3. Connect to Git → Select GitHub repo
4. Build settings:
   - Framework: Vite
   - Build command: npm run build
   - Output directory: dist
5. Environment variables:
   - VITE_SUPABASE_URL=your-project-url
   - VITE_SUPABASE_ANON_KEY=your-anon-key
6. Deploy!
```

**Result:**
- URL: `https://rentcompro.pages.dev`
- Auto-deploy on git push
- FREE SSL certificate
- Global CDN

---

#### Backend Deployment (Cloudflare Workers)

**Step 1: Install Wrangler CLI**
```bash
npm install -g wrangler
wrangler login
```

**Step 2: Configure wrangler.toml**
```toml
name = "rentcompro-api"
main = "src/index.ts"
compatibility_date = "2024-01-01"

[vars]
SUPABASE_URL = "https://your-project.supabase.co"
SUPABASE_ANON_KEY = "your-anon-key"

[[routes]]
pattern = "api.rentcompro.com/*"
zone_name = "rentcompro.com"
```

**Step 3: Deploy**
```bash
wrangler deploy
```

**Result:**
- URL: `https://rentcompro-api.workers.dev`
- Or custom domain: `https://api.rentcompro.com`
- FREE tier: 100k requests/day
- Auto-scaling

---

### 6. GitHub Workflow (CI/CD)

**Automatic Deployment on Git Push**

```yaml
# .github/workflows/deploy.yml

name: Deploy to Cloudflare

on:
  push:
    branches: [main]

jobs:
  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install
      - run: npm run build
      # Cloudflare Pages auto-deploys on push

  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm install -g wrangler
      - run: wrangler deploy
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CF_API_TOKEN }}
```

---

### 7. Mobile App (Optional - Future Phase)

#### Option 1: React Native
```
✅ Same React knowledge
✅ Code sharing with web
✅ Expo for easy development
```

#### Option 2: Flutter
```
✅ Better performance
✅ Single codebase
✅ Beautiful UI out of box
```

**Recommendation:** Start with web only, add mobile later if needed

---

## Cost Breakdown (100xCRM Stack)

### FREE Tier (0-100 devices)
```
Frontend: Cloudflare Pages - FREE
Backend: Cloudflare Workers - FREE (100k req/day)
Database: Supabase - FREE (500MB)
Storage: Supabase - FREE (1GB)
Auth: Supabase - FREE
Realtime: Supabase - FREE
Domain: ₹100/year
SSL: FREE (Cloudflare)

Total: ₹8/month (domain only)
```

### Paid Tier (100-500 devices)
```
Frontend: Cloudflare Pages - FREE
Backend: Cloudflare Workers - $5/month (~₹420)
Database: Supabase Pro - ₹2000/month (8GB)
Storage: Upgrade if needed
SMS: MSG91 - ₹500-1000/month
WhatsApp: WATI - ₹2000/month

Total: ₹4920/month
```

---

## Development Environment Setup

### Required Software
```bash
# Node.js 18+
node -v

# Git
git --version

# Wrangler CLI (Cloudflare)
npm install -g wrangler

# VS Code (recommended)
code --version
```

### Environment Variables

**Frontend (.env)**
```bash
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc...
VITE_API_URL=https://rentcompro-api.workers.dev
```

**Backend (wrangler.toml)**
```toml
[vars]
SUPABASE_URL = "https://xxxxx.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGc..."
JWT_SECRET = "your-secret-key"
```

**Desktop Agent (appsettings.json)**
```json
{
  "Supabase": {
    "Url": "https://xxxxx.supabase.co",
    "AnonKey": "eyJhbGc...",
    "DeviceId": "auto-generated"
  }
}
```

---

## Why This Stack? (100xCRM Proven Benefits)

### 1. **FREE to Start**
- All services have generous free tiers
- Can handle 50-100 devices completely FREE
- Only pay when you scale

### 2. **Fast Development**
- React is fast to build with
- Cloudflare Workers = no backend code complexity
- Supabase = no database management
- GitHub = version control + auto-deploy

### 3. **Production Ready**
- Used by 100xCRM in production
- Cloudflare = 99.99% uptime
- Supabase = managed PostgreSQL
- Proven reliability

### 4. **Scalable**
- Cloudflare Workers auto-scale
- Supabase can handle millions of rows
- Add more resources when needed

### 5. **Simple Architecture**
- Frontend → Workers → Supabase
- Easy to understand
- Easy to debug
- Easy to maintain

---

## Next Steps

1. **Setup Supabase Project** - Create tables
2. **Create GitHub Repo** - Version control
3. **Build React Frontend** - Dashboard UI
4. **Deploy to Cloudflare Pages** - FREE hosting
5. **Create Cloudflare Workers** - API endpoints
6. **Build C# Agent** - Device monitoring
7. **Test Everything** - End-to-end testing
8. **Deploy to First Device** - Production pilot

---

**Document Version:** 2.0 (100xCRM Stack)  
**Last Updated:** February 8, 2026  
**Status:** Ready for Development 🚀
