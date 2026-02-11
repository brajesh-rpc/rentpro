# RentComPro - Complete Development Roadmap

## 🎯 Project Timeline: 3 Months to MVP

**Goal:** Working rental management system with payment enforcement & theft prevention

---

## 📅 Month 1: Foundation & Basic CRUD

### Week 1: Setup & Database Design

#### Day 1-2: Project Setup
```bash
Tasks:
✅ Create Supabase account
✅ Create GitHub repository
✅ Setup local development environment
✅ Install required tools

Deliverables:
- Supabase project created
- GitHub repo ready
- Local dev environment working
```

**Supabase Setup:**
```sql
-- Create Supabase project
Project Name: rentcompro
Region: Mumbai (ap-south-1)
Database Password: [secure password]

-- Get credentials:
Project URL: https://xxxxx.supabase.co
Anon Key: eyJhbGc...
Service Role Key: eyJhbGc... (keep secret!)
```

**GitHub Repo Structure:**
```
rentcompro/
├── frontend/          # React dashboard
├── backend/           # Cloudflare Workers
├── agent/             # C# Windows Service
├── docs/              # Documentation
└── README.md
```

#### Day 3-5: Database Schema Creation

**Create all tables in Supabase:**

```sql
-- 1. Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(15),
  role VARCHAR(50) NOT NULL, -- SUPER_ADMIN, STAFF, CLIENT
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Devices table
CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  serial_number VARCHAR(100) UNIQUE NOT NULL,
  device_type VARCHAR(50) NOT NULL, -- DESKTOP, LAPTOP
  brand VARCHAR(100),
  model VARCHAR(255),
  processor VARCHAR(255),
  ram_gb INTEGER,
  storage_gb INTEGER,
  storage_type VARCHAR(20), -- HDD, SSD
  monitor_size INTEGER,
  purchase_date DATE,
  purchase_price DECIMAL(10,2),
  monthly_rent DECIMAL(10,2),
  security_deposit DECIMAL(10,2),
  condition VARCHAR(50), -- NEW, GOOD, FAIR, POOR
  status VARCHAR(50) DEFAULT 'AVAILABLE', -- AVAILABLE, DEPLOYED, MAINTENANCE, DAMAGED, STOLEN
  assigned_client_id UUID REFERENCES clients(id),
  assigned_at TIMESTAMPTZ,
  last_seen TIMESTAMPTZ,
  is_online BOOLEAN DEFAULT false,
  current_location JSONB,
  registered_location JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Clients table
CREATE TABLE clients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_name VARCHAR(255) NOT NULL,
  owner_name VARCHAR(255) NOT NULL,
  phone VARCHAR(15) NOT NULL,
  alternate_phone VARCHAR(15),
  email VARCHAR(255),
  whatsapp VARCHAR(15),
  business_type VARCHAR(100), -- LOAN_RECOVERY, INSURANCE_SALES, etc.
  gst_number VARCHAR(20),
  pan_number VARCHAR(20),
  office_address TEXT NOT NULL,
  gps_location JSONB,
  landmark VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  pincode VARCHAR(10),
  landlord_contact VARCHAR(15),
  credit_limit DECIMAL(10,2),
  security_deposit DECIMAL(10,2),
  late_penalty_percent DECIMAL(5,2) DEFAULT 0,
  status VARCHAR(50) DEFAULT 'ACTIVE', -- ACTIVE, OVERDUE, SUSPENDED, BLACKLISTED
  credit_score INTEGER DEFAULT 50,
  documents JSONB,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Payments table
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID REFERENCES clients(id) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  payment_date TIMESTAMPTZ NOT NULL,
  payment_method VARCHAR(50), -- CASH, BANK_TRANSFER, UPI, CHEQUE
  transaction_id VARCHAR(255),
  receipt_number VARCHAR(100) UNIQUE NOT NULL,
  for_month VARCHAR(7), -- YYYY-MM format
  rent_amount DECIMAL(10,2),
  late_fee DECIMAL(10,2),
  advance_months INTEGER DEFAULT 0,
  collected_by UUID REFERENCES users(id),
  proof_photo TEXT,
  status VARCHAR(50) DEFAULT 'PAID', -- PAID, PARTIALLY_PAID, PENDING, OVERDUE
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Hardware Stats table
CREATE TABLE hardware_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  cpu_temp DECIMAL(5,2),
  cpu_usage DECIMAL(5,2),
  cpu_clock_speed DECIMAL(5,2),
  ram_total INTEGER,
  ram_used INTEGER,
  ram_errors INTEGER DEFAULT 0,
  disk_total INTEGER,
  disk_used INTEGER,
  disk_health INTEGER,
  disk_life_remaining DECIMAL(5,2),
  bad_sectors INTEGER DEFAULT 0,
  gpu_temp DECIMAL(5,2),
  gpu_usage DECIMAL(5,2),
  system_temp DECIMAL(5,2),
  fan_speed INTEGER,
  voltage_12v DECIMAL(5,2),
  voltage_5v DECIMAL(5,2),
  voltage_3v DECIMAL(5,2),
  ip_address VARCHAR(50),
  internet_speed DECIMAL(10,2),
  data_usage DECIMAL(10,2),
  login_count INTEGER DEFAULT 0,
  active_hours DECIMAL(5,2),
  idle_hours DECIMAL(5,2),
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Alerts table
CREATE TABLE alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  alert_type VARCHAR(50) NOT NULL,
  severity VARCHAR(20) NOT NULL, -- INFO, WARNING, CRITICAL
  message TEXT NOT NULL,
  data JSONB,
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Maintenance table
CREATE TABLE maintenance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  issue_description TEXT NOT NULL,
  priority VARCHAR(20) NOT NULL, -- LOW, MEDIUM, HIGH, CRITICAL
  status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, IN_PROGRESS, RESOLVED
  reported_date TIMESTAMPTZ DEFAULT NOW(),
  resolved_date TIMESTAMPTZ,
  cost DECIMAL(10,2),
  technician_name VARCHAR(255),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_devices_status ON devices(status);
CREATE INDEX idx_devices_assigned ON devices(assigned_client_id);
CREATE INDEX idx_devices_serial ON devices(serial_number);
CREATE INDEX idx_clients_status ON clients(status);
CREATE INDEX idx_payments_client ON payments(client_id);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_hardware_device_time ON hardware_stats(device_id, timestamp);
CREATE INDEX idx_alerts_device ON alerts(device_id, created_at);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (basic - expand later)
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admins can view all devices" ON devices
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'SUPER_ADMIN'
    )
  );
```

