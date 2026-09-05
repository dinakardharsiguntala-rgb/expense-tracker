import 'package:flutter/services.dart';
import 'bank_sms_parser.dart';
import 'local_db_service.dart';

class SmsService {
  static const MethodChannel _channel = MethodChannel('com.expensetracker.app/sms');

  static final SmsService instance = SmsService._();
  SmsService._() {
    _channel.setMethodCallHandler(_handleNativeMethodCall);
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'onSmsReceived') {
      final Map<dynamic, dynamic> args = call.arguments;
      final String body = args['body'] as String? ?? '';
      final String sender = args['sender'] as String? ?? '';

      final parsed = BankSMSParser.instance.parse(body, sender: sender);
      if (parsed != null) {
        final tx = parsed.toExpenseTransaction();
        await LocalDatabaseService.instance.insertTransaction(tx);
      }
    }
  }

  Future<bool> hasPermissions() async {
    try {
      final bool? result = await _channel.invokeMethod('hasPermissions');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final bool? result = await _channel.invokeMethod('requestPermissions');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<int> scanAndImportHistoricalSms() async {
    try {
      final List<dynamic>? messages = await _channel.invokeMethod('getHistoricalSms');
      if (messages == null) return 0;

      int importedCount = 0;
      for (var item in messages) {
        if (item is Map) {
          final body = item['body'] as String? ?? '';
          final sender = item['sender'] as String? ?? '';
          final parsed = BankSMSParser.instance.parse(body, sender: sender);
          if (parsed != null) {
            final tx = parsed.toExpenseTransaction();
            await LocalDatabaseService.instance.insertTransaction(tx);
            importedCount++;
          }
        }
      }
      return importedCount;
    } catch (_) {
      return 0;
    }
  }
}

