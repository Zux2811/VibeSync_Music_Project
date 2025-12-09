import nodemailer from "nodemailer";

/**
 * Creates and configures a Nodemailer transport object.
 * @returns {import('nodemailer').Transporter}
 * @throws {Error} If SMTP environment variables are not set.
 */
export const getMailer = () => {
  const host = process.env.SMTP_HOST;
  const port = parseInt(process.env.SMTP_PORT || '587', 10);
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const secure = (process.env.SMTP_SECURE === 'true') || (process.env.SMTP_PORT === '465');

  if (!host || !user || !pass) {
    throw new Error('SMTP is not configured. Please set SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS in your .env file');
  }

  return nodemailer.createTransport({ 
    host, 
    port, 
    secure, 
    auth: { user, pass } 
  });
};