#### Day 6-7: Test Database

```sql
-- Insert test data
INSERT INTO users (email, password_hash, name, role) VALUES
('admin@rentcompro.com', 'hash_here', 'Admin User', 'SUPER_ADMIN');

INSERT INTO devices (serial_number, device_type, brand, model, processor, ram_gb, storage_gb, storage_type, monthly_rent, security_deposit, status) VALUES
('DEV001', 'DESKTOP', 'Dell', 'OptiPlex 3020', 'i5-4590', 4, 500, 'HDD', 1000, 5000, 'AVAILABLE'),
('DEV002', 'DESKTOP', 'HP', 'ProDesk 600 G1', 'i5-4570', 4, 500, 'HDD', 1000, 5000, 'AVAILABLE');

-- Test queries
SELECT * FROM devices WHERE status = 'AVAILABLE';
SELECT * FROM clients WHERE status = 'ACTIVE';
```

---

### Week 2: Frontend Boilerplate

#### Day 8-10: React Project Setup

```bash
# Create React project with Vite
npm create vite@latest frontend -- --template react-ts
cd frontend
npm install

# Install dependencies
npm install @supabase/supabase-js
npm install axios react-query
npm install react-router-dom
npm install zustand
npm install @shadcn/ui
npm install tailwindcss postcss autoprefixer
npm install react-hook-form zod @hookform/resolvers
npm install recharts
npm install lucide-react

# Initialize Tailwind
npx tailwindcss init -p

# Initialize Shadcn UI
npx shadcn-ui@latest init
```

**Project Structure:**
```
frontend/
├── src/
│   ├── components/
│   │   ├── ui/              # Shadcn components
│   │   ├── layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   └── Layout.tsx
│   │   └── dashboard/
│   │       └── StatsCard.tsx
│   │
│   ├── pages/
│   │   ├── Login.tsx
│   │   ├── Dashboard.tsx
│   │   ├── Devices.tsx
│   │   ├── Clients.tsx
│   │   └── Payments.tsx
│   │
│   ├── lib/
│   │   ├── supabase.ts      # Supabase client
│   │   └── api.ts           # API functions
│   │
│   ├── stores/
│   │   └── authStore.ts     # Zustand store
│   │
│   ├── types/
│   │   └── index.ts         # TypeScript types
│   │
│   ├── App.tsx
│   └── main.tsx
│
├── .env.local
├── vite.config.ts
└── package.json
```

