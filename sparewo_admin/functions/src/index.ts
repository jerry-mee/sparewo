// functions/src/index.ts
import * as https from "node:https";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {setGlobalOptions} from "firebase-functions/v2/options";
import {defineSecret} from "firebase-functions/params";

admin.initializeApp();
const db = admin.firestore();

type PlainObject = Record<string, unknown>;

const ADMIN_EMAIL = "admin@sparewo.ug";
const GARAGE_EMAIL = "garage@sparewo.ug";
const RESEND_API_KEY = defineSecret("RESEND_API_KEY");

setGlobalOptions({
  region: "us-central1",
  secrets: [RESEND_API_KEY],
});

const DASHBOARD_BASE_URL = (
  process.env.ADMIN_DASHBOARD_URL ||
  process.env.NEXT_PUBLIC_APP_URL ||
  "https://admin.sparewo.ug"
).replace(/\/$/, "");

const SUPPORT_EMAIL = "admin@sparewo.ug";

const toText = (value: unknown, fallback = ""): string => {
  if (typeof value === "string") {
    const trimmed = value.trim();
    return trimmed.length > 0 ? trimmed : fallback;
  }
  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }
  return fallback;
};

const toCurrency = (value: unknown): string => {
  const amount = typeof value === "number" ? value : Number(value || 0);
  if (!Number.isFinite(amount)) return "UGX 0";
  return `UGX ${Math.round(amount).toLocaleString()}`;
};

const formatValue = (value: unknown): string => {
  if (value === null) return "null";
  if (value === undefined) return "undefined";
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate().toISOString();
  }
  if (value instanceof Date) return value.toISOString();
  if (Array.isArray(value)) return value.map((item) => formatValue(item)).join(", ");
  if (typeof value === "object") {
    try {
      return JSON.stringify(value);
    } catch {
      return "[object]";
    }
  }
  return String(value);
};

const changedKeys = (beforeData: PlainObject, afterData: PlainObject): string[] => {
  const keys = new Set([...Object.keys(beforeData), ...Object.keys(afterData)]);
  return Array.from(keys).filter((key) => {
    if (key === "updatedAt") return false;
    return formatValue(beforeData[key]) !== formatValue(afterData[key]);
  });
};

const postJson = (
  host: string,
  path: string,
  body: Record<string, unknown>,
  headers: Record<string, string>
): Promise<{ statusCode: number; body: string }> => {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(body);

    const req = https.request(
      {
        host,
        path,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(payload).toString(),
          ...headers,
        },
      },
      (res) => {
        let responseBody = "";
        res.setEncoding("utf8");
        res.on("data", (chunk) => {
          responseBody += chunk;
        });
        res.on("end", () => {
          resolve({
            statusCode: res.statusCode || 0,
            body: responseBody,
          });
        });
      }
    );

    req.on("error", reject);
    req.write(payload);
    req.end();
  });
};

const renderOpsEmail = (opts: {
  title: string;
  summary: string;
  lines: Array<{ label: string; value: string }>;
  ctaLabel: string;
  ctaUrl: string;
}) => {
  const lineHtml = opts.lines
    .map(
      (line) =>
        `<tr><td style="padding: 6px 0; color:#64748b; width:170px; vertical-align:top;">${line.label}</td><td style="padding: 6px 0; color:#0f172a; font-weight:600;">${line.value}</td></tr>`
    )
    .join("");

  return `
  <div style="font-family: 'Poppins', Arial, sans-serif; max-width:680px; margin:0 auto; background:#fff; border:1px solid #e2e8f0; border-radius:12px; overflow:hidden;">
    <div style="background:#1A1B4B; color:#fff; padding:24px;">
      <h1 style="margin:0; font-size:22px;">SpareWo Ops Alert</h1>
      <p style="margin:8px 0 0; opacity:0.9; font-size:13px;">Action required in Admin Dashboard</p>
    </div>

    <div style="padding:24px;">
      <h2 style="margin:0 0 10px; color:#0f172a; font-size:20px;">${opts.title}</h2>
      <p style="margin:0 0 18px; color:#334155;">${opts.summary}</p>

      <table style="width:100%; border-collapse:collapse; background:#f8fafc; border:1px solid #e2e8f0; border-radius:10px; padding:14px;">
        ${lineHtml}
      </table>

      <div style="margin-top:24px;">
        <a href="${opts.ctaUrl}" style="display:inline-block; background:#f97316; color:#fff; text-decoration:none; font-weight:700; padding:12px 18px; border-radius:10px;">
          ${opts.ctaLabel}
        </a>
      </div>

      <p style="margin:16px 0 0; color:#64748b; font-size:12px;">If the button does not work, open: ${opts.ctaUrl}</p>
    </div>

    <div style="padding:16px 24px; border-top:1px solid #e2e8f0; color:#64748b; font-size:12px;">
      SpareWo Operations • Need help? ${SUPPORT_EMAIL}
    </div>
  </div>
  `;
};

