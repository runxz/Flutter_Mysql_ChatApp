import 'package:mysql1/mysql1.dart';

Future<MySqlConnection> getConnection() async {
  final settings = ConnectionSettings(
    host: 'YOURHOST',
    port: 3306, //YOUR MYSQL PORT
    user: 'YOUR USERNAME',
    password: 'YOUR PASSWORD',
    db: 'YOUR DATABASE NAME',
  );

  return await MySqlConnection.connect(settings);
}