**Supabase Client Setup:**
```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

**Environment Variables:**
```bash
# .env.local
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc...
```

#### Day 11-14: Basic UI Components

**Create Layout:**
```tsx
// src/components/layout/Layout.tsx
export function Layout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen">
      <Sidebar />
      <div className="flex-1 flex flex-col">
        <Header />
        <main className="flex-1 overflow-auto p-6">
          {children}
        </main>
      </div>
    </div>
  )
}
```

**Create Login Page:**
```tsx
// src/pages/Login.tsx
import { useState } from 'react'
import { supabase } from '@/lib/supabase'

export function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  
  const handleLogin = async () => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    })
    
    if (error) {
      alert(error.message)
    } else {
      // Redirect to dashboard
      window.location.href = '/dashboard'
    }
  }
  
  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="w-full max-w-md p-8 space-y-4 bg-white rounded-lg shadow">
        <h1 className="text-2xl font-bold">RentComPro Login</h1>
        <input
          type="email"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full px-4 py-2 border rounded"
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full px-4 py-2 border rounded"
        />
        <button
          onClick={handleLogin}
          className="w-full px-4 py-2 text-white bg-blue-600 rounded hover:bg-blue-700"
        >
          Login
        </button>
      </div>
    </div>
  )
}
```

**Deploy to Cloudflare Pages:**
```bash
# Push to GitHub
git add .
git commit -m "Initial frontend setup"
git push origin main

# Cloudflare Pages will auto-detect and deploy
# Setup: Cloudflare Dashboard → Pages → Connect GitHub
```

---

### Week 3: Devices CRUD

#### Day 15-17: Devices List Page

```tsx
// src/pages/Devices.tsx
import { useQuery } from 'react-query'
import { supabase } from '@/lib/supabase'

