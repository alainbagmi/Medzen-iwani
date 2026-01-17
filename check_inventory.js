#!/usr/bin/env node

const https = require('https');

const SUPABASE_URL = 'https://noaeltglphdlkbflipit.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0NDc2MzksImV4cCI6MjA3NTAyMzYzOX0.t8doxWhvLDsu27jad_T1IvACBl5HpfFmo8IillYBppk';

function query(table, select = '*', filters = {}) {
    return new Promise((resolve, reject) => {
        let url = `/rest/v1/${table}?select=${select}`;
        
        for (const [key, value] of Object.entries(filters)) {
            url += `&${key}=${encodeURIComponent(value)}`;
        }
        
        const options = {
            hostname: 'noaeltglphdlkbflipit.supabase.co',
            path: url,
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
                    resolve(data);
                }
            });
        });
        
        req.on('error', reject);
        req.end();
    });
}

async function main() {
    console.log('\n=== Checking Pharmacy Inventory ===\n');
    
    try {
        const inventory = await query('pharmacy_inventory', 'count');
        console.log('pharmacy_inventory records:', Array.isArray(inventory) ? inventory.length : 'unknown');
        
        const products = await query('pharmacy_products', 'count');
        console.log('pharmacy_products records:', Array.isArray(products) ? products.length : 'unknown');
        
        if (Array.isArray(inventory) && inventory.length > 0) {
            console.log('\nSample inventory records:');
            const sample = await query('pharmacy_inventory', 'id,pharmacy_id,medication_id,quantity_available,unit_price', { limit: '3' });
            console.log(JSON.stringify(sample, null, 2));
        }
        
        console.log('\n=== Check Complete ===\n');
    } catch (error) {
        console.error('Error:', error.message);
    }
}

main();
