#!/usr/bin/env node

const https = require('https');

const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0NDc2MzksImV4cCI6MjA3NTAyMzYzOX0.t8doxWhvLDsu27jad_T1IvACBl5HpfFmo8IillYBppk';

function query(path) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'noaeltglphdlkbflipit.supabase.co',
            path: path,
            method: 'GET',
            headers: {
                'apikey': SUPABASE_KEY,
                'Authorization': `Bearer ${SUPABASE_KEY}`
            }
        };
        
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (e) {
                    console.error('Parse error:', e.message);
                    console.error('Raw data:', data);
                    resolve(null);
                }
            });
        });
        
        req.on('error', reject);
        req.end();
    });
}

async function main() {
    console.log('\n=== Checking Products & Inventory ===\n');
    
    // Check pharmacy_products
    const products = await query('/rest/v1/pharmacy_products?select=id,name,price,quantity_in_stock,product_type');
    console.log('pharmacy_products:');
    if (Array.isArray(products)) {
        console.log(`  Found ${products.length} records`);
        products.forEach(p => {
            console.log(`  - ${p.name || 'unnamed'}: ${p.price} XAF, Stock: ${p.quantity_in_stock}, Type: ${p.product_type}`);
        });
    } else {
        console.log('  Query failed or returned non-array');
    }
    
    // Check pharmacy_inventory
    const inventory = await query('/rest/v1/pharmacy_inventory?select=id,medication_id,quantity_available,unit_price');
    console.log('\npharmacy_inventory:');
    if (Array.isArray(inventory)) {
        console.log(`  Found ${inventory.length} records`);
        inventory.forEach(i => {
            console.log(`  - medication_id: ${i.medication_id}, quantity: ${i.quantity_available}, price: ${i.unit_price}`);
        });
    } else {
        console.log('  Query failed or returned non-array');
    }
    
    console.log('\n=== Check Complete ===\n');
}

main();
