
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

interface EmailOptions {
  to: string;
  subject: string;
  html: string;
}

export async function sendEmail({ to, subject, html }: EmailOptions) {
  try {
    const { data, error } = await resend.emails.send({
      from: process.env.SENDER_EMAIL || 'SpareWo <onboarding@resend.dev>',
      to,
      subject,
      html,
    });

    if (error) {
      console.error('Resend Error:', error);
      throw error;
    }

    return { success: true, messageId: data?.id };
  } catch (error) {
    console.error('Error sending email:', error);
    throw error;
  }
}

function getEmailWrapper(title: string, content: string) {
  const year = new Date().getFullYear();
  return `
    <div style="font-family: 'Poppins', Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; border-radius: 8px; border: 1px solid #eaeaea; box-shadow: 0 2px 10px rgba(0,0,0,0.08); background-color: #ffffff;">
      <div style="text-align: center; margin-bottom: 30px;">
        <div style="background-color: #1A1B4B; color: white; padding: 20px; border-radius: 8px 8px 4px 4px;">
          <h1 style="margin: 0; color: white; font-size: 28px; letter-spacing: 1px;">SpareWo</h1>
          <p style="margin: 5px 0 0; font-size: 12px; opacity: 0.8; text-transform: uppercase; letter-spacing: 2px;">Admin Portal</p>
        </div>
      </div>

      <h2 style="color: #1A1B4B; font-size: 24px; margin-bottom: 20px; text-align: center;">${title}</h2>

      <div style="color: #333333; font-size: 16px; line-height: 1.6;">
        ${content}
      </div>

      <div style="background-color: #1A1B4B; color: white; text-align: center; padding: 20px; border-radius: 8px; margin: 30px 0;">
        <p style="margin: 0; font-size: 14px; opacity: 0.9;">Need technical assistance?</p>
        <p style="margin: 8px 0 0; font-size: 16px;">
          <a href="mailto:garage@sparewo.ug" style="color: #FF9800; text-decoration: none; font-weight: 600;">garage@sparewo.ug</a>
        </p>
      </div>

      <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eaeaea; text-align: center;">
        <p style="color: #777777; font-size: 12px; line-height: 1.5;">
          © ${year} SpareWo. All rights reserved.<br>
          <a href="https://maps.google.com/?q=3rd+floor,+Grate+Magil+Building,+behind+Oryx,+35d+Bukoto+Kisasi+Rd,+Kampala"
             style="color: #777777; text-decoration: underline;">
            3rd floor, Grate Magil Building, Bukoto Kisasi Rd, Kampala
          </a>
        </p>
      </div>
    </div>
  `;
}

export function getInviteEmailHtml(name: string, link: string) {
  const content = `
    <p>Hello <strong>${name}</strong>,</p>
    <p>You have been invited to join the <strong>SpareWo Admin Dashboard</strong> team. This portal allows you to manage operations, orders, and staff permissions.</p>
    <p>To activate your administrator account, please set up your secure password by clicking the button below:</p>
    
    <div style="text-align: center; margin: 40px 0;">
      <a href="${link}" style="background-color: #FF9800; color: white; padding: 16px 36px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px; display: inline-block; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">Set Up Admin Account</a>
    </div>
    
    <p style="font-size: 14px; color: #666666;">If you did not expect this invitation, please contact your system administrator.</p>
  `;
  return getEmailWrapper("Welcome to the Team", content);
}

export function getResetPasswordEmailHtml(name: string, link: string) {
  const content = `
    <p>Hello <strong>${name}</strong>,</p>
    <p>We received a request to reset your password for the SpareWo Admin Dashboard.</p>
    <p>If you made this request, click the button below to choose a new secure password:</p>
    
    <div style="text-align: center; margin: 40px 0;">
      <a href="${link}" style="background-color: #1A1B4B; color: white; padding: 16px 36px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px; display: inline-block; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">Reset My Password</a>
    </div>
    
    <p style="font-size: 14px; color: #666666;">If you didn't request a password reset, you can safely ignore this email. Your password will remain unchanged.</p>
  `;
  return getEmailWrapper("Password Reset Request", content);
}

export function getProductApprovedEmailHtml(vendorName: string, productName: string) {
  const content = `
    <p>Hello <strong>${vendorName}</strong>,</p>
    <p>Your product submission for <strong>${productName}</strong> has been approved by the SpareWo team.</p>
    <p>It is now active in the SpareWo catalog and available for client discovery.</p>
    <div style="margin: 24px 0; padding: 14px 16px; border-radius: 8px; background: #f8fafc; border: 1px solid #e2e8f0;">
      <p style="margin: 0; color: #334155; font-size: 14px;"><strong>Next step:</strong> Keep your product stock and pricing up to date so clients always see accurate listings.</p>
    </div>
  `;

  return getEmailWrapper("Product Approved", content);
}

export function getAutoHubApprovedEmailHtml(customerName: string, bookingNumber: string) {
  const content = `
    <p>Hello <strong>${customerName}</strong>,</p>
    <p>Your AutoHub request <strong>${bookingNumber}</strong> has been approved and is now being processed.</p>
    <p>Our team will reach out shortly with the next steps, including service coordination details.</p>
    <div style="margin: 24px 0; padding: 14px 16px; border-radius: 8px; background: #f8fafc; border: 1px solid #e2e8f0;">
      <p style="margin: 0; color: #334155; font-size: 14px;">If you need immediate assistance, reply to this email and our operations team will help you.</p>
    </div>
  `;

  return getEmailWrapper("AutoHub Request Approved", content);
}

export function getAutoHubStatusEmailHtml(
  customerName: string,
  bookingNumber: string,
  status: 'confirmed' | 'in_progress' | 'completed' | 'cancelled'
) {
  const titleMap = {
    confirmed: 'AutoHub Request Confirmed',
    in_progress: 'AutoHub Service In Progress',
    completed: 'AutoHub Service Completed',
    cancelled: 'AutoHub Request Cancelled',
  } as const;

  const messageMap = {
    confirmed: 'Your AutoHub request has been confirmed. Our team will contact you shortly with coordination details.',
    in_progress: 'Your AutoHub request is currently being worked on by our team.',
    completed: 'Your AutoHub request has been completed. Thank you for choosing SpareWo.',
    cancelled: 'Your AutoHub request has been cancelled. If this is unexpected, please contact support.',
  } as const;

  const content = `
    <p>Hello <strong>${customerName}</strong>,</p>
    <p>${messageMap[status]}</p>
    <div style="margin: 24px 0; padding: 14px 16px; border-radius: 8px; background: #f8fafc; border: 1px solid #e2e8f0;">
      <p style="margin: 0; color: #334155; font-size: 14px;">
        <strong>Booking reference:</strong> ${bookingNumber}<br>
        <strong>Current status:</strong> ${status.replace('_', ' ')}
      </p>
    </div>
    <p style="font-size: 14px; color: #475569;">Open the SpareWo app to view full booking details and progress updates.</p>
  `;

  return getEmailWrapper(titleMap[status], content);
}
