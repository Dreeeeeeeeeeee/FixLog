import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sends transactional emails via EmailJS (https://www.emailjs.com) directly
/// from the app — no Firebase Cloud Functions or Blaze plan required.
///
/// Fill in the three values below from your EmailJS dashboard:
/// - serviceId: Email Services → your connected Gmail service's Service ID
/// - templateId: Email Templates → the template you created → its Template ID
/// - publicKey: Account → API Keys → Public Key
class EmailService {
  EmailService._();
  static final EmailService instance = EmailService._();

  // TODO: replace templateId and publicKey with your own from EmailJS.
  static const String _serviceId = 'service_1cas9wa';
  static const String _templateId = 'template_sqj9e84';
  static const String _publicKey = 'fM3CQC_wM5gKcwY4I';

  static const _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Sends a repair status-update email. Returns true if EmailJS accepted
  /// the request (status 200), false otherwise. Never throws — callers
  /// can check the return value if they want to show an error, but a
  /// failed email should never block the actual status update.
  Future<bool> sendStatusUpdateEmail({
    required String toEmail,
    required String customerName,
    required String repairId,
    required String deviceName,
    required String statusLabel,
    String? note,
  }) async {
    if (_templateId == 'YOUR_TEMPLATE_ID' || _publicKey == 'YOUR_PUBLIC_KEY') {
      // Not configured yet — skip silently rather than spam errors.
      debugPrint('[EmailService] Skipped: templateId/publicKey not configured yet.');
      return false;
    }

    debugPrint('[EmailService] Sending status-update email to $toEmail for $repairId...');

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'service_id': _serviceId,
              'template_id': _templateId,
              'user_id': _publicKey,
              'template_params': {
                'to_email': toEmail,
                'to_name': customerName,
                'repair_id': repairId,
                'device_name': deviceName,
                'status': statusLabel,
                'note': (note != null && note.trim().isNotEmpty)
                    ? 'Note from the technician: ${note.trim()}'
                    : '',
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('[EmailService] Sent successfully.');
        return true;
      } else {
        debugPrint(
            '[EmailService] EmailJS rejected the request — status ${response.statusCode}: ${response.body}');
        return false;
      }
    } on TimeoutException {
      debugPrint('[EmailService] Timed out after 15s — device likely has no internet access.');
      return false;
    } catch (e) {
      debugPrint('[EmailService] Failed to send — $e');
      return false;
    }
  }
}