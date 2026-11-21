import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

const _apiHost = 'cantine-vatel.duckdns.org';
// Certains réseaux/DNS bloquent duckdns : on se connecte alors à l'IP du serveur
// en gardant le TLS (SNI + vérification du certificat) au nom du domaine.
const _fallbackIp = '13.51.65.68';

Future<bool> _dnsWorks(String host) async {
  try {
    final addrs = await InternetAddress.lookup(host).timeout(const Duration(seconds: 4));
    return addrs.isNotEmpty && !addrs.first.isLoopback && addrs.first.address != '0.0.0.0';
  } catch (_) {
    return false;
  }
}

Future<ConnectionTask<Socket>> _connect(Uri uri, String? proxyHost, int? proxyPort) async {
  final host = uri.host;
  final port = uri.port;
  final secure = uri.scheme == 'https';

  if (host != _apiHost || await _dnsWorks(host)) {
    return secure ? SecureSocket.startConnect(host, port) : Socket.startConnect(host, port);
  }

  final task = await Socket.startConnect(_fallbackIp, port);
  if (!secure) return task;
  final secured = task.socket.then((raw) => SecureSocket.secure(raw, host: host));
  return ConnectionTask.fromSocket(secured, task.cancel);
}

void configureDnsFallback(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () => HttpClient()..connectionFactory = _connect,
  );
}
