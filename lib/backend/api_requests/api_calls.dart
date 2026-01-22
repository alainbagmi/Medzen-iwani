import 'dart:convert';
import 'dart:typed_data';
import '../schema/structs/index.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'fapshipayment';

/// Start supagraphql Group Code

class SupagraphqlGroup {
  static String getBaseUrl({
    String? apikey,
    String? bearer,
    String? baseurl,
  }) {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    return '${baseurl}';
  }

  static Map<String, String> headers = {
    'apikey': '[apikey]',
    'Authorization': 'Bearer [Bearer]',
    'Content-Type': 'application/json',
  };
  static UserDetailsCall userDetailsCall = UserDetailsCall();
  static ProviderTypesCall providerTypesCall = ProviderTypesCall();
  static BloodGroupCall bloodGroupCall = BloodGroupCall();
  static FacilitiesCall facilitiesCall = FacilitiesCall();
  static FacilityDetailsCall facilityDetailsCall = FacilityDetailsCall();
  static ProviderSpecialtyCall providerSpecialtyCall = ProviderSpecialtyCall();
  static FacilityDeparmentCall facilityDeparmentCall = FacilityDeparmentCall();
  static UseridCall useridCall = UseridCall();
  static ProvidersCall providersCall = ProvidersCall();
  static ProvidersApprovalCall providersApprovalCall = ProvidersApprovalCall();
  static FacilityTypeCall facilityTypeCall = FacilityTypeCall();
  static SystemAdminCall systemAdminCall = SystemAdminCall();
  static ProviderAppointmentsCall providerAppointmentsCall =
      ProviderAppointmentsCall();
  static ProviderSytemCall providerSytemCall = ProviderSytemCall();
}

class UserDetailsCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "query GetCompleteUserData(\$userId: UUID!) {\\n  usersCollection(filter: {id: {eq: \$userId}}) {\\n    edges {\\n      node {\\n        id\\n        firebase_uid\\n        email\\n        phone_number\\n        secondary_phone\\n        first_name\\n        middle_name\\n        last_name\\n        full_name\\n        date_of_birth\\n        gender\\n        profile_picture_url\\n        avatar_url\\n        preferred_language\\n        timezone\\n        country\\n        account_status\\n        is_active\\n        is_verified\\n        email_verified\\n        phone_verified\\n        terms_accepted\\n        terms_accepted_at\\n        privacy_accepted\\n        privacy_accepted_at\\n        last_login_at\\n        last_seen_at\\n        unique_patient_id\\n        blood_donation\\n        created_at\\n        updated_at\\n        deleted_at\\n      }\\n    }\\n  }\\n  user_profilesCollection(filter: {user_id: {eq: \$userId}}) {\\n    edges {\\n      node {\\n        id\\n        user_id\\n        role\\n        bio\\n        display_name\\n        profile_completion_percentage\\n        address\\n        street_address\\n        building_name\\n        apartment_unit\\n        city\\n        state\\n        country\\n        postal_code\\n        region_code\\n        coordinates\\n        landmark_description\\n        division_code\\n        subdivision_code\\n        community_code\\n        neighborhood\\n        emergency_contact_name\\n        emergency_contact_phone\\n        emergency_contact_relationship\\n        emergency_contact_2_name\\n        emergency_contact_2_phone\\n        emergency_contact_2_relationship\\n        insurance_provider\\n        insurance_number\\n        insurance_policy_number\\n        insurance_expiry\\n        id_card_number\\n        id_card_issue_date\\n        id_card_expiration_date\\n        national_id\\n        national_id_encrypted\\n        passport_number\\n        blood_type\\n        height_cm\\n        weight_kg\\n        allergies\\n        chronic_conditions\\n        current_medications\\n        religion\\n        ethnicity\\n        verification_status\\n        verified_at\\n        verified_by\\n        verification_documents\\n        notification_preferences\\n        privacy_settings\\n        metadata\\n        created_at\\n        updated_at\\n      }\\n    }\\n  }\\n  user_subscriptionsCollection(filter: {user_id: {eq: \$userId}}) {\\n    edges {\\n      node {\\n        id\\n        user_id\\n        plan_id\\n        status\\n        start_date\\n        end_date\\n        next_billing_date\\n        payment_method_id\\n        provider_subscription_id\\n        created_at\\n        updated_at\\n      }\\n    }\\n  }\\n  patient_profilesCollection(filter: {user_id: {eq: \$userId}}) {\\n    edges {\\n      node {\\n        id\\n        user_id\\n        patient_number\\n        medical_record_number\\n        primary_physician_id\\n        preferred_hospital_id\\n        allergies\\n        chronic_conditions\\n        current_medications\\n        has_chronic_condition\\n        requires_special_care\\n        diabetes_type\\n        diabetes_diagnosis_date\\n        hypertension\\n        kidney_issue\\n        is_pregnant\\n        pregnancy_due_date\\n        last_blood_sugar\\n        last_blood_pressure_systolic\\n        last_blood_pressure_diastolic\\n        last_vitals_date\\n        is_blood_donor\\n        blood_donor_status\\n        last_donation_date\\n        disability_accommodations\\n        literacy_level\\n        interpreter_needed\\n        has_smartphone\\n        internet_access_quality\\n        prefers_ussd\\n        preferred_communication\\n        has_insurance\\n        insurance_details\\n        data_sharing_consent\\n        data_sharing_consent_date\\n        marketing_consent\\n        marketing_consent_date\\n        research_participation_consent\\n        research_participation_consent_date\\n        created_at\\n        updated_at\\n      }\\n    }\\n  }\\n  medical_provider_profilesCollection(filter: {user_id: {eq: \$userId}}) {\\n    edges {\\n      node {\\n        id\\n        user_id\\n        provider_number\\n        unique_identifier\\n        medical_license_number\\n        professional_registration_number\\n        license_issuing_authority\\n        license_expiry_date\\n        professional_role\\n        primary_specialization\\n        secondary_specializations\\n        sub_specialties\\n        areas_of_expertise\\n        is_specialist\\n        medical_school\\n        graduation_year\\n        qualifications\\n        residency_programs\\n        fellowship_programs\\n        board_certifications\\n        continuing_education_credits\\n        years_of_experience\\n        previous_positions\\n        hospital_affiliations\\n        professional_memberships\\n        awards\\n        research_interests\\n        practice_type\\n        consultation_fee\\n        consultation_fee_range\\n        consultation_duration_minutes\\n        max_patients_per_day\\n        accepts_new_patients\\n        accepts_emergency_calls\\n        languages_spoken\\n        telemedicine_setup_complete\\n        video_consultation_enabled\\n        audio_consultation_enabled\\n        chat_consultation_enabled\\n        ussd_consultation_enabled\\n        total_consultations\\n        patient_satisfaction_avg\\n        response_time_avg_minutes\\n        consultation_completion_rate\\n        content_creator_status\\n        total_posts_created\\n        total_followers\\n        content_engagement_score\\n        background_check_completed\\n        background_check_date\\n        malpractice_insurance_valid\\n        malpractice_insurance_expiry\\n        availability_status\\n        created_at\\n        updated_at\\n      }\\n    }\\n  }\\n  facility_admin_profilesCollection(filter: {user_id: {eq: \$userId}}) {\\n    edges {\\n      node {\\n        id\\n        user_id\\n        admin_number\\n        employee_id\\n        primary_facility_id\\n        managed_facilities\\n        facility_admin_level\\n        position_title\\n        department\\n        hire_date\\n        reporting_manager_id\\n        can_manage_staff\\n        can_manage_schedules\\n        can_view_reports\\n        can_manage_inventory\\n        can_approve_expenses\\n        can_manage_billing\\n        budget_authority_limit\\n        expense_approval_limit\\n        work_phone\\n        work_email\\n        office_location\\n        work_address\\n        education_background\\n        certifications\\n        training_completed\\n        license_numbers\\n        facilities_under_management\\n        staff_under_management\\n        patient_satisfaction_avg\\n        operational_efficiency_score\\n        total_staff_meetings_conducted\\n        total_reports_generated\\n        last_facility_visit\\n        working_hours\\n        on_call_availability\\n        vacation_days_remaining\\n        access_level\\n        two_factor_enabled\\n        failed_login_attempts\\n        last_login_at\\n        hipaa_training_completed\\n        hipaa_training_date\\n        safety_training_completed\\n        safety_training_date\\n        confidentiality_agreement_signed\\n        confidentiality_agreement_date\\n        notification_preferences\\n        created_at\\n        updated_at\\n      }\\n    }\\n  }\\n  system_admin_profilesCollection(filter: {user_id: {eq: \$userId}}) {\\n    edges {\\n      node {\\n        id\\n        user_id\\n        admin_number\\n        admin_level\\n        admin_role\\n        full_platform_access\\n        can_modify_users\\n        can_modify_facilities\\n        can_modify_providers\\n        can_view_all_data\\n        can_delete_data\\n        can_export_data\\n        can_manage_system_settings\\n        can_manage_billing\\n        can_access_financial_reports\\n        can_manage_integrations\\n        can_manage_api_keys\\n        two_factor_required\\n        ip_whitelist\\n        allowed_ip_ranges\\n        session_timeout_minutes\\n        require_password_change_days\\n        last_admin_action\\n        last_admin_action_type\\n        total_admin_actions\\n        total_users_modified\\n        total_data_exports\\n        last_login_at\\n        last_login_ip\\n        failed_login_attempts\\n        account_locked_until\\n        security_clearance_level\\n        background_check_completed\\n        background_check_date\\n        data_privacy_training_completed\\n        data_privacy_training_date\\n        confidentiality_agreement_signed\\n        confidentiality_agreement_date\\n        emergency_contact_name\\n        emergency_contact_phone\\n        emergency_contact_relationship\\n        notification_preferences\\n        created_at\\n        updated_at\\n      }\\n    }\\n  }\\n  provider_type_assignmentsCollection(filter: {user_id: {eq: \$userId}}) {\\n    edges {\\n      node {\\n        id\\n        user_id\\n        provider_type_id\\n        license_number\\n        license_expiry\\n        is_primary\\n        verification_status\\n        verified_at\\n        verified_by_id\\n        created_at\\n        updated_at\\n      }\\n    }\\n  }\\n  facility_providersCollection(filter: {provider_id: {eq: \$userId}}) {\\n    edges {\\n      node {\\n        id\\n        facility_id\\n        provider_id\\n        role\\n        department\\n        start_date\\n        end_date\\n        is_primary_facility\\n        is_active\\n        created_at\\n        updated_at\\n      }\\n    }\\n  }\\n  appointmentsAsPatientCollection: appointmentsCollection(filter: {patient_id: {eq: \$userId}}) {\\n    edges {\\n      node {\\n        id\\n        appointment_number\\n        patient_id\\n        provider_id\\n        facility_id\\n        appointment_type\\n        specialty\\n        status\\n        consultation_mode\\n        scheduled_start\\n        scheduled_end\\n        actual_start\\n        actual_end\\n        chief_complaint\\n        notes\\n        cancellation_reason\\n        cancelled_by_id\\n        cancelled_at\\n        reminder_sent\\n        reminder_sent_at\\n        video_call_id\\n        created_at\\n        updated_at\\n      }\\n    }\\n  }\\n  appointmentsAsProviderCollection: appointmentsCollection(filter: {provider_id: {eq: \$userId}}) {\\n    edges {\\n      node {\\n        id\\n        appointment_number\\n        patient_id\\n        provider_id\\n        facility_id\\n        appointment_type\\n        specialty\\n        status\\n        consultation_mode\\n        scheduled_start\\n        scheduled_end\\n        actual_start\\n        actual_end\\n        chief_complaint\\n        notes\\n        cancellation_reason\\n        cancelled_by_id\\n        cancelled_at\\n        reminder_sent\\n        reminder_sent_at\\n        video_call_id\\n        created_at\\n        updated_at\\n      }\\n    }\\n  }\\n}",
  "variables": {
    "userId": "${escapeStringForJson(userId)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'UserDetails',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic? userDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.usersCollection.edges[:].node''',
      );
  dynamic? userProfile(dynamic response) => getJsonField(
        response,
        r'''$.data.user_profilesCollection.edges[:].node''',
      );
  dynamic? patientProfile(dynamic response) => getJsonField(
        response,
        r'''$.data.patient_profilesCollection.edges[:].node''',
      );
  dynamic? subscription(dynamic response) => getJsonField(
        response,
        r'''$.data.user_subscriptionsCollection.edges[:].node''',
      );
  String? subscriptionStatus(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.user_subscriptionsCollection.edges[:].node.status''',
      ));
  String? role(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.user_profilesCollection.edges[:].node.role''',
      ));
  String? fullname(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.usersCollection.edges[:].node.full_name''',
      ));
  String? number(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.usersCollection.edges[:].node.phone_number''',
      ));
  dynamic? appts(dynamic response) => getJsonField(
        response,
        r'''$.data.appointmentsAsPatientCollection.edges[:].node''',
      );
  dynamic? systAdminProfiles(dynamic response) => getJsonField(
        response,
        r'''$.data.system_admin_profilesCollection.edges[:].node''',
      );
  dynamic? facilityAdminProfiles(dynamic response) => getJsonField(
        response,
        r'''$.data.facility_admin_profilesCollection.edges[:].node''',
      );
  dynamic? medicalproviderprofiles(dynamic response) => getJsonField(
        response,
        r'''$.data.medical_provider_profilesCollection.edges[:].node''',
      );
}

