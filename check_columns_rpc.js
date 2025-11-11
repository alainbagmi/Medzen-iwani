#!/usr/bin/env node

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://noaeltglphdlkbflipit.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function checkColumns() {
  console.log('Checking ehrbase_sync_queue columns using RPC function...\n');
  
  const { data, error } = await supabase.rpc('check_ehrbase_sync_queue_columns');
  
  if (error) {
    console.log('❌ Error:', error.message);
    return;
  }
  
  console.log('✅ Columns in ehrbase_sync_queue table:');
  console.log('━'.repeat(60));
  data.forEach((col, i) => {
    console.log(`${i + 1}. ${col.column_name.padEnd(30)} (${col.data_type})`);
  });
  console.log('━'.repeat(60));
  console.log(`\nTotal columns: ${data.length}`);
  
  // Check for our required columns
  const hasSyncType = data.some(col => col.column_name === 'sync_type');
  const hasDataSnapshot = data.some(col => col.column_name === 'data_snapshot');
  const hasUserRole = data.some(col => col.column_name === 'user_role');
  const hasCompCategory = data.some(col => col.column_name === 'composition_category');
  
  console.log('\nRequired columns check:');
  console.log(`  sync_type: ${hasSyncType ? '✅' : '❌'}`);
  console.log(`  data_snapshot: ${hasDataSnapshot ? '✅' : '❌'}`);
  console.log(`  user_role: ${hasUserRole ? '✅' : '❌'}`);
  console.log(`  composition_category: ${hasCompCategory ? '✅' : '❌'}`);
}

checkColumns();
