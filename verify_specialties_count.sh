#!/bin/bash

# Verify Medical Specialties Count in Database
# This script checks that all 103 specialties were successfully inserted

echo "🔍 Verifying Medical Specialties in Database..."
echo ""

# Count total specialties in migration file
MIGRATION_COUNT=$(grep -E "^\('.*', '.*'," supabase/migrations/20250131000000_seed_medical_specialties.sql | wc -l | xargs)
echo "✅ Migration file contains: $MIGRATION_COUNT specialty records"

# List categories
echo ""
echo "📋 Specialty Categories in Migration:"
echo "   • Primary Care & Family Medicine (5)"
echo "   • Surgical Specialties (10)"
echo "   • Internal Medicine Subspecialties (12)"
echo "   • Surgical Subspecialties (7)"
echo "   • Diagnostic Specialties (9)"
echo "   • Mental Health & Behavioral (6)"
echo "   • Pediatric Subspecialties (10)"
echo "   • Emergency & Critical Care (4)"
echo "   • Anesthesiology & Pain Management (5)"
echo "   • Rehabilitation & Physical Medicine (4)"
echo "   • Neurology & Neurosciences (6)"
echo "   • Dermatology (4)"
echo "   • Other Specialties (21)"
echo "   ────────────────────────────"
echo "   TOTAL: $MIGRATION_COUNT specialties"

echo ""
echo "🎯 Expected in Database: 103 specialties"
echo ""

# Check if Supabase CLI is available
if command -v npx &> /dev/null; then
    echo "📊 Querying database via Supabase CLI..."
    echo ""

    # Note: This requires Supabase project to be linked
    # Run: npx supabase link --project-ref YOUR_REF

    DB_COUNT=$(npx supabase db execute "SELECT COUNT(*) FROM specialties" --format csv 2>/dev/null | tail -1 | xargs)

    if [ -n "$DB_COUNT" ] && [ "$DB_COUNT" -gt 0 ]; then
        echo "✅ Database contains: $DB_COUNT specialties"

        if [ "$DB_COUNT" -eq 103 ]; then
            echo "✅ ✨ SUCCESS! All 103 specialties are in the database!"
        else
            echo "⚠️  WARNING: Expected 103, found $DB_COUNT"
            echo "   Run: npx supabase db push"
        fi
    else
        echo "⚠️  Could not query database"
        echo "   Make sure Supabase project is linked:"
        echo "   npx supabase link --project-ref YOUR_REF"
    fi
else
    echo "ℹ️  Supabase CLI not found"
    echo "   To verify database count, run:"
    echo "   npx supabase db execute \"SELECT COUNT(*) FROM specialties\""
fi

echo ""
echo "📝 To manually verify:"
echo "   1. Open Supabase Studio: https://supabase.com/dashboard"
echo "   2. Navigate to: Table Editor → specialties"
echo "   3. Check record count shows 103"
echo "   4. Or use SQL Editor:"
echo "      SELECT COUNT(*) FROM specialties;"
echo ""
echo "🚀 To use in FlutterFlow:"
echo "   Use custom action: getAllSpecialties()"
echo "   See: graphql_queries/SOLUTION_CUSTOM_ACTIONS.md"