class ProviderTypesCall {
  Future<ApiCallResponse> call({
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "query { medical_provider_typesCollection(first: 200, orderBy: {provider_type_name: AscNullsLast}) { edges { node { provider_type_code provider_type_name } } } specialtiesCollection(first: 200, orderBy: {specialty_name: AscNullsLast}) { edges { node { specialty_code specialty_name } } } }"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'providerTypes',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List<String>? prodType(dynamic response) => (getJsonField(
        response,
        r'''$.data.medical_provider_typesCollection.edges[:].node.provider_type_name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class BloodGroupCall {
  Future<ApiCallResponse> call({
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "{ blood_typesCollection(orderBy: { blood_type_code: AscNullsLast }) { edges { node { id blood_type_code blood_type_name } } } }"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'BloodGroup',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List<String>? bloodtype(dynamic response) => (getJsonField(
        response,
        r'''$.data.blood_typesCollection.edges[:].node.blood_type_code''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class FacilitiesCall {
  Future<ApiCallResponse> call({
    String? facilityName = '',
    String? city = '',
    dynamic? specialtiesJson,
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final specialties = _serializeJson(specialtiesJson);
    final ffApiRequestBody = '''
{
  "query": "query GetFacilities(\$facilityName: String, \$city: String) { facilitiesCollection(filter: { and: [{ facility_name: { ilike: \$facilityName } }, { city: { ilike: \$city } }] }, orderBy: { facility_code: AscNullsLast }) { edges { node { id facility_code facility_name facility_type address city state country postal_code location phone_number email website operating_hours emergency_services specialties certifications bed_capacity is_active metadata created_at updated_at image_url } } } }",
  "variables": {
    "facilityName": "${escapeStringForJson(facilityName)}",
    "city": "${escapeStringForJson(city)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Facilities',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic? facilityDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.facilitiesCollection.edges[:].node''',
      );
  String? facilityName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.facilitiesCollection.edges[:].node.facility_name''',
      ));
  String? facilityType(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.facilitiesCollection.edges[:].node.facility_type''',
      ));
  String? city(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.facilitiesCollection.edges[:].node.city''',
      ));
  String? address(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.facilitiesCollection.edges[:].node.address''',
      ));
  String? facilityID(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.facilitiesCollection.edges[:].node.id''',
      ));
}

class FacilityDetailsCall {
  Future<ApiCallResponse> call({
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "query GetFacilities { facilitiesCollection(orderBy: { facility_name: AscNullsLast }) { edges { node { id facility_name address } } } }"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'FacilityDetails',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic? facilityDetails(dynamic response) => getJsonField(
        response,
        r'''$.data.facilitiesCollection.edges[:].node''',
      );
  String? facilityName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.facilitiesCollection.edges[:].node.facility_name''',
      ));
  String? facilityType(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.facilitiesCollection.edges[:].node.facility_type''',
      ));
  String? city(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.facilitiesCollection.edges[:].node.city''',
      ));
  String? address(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.facilitiesCollection.edges[:].node.address''',
      ));
  String? facilityID(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.facilitiesCollection.edges[:].node.id''',
      ));
}

