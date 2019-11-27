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
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../config.dart' as config;
import '../../helper.dart';
import '../../logging.dart';

Future<http.Response> rpc2(final String method) async {
  final url = 'http://${config.host}:${config.c.port}/${method}';

  try {
    final response = await http.post
    ( url,
    );
    return response;
  }
  catch (e) {
    log.warning(e);
    return null;
  }
}

dynamic jsonDecode(final String responseBody) => json.decode(responseBody);

Future<String> rpc2String(final String method, {final String field}) async {
  final response = await rpc2(method);

  if (response == null) return '';

  if (response.statusCode != 200) {
    return '';
  } else {
    final _body = await compute(jsonDecode, response.body);
    final _field = field == null ? _body: _body[field];

    return pretty(_field);
  }
}

Future<http.Response> getTransactionPool() async => rpc2('get_transaction_pool');

Future<List<dynamic>> getTransactionPoolSimple() async {
  final response = await getTransactionPool();

  if (response == null) return [];

  log.finest('getTransactionPoolSimple response: ${response.body}');
  log.finest('Response status: ${response.statusCode}');

  if (response.statusCode != 200) {
    return [];
  } else {
    final responseBody = json.decode(response.body);
    final result = responseBody['transactions'];
    if (result == null) {
      return [];
    }
    else {
      final _sortedPool = result..sort
      (
        (x, y) {
          final int a = x['receive_time'];
          final int b = y['receive_time'];
          return b.compareTo(a);
        }
      );
      return Stream.fromIterable(_sortedPool).asyncMap
      (
        (x) async {
          const _remove =
          [
            'tx_blob',
            // 'tx_json',
            'last_failed_id_hash',
            'max_used_block_id_hash',
            // fields not useful for noobs
            'last_relayed_time',
            'kept_by_block',
            'double_spend_seen',
            'relayed',
            'do_not_relay',
            'last_failed_height',
            'max_used_block_height',
            'weight',
            // 'blob_size',
          ];

          final _filteredTx = x..removeWhere
          (
            (k,v) => _remove.contains(k)
          );

          final String _tx_json = _filteredTx['tx_json'];
          final _tx_json_decoded = await compute(jsonDecode, _tx_json);

          final _decodedTx = {
            ..._filteredTx,
            ...{'tx_decoded': _tx_json_decoded},
          };

          final _tx = _decodedTx.map
          (
            (k, v) {
              if (k == 'id_hash') {
                return MapEntry('id', v.substring(0, config.hashLength) + '...');
              }

              else if (k == 'blob_size') {
                return MapEntry('size', (v / 1024).toStringAsFixed(2) + ' kB');
              }

              else if (k == 'fee') {
                final formatter = NumberFormat.currency
                (
                  symbol: '',
                  decimalDigits: 2,
                );
                return MapEntry(k, formatter.format(v / pow(10, 11)) + ' ⍵');
              }

              else if (k == 'receive_time') {
                final _dateTime = DateTime.fromMillisecondsSinceEpoch(v * 1000);
                final _dateFormat = DateFormat.yMd().add_jm() ;
                return MapEntry('time', _dateFormat.format(_dateTime));
              }

              else if (k == 'tx_decoded') {
                final _out =
                {
                  'vin': v['vin'].length,
                  'vout': v['vout'].length,
                };
                final _outString = _out['vin'].toString() + '/' + _out['vout'].toString();
                return MapEntry('in/out', _outString);
              }

              else {
                return MapEntry(k, v);
              }
            }
          );

          final List<String> keys =
          [
            'id',
            'time',
            'fee',
            'in/out',
            'size',
          ]
          .where((k) => _tx.keys.contains(k))
          .toList();

          final _sortedTx = {
            for (var k in keys) k: _tx[k]
          };

          return _sortedTx;
        }
      ).toList();
    }
  }
}
