
import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
    },
});

interface EmailOptions {
    to: string;
    subject: string;
    html: string;
}

export async function sendEmail({ to, subject, html }: EmailOptions) {
    try {
        const info = await transporter.sendMail({
            from: process.env.SMTP_FROM || process.env.SMTP_USER,
            to,
            subject,
            html,
        });
        console.log('Email sent: %s', info.messageId);
        return { success: true, messageId: info.messageId };
    } catch (error) {
        console.error('Error sending email:', error);
        throw error;
    }
}

export function getInviteEmailHtml(name: string, link: string) {
    return `
    <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e5e7eb; border-radius: 12px;">
      <div style="text-align: center; margin-bottom: 24px;">
        <h1 style="color: #3b82f6; margin: 0;">Welcome to SpareWo</h1>
      </div>
      <p>Hello ${name},</p>
      <p>You have been invited to join the SpareWo Admin Dashboard as a team member. To get started, please set up your password by clicking the button below:</p>
      <div style="text-align: center; margin: 32px 0;">
        <a href="${link}" style="background-color: #3b82f6; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: bold; display: inline-block;">Set Up My Account</a>
      </div>
      <p style="color: #6b7280; font-size: 14px;">If the button doesn't work, copy and paste this link into your browser:</p>
      <p style="color: #3b82f6; font-size: 12px; word-break: break-all;">${link}</p>
      <hr style="border: 0; border-top: 1px solid #e5e7eb; margin: 24px 0;" />
      <p style="color: #9ca3af; font-size: 12px; text-align: center;">&copy; ${new Date().getFullYear()} SpareWo. All rights reserved.</p>
    </div>
  `;
}

export function getResetPasswordEmailHtml(name: string, link: string) {
    return `
    <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e5e7eb; border-radius: 12px;">
      <div style="text-align: center; margin-bottom: 24px;">
        <h1 style="color: #3b82f6; margin: 0;">Password Reset</h1>
      </div>
      <p>Hello ${name},</p>
      <p>We received a request to reset your SpareWo password. Click the button below to choose a new one:</p>
      <div style="text-align: center; margin: 32px 0;">
        <a href="${link}" style="background-color: #3b82f6; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: bold; display: inline-block;">Reset Password</a>
      </div>
      <p style="color: #6b7280; font-size: 14px;">If you didn't request a password reset, you can safely ignore this email.</p>
      <p style="color: #6b7280; font-size: 14px;">If the button doesn't work, copy and paste this link into your browser:</p>
      <p style="color: #3b82f6; font-size: 12px; word-break: break-all;">${link}</p>
      <hr style="border: 0; border-top: 1px solid #e5e7eb; margin: 24px 0;" />
      <p style="color: #9ca3af; font-size: 12px; text-align: center;">&copy; ${new Date().getFullYear()} SpareWo. All rights reserved.</p>
    </div>
  `;
}
