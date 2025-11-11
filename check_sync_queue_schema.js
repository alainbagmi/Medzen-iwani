#!/usr/bin/env node

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://noaeltglphdlkbflipit.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function checkSchema() {
  // Query to get column names
  const { data, error } = await supabase
    .from('ehrbase_sync_queue')
    .select('*')
    .limit(1);

  if (error) {
    console.error('❌ Error:', error.message);
    return;
  }

  if (data && data.length > 0) {
    console.log('✅ Columns found in ehrbase_sync_queue:');
    console.log(Object.keys(data[0]).join(', '));
  } else {
    console.log('ℹ️  Table is empty, checking information_schema...');
    
    // Try raw SQL query
    const { data: schemaData, error: schemaError } = await supabase
      .rpc('exec_sql', { 
        query: `SELECT column_name FROM information_schema.columns 
                WHERE table_name = 'ehrbase_sync_queue' 
                ORDER BY ordinal_position` 
      });
    
    if (schemaError) {
      console.error('❌ Schema query error:', schemaError.message);
    } else {
      console.log('✅ Columns:', schemaData);
    }
  }
}

checkSchema();
