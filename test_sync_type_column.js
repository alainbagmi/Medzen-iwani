#!/usr/bin/env node

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://noaeltglphdlkbflipit.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function testColumn() {
  console.log('Testing sync_type column access...\n');
  
  // Try 1: Select all columns
  console.log('1. Selecting all columns:');
  const { data: all, error: allError } = await supabase
    .from('ehrbase_sync_queue')
    .select('*')
    .limit(1);
  
  if (allError) {
    console.log('   ❌ Error:', allError.message);
  } else {
    console.log('   ✅ Success, columns:', all.length > 0 ? Object.keys(all[0]).join(', ') : 'empty table');
  }
  
  // Try 2: Select specific columns including sync_type
  console.log('\n2. Selecting specific columns (id, sync_type):');
  const { data: specific, error: specificError } = await supabase
    .from('ehrbase_sync_queue')
    .select('id, sync_type')
    .limit(1);
  
  if (specificError) {
    console.log('   ❌ Error:', specificError.message);
    console.log('   Error details:', JSON.stringify(specificError, null, 2));
  } else {
    console.log('   ✅ Success');
  }
  
  // Try 3: Filter by sync_type
  console.log('\n3. Filtering by sync_type:');
  const { data: filtered, error: filterError } = await supabase
    .from('ehrbase_sync_queue')
    .select('id')
    .eq('sync_type', 'role_profile_create')
    .limit(1);
  
  if (filterError) {
    console.log('   ❌ Error:', filterError.message);
  } else {
    console.log('   ✅ Success');
  }
}

testColumn();
