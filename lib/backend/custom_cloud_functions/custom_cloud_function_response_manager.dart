import '/backend/schema/structs/index.dart';

class GenerateTokenCloudFunctionCallResponse {
  GenerateTokenCloudFunctionCallResponse({
    this.errorCode,
    this.succeeded,
    this.jsonBody,
  });
  String? errorCode;
  bool? succeeded;
  dynamic jsonBody;
}
