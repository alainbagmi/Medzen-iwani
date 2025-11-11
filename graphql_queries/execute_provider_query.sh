#!/bin/bash

# =====================================================
# Medical Providers GraphQL Query Executor
# =====================================================
# Executes GraphQL queries against Supabase GraphQL API
# Usage: ./execute_provider_query.sh [query_type] [parameters]
# =====================================================

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0NDc2MzksImV4cCI6MjA3NTAyMzYzOX0.t8doxWhvLDsu27jad_T1IvACBl5HpfFmo8IillYBppk"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

GRAPHQL_URL="$SUPABASE_URL/graphql/v1"

# =====================================================
# Query 1: Get Specific Provider by User ID
# =====================================================

get_provider_by_id() {
  USER_ID=${1:-"ae6a139c-51fd-4d7c-877d-4bf19834a07d"}

  echo "Fetching provider details for user ID: $USER_ID"
  echo "======================================"

  QUERY='{
    "query": "query GetProvider($userId: UUID!) { medical_provider_profilesCollection(filter: { user_id: { eq: $userId } }) { edges { node { id user_id professional_role medical_license_number primary_specialization practice_type years_of_experience application_status consultation_fee_range patient_satisfaction_avg total_consultations video_consultation_enabled created_at updated_at users { full_name email phone_number avatar_url country } } } } }",
    "variables": {
      "userId": "'$USER_ID'"
    }
  }'

  curl -s "$GRAPHQL_URL" \
    -H "Content-Type: application/json" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -d "$QUERY" | jq '.'
}

# =====================================================
# Query 2: Get All Active Providers
# =====================================================

get_all_active_providers() {
  LIMIT=${1:-10}

  echo "Fetching all active providers (limit: $LIMIT)"
  echo "======================================"

  QUERY='{
    "query": "query GetAllProviders($limit: Int!) { medical_provider_profilesCollection(first: $limit, filter: { application_status: { eq: \"approved\" } }, orderBy: { created_at: DescNullsLast }) { edges { node { id user_id professional_role primary_specialization years_of_experience application_status users { full_name email } } } pageInfo { hasNextPage hasPreviousPage } } }",
    "variables": {
      "limit": '$LIMIT'
    }
  }'

  curl -s "$GRAPHQL_URL" \
    -H "Content-Type: application/json" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -d "$QUERY" | jq '.'
}

# =====================================================
# Query 3: Get Providers by Type
# =====================================================

get_providers_by_type() {
  PROVIDER_TYPE=${1:-"Medical Doctor"}
  LIMIT=${2:-20}

  echo "Fetching providers of type: $PROVIDER_TYPE (limit: $LIMIT)"
  echo "======================================"

  QUERY='{
    "query": "query GetByType($providerType: String!, $limit: Int!) { medical_provider_profilesCollection(first: $limit, filter: { professional_role: { eq: $providerType }, application_status: { eq: \"approved\" } }, orderBy: { years_of_experience: DescNullsLast }) { edges { node { id user_id professional_role primary_specialization years_of_experience consultation_fee_range patient_satisfaction_avg users { full_name email phone_number } } } } }",
    "variables": {
      "providerType": "'$PROVIDER_TYPE'",
      "limit": '$LIMIT'
    }
  }'

  curl -s "$GRAPHQL_URL" \
    -H "Content-Type: application/json" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -d "$QUERY" | jq '.'
}

# =====================================================
# Query 4: Get Providers by Specialization
# =====================================================

get_providers_by_specialization() {
  SPECIALIZATION=${1:-"general_medicine"}
  LIMIT=${2:-20}

  echo "Fetching providers with specialization: $SPECIALIZATION (limit: $LIMIT)"
  echo "======================================"

  QUERY='{
    "query": "query GetBySpecialization($specialization: String!, $limit: Int!) { medical_provider_profilesCollection(first: $limit, filter: { primary_specialization: { eq: $specialization }, application_status: { eq: \"approved\" } }, orderBy: { patient_satisfaction_avg: DescNullsLast }) { edges { node { id user_id professional_role primary_specialization years_of_experience patient_satisfaction_avg total_consultations users { full_name email } } } } }",
    "variables": {
      "specialization": "'$SPECIALIZATION'",
      "limit": '$LIMIT'
    }
  }'

  curl -s "$GRAPHQL_URL" \
    -H "Content-Type: application/json" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -d "$QUERY" | jq '.'
}

# =====================================================
# Query 5: Get Provider Statistics
# =====================================================

