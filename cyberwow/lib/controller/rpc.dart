/*

Copyright 2019 fuwa

This file is part of CyberWOW.

CyberWOW is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

CyberWOW is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with CyberWOW.  If not, see <https://www.gnu.org/licenses/>.

*/

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../config.dart';

int rpcID = 0;

Future<http.Response> rpc(String method) async {
  final url = 'http://127.0.0.1:${config.port}/json_rpc';

  rpcID += 1;

  final body = json.encode
  (
    {
      'jsonrpc': '2.0',
      'id': rpcID.toString(),
      'method': method,
    }
  );

  var response;
  try {
    response = await http.post
    ( url,
      body: body
    );
  }
  catch (e) {
    // print(e);
  }

  return response;
}

Future<String> rpcString(String method, {String field}) async {
  var response = await rpc(method);

  if (response == null) return '';

  if (response.statusCode != 200) {
    return '';
  } else {
    final _result = json.decode(response.body)['result'];
    final _field = field == null ? _result : _result[field];

    final JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    return encoder.convert(_field);
  }
}

Future<http.Response> rpcOther(String method) async {
  final url = 'http://127.0.0.1:${config.port}/json_rpc';

  var response;
  try {
    response = await http.post
    ( url,
    );
  }
  catch (e) {
    // print(e);
  }

  return response;
}

Future<String> rpcOtherString(String method, {String field}) async {
  var response = await rpcOther(method);

  if (response == null) return '';

  if (response.statusCode != 200) {
    return '';
  } else {
    final _body= json.decode(response.body);
    final _field = field == null ? _body: _body[field];

    final JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    return encoder.convert(_field);
  }
}



Future<http.Response> syncInfo() async => rpc('sync_info');
Future<String> syncInfoString() async => rpcString('sync_info');

Future<int> targetHeight() async {
  var response = await syncInfo();

  if (response == null) return -1;

  // print('Response status: ${response.statusCode}');
  if (response.statusCode != 200) {
    return -1;
  } else {
    final responseBody = json.decode(response.body)['result'];
    return responseBody["target_height"];
  }
}

Future<int> height() async {
  var response = await syncInfo();

  if (response == null) return -1;

  // print('Response status: ${response.statusCode}');
  if (response.statusCode != 200) {
    return -1;
  } else {
    final responseBody = json.decode(response.body)['result'];
    return responseBody["height"];
  }
}


Future<http.Response> getInfo() async => rpc('get_info');
Future<String> getInfoString() async => rpcString('get_info');

Future<bool> offline() async {
  var response = await getInfo();

  if (response == null) return true;

  // print('Response status: ${response.statusCode}');
  if (response.statusCode != 200) {
    return true;
  } else {
    final responseBody = json.decode(response.body)['result'];
    return responseBody["offline"];
  }
}

Future<int> outgoingConnectionsCount() async {
  var response = await getInfo();

  if (response == null) return -1;

  // print('Response status: ${response.statusCode}');
  if (response.statusCode != 200) {
    return -1;
  } else {
    final responseBody = json.decode(response.body)['result'];
    return responseBody["outgoing_connections_count"];
  }
}

Future<int> incomingConnectionsCount() async {
  var response = await getInfo();

  if (response == null) return -1;

  // print('Response status: ${response.statusCode}');
  if (response.statusCode != 200) {
    return -1;
  } else {
    final responseBody = json.decode(response.body)['result'];
    return responseBody["incoming_connections_count"];
  }
}


// Future<http.Response> getInfo() async {
//   // print('rpc get_info');
//   return rpc('get_info');
// }


// Future<String> getInfoString() async {
//   var response = await getInfo();

//   if (response == null) return '';

//   if (response.statusCode != 200) {
//     return '';
//   } else {
//     final _getInfo = json.decode(response.body)['result'];

//     JsonEncoder encoder = new JsonEncoder.withIndent('  ');
//     String _prettyInfo = encoder.convert(_getInfo);
//     return _prettyInfo;
//   }
// }


Future<String> getConnectionsString() async => rpcString('get_connections', field: 'connections');
Future<String> getTransactionPoolString() async => rpcOtherString('get_transaction_pool');
