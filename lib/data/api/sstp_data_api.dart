import 'package:dio/dio.dart';

class SstpDataApi {
  Future<dynamic> getAllHosts({
    void Function(int, int)? onReceiveProgress,
    required String authKey,
    required String deviceId,
    required int time,
  }) async {
    var response = await Dio().get(
      "https://dur-theta.vercel.app/api/sstps_2",
      queryParameters: {
        "key": authKey,
        "deviceId": deviceId,
        "time": time,
      },
      onReceiveProgress: onReceiveProgress,
    );

    return response.data;
  }
}
