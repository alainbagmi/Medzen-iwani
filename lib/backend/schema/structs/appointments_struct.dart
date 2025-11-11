// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class AppointmentsStruct extends FFFirebaseStruct {
  AppointmentsStruct({
    String? patientFullname,
    String? providerFullname,
    String? providerSpecialty,
    String? patientImageUrl,
    String? appointmentStartDate,
    String? appointmentStartTime,
    String? appointmentStatus,
    String? providerId,
    String? facilityId,
    String? providerImageUrl,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _patientFullname = patientFullname,
        _providerFullname = providerFullname,
        _providerSpecialty = providerSpecialty,
        _patientImageUrl = patientImageUrl,
        _appointmentStartDate = appointmentStartDate,
        _appointmentStartTime = appointmentStartTime,
        _appointmentStatus = appointmentStatus,
        _providerId = providerId,
        _facilityId = facilityId,
        _providerImageUrl = providerImageUrl,
        super(firestoreUtilData);

  // "patient_fullname" field.
  String? _patientFullname;
  String get patientFullname => _patientFullname ?? '';
  set patientFullname(String? val) => _patientFullname = val;

  bool hasPatientFullname() => _patientFullname != null;

  // "provider_fullname" field.
  String? _providerFullname;
  String get providerFullname => _providerFullname ?? '';
  set providerFullname(String? val) => _providerFullname = val;

  bool hasProviderFullname() => _providerFullname != null;

  // "provider_specialty" field.
  String? _providerSpecialty;
  String get providerSpecialty => _providerSpecialty ?? '';
  set providerSpecialty(String? val) => _providerSpecialty = val;

  bool hasProviderSpecialty() => _providerSpecialty != null;

  // "patient_image_url" field.
  String? _patientImageUrl;
  String get patientImageUrl => _patientImageUrl ?? '';
  set patientImageUrl(String? val) => _patientImageUrl = val;

  bool hasPatientImageUrl() => _patientImageUrl != null;

  // "appointment_start_date" field.
  String? _appointmentStartDate;
  String get appointmentStartDate => _appointmentStartDate ?? '';
  set appointmentStartDate(String? val) => _appointmentStartDate = val;

  bool hasAppointmentStartDate() => _appointmentStartDate != null;

  // "appointment_start_time" field.
  String? _appointmentStartTime;
  String get appointmentStartTime => _appointmentStartTime ?? '';
  set appointmentStartTime(String? val) => _appointmentStartTime = val;

  bool hasAppointmentStartTime() => _appointmentStartTime != null;

  // "appointment_status" field.
  String? _appointmentStatus;
  String get appointmentStatus => _appointmentStatus ?? '';
  set appointmentStatus(String? val) => _appointmentStatus = val;

  bool hasAppointmentStatus() => _appointmentStatus != null;

  // "provider_id" field.
  String? _providerId;
  String get providerId => _providerId ?? '';
  set providerId(String? val) => _providerId = val;

  bool hasProviderId() => _providerId != null;

  // "facility_id" field.
  String? _facilityId;
  String get facilityId => _facilityId ?? '';
  set facilityId(String? val) => _facilityId = val;

  bool hasFacilityId() => _facilityId != null;

  // "provider_image_url" field.
  String? _providerImageUrl;
  String get providerImageUrl => _providerImageUrl ?? '';
  set providerImageUrl(String? val) => _providerImageUrl = val;

  bool hasProviderImageUrl() => _providerImageUrl != null;

  static AppointmentsStruct fromMap(Map<String, dynamic> data) =>
      AppointmentsStruct(
        patientFullname: data['patient_fullname'] as String?,
        providerFullname: data['provider_fullname'] as String?,
        providerSpecialty: data['provider_specialty'] as String?,
        patientImageUrl: data['patient_image_url'] as String?,
        appointmentStartDate: data['appointment_start_date'] as String?,
        appointmentStartTime: data['appointment_start_time'] as String?,
        appointmentStatus: data['appointment_status'] as String?,
        providerId: data['provider_id'] as String?,
        facilityId: data['facility_id'] as String?,
        providerImageUrl: data['provider_image_url'] as String?,
      );

  static AppointmentsStruct? maybeFromMap(dynamic data) => data is Map
      ? AppointmentsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'patient_fullname': _patientFullname,
        'provider_fullname': _providerFullname,
        'provider_specialty': _providerSpecialty,
        'patient_image_url': _patientImageUrl,
        'appointment_start_date': _appointmentStartDate,
        'appointment_start_time': _appointmentStartTime,
        'appointment_status': _appointmentStatus,
        'provider_id': _providerId,
        'facility_id': _facilityId,
        'provider_image_url': _providerImageUrl,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'patient_fullname': serializeParam(
          _patientFullname,
          ParamType.String,
        ),
        'provider_fullname': serializeParam(
          _providerFullname,
          ParamType.String,
        ),
        'provider_specialty': serializeParam(
          _providerSpecialty,
          ParamType.String,
        ),
        'patient_image_url': serializeParam(
          _patientImageUrl,
          ParamType.String,
        ),
        'appointment_start_date': serializeParam(
          _appointmentStartDate,
          ParamType.String,
        ),
        'appointment_start_time': serializeParam(
          _appointmentStartTime,
          ParamType.String,
        ),
        'appointment_status': serializeParam(
          _appointmentStatus,
          ParamType.String,
        ),
        'provider_id': serializeParam(
          _providerId,
          ParamType.String,
        ),
        'facility_id': serializeParam(
          _facilityId,
          ParamType.String,
        ),
        'provider_image_url': serializeParam(
          _providerImageUrl,
          ParamType.String,
        ),
      }.withoutNulls;

  static AppointmentsStruct fromSerializableMap(Map<String, dynamic> data) =>
      AppointmentsStruct(
        patientFullname: deserializeParam(
          data['patient_fullname'],
          ParamType.String,
          false,
        ),
        providerFullname: deserializeParam(
          data['provider_fullname'],
          ParamType.String,
          false,
        ),
        providerSpecialty: deserializeParam(
          data['provider_specialty'],
          ParamType.String,
          false,
        ),
        patientImageUrl: deserializeParam(
          data['patient_image_url'],
          ParamType.String,
          false,
        ),
        appointmentStartDate: deserializeParam(
          data['appointment_start_date'],
          ParamType.String,
          false,
        ),
        appointmentStartTime: deserializeParam(
          data['appointment_start_time'],
          ParamType.String,
          false,
        ),
        appointmentStatus: deserializeParam(
          data['appointment_status'],
          ParamType.String,
          false,
        ),
        providerId: deserializeParam(
          data['provider_id'],
          ParamType.String,
          false,
        ),
        facilityId: deserializeParam(
          data['facility_id'],
          ParamType.String,
          false,
        ),
        providerImageUrl: deserializeParam(
          data['provider_image_url'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'AppointmentsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is AppointmentsStruct &&
        patientFullname == other.patientFullname &&
        providerFullname == other.providerFullname &&
        providerSpecialty == other.providerSpecialty &&
        patientImageUrl == other.patientImageUrl &&
        appointmentStartDate == other.appointmentStartDate &&
        appointmentStartTime == other.appointmentStartTime &&
        appointmentStatus == other.appointmentStatus &&
        providerId == other.providerId &&
        facilityId == other.facilityId &&
        providerImageUrl == other.providerImageUrl;
  }

  @override
  int get hashCode => const ListEquality().hash([
        patientFullname,
        providerFullname,
        providerSpecialty,
        patientImageUrl,
        appointmentStartDate,
        appointmentStartTime,
        appointmentStatus,
        providerId,
        facilityId,
        providerImageUrl
      ]);
}

AppointmentsStruct createAppointmentsStruct({
  String? patientFullname,
  String? providerFullname,
  String? providerSpecialty,
  String? patientImageUrl,
  String? appointmentStartDate,
  String? appointmentStartTime,
  String? appointmentStatus,
  String? providerId,
  String? facilityId,
  String? providerImageUrl,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    AppointmentsStruct(
      patientFullname: patientFullname,
      providerFullname: providerFullname,
      providerSpecialty: providerSpecialty,
      patientImageUrl: patientImageUrl,
      appointmentStartDate: appointmentStartDate,
      appointmentStartTime: appointmentStartTime,
      appointmentStatus: appointmentStatus,
      providerId: providerId,
      facilityId: facilityId,
      providerImageUrl: providerImageUrl,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

AppointmentsStruct? updateAppointmentsStruct(
  AppointmentsStruct? appointments, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    appointments
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addAppointmentsStructData(
  Map<String, dynamic> firestoreData,
  AppointmentsStruct? appointments,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (appointments == null) {
    return;
  }
  if (appointments.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && appointments.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final appointmentsData =
      getAppointmentsFirestoreData(appointments, forFieldValue);
  final nestedData =
      appointmentsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = appointments.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getAppointmentsFirestoreData(
  AppointmentsStruct? appointments, [
  bool forFieldValue = false,
]) {
  if (appointments == null) {
    return {};
  }
  final firestoreData = mapToFirestore(appointments.toMap());

  // Add any Firestore field values
  appointments.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getAppointmentsListFirestoreData(
  List<AppointmentsStruct>? appointmentss,
) =>
    appointmentss?.map((e) => getAppointmentsFirestoreData(e, true)).toList() ??
    [];
