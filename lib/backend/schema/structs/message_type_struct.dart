// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MessageTypeStruct extends FFFirebaseStruct {
  MessageTypeStruct({
    int? messageId,
    int? chatId,
    String? userId,
    String? message,
    bool? isTyping,
    bool? received,
    bool? read,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _messageId = messageId,
        _chatId = chatId,
        _userId = userId,
        _message = message,
        _isTyping = isTyping,
        _received = received,
        _read = read,
        super(firestoreUtilData);

  // "message_id" field.
  int? _messageId;
  int get messageId => _messageId ?? 0;
  set messageId(int? val) => _messageId = val;

  void incrementMessageId(int amount) => messageId = messageId + amount;

  bool hasMessageId() => _messageId != null;

  // "chat_id" field.
  int? _chatId;
  int get chatId => _chatId ?? 0;
  set chatId(int? val) => _chatId = val;

  void incrementChatId(int amount) => chatId = chatId + amount;

  bool hasChatId() => _chatId != null;

  // "user_id" field.
  String? _userId;
  String get userId => _userId ?? '';
  set userId(String? val) => _userId = val;

  bool hasUserId() => _userId != null;

  // "message" field.
  String? _message;
  String get message => _message ?? '';
  set message(String? val) => _message = val;

  bool hasMessage() => _message != null;

  // "isTyping" field.
  bool? _isTyping;
  bool get isTyping => _isTyping ?? false;
  set isTyping(bool? val) => _isTyping = val;

  bool hasIsTyping() => _isTyping != null;

  // "received" field.
  bool? _received;
  bool get received => _received ?? false;
  set received(bool? val) => _received = val;

  bool hasReceived() => _received != null;

  // "read" field.
  bool? _read;
  bool get read => _read ?? false;
  set read(bool? val) => _read = val;

  bool hasRead() => _read != null;

  static MessageTypeStruct fromMap(Map<String, dynamic> data) =>
      MessageTypeStruct(
        messageId: castToType<int>(data['message_id']),
        chatId: castToType<int>(data['chat_id']),
        userId: data['user_id'] as String?,
        message: data['message'] as String?,
        isTyping: data['isTyping'] as bool?,
        received: data['received'] as bool?,
        read: data['read'] as bool?,
      );

  static MessageTypeStruct? maybeFromMap(dynamic data) => data is Map
      ? MessageTypeStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'message_id': _messageId,
        'chat_id': _chatId,
        'user_id': _userId,
        'message': _message,
        'isTyping': _isTyping,
        'received': _received,
        'read': _read,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'message_id': serializeParam(
          _messageId,
          ParamType.int,
        ),
        'chat_id': serializeParam(
          _chatId,
          ParamType.int,
        ),
        'user_id': serializeParam(
          _userId,
          ParamType.String,
        ),
        'message': serializeParam(
          _message,
          ParamType.String,
        ),
        'isTyping': serializeParam(
          _isTyping,
          ParamType.bool,
        ),
        'received': serializeParam(
          _received,
          ParamType.bool,
        ),
        'read': serializeParam(
          _read,
          ParamType.bool,
        ),
      }.withoutNulls;

  static MessageTypeStruct fromSerializableMap(Map<String, dynamic> data) =>
      MessageTypeStruct(
        messageId: deserializeParam(
          data['message_id'],
          ParamType.int,
          false,
        ),
        chatId: deserializeParam(
          data['chat_id'],
          ParamType.int,
          false,
        ),
        userId: deserializeParam(
          data['user_id'],
          ParamType.String,
          false,
        ),
        message: deserializeParam(
          data['message'],
          ParamType.String,
          false,
        ),
        isTyping: deserializeParam(
          data['isTyping'],
          ParamType.bool,
          false,
        ),
        received: deserializeParam(
          data['received'],
          ParamType.bool,
          false,
        ),
        read: deserializeParam(
          data['read'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'MessageTypeStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is MessageTypeStruct &&
        messageId == other.messageId &&
        chatId == other.chatId &&
        userId == other.userId &&
        message == other.message &&
        isTyping == other.isTyping &&
        received == other.received &&
        read == other.read;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([messageId, chatId, userId, message, isTyping, received, read]);
}

MessageTypeStruct createMessageTypeStruct({
  int? messageId,
  int? chatId,
  String? userId,
  String? message,
  bool? isTyping,
  bool? received,
  bool? read,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    MessageTypeStruct(
      messageId: messageId,
      chatId: chatId,
      userId: userId,
      message: message,
      isTyping: isTyping,
      received: received,
      read: read,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

MessageTypeStruct? updateMessageTypeStruct(
  MessageTypeStruct? messageType, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    messageType
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addMessageTypeStructData(
  Map<String, dynamic> firestoreData,
  MessageTypeStruct? messageType,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (messageType == null) {
    return;
  }
  if (messageType.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && messageType.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final messageTypeData =
      getMessageTypeFirestoreData(messageType, forFieldValue);
  final nestedData =
      messageTypeData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = messageType.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getMessageTypeFirestoreData(
  MessageTypeStruct? messageType, [
  bool forFieldValue = false,
]) {
  if (messageType == null) {
    return {};
  }
  final firestoreData = mapToFirestore(messageType.toMap());

  // Add any Firestore field values
  messageType.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getMessageTypeListFirestoreData(
  List<MessageTypeStruct>? messageTypes,
) =>
    messageTypes?.map((e) => getMessageTypeFirestoreData(e, true)).toList() ??
    [];