export function Devices() {
  const { data: devices, isLoading } = useQuery('devices', async () => {
    const { data, error } = await supabase
      .from('devices')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data
  })
  
  if (isLoading) return <div>Loading...</div>
  
  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Devices</h1>
        <button className="px-4 py-2 bg-blue-600 text-white rounded">
          Add Device
        </button>
      </div>
      
      <div className="bg-white rounded-lg shadow">
        <table className="w-full">
          <thead>
            <tr className="border-b">
              <th className="p-4 text-left">Serial Number</th>
              <th className="p-4 text-left">Brand</th>
              <th className="p-4 text-left">Model</th>
              <th className="p-4 text-left">Status</th>
              <th className="p-4 text-left">Rent</th>
              <th className="p-4 text-left">Actions</th>
            </tr>
          </thead>
          <tbody>
            {devices?.map((device) => (
              <tr key={device.id} className="border-b">
                <td className="p-4">{device.serial_number}</td>
                <td className="p-4">{device.brand}</td>
                <td className="p-4">{device.model}</td>
                <td className="p-4">
                  <span className={`px-2 py-1 rounded text-sm ${
                    device.status === 'AVAILABLE' ? 'bg-green-100 text-green-800' :
                    device.status === 'DEPLOYED' ? 'bg-blue-100 text-blue-800' :
                    'bg-gray-100 text-gray-800'
                  }`}>
                    {device.status}
                  </span>
                </td>
                <td className="p-4">₹{device.monthly_rent}</td>
                <td className="p-4">
                  <button className="text-blue-600 hover:underline">
                    Edit
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

#### Day 18-21: Add/Edit Device Form

```tsx
// src/components/devices/DeviceForm.tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { supabase } from '@/lib/supabase'

const deviceSchema = z.object({
  serial_number: z.string().min(1, 'Serial number required'),
  device_type: z.enum(['DESKTOP', 'LAPTOP']),
  brand: z.string().min(1, 'Brand required'),
  model: z.string().min(1, 'Model required'),
  processor: z.string(),
  ram_gb: z.number().min(2).max(64),
  storage_gb: z.number().min(100),
  storage_type: z.enum(['HDD', 'SSD']),
  monthly_rent: z.number().min(0),
  security_deposit: z.number().min(0),
})

export function DeviceForm({ deviceId, onSuccess }) {
  const { register, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(deviceSchema)
  })
  
  const onSubmit = async (data) => {
    if (deviceId) {
      // Update
      const { error } = await supabase
        .from('devices')
        .update(data)
        .eq('id', deviceId)
      
      if (error) {
        alert(error.message)
      } else {
        onSuccess()
      }
    } else {
      // Insert
      const { error } = await supabase
        .from('devices')
        .insert(data)
      
      if (error) {
        alert(error.message)
      } else {
        onSuccess()
      }
    }
  }
  
  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div>
        <label>Serial Number *</label>
        <input
          {...register('serial_number')}
          className="w-full px-4 py-2 border rounded"
        />
        {errors.serial_number && (
          <p className="text-red-500 text-sm">{errors.serial_number.message}</p>
        )}
      </div>
      
      <div>
        <label>Device Type *</label>
        <select {...register('device_type')} className="w-full px-4 py-2 border rounded">
          <option value="DESKTOP">Desktop</option>
          <option value="LAPTOP">Laptop</option>
        </select>
      </div>
      
      <div>
        <label>Brand *</label>
        <input {...register('brand')} className="w-full px-4 py-2 border rounded" />
      </div>
      
      {/* Add more fields... */}
      
      <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded">
        {deviceId ? 'Update' : 'Add'} Device
      </button>
    </form>
  )
}
```

**Week 3 Deliverables:**
✅ Devices list page with table
✅ Add device form
✅ Edit device form
✅ Delete device functionality
✅ Search & filter devices

---

### Week 4: Clients CRUD

**Similar to Devices CRUD:**
- Clients list page
- Add client form (with all fields)
- Edit client
- Client details page
- Document upload (Supabase Storage)

**Key Features:**
```typescript
// Upload client documents
const uploadDocument = async (file: File) => {
  const { data, error } = await supabase.storage
    .from('client-documents')
    .upload(`${clientId}/${file.name}`, file)
  
  if (error) throw error
  return data.path
}

// Get public URL
const { data } = supabase.storage
  .from('client-documents')
  .getPublicUrl(path)
```

**Week 4 Deliverables:**
✅ Clients list page
✅ Add/edit client forms
✅ Document upload functionality
✅ Client details page
✅ Client status management

---

## 📅 Month 2: Core Features & Desktop Agent

### Week 5: Payment Management

#### Payment Recording Page

```tsx
// src/pages/Payments.tsx
export function Payments() {
  const [selectedClient, setSelectedClient] = useState<string>('')
  
  const recordPayment = async (data) => {
    // Generate receipt number
    const receiptNumber = `RCP${Date.now()}`
    
    const payment = {
      client_id: data.client_id,
      amount: data.amount,
      payment_date: new Date(),
      payment_method: data.payment_method,
      receipt_number: receiptNumber,
      for_month: data.for_month,
      collected_by: userId,
      status: 'PAID'
    }
    
    const { error } = await supabase
      .from('payments')
      .insert(payment)
    
    if (!error) {
      // Generate PDF receipt
      generateReceipt(payment)
      
      // Send SMS confirmation
      sendSMS(clientPhone, `Payment received. Receipt: ${receiptNumber}`)
    }
  }
  
  return (
    // Payment form UI
  )
}
```

#### Receipt Generation

```typescript
// src/lib/receipt.ts
import jsPDF from 'jspdf'

export function generateReceipt(payment, client) {
  const doc = new jsPDF()
  
  // Company header
  doc.setFontSize(20)
  doc.text('RentComPro', 105, 20, { align: 'center' })
  
  // Receipt details
  doc.setFontSize(12)
  doc.text(`Receipt No: ${payment.receipt_number}`, 20, 40)
  doc.text(`Date: ${formatDate(payment.payment_date)}`, 20, 50)
  doc.text(`Client: ${client.company_name}`, 20, 60)
  doc.text(`Amount: ₹${payment.amount}`, 20, 70)
  doc.text(`Payment Method: ${payment.payment_method}`, 20, 80)
  
  // Save
  doc.save(`receipt-${payment.receipt_number}.pdf`)
}
```

**Week 5 Deliverables:**
✅ Payment recording form
✅ Payment history table
✅ Receipt generation (PDF)
✅ Payment status tracking
✅ Overdue payments list

---

### Week 6: Dashboard & Analytics

#### Dashboard with Stats

```tsx
// src/pages/Dashboard.tsx
export function Dashboard() {
  const { data: stats } = useQuery('dashboard-stats', async () => {
    // Total devices
    const { count: totalDevices } = await supabase
      .from('devices')
      .select('*', { count: 'exact', head: true })
    
    // Deployed devices
    const { count: deployedDevices } = await supabase
      .from('devices')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'DEPLOYED')
    
    // This month revenue
    const { data: payments } = await supabase
      .from('payments')
      .select('amount')
      .gte('payment_date', startOfMonth)
    
    const revenue = payments?.reduce((sum, p) => sum + p.amount, 0) || 0
    
    // Pending payments
    const { count: pendingPayments } = await supabase
      .from('payments')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'PENDING')
    
    return {
      totalDevices,
      deployedDevices,
      revenue,
      pendingPayments
    }
  })
  
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Dashboard</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
        <StatsCard
          title="Total Devices"
          value={stats?.totalDevices || 0}
          icon="HardDrive"
        />
        <StatsCard
          title="Deployed"
          value={stats?.deployedDevices || 0}
          icon="Truck"
        />
        <StatsCard
          title="Revenue (This Month)"
          value={`₹${stats?.revenue || 0}`}
          icon="DollarSign"
        />
        <StatsCard
          title="Pending Payments"
          value={stats?.pendingPayments || 0}
          icon="AlertCircle"
        />
      </div>
      
      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <RevenueChart />
        <DeviceStatusChart />
      </div>
    </div>
  )
}
```

**Week 6 Deliverables:**
✅ Dashboard with stats cards
✅ Revenue chart (monthly trend)
✅ Device status pie chart
✅ Recent activities list
✅ Quick actions panel

---

### Week 7-8: Desktop Agent (C# Windows Service)

#### C# Project Setup

```bash
# Create Windows Service project
dotnet new worker -n RentComProAgent
cd RentComProAgent

# Add NuGet packages
dotnet add package OpenHardwareMonitor
dotnet add package Supabase
dotnet add package Newtonsoft.Json
```

#### Main Service Class

```csharp
// Worker.cs
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace RentComProAgent
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly SupabaseClient _supabase;
        private Timer _heartbeatTimer;
        private Timer _hardwareTimer;
        
        public Worker(ILogger<Worker> logger)
        {
            _logger = logger;
            _supabase = new SupabaseClient();
        }
        
        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("RentComPro Agent started");
            
            // Send heartbeat every 5 minutes
            _heartbeatTimer = new Timer(SendHeartbeat, null, 
                TimeSpan.Zero, TimeSpan.FromMinutes(5));
            
            // Collect hardware stats every 15 minutes
            _hardwareTimer = new Timer(CollectHardwareStats, null, 
                TimeSpan.Zero, TimeSpan.FromMinutes(15));
            
            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(60000, stoppingToken); // 1 minute
            }
        }
        
        private async void SendHeartbeat(object state)
        {
            try
            {
                var data = new
                {
                    device_id = GetDeviceId(),
                    timestamp = DateTime.UtcNow,
                    is_online = true
                };
                
                await _supabase.SendHeartbeat(data);
                _logger.LogInformation("Heartbeat sent successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending heartbeat");
            }
        }
        
        private async void CollectHardwareStats(object state)
        {
            try
            {
                var monitor = new HardwareMonitor();
                var stats = monitor.CollectStats();
                stats.DeviceId = GetDeviceId();
                
                await _supabase.SendHardwareStats(stats);
                _logger.LogInformation("Hardware stats sent successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error collecting hardware stats");
            }
        }
        
        private string GetDeviceId()
        {
            // Get unique device ID (motherboard serial or similar)
            var serialNumber = GetMotherboardSerial();
            return serialNumber;
        }
    }
}
```

#### Hardware Monitor

```csharp
// HardwareMonitor.cs
using OpenHardwareMonitor.Hardware;

public class HardwareMonitor
{
    private Computer _computer;
    
    public HardwareMonitor()
    {
        _computer = new Computer
        {
            CPUEnabled = true,
            RAMEnabled = true,
            GPUEnabled = true,
            HDDEnabled = true,
            MainboardEnabled = true
        };
        _computer.Open();
    }
    
    public HardwareStats CollectStats()
    {
        _computer.Accept(new UpdateVisitor());
        
        var stats = new HardwareStats
        {
            CpuTemp = GetCpuTemperature(),
            CpuUsage = GetCpuUsage(),
            RamTotal = GetTotalRam(),
            RamUsed = GetUsedRam(),
            DiskHealth = GetDiskSmartData(),
            Timestamp = DateTime.UtcNow
        };
        
        return stats;
    }
    
    private float GetCpuTemperature()
    {
        foreach (var hardware in _computer.Hardware)
        {
            if (hardware.HardwareType == HardwareType.CPU)
            {
                hardware.Update();
                foreach (var sensor in hardware.Sensors)
                {
                    if (sensor.SensorType == SensorType.Temperature)
                    {
                        return sensor.Value ?? 0;
                    }
                }
            }
        }
        return 0;
    }
    
    private float GetCpuUsage()
    {
        foreach (var hardware in _computer.Hardware)
        {
            if (hardware.HardwareType == HardwareType.CPU)
            {
                hardware.Update();
                foreach (var sensor in hardware.Sensors)
                {
                    if (sensor.SensorType == SensorType.Load && 
                        sensor.Name == "CPU Total")
                    {
                        return sensor.Value ?? 0;
                    }
                }
            }
        }
        return 0;
    }
}
```

#### Supabase Client

```csharp
// SupabaseClient.cs
using Supabase;
using System.Net.Http;

public class SupabaseClient
{
    private readonly string _url;
    private readonly string _key;
    private readonly HttpClient _httpClient;
    
    public SupabaseClient()
    {
        _url = "https://xxxxx.supabase.co";
        _key = "your-anon-key";
        _httpClient = new HttpClient();
        _httpClient.DefaultRequestHeaders.Add("apikey", _key);
        _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {_key}");
    }
    
    public async Task SendHeartbeat(object data)
    {
        var json = JsonConvert.SerializeObject(data);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        await _httpClient.PostAsync($"{_url}/rest/v1/heartbeats", content);
    }
    
    public async Task SendHardwareStats(HardwareStats stats)
    {
        var json = JsonConvert.SerializeObject(stats);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        await _httpClient.PostAsync($"{_url}/rest/v1/hardware_stats", content);
    }
}
```

#### Install as Windows Service

```bash
# Publish the project
dotnet publish -c Release -r win-x64 --self-contained

# Install as service
sc create RentComProAgent binPath="C:\Path\To\RentComProAgent.exe"
sc start RentComProAgent

# Set to auto-start
sc config RentComProAgent start=auto
```

**Week 7-8 Deliverables:**
✅ Windows Service project
✅ Heartbeat functionality
✅ Hardware monitoring (CPU, RAM, Disk)
✅ Supabase API integration
✅ Service installer
✅ Test on 2-3 devices

---

## 📅 Month 3: Advanced Features & Testing

### Week 9: Payment Enforcement

#### Payment Status Check

```csharp
// PaymentEnforcer.cs
public class PaymentEnforcer
{
    private readonly SupabaseClient _supabase;
    
    public async Task<PaymentStatus> CheckPaymentStatus()
    {
        var deviceId = GetDeviceId();
        var response = await _supabase.GetPaymentStatus(deviceId);
        return response;
    }
    
    public void EnforceRestrictions(PaymentStatus status)
    {
        switch (status.DaysOverdue)
        {
            case 0:
                // All good - remove restrictions
                RemoveAllRestrictions();
                break;
                
            case <= 3:
                // Level 1: Show reminder
                ShowPaymentReminder(status);
                break;
                
            case <= 7:
                // Level 2: Limit usage to 4 hours/day
                SetUsageLimit(4);
                ShowWarningScreen(status);
                break;
                
            case <= 15:
                // Level 3: Limit to 2 hours/day
                SetUsageLimit(2);
                ShowCriticalWarning(status);
                break;
                
            default:
                // Level 4: Lock device
                LockDevice(status);
                break;
        }
    }
    
    private void ShowPaymentReminder(PaymentStatus status)
    {
        // Show popup on login
        var form = new PaymentReminderForm
        {
            Message = $"Payment due: ₹{status.AmountDue}",
            DueDate = status.DueDate,
            ContactNumber = "+91-XXXXXXXXXX"
        };
        form.ShowDialog();
    }
    
    private void LockDevice(PaymentStatus status)
    {
        // Create lock screen
        var lockForm = new FullScreenLockForm
        {
            Message = "Device locked due to payment default",
            AmountDue = status.AmountDue,
            ContactNumber = "+91-XXXXXXXXXX"
        };
        
        // Make form topmost and fullscreen
        lockForm.FormBorderStyle = FormBorderStyle.None;
        lockForm.WindowState = FormWindowState.Maximized;
        lockForm.TopMost = true;
        lockForm.Show();
        
        // Disable Task Manager
        DisableTaskManager();
    }
}
```

**Week 9 Deliverables:**
✅ Payment status API endpoint
✅ Restriction enforcement logic
✅ Payment reminder popup
✅ Warning screens (Level 2-3)
✅ Device lock screen (Level 4)
✅ Usage time limiter

---

### Week 10: Hardware Health Alerts

#### Alert Detection Service

```typescript
// backend/src/services/alertService.ts
export async function checkHardwareHealth() {
  // Get latest stats for all devices
  const { data: stats } = await supabase
    .from('hardware_stats')
    .select(`
      *,
      devices(id, serial_number, assigned_client_id)
    `)
    .order('timestamp', { ascending: false })
  
  for (const stat of stats) {
    const alerts = []
    
    // CPU temperature check
    if (stat.cpu_temp > 85) {
      alerts.push({
        device_id: stat.device_id,
        alert_type: 'HARDWARE_CRITICAL',
        severity: 'CRITICAL',
        message: `CPU temperature critical: ${stat.cpu_temp}°C`
      })
    } else if (stat.cpu_temp > 75) {
      alerts.push({
        device_id: stat.device_id,
        alert_type: 'HARDWARE_WARNING',
        severity: 'WARNING',
        message: `CPU temperature high: ${stat.cpu_temp}°C`
      })
    }
    
    // SSD health check
    if (stat.disk_health < 10) {
      alerts.push({
        device_id: stat.device_id,
        alert_type: 'HARDWARE_CRITICAL',
        severity: 'CRITICAL',
        message: `SSD health critical: ${stat.disk_health}% remaining`
      })
    }
    
    // RAM errors
    if (stat.ram_errors > 0) {
      alerts.push({
        device_id: stat.device_id,
        alert_type: 'HARDWARE_WARNING',
        severity: 'WARNING',
        message: `RAM errors detected: ${stat.ram_errors} errors`
      })
    }
    
    // Insert alerts
    if (alerts.length > 0) {
      await supabase.from('alerts').insert(alerts)
      
      // Send SMS notification
      await sendSMS(
        adminPhone,
        `Hardware alert: ${stat.devices.serial_number} - ${alerts[0].message}`
      )
    }
  }
}

// Run every hour
setInterval(checkHardwareHealth, 3600000)
```

**Week 10 Deliverables:**
✅ Hardware health monitoring service
✅ Alert detection logic
✅ Critical alerts (SMS notifications)
✅ Alerts dashboard page
✅ Alert resolution workflow

---

### Week 11: SMS Integration & Anti-Theft

#### SMS Service

```typescript
// backend/src/services/smsService.ts
import axios from 'axios'

export async function sendSMS(phone: string, message: string) {
  const apiKey = process.env.FAST2SMS_API_KEY
  
  const response = await axios.post('https://www.fast2sms.com/dev/bulkV2', {
    authorization: apiKey,
    route: 'q',
    message: message,
    numbers: phone
  })
  
  return response.data
}

// Payment reminder cron
export async function sendPaymentReminders() {
  // Get all overdue payments
  const { data: overdueClients } = await supabase
    .from('clients')
    .select(`
      *,
      payments!inner(*)
    `)
    .eq('status', 'OVERDUE')
  
  for (const client of overdueClients) {
    const message = `Dear ${client.owner_name}, your rent payment of ₹${client.monthly_rent} is overdue. Please pay at the earliest to avoid service disruption. Contact: +91-XXXXXXXXXX`
    
    await sendSMS(client.phone, message)
    
    // Log notification
    await supabase.from('notifications').insert({
      client_id: client.id,
      type: 'PAYMENT_REMINDER',
      message: message,
      sent_at: new Date()
    })
  }
}
```

#### GPS Tracking

```csharp
// LocationTracker.cs
public class LocationTracker
{
    public async Task<Location> GetCurrentLocation()
    {
        // Try WiFi-based location first
        var location = await GetWiFiLocation();
        
        if (location == null)
        {
            // Fallback to IP geolocation
            location = await GetIPLocation();
        }
        
        return location;
    }
    
    private async Task<Location> GetWiFiLocation()
    {
        try
        {
            var networks = GetNearbyWiFiNetworks();
            
            // Call Google Geolocation API
            var request = new
            {
                wifiAccessPoints = networks.Select(n => new
                {
                    macAddress = n.MacAddress,
                    signalStrength = n.SignalStrength
                }).ToList()
            };
            
            var response = await _httpClient.PostAsync(
                "https://www.googleapis.com/geolocation/v1/geolocate?key=YOUR_API_KEY",
                new StringContent(JsonConvert.SerializeObject(request))
            );
            
            var result = await response.Content.ReadAsStringAsync();
            var location = JsonConvert.DeserializeObject<Location>(result);
            
            return location;
        }
        catch
        {
            return null;
        }
    }
}
```

**Week 11 Deliverables:**
✅ SMS integration (Fast2SMS)
✅ Automated payment reminders
✅ GPS/WiFi location tracking
✅ Movement alerts
✅ Location history

---

### Week 12: Testing, Bug Fixes & Documentation

#### Testing Checklist

```
Manual Testing:
☐ User login/logout
☐ Add/edit/delete devices
☐ Add/edit/delete clients
☐ Record payments
☐ Generate receipts
☐ Dashboard stats accuracy
☐ Hardware stats collection
☐ Payment enforcement (all levels)
☐ SMS notifications
☐ Alert generation
☐ Location tracking

Load Testing:
☐ 100 devices heartbeat simultaneously
☐ 1000 API requests/minute
☐ Large dataset queries

Security Testing:
☐ SQL injection attempts
☐ XSS attempts
☐ Authentication bypass attempts
☐ RLS policies working

Device Agent Testing:
☐ Install on fresh Windows
☐ Service auto-start after reboot
☐ Heartbeat sending
☐ Hardware stats accurate
☐ Payment restrictions working
☐ Uninstall prevention
```

#### Bug Fixes & Polish

- Fix any UI issues
- Improve performance
- Add loading states
- Error handling
- Responsive design fixes
- Cross-browser testing

#### Documentation

```
Create:
✅ User manual (how to use dashboard)
✅ Agent installation guide
✅ API documentation
✅ Deployment guide
✅ Troubleshooting guide
```

**Week 12 Deliverables:**
✅ All bugs fixed
✅ Performance optimized
✅ Complete testing done
✅ Documentation ready
✅ Ready for first 10 devices deployment

---

## 🎯 Post-MVP (Month 4+)

### Phase 2 Features
- Mobile app (React Native)
- Advanced reports & analytics
- WhatsApp integration
- Maintenance scheduling
- Automated reminders
- Client portal
- Multi-user access
- Audit logs

### Phase 3 Features
- Predictive maintenance (ML)
- Bulk operations
- Advanced theft recovery
- Contract management
- Barcode/QR scanning
- Voice commands
- Multi-language support

---

## ✅ Success Criteria

**MVP is complete when:**
1. ✅ Can manage 50+ devices
2. ✅ Can track 50+ clients
3. ✅ Payment enforcement working
4. ✅ Hardware monitoring active
5. ✅ SMS notifications sending
6. ✅ Dashboard shows real data
7. ✅ Desktop agent stable
8. ✅ Deployed to 10 real devices
9. ✅ Zero downtime for 1 week
10. ✅ User feedback positive

---

## 📊 Resource Requirements

### Team
- 1 Full-stack Developer (You!)
- Time: 3 months (3-4 hours/day)

### Tools & Services
- Total Cost: ₹0-500/month
- All FREE tiers initially

### Hardware for Testing
- 2-3 old desktops/laptops
- Windows 10/11
- Internet connection

---

**Ready to start! Let's build RentComPro! 🚀**

**Next Action:** Setup Supabase project and create database schema!
