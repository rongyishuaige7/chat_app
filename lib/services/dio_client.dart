import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;
  static String? _deviceId;

  factory DioClient() => _instance;

  DioClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://47.99.163.144:3000/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ));

    // 添加拦截器
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final deviceId = await getDeviceId();
        // GET 请求用 query 参数
        if (options.method == 'GET') {
          options.queryParameters['device_id'] = deviceId;
        }
        // POST/PUT 请求用 body
        if (options.method == 'POST' || options.method == 'PUT') {
          options.data = options.data ?? {};
          if (options.data is Map) {
            options.data['device_id'] = deviceId;
          }
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // 在这里可以进行全局错误统计或日志打印
        print('API Error [${e.response?.statusCode}]: ${e.message}');
        return handler.next(e);
      },
    ));

    // 可以添加日志拦截器 (开发模式)
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  static Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id');
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString('device_id', _deviceId!);
    }
    return _deviceId!;
  }
}
