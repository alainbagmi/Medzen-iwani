import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:from_css_color/from_css_color.dart';

import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';

import '/backend/supabase/supabase.dart';

import '../../flutter_flow/lat_lng.dart';
import '../../flutter_flow/place.dart';
import '../../flutter_flow/uploaded_file.dart';

/// SERIALIZATION HELPERS

String dateTimeRangeToString(DateTimeRange dateTimeRange) {
  final startStr = dateTimeRange.start.millisecondsSinceEpoch.toString();
  final endStr = dateTimeRange.end.millisecondsSinceEpoch.toString();
  return '$startStr|$endStr';
}

String placeToString(FFPlace place) => jsonEncode({
      'latLng': place.latLng.serialize(),
      'name': place.name,
      'address': place.address,
      'city': place.city,
      'state': place.state,
      'country': place.country,
      'zipCode': place.zipCode,
    });

String uploadedFileToString(FFUploadedFile uploadedFile) =>
    uploadedFile.serialize();

/// Converts the input value into a value that can be JSON encoded.
dynamic serializeParameter(dynamic value) {
  switch (value.runtimeType) {
    case DateTime:
      return (value as DateTime).millisecondsSinceEpoch;
    case DateTimeRange:
      return dateTimeRangeToString(value as DateTimeRange);
    case LatLng:
      return (value as LatLng).serialize();
    case Color:
      return (value as Color).toCssString();
    case FFPlace:
      return placeToString(value as FFPlace);
    case FFUploadedFile:
      return uploadedFileToString(value as FFUploadedFile);
    case SupabaseDataRow:
      return json.encode((value as SupabaseDataRow).data);
  }

  if (value is DocumentReference) {
    return value.path;
  }

  if (value is FirestoreRecord) {
    return (value as dynamic).reference.path;
  }

  return value;
}

String serializeParameterData(Map<String, dynamic> parameterData) => jsonEncode(
      parameterData.map(
        (key, value) => MapEntry(
          key,
          serializeParameter(value),
        ),
      )..removeWhere((k, v) => k == null || v == null),
    );

/// END SERIALIZATION HELPERS

/// DESERIALIZATION HELPERS

DateTimeRange? dateTimeRangeFromString(String dateTimeRangeStr) {
  final pieces = dateTimeRangeStr.split('|');
  if (pieces.length != 2) {
    return null;
  }
  return DateTimeRange(
    start: DateTime.fromMillisecondsSinceEpoch(int.parse(pieces.first)),
    end: DateTime.fromMillisecondsSinceEpoch(int.parse(pieces.last)),
  );
}

LatLng? latLngFromString(String? latLngStr) {
  final pieces = latLngStr?.split(',');
  if (pieces == null || pieces.length != 2) {
    return null;
  }
  return LatLng(
    double.parse(pieces.first.trim()),
    double.parse(pieces.last.trim()),
  );
}

FFPlace placeFromString(String placeStr) {
  final serializedData = jsonDecode(placeStr) as Map<String, dynamic>;
  final data = {
    'latLng': serializedData.containsKey('latLng')
        ? latLngFromString(serializedData['latLng'] as String)
        : const LatLng(0.0, 0.0),
    'name': serializedData['name'] ?? '',
    'address': serializedData['address'] ?? '',
    'city': serializedData['city'] ?? '',
    'state': serializedData['state'] ?? '',
    'country': serializedData['country'] ?? '',
    'zipCode': serializedData['zipCode'] ?? '',
  };
  return FFPlace(
    latLng: data['latLng'] as LatLng,
    name: data['name'] as String,
    address: data['address'] as String,
    city: data['city'] as String,
    state: data['state'] as String,
    country: data['country'] as String,
    zipCode: data['zipCode'] as String,
  );
}

FFUploadedFile uploadedFileFromString(String uploadedFileStr) =>
    FFUploadedFile.deserialize(uploadedFileStr);

