import 'dart:io';

abstract class ConnectionFailure {
  final String _message;
  const ConnectionFailure(this._message);

  String get message => this._message;

  static Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<ConnectionFailure> determineFailure(
      Exception ex, Uri hostport) async {
    final isConnectedWithInternet = await checkConnection();
    if (!isConnectedWithInternet) {
      return const NoInternetConnection();
    }
    final msg = ex.toString();
    if (msg.contains("Failed host lookup")) {
      return UnreachableHost(host: hostport.host);
    } else if (msg.contains("Connection refused")) {
      return InvalidPort(host: hostport.host, port: hostport.port);
    } else if (msg.contains("authorization failed")) {
      return const InvalidUserAndPasswordCombination();
    }
    return ServerError(message: msg);
  }
}

class NoInternetConnection extends ConnectionFailure {
  const NoInternetConnection()
      : super(
            'No internet connection. Check your network settings and try again.');
}

class UnreachableHost extends ConnectionFailure {
  const UnreachableHost({String host})
      : super("Destination host '$host' unreachable.");
}

class InvalidPort extends ConnectionFailure {
  const InvalidPort({String host, port})
      : super("Connect to host $host port $port: Connection refused");
}

class InvalidUserAndPasswordCombination extends ConnectionFailure {
  const InvalidUserAndPasswordCombination()
      : super('Invalid username or password.');
}

class ServerError extends ConnectionFailure {
  const ServerError({String message})
      : super("A server error occurred. Reported error message: $message");
}