const sendOpsEmail = async (opts: {
  to: string[];
  subject: string;
  html: string;
}) => {
  const key = RESEND_API_KEY.value();
  if (!key) {
    functions.logger.warn("RESEND_API_KEY is missing; skipping ops email", {
      to: opts.to,
      subject: opts.subject,
    });
    return;
  }

  const sender = process.env.SENDER_EMAIL || "SpareWo Ops <onboarding@resend.dev>";

  const response = await postJson(
    "api.resend.com",
    "/emails",
    {
      from: sender,
      to: opts.to,
      subject: opts.subject,
      html: opts.html,
    },
    {
      Authorization: `Bearer ${key}`,
    }
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    functions.logger.error("Resend email failed", {
      statusCode: response.statusCode,
      body: response.body,
      to: opts.to,
      subject: opts.subject,
    });
  } else {
    functions.logger.info("Resend email sent", {
      to: opts.to,
      subject: opts.subject,
    });
  }
};

const sendBookingOpsEmail = async (
  bookingId: string,
  bookingData: PlainObject,
  mode: "created" | "updated",
  changed?: string[]
) => {
  const bookingNumber = toText(bookingData.bookingNumber, bookingId);
  const status = toText(bookingData.status, "pending");
  const customerName = toText(bookingData.userName, "Customer");
  const customerEmail = toText(bookingData.userEmail, "N/A");
  const customerPhone = toText(bookingData.userPhone, "N/A");
  const vehicle = [
    toText(bookingData.vehicleYear),
    toText(bookingData.vehicleBrand),
    toText(bookingData.vehicleModel),
  ]
    .filter(Boolean)
    .join(" ");
  const pickupDate = formatValue(bookingData.pickupDate);
  const pickupTime = toText(bookingData.pickupTime, "N/A");
  const pickupLocation = toText(bookingData.pickupLocation, "N/A");

  const ctaUrl = `${DASHBOARD_BASE_URL}/dashboard/autohub/${bookingId}`;

  const title =
    mode === "created"
      ? `New AutoHub booking ${bookingNumber}`
      : `AutoHub booking updated ${bookingNumber}`;

  const summary =
    mode === "created"
      ? `A new AutoHub booking was created by ${customerName}.`
      : `AutoHub booking ${bookingNumber} was updated${changed && changed.length ? ` (${changed.join(", ")})` : ""}.`;

  await sendOpsEmail({
    to: [ADMIN_EMAIL, GARAGE_EMAIL],
    subject: `[SpareWo Ops] ${title}`,
    html: renderOpsEmail({
      title,
      summary,
      ctaLabel: "Open Booking In Dashboard",
      ctaUrl,
      lines: [
        {label: "Booking Number", value: bookingNumber},
        {label: "Status", value: status},
        {label: "Customer", value: customerName},
        {label: "Customer Email", value: customerEmail},
        {label: "Customer Phone", value: customerPhone},
        {label: "Vehicle", value: vehicle || "N/A"},
        {label: "Pickup", value: `${pickupDate} ${pickupTime}`.trim()},
        {label: "Location", value: pickupLocation},
      ],
    }),
  });
};