T? getParameter<T>(Map<String, dynamic> data, String paramName) {
  try {
    if (!data.containsKey(paramName)) {
      return null;
    }
    final param = data[paramName];
    switch (T) {
      case String:
        return param;
      case double:
        return param.toDouble();
      case DateTime:
        return DateTime.fromMillisecondsSinceEpoch(param) as T;
      case DateTimeRange:
        return dateTimeRangeFromString(param) as T;
      case LatLng:
        return latLngFromString(param) as T;
      case Color:
        return fromCssColor(param) as T;
      case FFPlace:
        return placeFromString(param) as T;
      case FFUploadedFile:
        return uploadedFileFromString(param) as T;
      case EmailLogsRow:
        return EmailLogsRow(json.decode(param) as Map<String, dynamic>) as T;
      case PathologyReportsRow:
        return PathologyReportsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case SystemAdminPatientViewRow:
        return SystemAdminPatientViewRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case InfectiousDiseaseVisitsRow:
        return InfectiousDiseaseVisitsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case PatientProfilesRow:
        return PatientProfilesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case AdminProfilesRow:
        return AdminProfilesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case PromotionsRow:
        return PromotionsRow(json.decode(param) as Map<String, dynamic>) as T;
      case AnnouncementReadsRow:
        return AnnouncementReadsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case PaymentsRow:
        return PaymentsRow(json.decode(param) as Map<String, dynamic>) as T;
      case VSpecialtyProviderCountsRow:
        return VSpecialtyProviderCountsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case SpatialRefSysRow:
        return SpatialRefSysRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case MedicationsRow:
        return MedicationsRow(json.decode(param) as Map<String, dynamic>) as T;
      case CustomVocabulariesRow:
        return CustomVocabulariesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case NurseProfilesRow:
        return NurseProfilesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case PharmacistProfilesRow:
        return PharmacistProfilesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case UnreadMessageCountsRow:
        return UnreadMessageCountsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case OpenehrIntegrationHealthRow:
        return OpenehrIntegrationHealthRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case UserMedicalConditionsRow:
        return UserMedicalConditionsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case PushNotificationsRow:
        return PushNotificationsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ElectronicHealthRecordsRow:
        return ElectronicHealthRecordsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case EndocrinologyVisitsRow:
        return EndocrinologyVisitsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case MedicalProviderProfilesRow:
        return MedicalProviderProfilesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case VProviderTypeDetailsRow:
        return VProviderTypeDetailsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case AiConversationLanguageStatsRow:
        return AiConversationLanguageStatsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case OncologyTreatmentsRow:
        return OncologyTreatmentsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case MedicationDispensingRow:
        return MedicationDispensingRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case PaymentAnalyticsRow:
        return PaymentAnalyticsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case AiMessagesRow:
        return AiMessagesRow(json.decode(param) as Map<String, dynamic>) as T;
      case VitalSignsRow:
        return VitalSignsRow(json.decode(param) as Map<String, dynamic>) as T;
      case AppointmentRemindersRow:
        return AppointmentRemindersRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ClinicalNotesOverviewRow:
        return ClinicalNotesOverviewRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case DocumentEmbeddingsRow:
        return DocumentEmbeddingsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case RadiologyReportsRow:
        return RadiologyReportsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ConversationParticipantsRow:
        return ConversationParticipantsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case AiMessagesWithAudioRow:
        return AiMessagesWithAudioRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ArchetypeFormFieldsRow:
        return ArchetypeFormFieldsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ImmunizationsRow:
        return ImmunizationsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case EdgeFunctionLogsRow:
        return EdgeFunctionLogsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case FacilityDepartmentAssignmentsRow:
        return FacilityDepartmentAssignmentsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case LabTestCategoriesRow:
        return LabTestCategoriesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case PaymentSumaryRow:
        return PaymentSumaryRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ArchetypesRow:
        return ArchetypesRow(json.decode(param) as Map<String, dynamic>) as T;
      case ProviderScheduleExceptionsRow:
        return ProviderScheduleExceptionsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case DoctorProfilesRow:
        return DoctorProfilesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case VideoCallParticipantsViewRow:
        return VideoCallParticipantsViewRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case SystemAdminProfilesRow:
        return SystemAdminProfilesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case VProviderSpecialtySearchRow:
        return VProviderSpecialtySearchRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case VideoCallAuditLogRow:
        return VideoCallAuditLogRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case MedicalProviderTypesRow:
        return MedicalProviderTypesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case NephrologyVisitsRow:
        return NephrologyVisitsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case WhatsappLogsRow:
        return WhatsappLogsRow(json.decode(param) as Map<String, dynamic>) as T;
      case MedicalRecordEmbeddingsRow:
        return MedicalRecordEmbeddingsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case GeometryColumnsRow:
        return GeometryColumnsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case WithdrawalListViewRow:
        return WithdrawalListViewRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case BloodDonorsRow:
        return BloodDonorsRow(json.decode(param) as Map<String, dynamic>) as T;
      case UserSubscriptionsRow:
        return UserSubscriptionsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case EhrbaseSyncQueueRow:
        return EhrbaseSyncQueueRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case PaymentOverviewRow:
        return PaymentOverviewRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case LabTestTypesRow:
        return LabTestTypesRow(json.decode(param) as Map<String, dynamic>) as T;
      case VEhrByRoleRow:
        return VEhrByRoleRow(json.decode(param) as Map<String, dynamic>) as T;
      case PaymentMethodsRow:
        return PaymentMethodsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case PsychiatricAssessmentsRow:
        return PsychiatricAssessmentsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case PublicationsRow:
        return PublicationsRow(json.decode(param) as Map<String, dynamic>) as T;
      case SpecialtyServicesRow:
        return SpecialtyServicesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case LanguagePreferencesRow:
        return LanguagePreferencesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case MedicalProviderFacilityViewRow:
        return MedicalProviderFacilityViewRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ClinicalConsultationsRow:
        return ClinicalConsultationsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case FacilityTypeAssignmentsRow:
        return FacilityTypeAssignmentsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case PulmonologyVisitsRow:
        return PulmonologyVisitsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case SpeechToTextLogsRow:
        return SpeechToTextLogsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case TransactionsRow:
        return TransactionsRow(json.decode(param) as Map<String, dynamic>) as T;
      case AiConversationsRow:
        return AiConversationsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case MedicalRecordConditionsRow:
        return MedicalRecordConditionsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case MedicalPractitionersViewRow:
        return MedicalPractitionersViewRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case CustomVocabularyAnalyticsRow:
        return CustomVocabularyAnalyticsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case AdmissionDischargesRow:
        return AdmissionDischargesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case FacilityAdminProfilesRow:
        return FacilityAdminProfilesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case FacilitiesRow:
        return FacilitiesRow(json.decode(param) as Map<String, dynamic>) as T;
      case PrescriptionMedicationsRow:
        return PrescriptionMedicationsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ChimeMessagesRow:
        return ChimeMessagesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case PatientMedicalReportExportsRow:
        return PatientMedicalReportExportsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case AppointmentsRow:
        return AppointmentsRow(json.decode(param) as Map<String, dynamic>) as T;
      case PushNotificationTargetsRow:
        return PushNotificationTargetsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case GastroenterologyProceduresRow:
        return GastroenterologyProceduresRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case WithdrawalTotalsRow:
        return WithdrawalTotalsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case TemplatesRow:
        return TemplatesRow(json.decode(param) as Map<String, dynamic>) as T;
      case NeurologyExamsRow:
        return NeurologyExamsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case AllReviewsRow:
        return AllReviewsRow(json.decode(param) as Map<String, dynamic>) as T;
      case MedicalRecordsRow:
        return MedicalRecordsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case SearchIndexesRow:
        return SearchIndexesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case FacilityDepartmentsRow:
        return FacilityDepartmentsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case SystemAdminAppointmentStatsRow:
        return SystemAdminAppointmentStatsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ProviderTypesRow:
        return ProviderTypesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case SubscriptionPlansRow:
        return SubscriptionPlansRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ProviderAvailabilityRow:
        return ProviderAvailabilityRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case SystemDashboardStatsRow:
        return SystemDashboardStatsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ChimeMessagingChannelsRow:
        return ChimeMessagingChannelsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case PrescriptionsRow:
        return PrescriptionsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case StorageFileOwnershipRow:
        return StorageFileOwnershipRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case UserMedicationsRow:
        return UserMedicationsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case AiAssistantsRow:
        return AiAssistantsRow(json.decode(param) as Map<String, dynamic>) as T;
      case GeographyColumnsRow:
        return GeographyColumnsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case VideoCallSessionsRow:
        return VideoCallSessionsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case FeedbackRow:
        return FeedbackRow(json.decode(param) as Map<String, dynamic>) as T;
      case LiveCaptionSegmentsRow:
        return LiveCaptionSegmentsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case WithdrawalsOverviewRow:
        return WithdrawalsOverviewRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case NotificationPreferencesRow:
        return NotificationPreferencesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case MedicalPractitionersDetailsViewRow:
        return MedicalPractitionersDetailsViewRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case LabTechnicianProfilesRow:
        return LabTechnicianProfilesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case PaymentTotalsRow:
        return PaymentTotalsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case UssdMenusRow:
        return UssdMenusRow(json.decode(param) as Map<String, dynamic>) as T;
      case PasswordResetTokensRow:
        return PasswordResetTokensRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case AnnouncementsRow:
        return AnnouncementsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case WaitlistRow:
        return WaitlistRow(json.decode(param) as Map<String, dynamic>) as T;
      case ClinicalNotesRow:
        return ClinicalNotesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case AllergiesRow:
        return AllergiesRow(json.decode(param) as Map<String, dynamic>) as T;
      case ProfilePicturesRow:
        return ProfilePicturesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case LabResultsRow:
        return LabResultsRow(json.decode(param) as Map<String, dynamic>) as T;
      case PhysiotherapySessionsRow:
        return PhysiotherapySessionsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case PublicationCommentsRow:
        return PublicationCommentsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case BloodTypesRow:
        return BloodTypesRow(json.decode(param) as Map<String, dynamic>) as T;
      case InvoicesRow:
        return InvoicesRow(json.decode(param) as Map<String, dynamic>) as T;
      case PublicationLikesRow:
        return PublicationLikesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case SystemAdminFacilityStatsRow:
        return SystemAdminFacilityStatsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case SystemAuditLogsRow:
        return SystemAuditLogsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case VProviderSecondarySpecialtiesRow:
        return VProviderSecondarySpecialtiesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ProviderSpecialtyServicesRow:
        return ProviderSpecialtyServicesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case MedicalConditionsRow:
        return MedicalConditionsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case UserProfilesRow:
        return UserProfilesRow(json.decode(param) as Map<String, dynamic>) as T;
      case UssdActionsRow:
        return UssdActionsRow(json.decode(param) as Map<String, dynamic>) as T;
      case FacilityAdminPatientViewRow:
        return FacilityAdminPatientViewRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case UserAllergiesRow:
        return UserAllergiesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case FacilityProvidersRow:
        return FacilityProvidersRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case RemindersRow:
        return RemindersRow(json.decode(param) as Map<String, dynamic>) as T;
      case SurgicalProceduresRow:
        return SurgicalProceduresRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ProviderTypeAssignmentsRow:
        return ProviderTypeAssignmentsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case PharmacyStockRow:
        return PharmacyStockRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case AiLanguageUsageStatsRow:
        return AiLanguageUsageStatsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case FacilityTypesRow:
        return FacilityTypesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case DoctorPerformanceReportsRow:
        return DoctorPerformanceReportsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case VProviderSpecialtyDetailsRow:
        return VProviderSpecialtyDetailsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case MessagesRow:
        return MessagesRow(json.decode(param) as Map<String, dynamic>) as T;
      case ConsultationMedicalEntitiesRow:
        return ConsultationMedicalEntitiesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case UssdSessionsRow:
        return UssdSessionsRow(json.decode(param) as Map<String, dynamic>) as T;
      case LabOrdersRow:
        return LabOrdersRow(json.decode(param) as Map<String, dynamic>) as T;
      case AntenatalVisitsRow:
        return AntenatalVisitsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case WithdrawalsRow:
        return WithdrawalsRow(json.decode(param) as Map<String, dynamic>) as T;
      case DocumentsRow:
        return DocumentsRow(json.decode(param) as Map<String, dynamic>) as T;
      case ChatConversationsRow:
        return ChatConversationsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case SearchAnalyticsRow:
        return SearchAnalyticsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ProviderSpecialtiesRow:
        return ProviderSpecialtiesRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case EmergencyVisitsRow:
        return EmergencyVisitsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case PublicationBookmarksRow:
        return PublicationBookmarksRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case VEhrbaseSyncStatusRow:
        return VEhrbaseSyncStatusRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case SmsLogsRow:
        return SmsLogsRow(json.decode(param) as Map<String, dynamic>) as T;
      case FacilityReportsRow:
        return FacilityReportsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case MessageReactionsRow:
        return MessageReactionsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case VSpecialtiesByCategoryRow:
        return VSpecialtiesByCategoryRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ActiveSessionsRow:
        return ActiveSessionsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case EhrCompositionsRow:
        return EhrCompositionsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case MediaLibraryRow:
        return MediaLibraryRow(json.decode(param) as Map<String, dynamic>) as T;
      case UsersRow:
        return UsersRow(json.decode(param) as Map<String, dynamic>) as T;
      case SystemAdminClinicalStatsRow:
        return SystemAdminClinicalStatsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case VideoCallParticipantsRow:
        return VideoCallParticipantsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ChimeMessageAuditRow:
        return ChimeMessageAuditRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case ReviewResponsesRow:
        return ReviewResponsesRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case InvoiceLineItemsRow:
        return InvoiceLineItemsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case MedicalRecordingMetadataRow:
        return MedicalRecordingMetadataRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case SpecialtiesRow:
        return SpecialtiesRow(json.decode(param) as Map<String, dynamic>) as T;
      case UserActivityLogsRow:
        return UserActivityLogsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case VPowersyncReplicationStatusRow:
        return VPowersyncReplicationStatusRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case FacilityAdminDetailsRow:
        return FacilityAdminDetailsRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ReviewsRow:
        return ReviewsRow(json.decode(param) as Map<String, dynamic>) as T;
      case PromotionUsageRow:
        return PromotionUsageRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case NotificationsRow:
        return NotificationsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case AppointmentOverviewRow:
        return AppointmentOverviewRow(
            json.decode(param) as Map<String, dynamic>) as T;
      case ConversationsRow:
        return ConversationsRow(json.decode(param) as Map<String, dynamic>)
            as T;
      case CardiologyVisitsRow:
        return CardiologyVisitsRow(json.decode(param) as Map<String, dynamic>)
            as T;
    }
    if (param is String) {
      return FirebaseFirestore.instance.doc(param) as T;
    }
    return param;
  } catch (e) {
    print('Error parsing parameter "$paramName": $e');
    return null;
  }
}

Future<T?> getDocumentParameter<T>(
  Map<String, dynamic> data,
  String paramName,
  RecordBuilder<T> recordBuilder,
) {
  if (!data.containsKey(paramName)) {
    return Future.value(null);
  }
  return FirebaseFirestore.instance
      .doc(data[paramName])
      .get()
      .then((s) => recordBuilder(s));
}

/// END DESERIALIZATION HELPERS
