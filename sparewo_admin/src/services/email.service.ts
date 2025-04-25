// src/services/email.service.ts
// This is a mock version that doesn't import Firebase Functions

interface EmailProps {
  to: string;
  subject?: string;
  templateId?: string;
  [key: string]: any;
}

interface GarageEmailProps {
  to: string;
  name: string;
  serviceType: string;
  appointmentDateTime: string;
  carMakeModel: string;
}

interface VendorApprovalEmailProps {
  to: string;
  vendorName: string;
  businessName: string;
}

interface ProductApprovalEmailProps {
  to: string;
  vendorName: string;
  productName: string;
}

interface OrderStatusEmailProps {
  to: string;
  customerName: string;
  orderId: string;
  status: string;
  products: string[];
}

/**
 * Mock email function for static build
 */
export const sendEmail = async (emailData: EmailProps) => {
  // This is a mock implementation that will be replaced at runtime
  if (typeof window === 'undefined') {
    // During build/SSR, return a mock result
    return { success: true, mock: true };
  }

  // In the browser, we'll implement this properly
  console.log("Would send email:", emailData);
  return { success: true };
};

/**
 * Send garage appointment confirmation email
 */
export const sendGarage = async ({
  to,
  name,
  serviceType,
  appointmentDateTime,
  carMakeModel
}: GarageEmailProps) => {
  return sendEmail({
    to,
    subject: "Your SpareWo Garage Appointment Confirmation",
    templateId: "garage_appointment",
    name,
    serviceType,
    appointmentDateTime,
    carMakeModel
  });
};

/**
 * Send vendor approval email
 */
export const sendVendorApproval = async ({
  to,
  vendorName,
  businessName
}: VendorApprovalEmailProps) => {
  return sendEmail({
    to,
    subject: "Your SpareWo Vendor Account Has Been Approved",
    templateId: "vendor_approval",
    vendorName,
    businessName
  });
};

/**
 * Send vendor rejection email
 */
export const sendVendorRejection = async ({
  to,
  vendorName,
  businessName,
  reason = "We are unable to approve your application at this time."
}: VendorApprovalEmailProps & { reason?: string }) => {
  return sendEmail({
    to,
    subject: "SpareWo Vendor Application Status",
    templateId: "vendor_rejection",
    vendorName,
    businessName,
    reason
  });
};

/**
 * Send product approval email
 */
export const sendProductApproval = async ({
  to,
  vendorName,
  productName
}: ProductApprovalEmailProps) => {
  return sendEmail({
    to,
    subject: "Your Product Has Been Approved on SpareWo",
    templateId: "product_approval",
    vendorName,
    productName
  });
};

/**
 * Send product rejection email
 */
export const sendProductRejection = async ({
  to,
  vendorName,
  productName,
  reason = "The product does not meet our current requirements."
}: ProductApprovalEmailProps & { reason?: string }) => {
  return sendEmail({
    to,
    subject: "SpareWo Product Review Status",
    templateId: "product_rejection",
    vendorName,
    productName,
    reason
  });
};

/**
 * Send order status update email
 */
export const sendOrderStatusUpdate = async ({
  to,
  customerName,
  orderId,
  status,
  products
}: OrderStatusEmailProps) => {
  return sendEmail({
    to,
    subject: `SpareWo Order #${orderId.substring(0, 8).toUpperCase()} Status Update`,
    templateId: "order_status",
    customerName,
    orderId: orderId.substring(0, 8).toUpperCase(),
    status,
    products
  });
};

export default {
  sendEmail,
  sendGarage,
  sendVendorApproval,
  sendVendorRejection,
  sendProductApproval,
  sendProductRejection,
  sendOrderStatusUpdate
};