get_provider_statistics() {
  echo "Fetching provider statistics..."
  echo "======================================"

  # Count all providers
  echo "Total Providers:"
  curl -s "$SUPABASE_URL/rest/v1/medical_provider_profiles?select=count" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "Prefer: count=exact"

  echo ""
  echo ""

  # Count by status
  echo "Approved Providers:"
  curl -s "$SUPABASE_URL/rest/v1/medical_provider_profiles?application_status=eq.approved&select=count" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "Prefer: count=exact"

  echo ""
  echo ""

  # Count by provider type
  echo "Providers by Type:"
  curl -s "$SUPABASE_URL/rest/v1/medical_provider_profiles?select=professional_role&application_status=eq.approved" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" | jq 'group_by(.professional_role) | map({type: .[0].professional_role, count: length})'
}

# =====================================================
# Query 6: List All Provider Types (Standardized)
# =====================================================

get_all_provider_types() {
  echo "Fetching all standardized provider types..."
  echo "======================================"

  curl -s "$SUPABASE_URL/rest/v1/medical_provider_types?select=*&order=provider_type_name.asc" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" | jq '.'
}

# =====================================================
# Query 7: Get Comprehensive Provider Profile
# =====================================================
# Based on user's comprehensive query example
# Fetches user, user_profile, medical_provider_profile, and facilities

get_provider_full_profile() {
  USER_ID=${1:-"ae6a139c-51fd-4d7c-877d-4bf19834a07d"}

  echo "Fetching comprehensive provider profile for user ID: $USER_ID"
  echo "======================================"

  QUERY='{
    "query": "query GetProviderFullProfile($userId:UUID!){usersCollection(filter:{id:{eq:$userId}}){edges{node{id full_name date_of_birth gender email phone_number country preferred_language timezone account_status last_seen_at created_at updated_at avatar_url unique_patient_id}}}user_profilesCollection(filter:{user_id:{eq:$userId}}){edges{node{id user_id role profile_completion_percentage verification_status verified_at verified_by verification_documents created_at updated_at id_card_number insurance_provider insurance_policy_number emergency_contact_name emergency_contact_phone emergency_contact_relationship emergency_contact_2_name emergency_contact_2_phone emergency_contact_2_relationship city region_code bio allergies chronic_conditions blood_type height_cm weight_kg}}}medical_provider_profilesCollection(filter:{user_id:{eq:$userId}}){edges{node{id user_id medical_license_number license_issuing_authority license_expiry_date professional_registration_number primary_specialization areas_of_expertise medical_school graduation_year residency_programs fellowship_programs board_certifications continuing_education_credits years_of_experience previous_positions practice_type consultation_fee_range languages_spoken max_patients_per_day consultation_duration_minutes accepts_emergency_calls video_consultation_enabled audio_consultation_enabled chat_consultation_enabled total_consultations patient_satisfaction_avg consultation_completion_rate hospital_affiliations professional_memberships content_creator_status content_engagement_score background_check_completed malpractice_insurance_valid is_specialist professional_role provider_number created_at updated_at facility_id}}}}",
    "variables": {
      "userId": "'$USER_ID'"
    }
  }'

  curl -s "$GRAPHQL_URL" \
    -H "Content-Type: application/json" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -d "$QUERY" | jq '.'
}

# =====================================================
# Main Menu
# =====================================================

case "${1:-help}" in
  "by-id")
    get_provider_by_id "$2"
    ;;
  "full-profile")
    get_provider_full_profile "$2"
    ;;
  "all")
    get_all_active_providers "$2"
    ;;
  "by-type")
    get_providers_by_type "$2" "$3"
    ;;
  "by-specialization")
    get_providers_by_specialization "$2" "$3"
    ;;
  "statistics")
    get_provider_statistics
    ;;
  "types")
    get_all_provider_types
    ;;
  "help"|*)
    echo "Medical Providers GraphQL Query Executor"
    echo "========================================"
    echo ""
    echo "Usage: ./execute_provider_query.sh [command] [parameters]"
    echo ""
    echo "Commands:"
    echo "  by-id [user_id]                    Get specific provider by user ID"
    echo "  full-profile [user_id]             Get comprehensive provider profile (all tables)"
    echo "  all [limit]                        Get all active providers"
    echo "  by-type [type] [limit]             Get providers by professional role"
    echo "  by-specialization [spec] [limit]   Get providers by specialization"
    echo "  statistics                         Get provider statistics"
    echo "  types                              List all standardized provider types"
    echo ""
    echo "Examples:"
    echo "  ./execute_provider_query.sh by-id ae6a139c-51fd-4d7c-877d-4bf19834a07d"
    echo "  ./execute_provider_query.sh full-profile ae6a139c-51fd-4d7c-877d-4bf19834a07d"
    echo "  ./execute_provider_query.sh all 10"
    echo "  ./execute_provider_query.sh by-type 'Medical Doctor' 20"
    echo "  ./execute_provider_query.sh by-specialization general_medicine 15"
    echo "  ./execute_provider_query.sh statistics"
    echo "  ./execute_provider_query.sh types"
    echo ""
    ;;
esac