class ProviderSpecialtyCall {
  Future<ApiCallResponse> call({
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "query { specialtiesCollection(orderBy: { specialty_code: AscNullsLast }) { edges { node { specialty_code specialty_name description } } } medical_provider_typesCollection(orderBy: { provider_type_name: AscNullsLast }) { edges { node { provider_type_code provider_type_name description } } } }"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'ProviderSpecialty',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List<String>? description(dynamic response) => (getJsonField(
        response,
        r'''$.data.specialtiesCollection.edges[:].node.description''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? specialtyname(dynamic response) => (getJsonField(
        response,
        r'''$.data.specialtiesCollection.edges[:].node.specialty_name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? specialtyCode(dynamic response) => (getJsonField(
        response,
        r'''$.data.specialtiesCollection.edges[:].node.specialty_code''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? providerDescription(dynamic response) => (getJsonField(
        response,
        r'''$.data.medical_provider_typesCollection.edges[:].node.description''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? providerTypeCode(dynamic response) => (getJsonField(
        response,
        r'''$.data.medical_provider_typesCollection.edges[:].node.provider_type_code''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? providerTYpe(dynamic response) => (getJsonField(
        response,
        r'''$.data.medical_provider_typesCollection.edges[:].node.provider_type_name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class FacilityDeparmentCall {
  Future<ApiCallResponse> call({
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "query { facility_departmentsCollection(orderBy: { department_name: AscNullsLast }) { edges { node { department_code department_name } } } facility_typesCollection(filter: { is_active: { eq: true } }, orderBy: { facility_type_name: AscNullsLast }) { edges { node { id facility_type_code facility_type_name description } } } }"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'FacilityDeparment',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List<String>? departmentCode(dynamic response) => (getJsonField(
        response,
        r'''$.data.facility_departmentsCollection.edges[:].node.department_code''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? departmentName(dynamic response) => (getJsonField(
        response,
        r'''$.data.facility_departmentsCollection.edges[:].node.department_name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? facilityType(dynamic response) => (getJsonField(
        response,
        r'''$.data.facility_typesCollection.edges[:].node.facility_type_name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? facilityCOde(dynamic response) => (getJsonField(
        response,
        r'''$.data.facility_typesCollection.edges[:].node.facility_type_code''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? facilityDescription(dynamic response) => (getJsonField(
        response,
        r'''$.data.facility_typesCollection.edges[:].node.description''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class UseridCall {
  Future<ApiCallResponse> call({
    String? firebaseUID = '',
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "query GetUserByFirebaseUID(\$firebaseUID: String!) {\\n  usersCollection(filter: {firebase_uid: {eq: \$firebaseUID}}) {\\n    edges {\\n      node {\\n        id\\n        firebase_uid\\n        email\\n        phone_number\\n        secondary_phone\\n        first_name\\n        middle_name\\n        last_name\\n        full_name\\n        date_of_birth\\n        gender\\n        profile_picture_url\\n        avatar_url\\n        preferred_language\\n        timezone\\n        country\\n        account_status\\n        is_active\\n        is_verified\\n        email_verified\\n        phone_verified\\n        terms_accepted\\n        terms_accepted_at\\n        privacy_accepted\\n        privacy_accepted_at\\n        last_login_at\\n        last_seen_at\\n        unique_patient_id\\n        blood_donation\\n        created_at\\n        updated_at\\n        deleted_at\\n      }\\n    }\\n  }\\n}",
  "variables": {
    "firebaseUID": "${escapeStringForJson(firebaseUID)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'USERID',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? userAuthID(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.usersCollection.edges[:].node.id''',
      ));
  String? fullname(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.usersCollection.edges[:].node.full_name''',
      ));
  String? email(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.usersCollection.edges[:].node.email''',
      ));
  String? gender(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.usersCollection.edges[:].node.gender''',
      ));
}

class ProvidersCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "query GetMedicalProviderByUserId(\$userId:UUID){medical_provider_profilesCollection(filter:{user_id:{eq:\$userId}}){edges{node{id user_id provider_number unique_identifier medical_license_number professional_registration_number license_issuing_authority license_expiry_date professional_role primary_specialization secondary_specializations sub_specialties areas_of_expertise is_specialist medical_school graduation_year qualifications residency_programs fellowship_programs board_certifications continuing_education_credits years_of_experience previous_positions hospital_affiliations professional_memberships awards research_interests practice_type consultation_fee consultation_fee_range consultation_duration_minutes max_patients_per_day accepts_new_patients accepts_emergency_calls languages_spoken telemedicine_setup_complete video_consultation_enabled audio_consultation_enabled chat_consultation_enabled ussd_consultation_enabled total_consultations patient_satisfaction_avg response_time_avg_minutes consultation_completion_rate content_creator_status total_posts_created total_followers content_engagement_score background_check_completed background_check_date malpractice_insurance_valid malpractice_insurance_expiry availability_status application_status rejection_reason facility_id approved_at approved_by_id revoked_at revoked_by_id primary_specialty_id avatar_url created_at updated_at users{id firebase_uid email phone_number first_name last_name middle_name full_name date_of_birth gender profile_picture_url avatar_url preferred_language timezone country account_status fcm_token is_active is_verified email_verified phone_verified terms_accepted terms_accepted_at privacy_accepted privacy_accepted_at last_login_at last_seen_at unique_patient_id secondary_phone blood_donation created_at updated_at user_profilesCollection{edges{node{id user_id bio display_name address street_address building_name apartment_unit city state region_code division_code subdivision_code community_code neighborhood country postal_code location coordinates landmark_description emergency_contact_name emergency_contact_phone emergency_contact_relationship emergency_contact_2_name emergency_contact_2_phone emergency_contact_2_relationship insurance_provider insurance_number insurance_policy_number insurance_expiry blood_type allergies chronic_conditions current_medications height_cm weight_kg id_card_number id_card_issue_date id_card_expiration_date national_id passport_number religion ethnicity verification_status verified_at verified_by verification_documents notification_preferences privacy_settings role profile_completion_percentage metadata created_at updated_at}}}}}}}}",
  "variables": {
    "userId": "${escapeStringForJson(userId)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'providers',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic? users(dynamic response) => getJsonField(
        response,
        r'''$.data.medical_provider_profilesCollection.edges[:].node''',
      );
}

class ProvidersApprovalCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? applicationStatus = '',
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "query GetMedicalProviderByUserId(\$userId: UUID) { medical_provider_profilesCollection(filter: { user_id: {eq: \$userId} }) { edges { node { id user_id provider_number unique_identifier medical_license_number professional_registration_number license_issuing_authority license_expiry_date professional_role primary_specialization secondary_specializations sub_specialties areas_of_expertise is_specialist medical_school graduation_year qualifications years_of_experience practice_type consultation_fee consultation_fee_range consultation_duration_minutes accepts_new_patients accepts_emergency_calls languages_spoken telemedicine_setup_complete video_consultation_enabled audio_consultation_enabled chat_consultation_enabled total_consultations patient_satisfaction_avg response_time_avg_minutes application_status rejection_reason availability_status facility_id approved_at approved_by_id avatar_url created_at updated_at users { id firebase_uid email phone_number first_name last_name middle_name full_name date_of_birth gender profile_picture_url preferred_language country account_status is_active is_verified user_profilesCollection { edges { node { id bio display_name address city state country postal_code emergency_contact_name emergency_contact_phone blood_type allergies chronic_conditions } } } } } } } }",
  "variables": {
    "userId": "${escapeStringForJson(userId)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'providersApproval',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  dynamic? users(dynamic response) => getJsonField(
        response,
        r'''$.data.medical_provider_profilesCollection.edges[:].node''',
      );
  String? providerID(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.medical_provider_profilesCollection.edges[:].node.users.id''',
      ));
  String? rejectionReason(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.medical_provider_profilesCollection.edges[:].node.rejection_reason''',
      ));
  String? licensenumber(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.medical_provider_profilesCollection.edges[:].node.medical_license_number''',
      ));
  String? applicationStatus(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.medical_provider_profilesCollection.edges[:].node.application_status''',
      ));
  String? avatarurl(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.medical_provider_profilesCollection.edges[:].node.avatar_url''',
      ));
  String? fullname(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.medical_provider_profilesCollection.edges[:].node.users.full_name''',
      ));
}

class FacilityTypeCall {
  Future<ApiCallResponse> call({
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "query GetAllFacilityTypes { facility_typesCollection { edges { node { id facility_type_code facility_type_name description typical_services accreditation_requirements is_active created_at updated_at } } } }"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'FacilityType',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  List<String>? facilityType(dynamic response) => (getJsonField(
        response,
        r'''$.data.facility_typesCollection.edges[:].node.facility_type_name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class SystemAdminCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "query GetCompleteUserData(\$userId: UUID!) { usersCollection(filter: {id: {eq: \$userId}}) { edges { node { id firebase_uid email phone_number secondary_phone first_name middle_name last_name full_name date_of_birth gender profile_picture_url avatar_url preferred_language timezone country account_status is_active is_verified email_verified phone_verified terms_accepted terms_accepted_at privacy_accepted privacy_accepted_at last_login_at last_seen_at unique_patient_id blood_donation created_at updated_at deleted_at } } } user_profilesCollection(filter: {user_id: {eq: \$userId}}) { edges { node { id user_id role bio display_name profile_completion_percentage address street_address building_name apartment_unit city state country postal_code region_code coordinates landmark_description division_code subdivision_code community_code neighborhood emergency_contact_name emergency_contact_phone emergency_contact_relationship emergency_contact_2_name emergency_contact_2_phone emergency_contact_2_relationship insurance_provider insurance_number insurance_policy_number insurance_expiry id_card_number id_card_issue_date id_card_expiration_date national_id national_id_encrypted passport_number blood_type height_cm weight_kg allergies chronic_conditions current_medications religion ethnicity verification_status verified_at verified_by verification_documents notification_preferences privacy_settings metadata created_at updated_at } } } user_subscriptionsCollection(filter: {user_id: {eq: \$userId}}) { edges { node { id user_id plan_id status start_date end_date next_billing_date payment_method_id provider_subscription_id created_at updated_at } } } patient_profilesCollection(filter: {user_id: {eq: \$userId}}) { edges { node { id user_id patient_number medical_record_number primary_physician_id preferred_hospital_id allergies chronic_conditions current_medications has_chronic_condition requires_special_care diabetes_type diabetes_diagnosis_date hypertension kidney_issue is_pregnant pregnancy_due_date last_blood_sugar last_blood_pressure_systolic last_blood_pressure_diastolic last_vitals_date is_blood_donor blood_donor_status last_donation_date disability_accommodations literacy_level interpreter_needed has_smartphone internet_access_quality prefers_ussd preferred_communication has_insurance insurance_details data_sharing_consent data_sharing_consent_date marketing_consent marketing_consent_date research_participation_consent research_participation_consent_date created_at updated_at } } } medical_provider_profilesCollection(filter: {user_id: {eq: \$userId}}) { edges { node { id user_id provider_number unique_identifier medical_license_number professional_registration_number license_issuing_authority license_expiry_date professional_role primary_specialization secondary_specializations sub_specialties areas_of_expertise is_specialist medical_school graduation_year qualifications residency_programs fellowship_programs board_certifications continuing_education_credits years_of_experience previous_positions hospital_affiliations professional_memberships awards research_interests practice_type consultation_fee consultation_fee_range consultation_duration_minutes max_patients_per_day accepts_new_patients accepts_emergency_calls languages_spoken telemedicine_setup_complete video_consultation_enabled audio_consultation_enabled chat_consultation_enabled ussd_consultation_enabled total_consultations patient_satisfaction_avg response_time_avg_minutes consultation_completion_rate content_creator_status total_posts_created total_followers content_engagement_score background_check_completed background_check_date malpractice_insurance_valid malpractice_insurance_expiry availability_status created_at updated_at } } } facility_admin_profilesCollection(filter: {user_id: {eq: \$userId}}) { edges { node { id user_id admin_number employee_id primary_facility_id managed_facilities facility_admin_level position_title department hire_date reporting_manager_id can_manage_staff can_manage_schedules can_view_reports can_manage_inventory can_approve_expenses can_manage_billing budget_authority_limit expense_approval_limit work_phone work_email office_location work_address education_background certifications training_completed license_numbers facilities_under_management staff_under_management patient_satisfaction_avg operational_efficiency_score total_staff_meetings_conducted total_reports_generated last_facility_visit working_hours on_call_availability vacation_days_remaining access_level two_factor_enabled failed_login_attempts last_login_at hipaa_training_completed hipaa_training_date safety_training_completed safety_training_date confidentiality_agreement_signed confidentiality_agreement_date notification_preferences created_at updated_at } } } system_admin_profilesCollection(filter: {user_id: {eq: \$userId}}) { edges { node { id user_id admin_number admin_level admin_role full_platform_access can_modify_users can_modify_facilities can_modify_providers can_view_all_data can_delete_data can_export_data can_manage_system_settings can_manage_billing can_access_financial_reports can_manage_integrations can_manage_api_keys two_factor_required ip_whitelist allowed_ip_ranges session_timeout_minutes require_password_change_days last_admin_action last_admin_action_type total_admin_actions total_users_modified total_data_exports last_login_at last_login_ip failed_login_attempts account_locked_until security_clearance_level background_check_completed background_check_date data_privacy_training_completed data_privacy_training_date confidentiality_agreement_signed confidentiality_agreement_date emergency_contact_name emergency_contact_phone emergency_contact_relationship notification_preferences created_at updated_at } } } provider_type_assignmentsCollection(filter: {user_id: {eq: \$userId}}) { edges { node { id user_id provider_type_id license_number license_expiry is_primary verification_status verified_at verified_by_id created_at updated_at } } } facility_providersCollection(filter: {provider_id: {eq: \$userId}}) { edges { node { id facility_id provider_id role department start_date end_date is_primary_facility is_active created_at updated_at } } } appointmentsAsPatientCollection: appointmentsCollection(filter: {patient_id: {eq: \$userId}}) { edges { node { id appointment_number patient_id provider_id facility_id appointment_type specialty status consultation_mode scheduled_start scheduled_end actual_start actual_end chief_complaint notes cancellation_reason cancelled_by_id cancelled_at reminder_sent reminder_sent_at video_call_id created_at updated_at } } } appointmentsAsProviderCollection: appointmentsCollection(filter: {provider_id: {eq: \$userId}}) { edges { node { id appointment_number patient_id provider_id facility_id appointment_type specialty status consultation_mode scheduled_start scheduled_end actual_start actual_end chief_complaint notes cancellation_reason cancelled_by_id cancelled_at reminder_sent reminder_sent_at video_call_id created_at updated_at } } } }",
  "variables": {
    "userId": "${escapeStringForJson(userId)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'SystemAdmin',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ProviderAppointmentsCall {
  Future<ApiCallResponse> call({
    String? userId = '',
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "query GetUserWithAppointments(\$userId: UUID!) { usersCollection(filter: {id: {eq: \$userId}}) { edges { node { id firebase_uid email phone_number first_name last_name middle_name full_name date_of_birth gender profile_picture_url avatar_url preferred_language timezone country account_status is_active is_verified user_profilesCollection { edges { node { id bio display_name address city state country postal_code blood_type allergies chronic_conditions role } } } } } } appointmentsCollection(filter: {or: [{patient_id: {eq: \$userId}}, {provider_id: {eq: \$userId}}]}) { edges { node { id appointment_number patient_id provider_id facility_id appointment_type specialty status consultation_mode scheduled_start scheduled_end actual_start actual_end start_date start_time chief_complaint notes cancellation_reason cancelled_at reminder_sent video_call_id created_at updated_at } } } }",
  "variables": {
    "userId": "${escapeStringForJson(userId)}"
  }
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'ProviderAppointments',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ProviderSytemCall {
  Future<ApiCallResponse> call({
    String? apikey,
    String? bearer,
    String? baseurl,
  }) async {
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    bearer ??= FFDevEnvironmentValues().Supabasekey;
    baseurl ??= FFDevEnvironmentValues().SupaBaseAPIBaseUrl;
    final baseUrl = SupagraphqlGroup.getBaseUrl(
      apikey: apikey,
      bearer: bearer,
      baseurl: baseurl,
    );

    final ffApiRequestBody = '''
{
  "query": "query GetAllProviders { medical_provider_profilesCollection { edges { node { medical_license_number avatar_url application_status users { full_name phone_number } } } } }"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'ProviderSytem',
      apiUrl: '${baseUrl}/graphql/v1',
      callType: ApiCallType.POST,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${bearer}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

/// End supagraphql Group Code

/// Start Twillo Group Code

class TwilloGroup {
  static String getBaseUrl() => 'https://verify.twilio.com/v2/Services';
  static Map<String, String> headers = {
    'Authorization':
        'Basic QUM0NGJiNjI1MmE0OWQyZWIwMzRlNjA5ZjU0Y2JiZDRhMTpmNmEyMjY3OGQwNmFlZDllMWY1MWFiZjY0MDViNjJjOQ==',
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  static SendOtpCall sendOtpCall = SendOtpCall();
  static VerifyOtpCall verifyOtpCall = VerifyOtpCall();
}

class SendOtpCall {
  Future<ApiCallResponse> call({
    String? phone = '+237691959357',
  }) async {
    final baseUrl = TwilloGroup.getBaseUrl();

    return ApiManager.instance.makeApiCall(
      callName: 'SendOtp',
      apiUrl: '${baseUrl}/VAec657a00bdc58bdc3e9086d4f6282949/Verifications',
      callType: ApiCallType.POST,
      headers: {
        'Authorization':
            'Basic QUM0NGJiNjI1MmE0OWQyZWIwMzRlNjA5ZjU0Y2JiZDRhMTpmNmEyMjY3OGQwNmFlZDllMWY1MWFiZjY0MDViNjJjOQ==',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      params: {
        'To': phone,
        'Channel': "sms",
      },
      bodyType: BodyType.X_WWW_FORM_URL_ENCODED,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class VerifyOtpCall {
  Future<ApiCallResponse> call({
    String? phone = '',
    String? code = '',
  }) async {
    final baseUrl = TwilloGroup.getBaseUrl();

    return ApiManager.instance.makeApiCall(
      callName: 'VerifyOtp',
      apiUrl: '${baseUrl}/VAec657a00bdc58bdc3e9086d4f6282949/VerificationCheck',
      callType: ApiCallType.POST,
      headers: {
        'Authorization':
            'Basic QUM0NGJiNjI1MmE0OWQyZWIwMzRlNjA5ZjU0Y2JiZDRhMTpmNmEyMjY3OGQwNmFlZDllMWY1MWFiZjY0MDViNjJjOQ==',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      params: {
        'To': phone,
        'Code': code,
      },
      bodyType: BodyType.X_WWW_FORM_URL_ENCODED,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? checkstatus(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.status''',
      ));
}

/// End Twillo Group Code

/// Start Payment Group Code

class PaymentGroup {
  static String getBaseUrl({
    String? pUBaseUrl,
    String? pUMode,
    String? pUApiKey,
    String? pUAuth,
  }) {
    pUBaseUrl ??= FFDevEnvironmentValues().PUBaseUrl;
    pUMode ??= FFDevEnvironmentValues().PUMode;
    pUApiKey ??= FFDevEnvironmentValues().PUApiKey;
    pUAuth ??= FFDevEnvironmentValues().PUAuth;
    return '${pUBaseUrl}';
  }

  static Map<String, String> headers = {
    'Content-Type': 'application/Json',
    'Authorization': '[PUAuth]',
    'mode': '[PUMode]',
    'x-api-key': '[PUApiKey]',
  };
  static InitializePaymentCall initializePaymentCall = InitializePaymentCall();
  static MobileMoneyCall mobileMoneyCall = MobileMoneyCall();
  static GetPaymentStatusCall getPaymentStatusCall = GetPaymentStatusCall();
}

class InitializePaymentCall {
  Future<ApiCallResponse> call({
    String? amount = '',
    String? transactionID = '',
    String? pUBaseUrl,
    String? pUMode,
    String? pUApiKey,
    String? pUAuth,
  }) async {
    pUBaseUrl ??= FFDevEnvironmentValues().PUBaseUrl;
    pUMode ??= FFDevEnvironmentValues().PUMode;
    pUApiKey ??= FFDevEnvironmentValues().PUApiKey;
    pUAuth ??= FFDevEnvironmentValues().PUAuth;
    final baseUrl = PaymentGroup.getBaseUrl(
      pUBaseUrl: pUBaseUrl,
      pUMode: pUMode,
      pUApiKey: pUApiKey,
      pUAuth: pUAuth,
    );

    final ffApiRequestBody = '''
{
  "total_amount": "${escapeStringForJson(amount)}",
  "currency": "XAF",
  "transaction_id": "${escapeStringForJson(transactionID)}",
  "return_url": "https://medzenhealth.app/",
  "notify_url":"https://noaeltglphdlkbflipit.supabase.co/functions/v1/payunit",
  "callback_url": "https://noaeltglphdlkbflipit.supabase.co/functions/v1/payunit"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Initialize Payment',
      apiUrl: '${baseUrl}/initialize',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/Json',
        'Authorization': '${pUAuth}',
        'mode': '${pUMode}',
        'x-api-key': '${pUApiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? transactionID(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.transaction_id''',
      ));
  String? transactionURL(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.transaction_url''',
      ));
}

class MobileMoneyCall {
  Future<ApiCallResponse> call({
    String? transactionID = '',
    String? amount = '',
    String? phone = '',
    String? paymentMethod = '',
    String? pUBaseUrl,
    String? pUMode,
    String? pUApiKey,
    String? pUAuth,
  }) async {
    pUBaseUrl ??= FFDevEnvironmentValues().PUBaseUrl;
    pUMode ??= FFDevEnvironmentValues().PUMode;
    pUApiKey ??= FFDevEnvironmentValues().PUApiKey;
    pUAuth ??= FFDevEnvironmentValues().PUAuth;
    final baseUrl = PaymentGroup.getBaseUrl(
      pUBaseUrl: pUBaseUrl,
      pUMode: pUMode,
      pUApiKey: pUApiKey,
      pUAuth: pUAuth,
    );

    final ffApiRequestBody = '''
{
  "gateway": "${escapeStringForJson(paymentMethod)}",
  "amount": "${escapeStringForJson(amount)}",
  "transaction_id": "${escapeStringForJson(transactionID)}",
  "phone_number": "${escapeStringForJson(phone)}",
  "currency": "XAF",
  "paymentType": "button",
  "return_url": "https://medzenhealth.app/"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Mobile Money',
      apiUrl: '${baseUrl}/makepayment',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/Json',
        'Authorization': '${pUAuth}',
        'mode': '${pUMode}',
        'x-api-key': '${pUApiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? paymentStatus(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.payment_status''',
      ));
  String? providerTransactionID(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.transaction_id''',
      ));
}

class GetPaymentStatusCall {
  Future<ApiCallResponse> call({
    String? transactionID = '',
    String? pUBaseUrl,
    String? pUMode,
    String? pUApiKey,
    String? pUAuth,
  }) async {
    pUBaseUrl ??= FFDevEnvironmentValues().PUBaseUrl;
    pUMode ??= FFDevEnvironmentValues().PUMode;
    pUApiKey ??= FFDevEnvironmentValues().PUApiKey;
    pUAuth ??= FFDevEnvironmentValues().PUAuth;
    final baseUrl = PaymentGroup.getBaseUrl(
      pUBaseUrl: pUBaseUrl,
      pUMode: pUMode,
      pUApiKey: pUApiKey,
      pUAuth: pUAuth,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'GetPaymentStatus',
      apiUrl: '${baseUrl}/paymentstatus/${transactionID}',
      callType: ApiCallType.GET,
      headers: {
        'Content-Type': 'application/Json',
        'Authorization': '${pUAuth}',
        'mode': '${pUMode}',
        'x-api-key': '${pUApiKey}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? transactionStatus(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.transaction_status''',
      ));
  String? transactionMessage(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.message''',
      ));
  dynamic paymentMethod(dynamic response) => getJsonField(
        response,
        r'''$.data.transaction_gateway''',
      );
}

/// End Payment Group Code

/// Start SupaBaseRest Group Code

class SupaBaseRestGroup {
  static String getBaseUrl({
    String? baseurl,
    String? apikey,
    String? token,
  }) {
    baseurl ??= FFDevEnvironmentValues().SupabaseRestAPIBaseUrl;
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    token ??= FFDevEnvironmentValues().Supabasekey;
    return '${baseurl}';
  }

  static Map<String, String> headers = {
    'apikey': '[apikey]',
    'Authorization': 'Bearer [token]',
  };
  static MedicalProvidersDetailsCall medicalProvidersDetailsCall =
      MedicalProvidersDetailsCall();
  static FacilityAppointmentsCall facilityAppointmentsCall =
      FacilityAppointmentsCall();
  static FacilityAdminsCall facilityAdminsCall = FacilityAdminsCall();
  static GetFacilitiesCall getFacilitiesCall = GetFacilitiesCall();
  static PatientAppointmentsCall patientAppointmentsCall =
      PatientAppointmentsCall();
  static FacilityStatsCall facilityStatsCall = FacilityStatsCall();
  static MedicalProviderAppointmentsCall medicalProviderAppointmentsCall =
      MedicalProviderAppointmentsCall();
  static PaymentHistoryCall paymentHistoryCall = PaymentHistoryCall();
  static CheckuserCall checkuserCall = CheckuserCall();
  static SumWithdrawalsCall sumWithdrawalsCall = SumWithdrawalsCall();
}

class MedicalProvidersDetailsCall {
  Future<ApiCallResponse> call({
    String? providerid = '',
    String? baseurl,
    String? apikey,
    String? token,
  }) async {
    baseurl ??= FFDevEnvironmentValues().SupabaseRestAPIBaseUrl;
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    token ??= FFDevEnvironmentValues().Supabasekey;
    final baseUrl = SupaBaseRestGroup.getBaseUrl(
      baseurl: baseurl,
      apikey: apikey,
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'MedicalProvidersDetails',
      apiUrl: '${baseUrl}medical_practitioners_details_view',
      callType: ApiCallType.GET,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${token}',
      },
      params: {
        'providerid': providerid,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? image(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].picture''',
      ));
  String? fullName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].name''',
      ));
  String? specialty(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].specialization''',
      ));
  int? experience(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$[:].experience''',
      ));
  int? fees(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$[:].fees''',
      ));
  double? rating(dynamic response) => castToType<double>(getJsonField(
        response,
        r'''$[:].rating''',
      ));
  int? consultations(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$[:].number_of_consultations''',
      ));
  String? providerid(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].providerid''',
      ));
  String? bio(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].bio''',
      ));
}

class FacilityAppointmentsCall {
  Future<ApiCallResponse> call({
    String? facilityId = '',
    String? baseurl,
    String? apikey,
    String? token,
  }) async {
    baseurl ??= FFDevEnvironmentValues().SupabaseRestAPIBaseUrl;
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    token ??= FFDevEnvironmentValues().Supabasekey;
    final baseUrl = SupaBaseRestGroup.getBaseUrl(
      baseurl: baseurl,
      apikey: apikey,
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'FacilityAppointments',
      apiUrl: '${baseUrl}appointment_overview',
      callType: ApiCallType.GET,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${token}',
      },
      params: {
        'facility_id': facilityId,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? patientName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].patient_fullname''',
      ));
  String? providerName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].provider_fullname''',
      ));
  String? providerSpecialty(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].provider_specialty''',
      ));
  String? providerimg(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].provider_image_url''',
      ));
  String? appointmentStartDate(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].appointment_start_date''',
      ));
  String? appointmentStartTime(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].appointment_start_time''',
      ));
  String? appointmentStatus(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].appointment_status''',
      ));
  String? patientid(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].patient_id''',
      ));
  String? providerid(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].provider_id''',
      ));
  List<String>? patientimg(dynamic response) => (getJsonField(
        response,
        r'''$[:].patient_image_url''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List? facilityid(dynamic response) => getJsonField(
        response,
        r'''$[:].facility_id''',
        true,
      ) as List?;
}

class FacilityAdminsCall {
  Future<ApiCallResponse> call({
    String? baseurl,
    String? apikey,
    String? token,
  }) async {
    baseurl ??= FFDevEnvironmentValues().SupabaseRestAPIBaseUrl;
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    token ??= FFDevEnvironmentValues().Supabasekey;
    final baseUrl = SupaBaseRestGroup.getBaseUrl(
      baseurl: baseurl,
      apikey: apikey,
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'FacilityAdmins',
      apiUrl:
          '${baseUrl}facility_admin_profiles?select=id,application_status,users!facility_admin_profiles_user_id_fkey(full_name,phone_number,avatar_url)',
      callType: ApiCallType.GET,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? facilityAdminID(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].id''',
      ));
  String? applicationstatus(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].application_status''',
      ));
  String? facilityAdminName(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].users.full_name''',
      ));
  String? facilityADminImage(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].users.avatar_url''',
      ));
  String? facilityAdminNumber(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].users.phone_number''',
      ));
}

