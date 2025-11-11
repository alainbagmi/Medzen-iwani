import 'dart:convert';

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

const _kDocIdDelimeter = '|';
String _serializeDocumentReference(DocumentReference ref) {
  final docIds = <String>[];
  DocumentReference? currentRef = ref;
  while (currentRef != null) {
    docIds.add(currentRef.id);
    // Get the parent document (catching any errors that arise).
    currentRef = safeGet<DocumentReference?>(() => currentRef?.parent.parent);
  }
  // Reverse the list to get the correct ordering.
  return docIds.reversed.join(_kDocIdDelimeter);
}

String? serializeParam(
  dynamic param,
  ParamType paramType, {
  bool isList = false,
}) {
  try {
    if (param == null) {
      return null;
    }
    if (isList) {
      final serializedValues = (param as Iterable)
          .map((p) => serializeParam(p, paramType, isList: false))
          .where((p) => p != null)
          .map((p) => p!)
          .toList();
      return json.encode(serializedValues);
    }
    String? data;
    switch (paramType) {
      case ParamType.int:
        data = param.toString();
      case ParamType.double:
        data = param.toString();
      case ParamType.String:
        data = param;
      case ParamType.bool:
        data = param ? 'true' : 'false';
      case ParamType.DateTime:
        data = (param as DateTime).millisecondsSinceEpoch.toString();
      case ParamType.DateTimeRange:
        data = dateTimeRangeToString(param as DateTimeRange);
      case ParamType.LatLng:
        data = (param as LatLng).serialize();
      case ParamType.Color:
        data = (param as Color).toCssString();
      case ParamType.FFPlace:
        data = placeToString(param as FFPlace);
      case ParamType.FFUploadedFile:
        data = uploadedFileToString(param as FFUploadedFile);
      case ParamType.JSON:
        data = json.encode(param);
      case ParamType.DocumentReference:
        data = _serializeDocumentReference(param as DocumentReference);
      case ParamType.Document:
        final reference = (param as FirestoreRecord).reference;
        data = _serializeDocumentReference(reference);

      case ParamType.DataStruct:
        data = param is BaseStruct ? param.serialize() : null;

      case ParamType.SupabaseRow:
        return json.encode((param as SupabaseDataRow).data);

      default:
        data = null;
    }
    return data;
  } catch (e) {
    print('Error serializing parameter: $e');
    return null;
  }
}

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

DocumentReference _deserializeDocumentReference(
  String refStr,
  List<String> collectionNamePath,
) {
  var path = '';
  final docIds = refStr.split(_kDocIdDelimeter);
  for (int i = 0; i < docIds.length && i < collectionNamePath.length; i++) {
    path += '/${collectionNamePath[i]}/${docIds[i]}';
  }
  return FirebaseFirestore.instance.doc(path);
}

enum ParamType {
  int,
  double,
  String,
  bool,
  DateTime,
  DateTimeRange,
  LatLng,
  Color,
  FFPlace,
  FFUploadedFile,
  JSON,

  Document,
  DocumentReference,
  DataStruct,
  SupabaseRow,
}

