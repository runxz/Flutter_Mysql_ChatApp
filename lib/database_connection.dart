import 'package:mysql1/mysql1.dart';

Future<MySqlConnection> getConnection() async {
  final settings = ConnectionSettings(
    host: 'sql12.freemysqlhosting.net',
    port: 3306,
    user: 'sql12657585',
    password: 'EGq7q1E5ir',
    db: 'sql12657585',
  );

  return await MySqlConnection.connect(settings);
}
