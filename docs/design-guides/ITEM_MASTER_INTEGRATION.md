# Item Master Integration in Invoice Creation

## Changes Required in create-invoice.html

### 1. Load Item Master on Page Load

Add this function after `loadRentalItems()`:

```javascript
// Load item master for quick selection
async function loadItemMaster() {
  const token = localStorage.getItem('token');
  
  try {
    const response = await fetch(`${API_URL}/api/items/active`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    const data = await response.json();
    if (data.success) {
      window.itemMaster = data.data; // Store globally
    }
  } catch (error) {
    console.error('Load item master error:', error);
  }
}
```

### 2. Update addRentalItem() Function

Replace the current `addRentalItem()` with:

```javascript
function addRentalItem(description = '', quantity = 1, rate = 0) {
  rentalItemCounter++;
  const id = `rental_${rentalItemCounter}`;
  
  // Build dropdown options from item master
  let itemOptions = '<option value="">-- Select Item --</option>';
  if (window.itemMaster) {
    const rentalItems = window.itemMaster.filter(item => item.item_type === 'RENTAL');
    itemOptions += rentalItems.map(item => 
      `<option value="${item.item_code}" data-rate="${item.default_rate}">
        ${item.item_name} (₹${item.default_rate}/month)
      </option>`
    ).join('');
  }
  itemOptions += '<option value="CUSTOM">-- Custom Item --</option>';
  
  const html = `
    <div class="item-row" id="${id}">
      <select class="item-select" onchange="selectItem(this, '${id}')" style="grid-column: span 2;">
        ${itemOptions}
      </select>
      <input type="text" class="item-description" placeholder="Description" value="${description}" onchange="calculateSummary()" style="display: none;">
      <input type="number" class="item-qty" placeholder="Qty" value="${quantity}" min="1" onchange="calculateSummary()">
      <input type="number" class="item-rate" placeholder="Rate" value="${rate}" step="0.01" onchange="calculateSummary()">
      <input type="number" class="item-amount" placeholder="Amount" value="${quantity * rate}" readonly>
      <button class="btn btn-danger btn-sm" onclick="removeItem('${id}')">×</button>
    </div>
  `;
  
  document.getElementById('rentalItems').insertAdjacentHTML('beforeend', html);
  calculateSummary();
}
```

### 3. Add selectItem() Function

```javascript
function selectItem(selectEl, rowId) {
  const selectedOption = selectEl.options[selectEl.selectedIndex];
  const row = document.getElementById(rowId);
  const descInput = row.querySelector('.item-description');
  const rateInput = row.querySelector('.item-rate');
  
  if (selectedOption.value === 'CUSTOM') {
    // Show description input for custom items
    selectEl.style.display = 'none';
    descInput.style.display = 'block';
    descInput.focus();
    rateInput.value = 0;
  } else if (selectedOption.value) {
    // Auto-fill from item master
    const rate = selectedOption.dataset.rate;
    descInput.value = selectedOption.text.split(' (₹')[0]; // Get item name
    rateInput.value = rate;
  } else {
    descInput.value = '';
    rateInput.value = 0;
  }
  
  calculateSummary();
}
```

### 4. Update Sale Items Similarly

Same approach for `addSaleItem()`:

```javascript
function addSaleItem() {
  saleItemCounter++;
  const id = `sale_${saleItemCounter}`;
  
  let itemOptions = '<option value="">-- Select Item --</option>';
  if (window.itemMaster) {
    const saleItems = window.itemMaster.filter(item => item.item_type === 'SALE');
    itemOptions += saleItems.map(item => 
      `<option value="${item.item_code}" data-rate="${item.default_rate}">
        ${item.item_name} (₹${item.default_rate})
      </option>`
    ).join('');
  }
  itemOptions += '<option value="CUSTOM">-- Custom Item --</option>';
  
  const html = `
    <div class="item-row" id="${id}">
      <select class="item-select" onchange="selectItem(this, '${id}')" style="grid-column: span 2;">
        ${itemOptions}
      </select>
      <input type="text" class="item-description" placeholder="Description" value="" onchange="calculateSummary()" style="display: none;">
      <input type="number" class="item-qty" placeholder="Qty" value="1" min="1" onchange="calculateSummary()">
      <input type="number" class="item-rate" placeholder="Rate" value="0" step="0.01" onchange="calculateSummary()">
      <input type="number" class="item-amount" placeholder="Amount" value="0" readonly>
      <button class="btn btn-danger btn-sm" onclick="removeItem('${id}')">×</button>
    </div>
  `;
  
  document.getElementById('saleItems').insertAdjacentHTML('beforeend', html);
  calculateSummary();
}
```

### 5. Update init() Function

Add loadItemMaster() call:

```javascript
async function init() {
  await loadClientData();
  await loadLastInvoice();
  await loadItemMaster();  // ← Add this
  await loadRentalItems();
  setDefaultDates();
  
  // ... rest of code
}
```

### 6. Update collectInvoiceData()

Change to get description from hidden input:

```javascript
// Rental items
document.querySelectorAll('#rentalItems .item-row').forEach(row => {
  const inputs = row.querySelectorAll('input');
  const descInput = row.querySelector('.item-description');
  items.push({
    itemType: 'RENTAL',
    description: descInput.value || 'Rental Item', // Use hidden description
    quantity: parseFloat(inputs[0].value),
    rate: parseFloat(inputs[1].value),
    amount: parseFloat(inputs[2].value)
  });
});
```

---

## Benefits:

✅ **Quick Selection** - Click dropdown, select item, auto-fill rate
✅ **Consistent Pricing** - Rates from Item Master
✅ **Custom Items** - Still can add custom items manually
✅ **Better UX** - Less typing, fewer errors
✅ **Integration** - Item Master actually useful now!

---

## Testing Flow:

1. Go to Item Master → Add items
2. Go to Create Invoice
3. Add Rental Item → See dropdown with items
4. Select item → Rate auto-fills
5. Change quantity → Amount calculates
6. Preview → Generate PDF

---

**Ye changes manually apply karo ya chahiye ki main complete updated create-invoice.html file banau?**
