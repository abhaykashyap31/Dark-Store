import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'api_response.dart';

ApiException mapDioError(DioException e, {required String fallback}) {
  final data = e.response?.data;
  final code = apiErrorCode(data);
  final message = apiErrorMessage(data) ?? e.message ?? fallback;
  return ApiException(
    message: message,
    statusCode: e.response?.statusCode,
    code: code,
  );
}
