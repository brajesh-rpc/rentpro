# RentComPro Frontend

Frontend application for RentComPro - Desktop & Laptop Rental Management System

## Deployment

This folder is deployed to Cloudflare Pages.

**Build settings:**
- Build command: (none)
- Build output directory: `/Frontend`
- Root directory: `Frontend`

## Structure

```
Frontend/
├── index.html              # Landing/Login page
├── login.html              # Login page (deprecated)
├── dashboard.html          # Main dashboard
├── add-device.html         # Add device form
├── register-client.html    # Register client form
├── edit-client.html        # Edit client form
├── manage-clients.html     # Client list
├── view-client.html        # View client details
├── manage-assets.html      # Manage rental items
├── create-invoice.html     # Create invoice form
├── preview-invoice.html    # Invoice preview & PDF
└── invoices.html           # Invoice list
```

## Local Development

Simply open `index.html` in a browser.

All HTML files are standalone with inline CSS and JavaScript.

## API Configuration

The frontend automatically detects environment:
- Local: `http://localhost:8787`
- Production: `https://rentcompro-backend.brajesh-jimmc.workers.dev`

## Features

- ✅ Authentication & Authorization
- ✅ Dashboard with real-time stats
- ✅ Client Management
- ✅ Device Management
- ✅ Rental Items Management
- ✅ Invoice Generation (with/without GST)
- ✅ Payment Tracking
- ✅ Asset History

## Notes

- No build process required
- Pure HTML/CSS/JS
- No framework dependencies
- Mobile responsive
