// lib/services/email_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // FIX: Import dotenv
import 'logger_service.dart';

// A central service for handling all email communications via the Resend API.
class EmailService {
  final LoggerService _logger = LoggerService.instance;

  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // --- FIX: Use Resend configuration and load key from environment ---
  static final String? _apiKey = dotenv.env['RESEND_API_KEY'];
  static const String _apiUrl = 'https://api.resend.com/emails';

  // The "from" email must be on a domain you have verified in Resend.
  static const String _senderEmail = "SpareWo Garage <garage@sparewo.ug>";

  /// Sends a verification email with a code using Resend.
  Future<bool> sendVerificationEmail({
    required String to,
    required String code,
    required bool isVendor,
  }) async {
    final String subject = isVendor
        ? 'Verify your SpareWo Vendor Account'
        : 'Verify your SpareWo Account';

    // FIX: Your original HTML content is preserved exactly as requested.
    final String htmlContent = '''
      <div style="font-family: 'Poppins', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; border-radius: 8px; border: 1px solid #eaeaea; box-shadow: 0 2px 10px rgba(0,0,0,0.08);">
        <div style="text-align: center; margin-bottom: 30px;">
          <div style="background-color: #1A1B4B; color: white; padding: 15px; border-radius: 4px;">
            <h1 style="margin: 0; color: white; font-size: 24px;">SpareWo</h1>
          </div>
        </div>
        
        <h2 style="color: #1A1B4B; font-size: 24px; margin-bottom: 20px; text-align: center;">Verify Your Email Address</h2>
        
        <p style="color: #333; font-size: 16px; line-height: 1.5; margin-bottom: 25px;">
          Thank you for registering with SpareWo! Please use the verification code below to complete your registration:
        </p>
        
        <div style="background-color: #f7f9fc; padding: 15px; border-radius: 6px; text-align: center; margin: 25px 0;">
          <span style="font-family: 'Courier New', monospace; font-weight: bold; font-size: 28px; letter-spacing: 5px; color: #FF9800;">$code</span>
        </div>
        
        <p style="color: #666; font-size: 14px;">
          This code will expire in 30 minutes. If you did not request this verification, please ignore this email.
        </p>
        
        <div style="background-color: #1A1B4B; color: white; text-align: center; padding: 15px; border-radius: 6px; margin: 30px 0;">
          <p style="margin: 0; font-size: 16px;">Need help? Contact our support team:</p>
          <p style="margin: 5px 0 0; font-size: 16px;">
            <a href="mailto:garage@sparewo.ug" style="color: #FF9800; text-decoration: none;">garage@sparewo.ug</a> | 
            <a href="tel:+256773276096" style="color: #FF9800; text-decoration: none;">0773 276096</a>
          </p>
        </div>
        
        ${_createEmailFooter()}
      </div>
    ''';

    return _sendEmail(to: to, subject: subject, htmlContent: htmlContent);
  }

  /// Sends a welcome email to a new vendor.
  Future<bool> sendWelcomeEmail({
    required String to,
    String? vendorName,
  }) async {
    const String subject = 'Welcome to SpareWo Vendor Platform!';
    final String name = vendorName ?? 'Valued Vendor';

    // FIX: Your original HTML content is preserved exactly as requested.
    final String htmlContent = '''
      <div style="font-family: 'Poppins', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; border-radius: 8px; border: 1px solid #eaeaea; box-shadow: 0 2px 10px rgba(0,0,0,0.08);">
        <div style="text-align: center; margin-bottom: 30px;">
          <div style="background-color: #1A1B4B; color: white; padding: 15px; border-radius: 4px;">
            <h1 style="margin: 0; color: white; font-size: 24px;">SpareWo</h1>
          </div>
        </div>
        
        <h2 style="color: #1A1B4B; font-size: 28px; margin-bottom: 20px; text-align: center;">Welcome to SpareWo!</h2>
        
        <p style="color: #333; font-size: 16px; line-height: 1.5;">
          Hello $name,
        </p>
        
        <p style="color: #333; font-size: 16px; line-height: 1.5;">
          Thank you for joining SpareWo as a vendor! Your account has been successfully verified and you're now ready to start selling auto parts on our platform.
        </p>
        
        <div style="background-color: #f7f9fc; padding: 20px; border-radius: 6px; margin: 25px 0;">
          <h3 style="color: #1A1B4B; margin-top: 0; font-size: 18px;">Next Steps:</h3>
          <ul style="color: #555; padding-left: 20px;">
            <li style="margin-bottom: 10px;">Complete your store profile</li>
            <li style="margin-bottom: 10px;">Add your first products</li>
            <li style="margin-bottom: 10px;">Set up your payment information</li>
            <li>Customize your store appearance</li>
          </ul>
        </div>
        
        <div style="text-align: center; margin: 30px 0;">
          <a href="https://vendor.sparewo.ug/dashboard" style="background-color: #FF9800; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">Go to Vendor Dashboard</a>
        </div>
        
        <p style="color: #666; font-size: 14px; line-height: 1.5;">
          If you have any questions or need assistance, our support team is here to help you get started.
        </p>
        
        <div style="background-color: #1A1B4B; color: white; text-align: center; padding: 15px; border-radius: 6px; margin: 30px 0;">
          <p style="margin: 0; font-size: 16px;">Need help? Contact our support team:</p>
          <p style="margin: 5px 0 0; font-size: 16px;">
            <a href="mailto:garage@sparewo.ug" style="color: #FF9800; text-decoration: none;">garage@sparewo.ug</a> | 
            <a href="tel:+256773276096" style="color: #FF9800; text-decoration: none;">0773 276096</a>
          </p>
        </div>
        
        ${_createEmailFooter()}
      </div>
    ''';

    return _sendEmail(to: to, subject: subject, htmlContent: htmlContent);
  }

  /// The core function that sends the email via the Resend API.
  Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    // FIX: Check if the API key was loaded successfully.
    if (_apiKey == null || _apiKey!.isEmpty) {
      _logger.error('Resend API Key is not configured. Email not sent.');
      return false;
    }

    // FIX: Headers for Resend API.
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    // FIX: Body structure for Resend API.
    final body = json.encode({
      "from": _senderEmail,
      "to": [to.trim().toLowerCase()],
      "subject": subject,
      "html": htmlContent,
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: body,
      );

      // FIX: Resend API returns 200 OK on success.
      if (response.statusCode == 200) {
        _logger.info('Email sent successfully to $to via Resend');
        return true;
      } else {
        _logger.error(
          'Failed to send email via Resend. Status: ${response.statusCode}',
          error: response.body,
        );
        return false;
      }
    } catch (e) {
      _logger.error('HTTP error occurred while sending email via Resend',
          error: e);
      return false;
    }
  }

  /// Private helper to generate the common email footer.
  String _createEmailFooter() {
    return '''
      <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eaeaea; text-align: center;">
        <p style="color: #777777; font-size: 12px; text-align: center;">
          © ${DateTime.now().year} Sparewo. All rights reserved.<br>
          <a href="https://maps.google.com/?q=3rd+floor,+Grate+Magil+Building,+behind+Orxy,+35d+Bukoto+Kisasi+Rd,+Kampala" 
             style="color: #777777; text-decoration: underline;">
            3rd floor, Grate Magil Building, behind Orxy, 35d Bukoto Kisasi Rd, Kampala
          </a><br>
          Contact us: <a href="mailto:garage@sparewo.ug" style="color: #777777;">garage@sparewo.ug</a> |
          <a href="tel:+256773276096" style="color: #777777;">0773 276096</a>
        </p>
      </div>
    ''';
  }
}
