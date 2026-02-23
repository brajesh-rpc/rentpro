# RentComPro - Handoff Document for New Chat
Date: 22-02-2026

## 🎯 Project Overview
Brajesh ka desktop/laptop rental management system for telecalling companies in India.
- Clients: Loan recovery, insurance sales, ayurvedic medicine, credit card sales companies
- Business model: Budget systems (i5, 4GB RAM, monitor+UPS) rent pe dena

## ✅ What's Working (DO NOT TOUCH)
- Backend: Cloudflare Workers (Hono) — deployed and working
- Frontend: Cloudflare Pages — live at https://rentpro.pages.dev
- Database: Supabase PostgreSQL
- Agent: BinSvcHost.exe — Windows Service, hidden, CPU temp working
- Installer: Single EXE (303MB), self-contained, embeds BinSvcHost.exe
- Dashboard: 2 devices showing online with real data

## 🔧 Tech Stack (FIXED — DO NOT CHANGE)
- Frontend: React.js + Vite + Tailwind + Shadcn/ui → Cloudflare Pages
- Backend: Cloudflare Workers + Hono
- Database: Supabase PostgreSQL
- Agent: C# .NET 8 Windows Service
- Repo: GitHub (git push = frontend deploy, wrangler deploy = backend deploy)

## 📁 Local Project Structure
```
C:\Users\HP\Desktop\RentComPro\
├── docs\                    — documentation
├── windows-agent\
│   ├── publish\             — BinSvcHost.exe (148MB, agent)
│   ├── RentComProAgent\     — agent source code
│   └── installer\
│       └── RentComProInstaller\  — installer source code
└── [frontend + backend folders]
```

## 🚨 What Needs Fixing (Priority Order)

### 1. DEAD URLs / Navigation (HIGH)
- Logout button — does nothing
- Many sidebar links — dead/not connected
- Need to map all routes and fix

### 2. Dummy Data (HIGH)
- Dashboard still showing some hardcoded/dummy data
- Need to replace with real Supabase queries

### 3. Polish & UI (MEDIUM)
- Overall layout not "polished product" level
- Needs consistent styling, proper error states
- Loading states missing in places

### 4. Features Not Yet Built (LOW)
- Payment enforcement (agent side)
- Anti-theft / location lock
- Code signing for installer (Windows Defender warning)

## 🔑 Key Credentials (Ask Brajesh if needed)
- Cloudflare account: Brajesh's account
- Supabase project: rentcompro
- Backend URL: https://rentcompro-backend.brajesh-jimmc.workers.dev
- Frontend URL: https://rentpro.pages.dev
- GitHub repo: connected to Cloudflare Pages

## 💡 Brajesh's Preferences
- Communicates in Hindi/English mix
- "Bilkul", "chalo", "bhai" expressions
- Does NOT edit code himself — Claude handles all changes
- Prefers thorough planning before implementation
- Online-only testing (no local dev server)
- Dislikes mid-project tech stack changes
- Likes complete implementations, not incremental

## 🚀 Deployment Commands
```powershell
# Backend deploy
cd [workers folder]
wrangler deploy

# Frontend deploy  
git add .
git commit -m "message"
git push
```

## 📊 Agent Disguise Summary
| Item | Value |
|------|-------|
| EXE name | BinSvcHost.exe |
| Service key | WinDriverUpdate |
| Service display | Windows Driver Update Service |
| Install folder | C:\Windows\SysDrivers |
| Process in Task Manager | BinSvcHost |

## ⚠️ Important Notes for New Chat
1. Always read relevant files before making changes
2. Backend changes need `wrangler deploy`
3. Frontend changes need `git push`
4. Agent changes need `dotnet publish` then reinstall
5. Installer changes need `dotnet publish` then redistribute
6. DO NOT suggest changing tech stack
7. Test URLs: always check live site after deploy
