# Preview Invoice Update - Adding Save Functionality

## Problem
Current `preview-invoice.html` has only "Generate PDF" button which:
- ❌ Does save to database BUT immediately prints
- ❌ User can't save without printing
- ❌ No way to save and view later

## Solution
Add TWO buttons:
1. **💾 Save Invoice** - Save to database only
2. **💾📄 Save & Print** - Save AND print PDF

## Changes Made

### Buttons Section
```html
OLD:
<div class="action-bar">
  <button class="btn btn-secondary" onclick="window.history.back()">← Back to Edit</button>
  <button class="btn btn-primary" onclick="generatePDF()">📄 Generate PDF</button>
</div>

NEW:
<div class="action-bar">
  <button class="btn btn-secondary" onclick="window.history.back()">← Back to Edit</button>
  <button class="btn btn-success" onclick="saveInvoice()">💾 Save Invoice</button>
  <button class="btn btn-primary" onclick="saveAndPrint()">💾📄 Save & Print</button>
</div>

<div id="message" class="message"></div>
```

### JavaScript Functions
```javascript
// NEW: Save invoice only (no print)
async function saveInvoice() {
  const token = localStorage.getItem('token');
  const messageEl = document.getElementById('message');

  try {
    messageEl.textContent = 'Saving invoice...';
    messageEl.className = 'message';
    messageEl.style.display = 'block';

    const response = await fetch(`${API_URL}/api/invoices`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(invoiceData),
    });

    const data = await response.json();

    if (data.success) {
      messageEl.textContent = '✅ Invoice saved successfully!';
      messageEl.className = 'message success';
      
      // Clear preview data
      localStorage.removeItem('invoicePreview');
      
      // Redirect after 2 seconds
      setTimeout(() => {
        window.location.href = '/invoices.html';
      }, 2000);
    } else {
      messageEl.textContent = `❌ ${data.message}`;
      messageEl.className = 'message error';
    }
  } catch (error) {
    console.error('Save invoice error:', error);
    messageEl.textContent = '❌ Failed to save invoice';
    messageEl.className = 'message error';
  }
}

// NEW: Save and print
async function saveAndPrint() {
  const token = localStorage.getItem('token');
  const messageEl = document.getElementById('message');

  try {
    messageEl.textContent = 'Saving invoice...';
    messageEl.className = 'message';
    messageEl.style.display = 'block';

    const response = await fetch(`${API_URL}/api/invoices`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(invoiceData),
    });

    const data = await response.json();

    if (data.success) {
      messageEl.textContent = '✅ Invoice saved! Opening print dialog...';
      messageEl.className = 'message success';
      
      // Print after 1 second
      setTimeout(() => {
        window.print();
        
        // Clear and redirect after print
        localStorage.removeItem('invoicePreview');
        setTimeout(() => {
          window.location.href = '/invoices.html';
        }, 1000);
      }, 1000);
    } else {
      messageEl.textContent = `❌ ${data.message}`;
      messageEl.className = 'message error';
    }
  } catch (error) {
    console.error('Save and print error:', error);
    messageEl.textContent = '❌ Failed to save invoice';
    messageEl.className = 'message error';
  }
}

// REMOVE: Old generatePDF function
```

## User Flow

### Save Invoice (New)
```
Click "Save Invoice"
  ↓
Save to Database
  ↓
Show Success Message
  ↓
Redirect to /invoices.html
```

### Save & Print (New)
```
Click "Save & Print"
  ↓
Save to Database
  ↓
Open Print Dialog
  ↓
User prints/cancels
  ↓
Redirect to /invoices.html
```

## Benefits
✅ User can save without printing
✅ User can save and print together
✅ Invoice saved to database properly
✅ Can view saved invoices later in /invoices.html
✅ Better UX - clear actions

## Files to Update
1. `Frontend/preview-invoice.html` - Add new buttons and functions
