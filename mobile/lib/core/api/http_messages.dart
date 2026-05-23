import 'package:study_time_tracker/core/api/api_error_response.dart';

APIErrorResponse httpNoConnectionError() {
  return APIErrorResponse(message: 'No connection to server', statusCode: 503);
}