class GetFacilitiesCall {
  Future<ApiCallResponse> call({
    String? facilityId = '',
    String? baseurl,
    String? apikey,
    String? token,
  }) async {
    baseurl ??= FFDevEnvironmentValues().SupabaseRestAPIBaseUrl;
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    token ??= FFDevEnvironmentValues().Supabasekey;
    final baseUrl = SupaBaseRestGroup.getBaseUrl(
      baseurl: baseurl,
      apikey: apikey,
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'GetFacilities',
      apiUrl: '${baseUrl}facilities?select=*',
      callType: ApiCallType.GET,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${token}',
      },
      params: {
        'id': facilityId,
        'application_status': "eq.approved",
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? facilityName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].facility_name''',
      ));
  String? facilityType(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].facility_type''',
      ));
  String? facilityCode(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].facility_code''',
      ));
  String? facilityCity(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].city''',
      ));
  String? facilityCountry(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].country''',
      ));
  String? facilityPostCode(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].postal_code''',
      ));
  String? facilityEmail(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].email''',
      ));
  String? facilitySite(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].website''',
      ));
  String? facilityImage(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].image_url''',
      ));
  String? facilityPhone(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].phone_number''',
      ));
  String? facilityAddress(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].address''',
      ));
  String? status(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].application_status''',
      ));
  int? fees(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$[:].consultation_fee''',
      ));
  String? bio(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].Description''',
      ));
  List<String>? specialties(dynamic response) => (getJsonField(
        response,
        r'''$[:].specialties[:].specialty_id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List<String>? departments(dynamic response) => (getJsonField(
        response,
        r'''$[:].Departments''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class PatientAppointmentsCall {
  Future<ApiCallResponse> call({
    String? patientId = '',
    String? baseurl,
    String? apikey,
    String? token,
  }) async {
    baseurl ??= FFDevEnvironmentValues().SupabaseRestAPIBaseUrl;
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    token ??= FFDevEnvironmentValues().Supabasekey;
    final baseUrl = SupaBaseRestGroup.getBaseUrl(
      baseurl: baseurl,
      apikey: apikey,
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'PatientAppointments',
      apiUrl: '${baseUrl}appointment_overview',
      callType: ApiCallType.GET,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${token}',
      },
      params: {
        'patient_id': patientId,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? patientName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].patient_fullname''',
      ));
  String? providerName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].provider_fullname''',
      ));
  String? providerSpecialty(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].provider_specialty''',
      ));
  String? providerimg(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].provider_image_url''',
      ));
  String? appointmentStartDate(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].appointment_start_date''',
      ));
  String? appointmentStartTime(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].appointment_start_time''',
      ));
  String? appointmentStatus(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].appointment_status''',
      ));
  String? patientid(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].patient_id''',
      ));
  String? providerid(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].provider_id''',
      ));
  List<String>? patientimg(dynamic response) => (getJsonField(
        response,
        r'''$[:].patient_image_url''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List? facilityid(dynamic response) => getJsonField(
        response,
        r'''$[:].facility_id''',
        true,
      ) as List?;
}

