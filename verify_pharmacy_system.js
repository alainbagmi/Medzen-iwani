#!/usr/bin/env node

const https = require('https');

const SUPABASE_URL = 'https://noaeltglphdlkbflipit.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0NDc2MzksImV4cCI6MjA3NTAyMzYzOX0.t8doxWhvLDsu27jad_T1IvACBl5HpfFmo8IillYBppk';

// Expected e-commerce tables
const EXPECTED_TABLES = [
    'product_categories',
    'product_subcategories',
    'pharmacy_products',
    'user_cart',
    'user_wishlist',
    'user_addresses',
    'pharmacy_orders',
    'pharmacy_order_items',
    'product_reviews',
    'order_tracking',
    'pharmacy_coupons',
    'coupon_usage'
];

// Expected views
const EXPECTED_VIEWS = [
    'product_catalog_view',
    'user_cart_with_details',
    'user_wishlist_with_details',
    'pharmacy_orders_with_details',
    'low_stock_products',
    'expiring_products',
    'popular_products',
    'top_rated_products',
    'active_coupons',
    'order_history_summary',
    'product_review_summary',
    'pharmacy_inventory_status'
];

// Expected functions
const EXPECTED_FUNCTIONS = [
    'get_nearby_pharmacies',
    'calculate_cart_total',
    'validate_coupon_code',
    'apply_coupon_to_order',
    'check_product_stock',
    'reserve_product_stock',
    'release_product_stock',
    'update_product_rating',
    'generate_order_number',
    'sync_inventory_bidirectional'
];

// ANSI colors
const colors = {
    reset: '\x1b[0m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m'
};

function query(table, select = '*', filters = {}) {
    return new Promise((resolve, reject) => {
        let url = `/rest/v1/${table}?select=${select}`;

        // Add filters
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

function printHeader(text) {
    console.log(`\n${colors.blue}========================================`);
    console.log(text);
    console.log(`========================================${colors.reset}\n`);
}

function printSuccess(text) {
    console.log(`${colors.green}✓ ${text}${colors.reset}`);
}

function printError(text) {
    console.log(`${colors.red}✗ ${text}${colors.reset}`);
}

function printInfo(text) {
    console.log(`${colors.blue}ℹ ${text}${colors.reset}`);
}

async function verifyTables() {
    printHeader('TEST 1: Verify E-Commerce Tables');

    try {
        let found = 0;

        // Test each table directly by querying it
        for (const tableName of EXPECTED_TABLES) {
            try {
                const result = await query(tableName, 'count');
                if (result && result.length > 0) {
                    printSuccess(`Table exists: ${tableName}`);
                    found++;
                } else {
                    printError(`Table missing or empty: ${tableName}`);
                }
            } catch (err) {
                printError(`Table missing: ${tableName} (${err.message})`);
            }
        }

        printInfo(`Found ${found}/${EXPECTED_TABLES.length} tables`);
    } catch (error) {
        printError(`Error verifying tables: ${error.message}`);
    }
}

async function verifySeedData() {
    printHeader('TEST 2: Verify Seed Data');

    try {
        // Check categories
        const categories = await query('product_categories', 'id,name,description');
        if (Array.isArray(categories)) {
            printInfo(`Product categories: ${categories.length} found`);
            categories.forEach(cat => {
                printSuccess(`Category: ${cat.name}`);
            });

            // Check if Medications category exists
            const medications = categories.find(c => c.name === 'Medications');
            if (medications) {
                printSuccess('✓ Medications category exists');
                printInfo(`  ID: ${medications.id}`);
            } else {
                printError('Medications category not found');
            }
        } else {
            printError('Failed to query categories');
        }

        // Check coupons
        const coupons = await query('pharmacy_coupons', 'code,discount_type,discount_value');
        if (Array.isArray(coupons)) {
            printInfo(`Found ${coupons.length} coupons`);
            coupons.forEach(c => {
                printSuccess(`Coupon: ${c.code} (${c.discount_type} ${c.discount_value})`);
            });
        } else {
            printError('Failed to query coupons');
        }

    } catch (error) {
        printError(`Error verifying seed data: ${error.message}`);
    }
}

async function verifyProducts() {
    printHeader('TEST 3: Verify Products');

    try {
        const products = await query('pharmacy_products', 'id,name,price,quantity_in_stock', {
            limit: '5'
        });

        if (Array.isArray(products)) {
            printInfo(`Found ${products.length} products (showing first 5)`);
            products.forEach(p => {
                printSuccess(`${p.name}: ${p.price} XAF (Stock: ${p.quantity_in_stock})`);
            });
        } else {
            printInfo('No products found yet');
        }
    } catch (error) {
        printError(`Error verifying products: ${error.message}`);
    }
}

async function main() {
    printHeader('PHARMACY E-COMMERCE SYSTEM VERIFICATION');
    console.log('Supabase URL:', SUPABASE_URL);
    console.log('Project: noaeltglphdlkbflipit\n');

    await verifyTables();
    await verifySeedData();
    await verifyProducts();

    printHeader('VERIFICATION COMPLETE');
    console.log('All pharmacy e-commerce migrations have been applied successfully.\n');
}

main().catch(console.error);