const sendOrderOpsEmail = async (
  orderId: string,
  orderData: PlainObject,
  mode: "created" | "updated",
  changed?: string[]
) => {
  const orderNumber = toText(orderData.orderNumber, orderId);
  const status = toText(orderData.status, "pending");
  const customerName = toText(orderData.userName, "Customer");
  const customerEmail = toText(orderData.userEmail, "N/A");
  const customerPhone = toText(orderData.contactPhone, "N/A");
  const totalAmount = toCurrency(orderData.totalAmount);
  const deliveryAddress = toText(orderData.deliveryAddress, "N/A");

  const items = Array.isArray(orderData.items) ? orderData.items : [];
  const itemCount = items.length;

  const ctaUrl = `${DASHBOARD_BASE_URL}/dashboard/orders/${orderId}`;
  const title =
    mode === "created"
      ? `New purchase order ${orderNumber}`
      : `Purchase order updated ${orderNumber}`;
  const summary =
    mode === "created"
      ? `A new client purchase order was created by ${customerName}.`
      : `Order ${orderNumber} was updated${changed && changed.length ? ` (${changed.join(", ")})` : ""}.`;

  await sendOpsEmail({
    to: [ADMIN_EMAIL],
    subject: `[SpareWo Ops] ${title}`,
    html: renderOpsEmail({
      title,
      summary,
      ctaLabel: "Open Order In Dashboard",
      ctaUrl,
      lines: [
        {label: "Order Number", value: orderNumber},
        {label: "Status", value: status},
        {label: "Customer", value: customerName},
        {label: "Customer Email", value: customerEmail},
        {label: "Customer Phone", value: customerPhone},
        {label: "Total", value: totalAmount},
        {label: "Items", value: String(itemCount)},
        {label: "Delivery Address", value: deliveryAddress},
      ],
    }),
  });
};

/**
 * FINAL, SIMPLIFIED VERSION: A one-time-use HTTP Request function.
 *
 * To run, set permissions to "Allow public access" and then simply
 * open the trigger URL in your browser.
 */
export const migrateApprovedProductsToCatalog = functions.https.onRequest(async (request, response) => {
  response.set("Access-Control-Allow-Origin", "*");

  if (request.method === "OPTIONS") {
    response.set("Access-Control-Allow-Methods", "GET");
    response.set("Access-Control-Allow-Headers", "Content-Type");
    response.status(204).send("");
    return;
  }

  try {
    functions.logger.info("Starting migration of approved products...");

    const vendorProductsRef = db.collection("vendor_products");
    const catalogProductsRef = db.collection("catalog_products");

    const snapshot = await vendorProductsRef.where("status", "==", "approved").get();

    if (snapshot.empty) {
      functions.logger.info("No approved products found.");
      response.status(200).send("SUCCESS: No approved products found to migrate.");
      return;
    }

    const productsToMigrate = snapshot.docs.filter((doc) => !doc.data().catalogProductId);

    if (productsToMigrate.length === 0) {
      functions.logger.info("All approved products have already been migrated.");
      response.status(200).send("SUCCESS: All approved products have already been migrated.");
      return;
    }

    const batch = db.batch();
    let processedCount = 0;

    productsToMigrate.forEach((doc) => {
      const vendorProduct = doc.data();
      const vendorPrice = vendorProduct.unitPrice || vendorProduct.price || 0;

      if (vendorPrice > 0) {
        const retailPrice = Math.round(vendorPrice * 1.25);
        const newCatalogDocRef = catalogProductsRef.doc();

        batch.set(newCatalogDocRef, {
          partName: vendorProduct.partName || vendorProduct.name || "N/A",
          description: vendorProduct.description || "",
          brand: vendorProduct.brand || "N/A",
          unitPrice: retailPrice,
          stockQuantity: vendorProduct.stockQuantity || vendorProduct.quantity || 0,
          imageUrls: vendorProduct.images || vendorProduct.imageUrls || [],
          partNumber: vendorProduct.partNumber || null,
          condition: vendorProduct.condition || "New",
          category: vendorProduct.category || "Uncategorized",
          categories: Array.isArray(vendorProduct.categories)
            ? vendorProduct.categories
            : [vendorProduct.category || "Uncategorized"],
          createdAt: vendorProduct.createdAt || admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          isActive: true,
          isFeatured: false,
        });

        batch.update(doc.ref, {catalogProductId: newCatalogDocRef.id});
        processedCount++;
      } else {
        functions.logger.warn(`Skipping product ${doc.id} due to zero price.`);
      }
    });

    await batch.commit();

    functions.logger.info(`Successfully migrated ${processedCount} products.`);
    response
      .status(200)
      .send(`SUCCESS: Successfully migrated ${processedCount} products to the catalog.`);
  } catch (error) {
    functions.logger.error("Migration failed:", error);
    response.status(500).send("ERROR: Migration failed. Check function logs for details.");
  }
});