class FacilityStatsCall {
  Future<ApiCallResponse> call({
    String? facilityId = '',
    String? baseurl,
    String? apikey,
    String? token,
  }) async {
    baseurl ??= FFDevEnvironmentValues().SupabaseRestAPIBaseUrl;
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    token ??= FFDevEnvironmentValues().Supabasekey;
    final baseUrl = SupaBaseRestGroup.getBaseUrl(
      baseurl: baseurl,
      apikey: apikey,
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'FacilityStats',
      apiUrl: '${baseUrl}appointments?select=status,id',
      callType: ApiCallType.GET,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${token}',
      },
      params: {
        'facility_id': facilityId,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class MedicalProviderAppointmentsCall {
  Future<ApiCallResponse> call({
    String? providerId = '',
    String? baseurl,
    String? apikey,
    String? token,
  }) async {
    baseurl ??= FFDevEnvironmentValues().SupabaseRestAPIBaseUrl;
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    token ??= FFDevEnvironmentValues().Supabasekey;
    final baseUrl = SupaBaseRestGroup.getBaseUrl(
      baseurl: baseurl,
      apikey: apikey,
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'MedicalProviderAppointments',
      apiUrl: '${baseUrl}appointment_overview',
      callType: ApiCallType.GET,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${token}',
      },
      params: {
        'provider_id': providerId,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? patientName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].patient_fullname''',
      ));
  String? providerName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].provider_fullname''',
      ));
  String? providerSpecialty(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].provider_specialty''',
      ));
  String? providerimg(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].provider_image_url''',
      ));
  String? appointmentStartDate(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].appointment_start_date''',
      ));
  String? appointmentStartTime(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].appointment_start_time''',
      ));
  String? appointmentStatus(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].appointment_status''',
      ));
  String? patientid(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].patient_id''',
      ));
  String? providerid(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].provider_id''',
      ));
  List<String>? patientimg(dynamic response) => (getJsonField(
        response,
        r'''$[:].patient_image_url''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  List? facilityid(dynamic response) => getJsonField(
        response,
        r'''$[:].facility_id''',
        true,
      ) as List?;
}