dynamic deserializeParam<T>(
  String? param,
  ParamType paramType,
  bool isList, {
  List<String>? collectionNamePath,
  StructBuilder<T>? structBuilder,
}) {
  try {
    if (param == null) {
      return null;
    }
    if (isList) {
      final paramValues = json.decode(param);
      if (paramValues is! Iterable || paramValues.isEmpty) {
        return null;
      }
      return paramValues
          .where((p) => p is String)
          .map((p) => p as String)
          .map((p) => deserializeParam<T>(
                p,
                paramType,
                false,
                collectionNamePath: collectionNamePath,
                structBuilder: structBuilder,
              ))
          .where((p) => p != null)
          .map((p) => p! as T)
          .toList();
    }
    switch (paramType) {
      case ParamType.int:
        return int.tryParse(param);
      case ParamType.double:
        return double.tryParse(param);
      case ParamType.String:
        return param;
      case ParamType.bool:
        return param == 'true';
      case ParamType.DateTime:
        final milliseconds = int.tryParse(param);
        return milliseconds != null
            ? DateTime.fromMillisecondsSinceEpoch(milliseconds)
            : null;
      case ParamType.DateTimeRange:
        return dateTimeRangeFromString(param);
      case ParamType.LatLng:
        return latLngFromString(param);
      case ParamType.Color:
        return fromCssColor(param);
      case ParamType.FFPlace:
        return placeFromString(param);
      case ParamType.FFUploadedFile:
        return uploadedFileFromString(param);
      case ParamType.JSON:
        return json.decode(param);
      case ParamType.DocumentReference:
        return _deserializeDocumentReference(param, collectionNamePath ?? []);

      case ParamType.SupabaseRow:
        final data = json.decode(param) as Map<String, dynamic>;
        switch (T) {
          case EmailLogsRow:
            return EmailLogsRow(data);
          case PathologyReportsRow:
            return PathologyReportsRow(data);
          case InfectiousDiseaseVisitsRow:
            return InfectiousDiseaseVisitsRow(data);
          case PatientProfilesRow:
            return PatientProfilesRow(data);
          case AdminProfilesRow:
            return AdminProfilesRow(data);
          case PromotionsRow:
            return PromotionsRow(data);
          case AnnouncementReadsRow:
            return AnnouncementReadsRow(data);
          case PaymentsRow:
            return PaymentsRow(data);
          case VSpecialtyProviderCountsRow:
            return VSpecialtyProviderCountsRow(data);
          case SpatialRefSysRow:
            return SpatialRefSysRow(data);
          case MedicationsRow:
            return MedicationsRow(data);
          case NurseProfilesRow:
            return NurseProfilesRow(data);
          case PharmacistProfilesRow:
            return PharmacistProfilesRow(data);
          case OpenehrIntegrationHealthRow:
            return OpenehrIntegrationHealthRow(data);
          case UserMedicalConditionsRow:
            return UserMedicalConditionsRow(data);
          case PushNotificationsRow:
            return PushNotificationsRow(data);
          case ElectronicHealthRecordsRow:
            return ElectronicHealthRecordsRow(data);
          case EndocrinologyVisitsRow:
            return EndocrinologyVisitsRow(data);
          case MedicalProviderProfilesRow:
            return MedicalProviderProfilesRow(data);
          case OncologyTreatmentsRow:
            return OncologyTreatmentsRow(data);
          case MedicationDispensingRow:
            return MedicationDispensingRow(data);
          case PaymentAnalyticsRow:
            return PaymentAnalyticsRow(data);
          case AiMessagesRow:
            return AiMessagesRow(data);
          case VitalSignsRow:
            return VitalSignsRow(data);
          case DocumentEmbeddingsRow:
            return DocumentEmbeddingsRow(data);
          case RadiologyReportsRow:
            return RadiologyReportsRow(data);
          case ArchetypeFormFieldsRow:
            return ArchetypeFormFieldsRow(data);
          case ImmunizationsRow:
            return ImmunizationsRow(data);
          case FacilityDepartmentAssignmentsRow:
            return FacilityDepartmentAssignmentsRow(data);
          case LabTestCategoriesRow:
            return LabTestCategoriesRow(data);
          case ArchetypesRow:
            return ArchetypesRow(data);
          case ProviderScheduleExceptionsRow:
            return ProviderScheduleExceptionsRow(data);
          case DoctorProfilesRow:
            return DoctorProfilesRow(data);
          case SystemAdminProfilesRow:
            return SystemAdminProfilesRow(data);
          case VProviderSpecialtySearchRow:
            return VProviderSpecialtySearchRow(data);
          case MedicalProviderTypesRow:
            return MedicalProviderTypesRow(data);
          case NephrologyVisitsRow:
            return NephrologyVisitsRow(data);
          case WhatsappLogsRow:
            return WhatsappLogsRow(data);
          case MedicalRecordEmbeddingsRow:
            return MedicalRecordEmbeddingsRow(data);
          case GeometryColumnsRow:
            return GeometryColumnsRow(data);
          case BloodDonorsRow:
            return BloodDonorsRow(data);
          case UserSubscriptionsRow:
            return UserSubscriptionsRow(data);
          case EhrbaseSyncQueueRow:
            return EhrbaseSyncQueueRow(data);
          case LabTestTypesRow:
            return LabTestTypesRow(data);
          case VEhrByRoleRow:
            return VEhrByRoleRow(data);
          case PaymentMethodsRow:
            return PaymentMethodsRow(data);
          case PsychiatricAssessmentsRow:
            return PsychiatricAssessmentsRow(data);
          case PublicationsRow:
            return PublicationsRow(data);
          case SpecialtyServicesRow:
            return SpecialtyServicesRow(data);
          case ClinicalConsultationsRow:
            return ClinicalConsultationsRow(data);
          case FacilityTypeAssignmentsRow:
            return FacilityTypeAssignmentsRow(data);
          case PulmonologyVisitsRow:
            return PulmonologyVisitsRow(data);
          case SpeechToTextLogsRow:
            return SpeechToTextLogsRow(data);
          case TransactionsRow:
            return TransactionsRow(data);
          case AiConversationsRow:
            return AiConversationsRow(data);
          case MedicalRecordConditionsRow:
            return MedicalRecordConditionsRow(data);
          case MedicalPractitionersViewRow:
            return MedicalPractitionersViewRow(data);
          case AdmissionDischargesRow:
            return AdmissionDischargesRow(data);
          case VPendingProviderApplicationsRow:
            return VPendingProviderApplicationsRow(data);
          case FacilityAdminProfilesRow:
            return FacilityAdminProfilesRow(data);
          case FacilitiesRow:
            return FacilitiesRow(data);
          case PrescriptionMedicationsRow:
            return PrescriptionMedicationsRow(data);
          case PatientMedicalReportExportsRow:
            return PatientMedicalReportExportsRow(data);
          case AppointmentsRow:
            return AppointmentsRow(data);
          case GastroenterologyProceduresRow:
            return GastroenterologyProceduresRow(data);
          case TemplatesRow:
            return TemplatesRow(data);
          case NeurologyExamsRow:
            return NeurologyExamsRow(data);
          case MedicalRecordsRow:
            return MedicalRecordsRow(data);
          case SearchIndexesRow:
            return SearchIndexesRow(data);
          case FacilityDepartmentsRow:
            return FacilityDepartmentsRow(data);
          case SystemAdminAppointmentStatsRow:
            return SystemAdminAppointmentStatsRow(data);
          case SubscriptionPlansRow:
            return SubscriptionPlansRow(data);
          case ProviderAvailabilityRow:
            return ProviderAvailabilityRow(data);
          case SystemDashboardStatsRow:
            return SystemDashboardStatsRow(data);
          case PrescriptionsRow:
            return PrescriptionsRow(data);
          case StorageFileOwnershipRow:
            return StorageFileOwnershipRow(data);
          case UserMedicationsRow:
            return UserMedicationsRow(data);
          case GeographyColumnsRow:
            return GeographyColumnsRow(data);
          case VideoCallSessionsRow:
            return VideoCallSessionsRow(data);
          case FeedbackRow:
            return FeedbackRow(data);
          case NotificationPreferencesRow:
            return NotificationPreferencesRow(data);
          case MedicalPractitionersDetailsViewRow:
            return MedicalPractitionersDetailsViewRow(data);
          case LabTechnicianProfilesRow:
            return LabTechnicianProfilesRow(data);
          case UssdMenusRow:
            return UssdMenusRow(data);
          case AnnouncementsRow:
            return AnnouncementsRow(data);
          case WaitlistRow:
            return WaitlistRow(data);
          case AllergiesRow:
            return AllergiesRow(data);
          case ProfilePicturesRow:
            return ProfilePicturesRow(data);
          case LabResultsRow:
            return LabResultsRow(data);
          case PhysiotherapySessionsRow:
            return PhysiotherapySessionsRow(data);
          case PublicationCommentsRow:
            return PublicationCommentsRow(data);
          case BloodTypesRow:
            return BloodTypesRow(data);
          case InvoicesRow:
            return InvoicesRow(data);
          case PublicationLikesRow:
            return PublicationLikesRow(data);
          case SystemAdminFacilityStatsRow:
            return SystemAdminFacilityStatsRow(data);
          case SystemAuditLogsRow:
            return SystemAuditLogsRow(data);
          case VProviderSecondarySpecialtiesRow:
            return VProviderSecondarySpecialtiesRow(data);
          case ProviderSpecialtyServicesRow:
            return ProviderSpecialtyServicesRow(data);
          case MedicalConditionsRow:
            return MedicalConditionsRow(data);
          case UserProfilesRow:
            return UserProfilesRow(data);
          case UssdActionsRow:
            return UssdActionsRow(data);
          case UserAllergiesRow:
            return UserAllergiesRow(data);
          case FacilityProvidersRow:
            return FacilityProvidersRow(data);
          case RemindersRow:
            return RemindersRow(data);
          case SurgicalProceduresRow:
            return SurgicalProceduresRow(data);
          case ProviderTypeAssignmentsRow:
            return ProviderTypeAssignmentsRow(data);
          case PharmacyStockRow:
            return PharmacyStockRow(data);
          case FacilityTypesRow:
            return FacilityTypesRow(data);
          case DoctorPerformanceReportsRow:
            return DoctorPerformanceReportsRow(data);
          case VProviderSpecialtyDetailsRow:
            return VProviderSpecialtyDetailsRow(data);
          case MessagesRow:
            return MessagesRow(data);
          case UssdSessionsRow:
            return UssdSessionsRow(data);
          case LabOrdersRow:
            return LabOrdersRow(data);
          case AntenatalVisitsRow:
            return AntenatalVisitsRow(data);
          case DocumentsRow:
            return DocumentsRow(data);
          case SearchAnalyticsRow:
            return SearchAnalyticsRow(data);
          case ProviderSpecialtiesRow:
            return ProviderSpecialtiesRow(data);
          case EmergencyVisitsRow:
            return EmergencyVisitsRow(data);
          case PublicationBookmarksRow:
            return PublicationBookmarksRow(data);
          case VEhrbaseSyncStatusRow:
            return VEhrbaseSyncStatusRow(data);
          case SmsLogsRow:
            return SmsLogsRow(data);
          case FacilityReportsRow:
            return FacilityReportsRow(data);
          case MessageReactionsRow:
            return MessageReactionsRow(data);
          case VSpecialtiesByCategoryRow:
            return VSpecialtiesByCategoryRow(data);
          case EhrCompositionsRow:
            return EhrCompositionsRow(data);
          case MediaLibraryRow:
            return MediaLibraryRow(data);
          case UsersRow:
            return UsersRow(data);
          case SystemAdminClinicalStatsRow:
            return SystemAdminClinicalStatsRow(data);
          case ReviewResponsesRow:
            return ReviewResponsesRow(data);
          case InvoiceLineItemsRow:
            return InvoiceLineItemsRow(data);
          case SpecialtiesRow:
            return SpecialtiesRow(data);
          case UserActivityLogsRow:
            return UserActivityLogsRow(data);
          case VPowersyncReplicationStatusRow:
            return VPowersyncReplicationStatusRow(data);
          case ReviewsRow:
            return ReviewsRow(data);
          case PromotionUsageRow:
            return PromotionUsageRow(data);
          case NotificationsRow:
            return NotificationsRow(data);
          case AppointmentOverviewRow:
            return AppointmentOverviewRow(data);
          case ConversationsRow:
            return ConversationsRow(data);
          case CardiologyVisitsRow:
            return CardiologyVisitsRow(data);
          default:
            return null;
        }

      case ParamType.DataStruct:
        final data = json.decode(param) as Map<String, dynamic>? ?? {};
        return structBuilder != null ? structBuilder(data) : null;

      default:
        return null;
    }
  } catch (e) {
    print('Error deserializing parameter: $e');
    return null;
  }
}

Future<dynamic> Function(String) getDoc(
  List<String> collectionNamePath,
  RecordBuilder recordBuilder,
) {
  return (String ids) => _deserializeDocumentReference(ids, collectionNamePath)
      .get()
      .then((s) => recordBuilder(s));
}

Future<List<T>> Function(String) getDocList<T>(
  List<String> collectionNamePath,
  RecordBuilder<T> recordBuilder,
) {
  return (String idsList) {
    List<String> docIds = [];
    try {
      final ids = json.decode(idsList) as Iterable;
      docIds = ids.where((d) => d is String).map((d) => d as String).toList();
    } catch (_) {}
    return Future.wait(
      docIds.map(
        (ids) => _deserializeDocumentReference(ids, collectionNamePath)
            .get()
            .then((s) => recordBuilder(s)),
      ),
    ).then((docs) => docs.where((d) => d != null).map((d) => d!).toList());
  };
}