export const notifyAdminsOnNewBooking = functions.firestore.onDocumentCreated(
  "service_bookings/{bookingId}",
  async (event) => {
    try {
      const bookingId = event.params.bookingId as string;
      const bookingData = (event.data?.data() || {}) as PlainObject;
      const bookingNumber = toText(bookingData.bookingNumber, bookingId);
      const customerName = toText(bookingData.userName, "Customer");
      const vehicle = [
        toText(bookingData.vehicleYear),
        toText(bookingData.vehicleBrand),
        toText(bookingData.vehicleModel),
      ].filter(Boolean).join(" ");
      const now = admin.firestore.FieldValue.serverTimestamp();

      const adminUsersSnap = await db.collection("adminUsers").get();
      if (adminUsersSnap.empty) {
        functions.logger.info("No admin users found for booking notification", {bookingId});
      } else {
        const batch = db.batch();
        for (const adminDoc of adminUsersSnap.docs) {
          const notifRef = db.collection("notifications").doc();
          batch.set(notifRef, {
            userId: adminDoc.id,
            recipientId: adminDoc.id,
            title: "New AutoHub Booking",
            message: `${bookingNumber} from ${customerName}${vehicle ? ` • ${vehicle}` : ""}`,
            type: "info",
            entityType: "booking",
            bookingId,
            bookingNumber,
            link: `/dashboard/autohub/${bookingId}`,
            read: false,
            isRead: false,
            createdAt: now,
            updatedAt: now,
          });
        }
        await batch.commit();
      }

      await sendBookingOpsEmail(bookingId, bookingData, "created");
    } catch (error) {
      functions.logger.error("notifyAdminsOnNewBooking failed", error);
    }
  }
);

export const sendOpsEmailOnBookingUpdate = functions.firestore.onDocumentUpdated(
  "service_bookings/{bookingId}",
  async (event) => {
    try {
      const bookingId = event.params.bookingId as string;
      const beforeData = (event.data?.before.data() || {}) as PlainObject;
      const afterData = (event.data?.after.data() || {}) as PlainObject;

      const changes = changedKeys(beforeData, afterData);
      if (changes.length === 0) return;

      await sendBookingOpsEmail(bookingId, afterData, "updated", changes);
    } catch (error) {
      functions.logger.error("sendOpsEmailOnBookingUpdate failed", error);
    }
  }
);

export const sendOpsEmailOnOrderCreate = functions.firestore.onDocumentCreated(
  "orders/{orderId}",
  async (event) => {
    try {
      const orderId = event.params.orderId as string;
      const orderData = (event.data?.data() || {}) as PlainObject;
      await sendOrderOpsEmail(orderId, orderData, "created");
    } catch (error) {
      functions.logger.error("sendOpsEmailOnOrderCreate failed", error);
    }
  }
);

export const sendOpsEmailOnOrderUpdate = functions.firestore.onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    try {
      const orderId = event.params.orderId as string;
      const beforeData = (event.data?.before.data() || {}) as PlainObject;
      const afterData = (event.data?.after.data() || {}) as PlainObject;

      const changes = changedKeys(beforeData, afterData);
      if (changes.length === 0) return;

      await sendOrderOpsEmail(orderId, afterData, "updated", changes);
    } catch (error) {
      functions.logger.error("sendOpsEmailOnOrderUpdate failed", error);
    }
  }
);