class PaymentHistoryCall {
  Future<ApiCallResponse> call({
    String? payerId = '',
    String? baseurl,
    String? apikey,
    String? token,
  }) async {
    baseurl ??= FFDevEnvironmentValues().SupabaseRestAPIBaseUrl;
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    token ??= FFDevEnvironmentValues().Supabasekey;
    final baseUrl = SupaBaseRestGroup.getBaseUrl(
      baseurl: baseurl,
      apikey: apikey,
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'PaymentHistory',
      apiUrl: '${baseUrl}payments',
      callType: ApiCallType.GET,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${token}',
      },
      params: {
        'payer_id': payerId,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CheckuserCall {
  Future<ApiCallResponse> call({
    String? useremail = '',
    String? baseurl,
    String? apikey,
    String? token,
  }) async {
    baseurl ??= FFDevEnvironmentValues().SupabaseRestAPIBaseUrl;
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    token ??= FFDevEnvironmentValues().Supabasekey;
    final baseUrl = SupaBaseRestGroup.getBaseUrl(
      baseurl: baseurl,
      apikey: apikey,
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'checkuser',
      apiUrl: '${baseUrl}users?select=email',
      callType: ApiCallType.GET,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${token}',
      },
      params: {
        'email': useremail,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? email(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].email''',
      ));
}

class SumWithdrawalsCall {
  Future<ApiCallResponse> call({
    String? providerId = 'is.null',
    String? facilityid = 'is.null',
    String? baseurl,
    String? apikey,
    String? token,
  }) async {
    baseurl ??= FFDevEnvironmentValues().SupabaseRestAPIBaseUrl;
    apikey ??= FFDevEnvironmentValues().Supabasekey;
    token ??= FFDevEnvironmentValues().Supabasekey;
    final baseUrl = SupaBaseRestGroup.getBaseUrl(
      baseurl: baseurl,
      apikey: apikey,
      token: token,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'SumWithdrawals',
      apiUrl: '${baseUrl}/withdrawals?select=total:sum(amount)',
      callType: ApiCallType.GET,
      headers: {
        'apikey': '${apikey}',
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

/// End SupaBaseRest Group Code

/// Start OpenAI ChatGPT Group Code

class OpenAIChatGPTGroup {
  static String getBaseUrl() => 'https://api.openai.com/v1';
  static Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
  static SendFullPromptCall sendFullPromptCall = SendFullPromptCall();
}

class SendFullPromptCall {
  Future<ApiCallResponse> call({
    String? apiKey = '',
    dynamic? promptJson,
  }) async {
    final baseUrl = OpenAIChatGPTGroup.getBaseUrl();

    final prompt = _serializeJson(promptJson);
    final ffApiRequestBody = '''
{
  "model": "gpt-4",
  "messages": ${prompt}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Send Full Prompt',
      apiUrl: '${baseUrl}/chat/completions',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? createdTimestamp(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.created''',
      ));
  String? role(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.choices[:].message.role''',
      ));
  String? content(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.choices[:].message.content''',
      ));
}

/// End OpenAI ChatGPT Group Code

/// Start FapShi Group Code

class FapShiGroup {
  static String getBaseUrl({
    String? paymentApi,
    String? paymentUser,
    String? paypentAPIKey,
  }) {
    paymentApi ??= FFDevEnvironmentValues().PaymentApi;
    paymentUser ??= FFDevEnvironmentValues().PaymentUser;
    paypentAPIKey ??= FFDevEnvironmentValues().PaypentAPIKey;
    return '${paymentApi}';
  }

  static Map<String, String> headers = {
    'apiuser': '[PaymentUser]',
    'apikey': '[PaypentAPIKey]',
  };
  static HelpMePaysCall helpMePaysCall = HelpMePaysCall();
  static CheckPaymentCall checkPaymentCall = CheckPaymentCall();
  static DirectDebitCall directDebitCall = DirectDebitCall();
}

class HelpMePaysCall {
  Future<ApiCallResponse> call({
    double? amount,
    String? message = '',
    String? transactionid = '',
    String? paymentApi,
    String? paymentUser,
    String? paypentAPIKey,
  }) async {
    paymentApi ??= FFDevEnvironmentValues().PaymentApi;
    paymentUser ??= FFDevEnvironmentValues().PaymentUser;
    paypentAPIKey ??= FFDevEnvironmentValues().PaypentAPIKey;
    final baseUrl = FapShiGroup.getBaseUrl(
      paymentApi: paymentApi,
      paymentUser: paymentUser,
      paypentAPIKey: paypentAPIKey,
    );

    final ffApiRequestBody = '''
{
  "amount": ${amount},
  "redirectUrl": "https://medzenhealth.app/",
  "externalId": "${escapeStringForJson(transactionid)}",
  "message": "${escapeStringForJson(message)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Help Me Pays',
      apiUrl: '${baseUrl}/initiate-pay',
      callType: ApiCallType.POST,
      headers: {
        'apiuser': '${paymentUser}',
        'apikey': '${paypentAPIKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CheckPaymentCall {
  Future<ApiCallResponse> call({
    String? transactionid = '',
    String? paymentApi,
    String? paymentUser,
    String? paypentAPIKey,
  }) async {
    paymentApi ??= FFDevEnvironmentValues().PaymentApi;
    paymentUser ??= FFDevEnvironmentValues().PaymentUser;
    paypentAPIKey ??= FFDevEnvironmentValues().PaypentAPIKey;
    final baseUrl = FapShiGroup.getBaseUrl(
      paymentApi: paymentApi,
      paymentUser: paymentUser,
      paypentAPIKey: paypentAPIKey,
    );

    return ApiManager.instance.makeApiCall(
      callName: 'Check Payment',
      apiUrl: '${baseUrl}/payment-status/${transactionid}',
      callType: ApiCallType.GET,
      headers: {
        'apiuser': '${paymentUser}',
        'apikey': '${paypentAPIKey}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? status(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.status''',
      ));
}

class DirectDebitCall {
  Future<ApiCallResponse> call({
    double? amount,
    String? phonenumber = '',
    String? internalid = '',
    String? message = '',
    String? usernumber = '',
    String? paymentApi,
    String? paymentUser,
    String? paypentAPIKey,
  }) async {
    paymentApi ??= FFDevEnvironmentValues().PaymentApi;
    paymentUser ??= FFDevEnvironmentValues().PaymentUser;
    paypentAPIKey ??= FFDevEnvironmentValues().PaypentAPIKey;
    final baseUrl = FapShiGroup.getBaseUrl(
      paymentApi: paymentApi,
      paymentUser: paymentUser,
      paypentAPIKey: paypentAPIKey,
    );

    final ffApiRequestBody = '''
{
  "amount": ${amount},
  "phone": "${escapeStringForJson(phonenumber)}",
  "medium": "mobile money",
  "userId": "${escapeStringForJson(usernumber)}",
  "externalId": "${escapeStringForJson(internalid)}",
  "message": "MEDZENE-HEALTH Service"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Direct Debit',
      apiUrl: '${baseUrl}/direct-pay',
      callType: ApiCallType.POST,
      headers: {
        'apiuser': '${paymentUser}',
        'apikey': '${paypentAPIKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  String? dateInitiated(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.dateInitiated''',
      ));
  String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
  String? transactionID(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.transId''',
      ));
}

/// End FapShi Group Code

class HelpMePayCall {
  static Future<ApiCallResponse> call({
    String? phone = '',
    String? sms = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Help Me Pay',
      apiUrl:
          'https://api.twilio.com/2010-04-01/Accounts/${FFAppState().twilioAccountSid}/Messages.json',
      callType: ApiCallType.POST,
      headers: {
        'Authorization':
            'Basic ${FFAppState().twilioAuthToken}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      params: {
        'MessagingServiceSid': "YOUR_TWILIO_MESSAGING_SERVICE_SID",
        'Body': sms,
        'To': phone,
        'ShortenUrls': true,
      },
      bodyType: BodyType.X_WWW_FORM_URL_ENCODED,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AwsSmsCall {
  static Future<ApiCallResponse> call({
    String? phonenumber = '',
    String? message = '',
    String? api,
    String? key,
  }) async {
    api ??= FFDevEnvironmentValues().AwsSmsApiUrl;
    key ??= FFDevEnvironmentValues().AwsSmsApiKey;

    final ffApiRequestBody = '''
{
  "to": "${escapeStringForJson(phonenumber)}",
  "message": "${escapeStringForJson(message)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'AWS SMS',
      apiUrl: '${api}',
      callType: ApiCallType.POST,
      headers: {
        'x-api-key': '${key}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AWSSendOTPCall {
  static Future<ApiCallResponse> call({
    String? phone = '',
    String? api,
    String? key,
  }) async {
    api ??= FFDevEnvironmentValues().AWSOtpsendurl;
    key ??= FFDevEnvironmentValues().AWSOtpsendApiKey;

    final ffApiRequestBody = '''
{
  "phone": "${escapeStringForJson(phone)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'AWS Send OTP',
      apiUrl: '${api}',
      callType: ApiCallType.POST,
      headers: {
        'x-api-key': '${key}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static bool? success(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.success''',
      ));
}

class AWSVerifyOTPCall {
  static Future<ApiCallResponse> call({
    String? phone = '',
    String? api,
    String? key,
    String? otp = '',
  }) async {
    api ??= FFDevEnvironmentValues().AWSOtpVerifyurl;
    key ??= FFDevEnvironmentValues().AWSOtpVerifyApiKey;

    final ffApiRequestBody = '''
{
  "phone": "${escapeStringForJson(phone)}",
  "otp": "${escapeStringForJson(otp)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'AWS Verify OTP ',
      apiUrl: '${api}',
      callType: ApiCallType.POST,
      headers: {
        'x-api-key': '${key}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class TwillioSendSmsCall {
  static Future<ApiCallResponse> call({
    String? phone = '',
    String? message = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Twillio Send sms',
      apiUrl:
          'https://api.twilio.com/2010-04-01/Accounts/${FFAppState().twilioAccountSid}/Messages.json',
      callType: ApiCallType.POST,
      headers: {
        'Authorization':
            'Basic ${FFAppState().twilioAuthToken}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      params: {
        'To': phone,
        'Body': message,
        'MessagingServiceSid': "YOUR_TWILIO_MESSAGING_SERVICE_SID",
      },
      bodyType: BodyType.X_WWW_FORM_URL_ENCODED,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AWSResetPwdCall {
  static Future<ApiCallResponse> call({
    String? phone = '',
    String? api,
    String? key,
    String? email = '',
  }) async {
    api ??= FFDevEnvironmentValues().AWSResetPwdurl;
    key ??= FFDevEnvironmentValues().AWSResetPwdKey;

    final ffApiRequestBody = '''
{
  "phone": "${escapeStringForJson(phone)}",
  "email": "${escapeStringForJson(email)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'AWS Reset Pwd',
      apiUrl: '${api}',
      callType: ApiCallType.POST,
      headers: {
        'x-api-key': '${key}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static int? statusCode(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.statusCode''',
      ));
  static String? resetLink(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.ResetLink''',
      ));
}

class FirebaseCreateUserCall {
  static Future<ApiCallResponse> call({
    String? api,
    String? key,
    String? email = '',
    String? displayname = '',
  }) async {
    api ??= FFDevEnvironmentValues().FirebaseCreateUserURL;
    key ??= FFDevEnvironmentValues().FirebaseCreateUserApi;

    final ffApiRequestBody = '''
{
  "email": "${escapeStringForJson(email)}",
  "displayName": "${escapeStringForJson(displayname)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Firebase Create User',
      apiUrl: '${api}',
      callType: ApiCallType.POST,
      headers: {
        'x-api-key': '${key}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
