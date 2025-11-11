#!/bin/bash

# Model Generator Script
# Generates Dart model files for Supabase tables
# Usage: ./generate_model.sh <table_name> <class_name>

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if table name provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}❌ Error: Table name and class name required${NC}"
    echo "Usage: ./generate_model.sh <table_name> <class_name>"
    echo "Example: ./generate_model.sh user_profiles UserProfiles"
    exit 1
fi

TABLE_NAME=$1
CLASS_NAME=$2
FILE_NAME="${TABLE_NAME}.dart"
MODEL_FILE="lib/backend/supabase/database/tables/${FILE_NAME}"

echo -e "${BLUE}📝 Generating model file...${NC}"
echo "Table name: $TABLE_NAME"
echo "Class name: $CLASS_NAME"
echo "File: $MODEL_FILE"

# Create model file with template
cat > "$MODEL_FILE" << 'EOF'
import '../database.dart';

class TABLE_NAMETable extends SupabaseTable<TABLE_NAMERow> {
  @override
  String get tableName => 'SNAKE_CASE_TABLE';

  @override
  TABLE_NAMERow createRow(Map<String, dynamic> data) =>
      TABLE_NAMERow(data);
}

class TABLE_NAMERow extends SupabaseDataRow {
  TABLE_NAMERow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TABLE_NAMETable();

  // Primary key
  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  // Add your fields here following these patterns:

  // String fields
  // String? get fieldName => getField<String>('field_name');
  // set fieldName(String? value) => setField<String>('field_name', value);

  // Integer fields
  // int? get fieldName => getField<int>('field_name');
  // set fieldName(int? value) => setField<int>('field_name', value);

  // Double fields
  // double? get fieldName => getField<double>('field_name');
  // set fieldName(double? value) => setField<double>('field_name', value);

  // Boolean fields
  // bool? get fieldName => getField<bool>('field_name');
  // set fieldName(bool? value) => setField<bool>('field_name', value);

  // DateTime fields
  // DateTime? get fieldName => getField<DateTime>('field_name');
  // set fieldName(DateTime? value) => setField<DateTime>('field_name', value);

  // List<String> fields (TEXT[] in PostgreSQL)
  // List<String> get fieldName => getListField<String>('field_name');
  // set fieldName(List<String>? value) => setListField<String>('field_name', value);

  // JSONB fields (dynamic type)
  // dynamic get fieldName => getField<dynamic>('field_name');
  // set fieldName(dynamic value) => setField<dynamic>('field_name', value);

  // Standard timestamps
  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
EOF

# Replace placeholders
sed -i '' "s/TABLE_NAME/${CLASS_NAME}/g" "$MODEL_FILE"
sed -i '' "s/SNAKE_CASE_TABLE/${TABLE_NAME}/g" "$MODEL_FILE"

echo -e "${GREEN}✅ Model file created successfully!${NC}"
echo -e "${YELLOW}📄 Location: $MODEL_FILE${NC}"
echo ""
echo "Next steps:"
echo "1. Edit the model file to add your field definitions"
echo "2. Add export to lib/backend/supabase/database/database.dart:"
echo "   export 'tables/${FILE_NAME}';"
echo "3. Run: flutter pub get"
echo "4. Test the model in your app"
echo ""
echo -e "${BLUE}💡 Field type mapping guide:${NC}"
echo "   PostgreSQL → Dart"
echo "   VARCHAR/TEXT → String"
echo "   INTEGER → int"
echo "   REAL/DOUBLE PRECISION → double"
echo "   BOOLEAN → bool"
echo "   TIMESTAMPTZ/DATE → DateTime"
echo "   TEXT[] → List<String>"
echo "   JSONB → dynamic"
echo "   UUID → String"
