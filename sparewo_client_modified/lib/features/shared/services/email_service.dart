// lib/features/shared/services/email_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sparewo_client/core/logging/app_logger.dart';

/// Central service for handling all email communications via the Resend API
/// for the SpareWo client app.
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  static const String _apiUrl = 'https://api.resend.com/emails';
  String? _lastFailureReason;

  String? get lastFailureReason => _lastFailureReason;

  // The "from" email must be on a domain verified in Resend
  static const String _senderEmail = "SpareWo <garage@sparewo.ug>";

  /// Sends a verification email with a 6-digit code
  Future<bool> sendVerificationEmail({
    required String to,
    required String code,
    String? customerName,
  }) async {
    final String subject = 'Verify your SpareWo Account - Code: $code';
    final String name = customerName ?? 'Valued Customer';

    final String htmlContent =
        '''
      <div style="font-family: 'Poppins', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; border-radius: 8px; border: 1px solid #eaeaea; box-shadow: 0 2px 10px rgba(0,0,0,0.08);">
        <div style="text-align: center; margin-bottom: 30px;">
          <div style="background-color: #1A1B4B; color: white; padding: 15px; border-radius: 4px;">
            <h1 style="margin: 0; color: white; font-size: 24px;">SpareWo</h1>
          </div>
        </div>

        <h2 style="color: #1A1B4B; font-size: 24px; margin-bottom: 20px; text-align: center;">Verify Your Email</h2>

        <p style="color: #333; font-size: 16px; line-height: 1.5;">
          Hi $name,
        </p>

        <p style="color: #333; font-size: 16px; line-height: 1.5;">
          Welcome to SpareWo! Please use the verification code below to complete your registration:
        </p>

        <div style="background-color: #f7f9fc; padding: 20px; border-radius: 6px; text-align: center; margin: 25px 0;">
          <span style="font-family: 'Courier New', monospace; font-weight: bold; font-size: 32px; letter-spacing: 8px; color: #FF9800;">$code</span>
        </div>

        <p style="color: #666; font-size: 14px; text-align: center;">
          This code will expire in 30 minutes. If you didn't request this verification, please ignore this email.
        </p>

        <div style="background-color: #FFF3E0; padding: 15px; border-radius: 6px; margin: 25px 0;">
          <p style="margin: 0; color: #F57C00;">
            <strong>Tip:</strong> Copy this code and it will automatically paste in the app!
          </p>
        </div>

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

    return _sendEmail(
      recipients: [to],
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Sends order confirmation email to customer
  Future<bool> sendOrderConfirmation({
    required String to,
    required String orderNumber,
    required String customerName,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryDate,
  }) async {
    final String subject = 'Order Confirmation - #$orderNumber';

    // Build items HTML
    final itemsHtml = items
        .map(
          (item) =>
              '''
      <tr>
        <td style="padding: 12px; border-bottom: 1px solid #eaeaea;">
          ${item['name']}
        </td>
        <td style="padding: 12px; border-bottom: 1px solid #eaeaea; text-align: center;">
          ${item['quantity']}
        </td>
        <td style="padding: 12px; border-bottom: 1px solid #eaeaea; text-align: right;">
          UGX ${_formatCurrency(item['price'])}
        </td>
      </tr>
    ''',
        )
        .join('');

    final String htmlContent =
        '''
      <div style="font-family: 'Poppins', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; border-radius: 8px; border: 1px solid #eaeaea; box-shadow: 0 2px 10px rgba(0,0,0,0.08);">
        <div style="text-align: center; margin-bottom: 30px;">
          <div style="background-color: #1A1B4B; color: white; padding: 15px; border-radius: 4px;">
            <h1 style="margin: 0; color: white; font-size: 24px;">SpareWo</h1>
          </div>
        </div>

        <h2 style="color: #1A1B4B; font-size: 24px; margin-bottom: 20px; text-align: center;">Order Confirmed!</h2>

        <p style="color: #333; font-size: 16px; line-height: 1.5;">
          Hello $customerName,
        </p>

        <p style="color: #333; font-size: 16px; line-height: 1.5;">
          Thank you for your order! We're pleased to confirm that we've received your order and it's being processed.
        </p>

        <div style="background-color: #f7f9fc; padding: 20px; border-radius: 6px; margin: 25px 0;">
          <h3 style="color: #1A1B4B; margin-top: 0; font-size: 18px;">Order Details</h3>
          <p style="margin: 5px 0;"><strong>Order Number:</strong> #$orderNumber</p>
          <p style="margin: 5px 0;"><strong>Estimated Delivery:</strong> $deliveryDate</p>
        </div>

        <table style="width: 100%; border-collapse: collapse; margin: 25px 0;">
          <thead>
            <tr style="background-color: #f7f9fc;">
              <th style="padding: 12px; text-align: left; font-weight: 600;">Item</th>
              <th style="padding: 12px; text-align: center; font-weight: 600;">Qty</th>
              <th style="padding: 12px; text-align: right; font-weight: 600;">Price</th>
            </tr>
          </thead>
          <tbody>
            $itemsHtml
          </tbody>
          <tfoot>
            <tr>
              <td colspan="2" style="padding: 12px; text-align: right; font-weight: 600;">Total:</td>
              <td style="padding: 12px; text-align: right; font-weight: 600; color: #FF9800; font-size: 18px;">
                UGX ${_formatCurrency(totalAmount)}
              </td>
            </tr>
          </tfoot>
        </table>

        <div style="background-color: #FFF3E0; padding: 15px; border-radius: 6px; margin: 25px 0;">
          <p style="margin: 0; color: #F57C00;">
            <strong>Next Steps:</strong> Our team will contact you within 24 hours to confirm delivery details and installation schedule.
          </p>
        </div>

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

    return _sendEmail(
      recipients: [to],
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Sends service booking confirmation email
  Future<bool> sendServiceBookingConfirmation({
    required String to,
    required String customerName,
    required String bookingNumber,
    required List<String> services,
    required String carDetails,
    required String dateTime,
    required String location,
    String? notes,
  }) async {
    final String subject = 'Service Booking Confirmed - #$bookingNumber';
    final String servicesHtml = services.map((s) => "• $s").join("<br>");

    final String htmlContent =
        '''
      <div style="font-family: 'Poppins', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; border-radius: 8px; border: 1px solid #eaeaea; box-shadow: 0 2px 10px rgba(0,0,0,0.08);">
        <div style="text-align: center; margin-bottom: 30px;">
          <div style="background-color: #1A1B4B; color: white; padding: 15px; border-radius: 4px;">
            <h1 style="margin: 0; color: white; font-size: 24px;">SpareWo AutoHub</h1>
          </div>
        </div>

        <h2 style="color: #1A1B4B; font-size: 24px; margin-bottom: 20px; text-align: center;">Service Booking Confirmed!</h2>

        <p style="color: #333; font-size: 16px; line-height: 1.5;">
          Hello $customerName,
        </p>

        <p style="color: #333; font-size: 16px; line-height: 1.5;">
          Your service appointment has been successfully booked. Our team is ready to take care of your vehicle.
        </p>

        <div style="background-color: #f7f9fc; padding: 20px; border-radius: 6px; margin: 25px 0;">
          <h3 style="color: #1A1B4B; margin-top: 0; font-size: 18px;">Booking Details</h3>
          <table style="width: 100%;">
            <tr>
              <td style="padding: 8px 0; color: #666;">Booking Number:</td>
              <td style="padding: 8px 0; font-weight: 600;">#$bookingNumber</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #666; vertical-align: top;">Services:</td>
              <td style="padding: 8px 0; font-weight: 600;">$servicesHtml</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #666;">Vehicle:</td>
              <td style="padding: 8px 0; font-weight: 600;">$carDetails</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #666;">Date & Time:</td>
              <td style="padding: 8px 0; font-weight: 600;">$dateTime</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #666;">Location:</td>
              <td style="padding: 8px 0; font-weight: 600;">$location</td>
            </tr>
            ${notes != null && notes.isNotEmpty ? '''
            <tr>
              <td style="padding: 8px 0; color: #666; vertical-align: top;">Notes:</td>
              <td style="padding: 8px 0;">$notes</td>
            </tr>
            ''' : ''}
          </table>
        </div>

        <div style="background-color: #E8F5E9; padding: 15px; border-radius: 6px; margin: 25px 0;">
          <p style="margin: 0; color: #2E7D32;">
            <strong>What to expect:</strong> Our technician will arrive at the scheduled time. Please ensure your vehicle is accessible and someone is available to hand over the keys.
          </p>
        </div>

        <div style="text-align: center; margin: 30px 0;">
          <p style="color: #666; font-size: 14px;">
            Need to reschedule? Call us at least 2 hours before your appointment.
          </p>
        </div>

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

    return _sendEmail(
      recipients: [to],
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Sends a copy of the booking details to admins
  Future<bool> sendServiceBookingAdminCopy({
    required String bookingNumber,
    required List<String> services,
    required String carDetails,
    required String dateTime,
    required String location,
    required String customerEmail,
    required String customerName,
    String? notes,
  }) async {
    final to = ["admin@sparewo.ug", "garage@sparewo.ug"];
    final subject = "New AutoHub Booking - #$bookingNumber";
    final servicesHtml = services.map((s) => "• $s").join("<br>");

    final htmlContent =
        '''
     <div style="font-family: 'Poppins', Arial, sans-serif; max-width: 600px; margin: auto; padding: 30px;">
       <h2 style="color: #1A1B4B; text-align:center;">New Service Booking</h2>

       <p>A customer has submitted a service booking.</p>

       <h3>Customer Info</h3>
       <p><strong>Name:</strong> $customerName<br>
       <strong>Email:</strong> $customerEmail</p>

       <h3>Service Details</h3>
       <p><strong>Booking Number:</strong> #$bookingNumber<br>
       <strong>Services:</strong><br>$servicesHtml<br>
       <strong>Vehicle:</strong> $carDetails<br>
       <strong>Date & Time:</strong> $dateTime<br>
       <strong>Location:</strong> $location</p>

       ${notes != null && notes.isNotEmpty ? "<p><strong>Notes:</strong> $notes</p>" : ""}

       ${_createEmailFooter()}
     </div>
  ''';

    return _sendEmail(
      recipients: to,
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Sends welcome email to new customers
  Future<bool> sendWelcomeEmail({
    required String to,
    required String customerName,
  }) async {
    const String subject = 'Welcome to SpareWo!';

    final String htmlContent =
        '''
      <div style="font-family: 'Poppins', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; border-radius: 8px; border: 1px solid #eaeaea; box-shadow: 0 2px 10px rgba(0,0,0,0.08);">
        <div style="text-align: center; margin-bottom: 30px;">
          <div style="background-color: #1A1B4B; color: white; padding: 15px; border-radius: 4px;">
            <h1 style="margin: 0; color: white; font-size: 24px;">SpareWo</h1>
          </div>
        </div>

        <h2 style="color: #1A1B4B; font-size: 28px; margin-bottom: 20px; text-align: center;">Welcome to SpareWo!</h2>

        <p style="color: #333; font-size: 16px; line-height: 1.5;">
          Hello $customerName,
        </p>

        <p style="color: #333; font-size: 16px; line-height: 1.5;">
          Welcome to SpareWo - your trusted partner for genuine auto parts and professional car services in Uganda!
        </p>

        <div style="background-color: #f7f9fc; padding: 20px; border-radius: 6px; margin: 25px 0;">
          <h3 style="color: #1A1B4B; margin-top: 0; font-size: 18px;">What you can do with SpareWo:</h3>
          <ul style="color: #555; padding-left: 20px;">
            <li style="margin-bottom: 10px;">Browse genuine auto parts from verified suppliers</li>
            <li style="margin-bottom: 10px;">Book professional car services at your convenience</li>
            <li style="margin-bottom: 10px;">Get doorstep delivery and installation</li>
            <li style="margin-bottom: 10px;">Track your orders in real-time</li>
            <li>Access exclusive deals and offers</li>
          </ul>
        </div>

        <div style="text-align: center; margin: 30px 0;">
          <a href="https://sparewo.ug/catalog" style="background-color: #FF9800; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">Browse Parts</a>
        </div>

        <div style="background-color: #FFF3E0; padding: 15px; border-radius: 6px; margin: 25px 0;">
          <p style="margin: 0; color: #F57C00;">
            <strong>Special Offer:</strong> Get 10% off your first order! Use code WELCOME10 at checkout.
          </p>
        </div>

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

    return _sendEmail(
      recipients: [to],
      subject: subject,
      htmlContent: htmlContent,
    );
  }

  /// Core function that sends the email via the Resend API
  Future<bool> _sendEmail({
    required List<String> recipients,
    required String subject,
    required String htmlContent,
  }) async {
    _lastFailureReason = null;
    final apiKey = _readApiKey();

    // Check if the API key was loaded successfully
    if (apiKey == null || apiKey.isEmpty) {
      _lastFailureReason = 'missing_api_key';
      AppLogger.warn(
        'EmailService',
        'Resend API key is not configured or dotenv is not initialized. Email not sent.',
      );
      return false;
    }

    // Headers for Resend API
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    // Body structure for Resend API
    final body = json.encode({
      "from": _senderEmail,
      "to": recipients.map((e) => e.trim().toLowerCase()).toList(),
      "subject": subject,
      "html": htmlContent,
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: body,
      );

      // Resend API returns 200 OK on success
      if (response.statusCode == 200) {
        _lastFailureReason = null;
        AppLogger.info(
          'EmailService',
          'Email sent successfully via Resend',
          extra: {'recipients': recipients},
        );
        return true;
      } else {
        if (response.statusCode == 401 || response.statusCode == 403) {
          _lastFailureReason = 'invalid_api_key';
        } else if (response.statusCode == 429) {
          _lastFailureReason = 'rate_limited';
        } else {
          _lastFailureReason = 'provider_error';
        }
        AppLogger.warn(
          'EmailService',
          'Failed to send email via Resend',
          extra: {
            'statusCode': response.statusCode,
            'response': response.body,
            'recipients': recipients,
          },
        );
        return false;
      }
    } catch (e) {
      _lastFailureReason = 'network_error';
      AppLogger.error(
        'EmailService',
        'HTTP error while sending email via Resend',
        error: e,
        extra: {'recipients': recipients},
      );
      return false;
    }
  }

  String? _readApiKey() {
    try {
      return dotenv.env['RESEND_API_KEY'];
    } catch (_) {
      return null;
    }
  }

  /// Private helper to generate the common email footer
  String _createEmailFooter() {
    return '''
      <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eaeaea; text-align: center;">
        <p style="color: #777777; font-size: 12px; text-align: center;">
          © ${DateTime.now().year} SpareWo. All rights reserved.<br>
          <a href="https://maps.google.com/?q=3rd+floor,+Grate+Magil+Building,+behind+Oryx,+35d+Bukoto+Kisasi+Rd,+Kampala"
             style="color: #777777; text-decoration: underline;">
            3rd floor, Grate Magil Building, behind Oryx, 35d Bukoto Kisasi Rd, Kampala
          </a><br>
          Contact us: <a href="mailto:garage@sparewo.ug" style="color: #777777;">garage@sparewo.ug</a> |
          <a href="tel:+256773276096" style="color: #777777;">0773 276096</a>
        </p>
      </div>
    ''';
  }

  /// Helper function to format currency
  String _formatCurrency(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }
}
