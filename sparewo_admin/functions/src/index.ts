// functions/src/index.ts
import * as https from "node:https";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {setGlobalOptions} from "firebase-functions/v2/options";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";

admin.initializeApp();
const db = admin.firestore();

type PlainObject = Record<string, unknown>;

const ADMIN_EMAIL = "admin@sparewo.ug";
const GARAGE_EMAIL = "garage@sparewo.ug";
const RESEND_API_KEY = defineSecret("RESEND_API_KEY");
const FUNCTIONS_PROJECT_ID =
  process.env.GCLOUD_PROJECT || process.env.PROJECT_ID || "sparewoapp";
const FUNCTIONS_SERVICE_ACCOUNT =
  process.env.FUNCTIONS_SERVICE_ACCOUNT ||
  `${FUNCTIONS_PROJECT_ID}@appspot.gserviceaccount.com`;

setGlobalOptions({
  region: "us-central1",
  secrets: [RESEND_API_KEY],
  serviceAccount: FUNCTIONS_SERVICE_ACCOUNT,
});

const DASHBOARD_BASE_URL = (
  process.env.ADMIN_DASHBOARD_URL ||
  process.env.NEXT_PUBLIC_APP_URL ||
  "https://admin.sparewo.ug"
).replace(/\/$/, "");

const SUPPORT_EMAIL = "admin@sparewo.ug";
const ACCOUNT_DELETION_RECENT_AUTH_SECONDS = 15 * 60;
const BATCH_WRITE_LIMIT = 400;
const CLIENT_APP_BASE_URL = (
  process.env.CLIENT_APP_URL ||
  process.env.CLIENT_WEB_URL ||
  "https://sparewo.ug"
).replace(/\/$/, "");

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

const toAddressText = (value: unknown): string => {
  if (typeof value === "string") {
    return toText(value, "N/A");
  }
  if (value && typeof value === "object") {
    const map = value as PlainObject;
    const parts = [
      toText(map.street || map.line1),
      toText(map.line2),
      toText(map.city || map.area),
      toText(map.country),
    ].filter((part) => part.length > 0);
    if (parts.length > 0) return parts.join(", ");
  }
  return "N/A";
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

const toAuthTimeMillis = (value: unknown): number | null => {
  if (typeof value !== "number" && typeof value !== "string") return null;
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) return null;
  if (parsed < 1000000000000) return parsed * 1000;
  return parsed;
};

const uniqueDocsByFieldMatch = async (
  collectionName: string,
  fieldNames: string[],
  matchValue: string
): Promise<admin.firestore.QueryDocumentSnapshot[]> => {
  const snapshots = await Promise.all(
    fieldNames.map((fieldName) =>
      db.collection(collectionName).where(fieldName, "==", matchValue).get()
    )
  );

  const deduped = new Map<string, admin.firestore.QueryDocumentSnapshot>();
  for (const snapshot of snapshots) {
    for (const doc of snapshot.docs) {
      deduped.set(doc.ref.path, doc);
    }
  }
  return Array.from(deduped.values());
};

const deleteDocsInBatches = async (
  docs: admin.firestore.QueryDocumentSnapshot[]
): Promise<number> => {
  if (docs.length === 0) return 0;
  let deleted = 0;
  for (let i = 0; i < docs.length; i += BATCH_WRITE_LIMIT) {
    const chunk = docs.slice(i, i + BATCH_WRITE_LIMIT);
    const batch = db.batch();
    for (const doc of chunk) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    deleted += chunk.length;
  }
  return deleted;
};

const updateDocsInBatches = async (
  docs: admin.firestore.QueryDocumentSnapshot[],
  updateFactory: (
    doc: admin.firestore.QueryDocumentSnapshot
  ) => admin.firestore.UpdateData<admin.firestore.DocumentData>
): Promise<number> => {
  if (docs.length === 0) return 0;
  let updated = 0;
  for (let i = 0; i < docs.length; i += BATCH_WRITE_LIMIT) {
    const chunk = docs.slice(i, i + BATCH_WRITE_LIMIT);
    const batch = db.batch();
    for (const doc of chunk) {
      batch.update(doc.ref, updateFactory(doc));
    }
    await batch.commit();
    updated += chunk.length;
  }
  return updated;
};

const recursiveDeleteDocument = async (path: string): Promise<void> => {
  const ref = db.doc(path);
  await db.recursiveDelete(ref);
};

const safeRecursiveDeleteDocument = async (path: string): Promise<void> => {
  try {
    await recursiveDeleteDocument(path);
  } catch (error) {
    functions.logger.warn("safeRecursiveDeleteDocument skipped", {path, error});
  }
};

const normalizeEmail = (value: unknown): string => toText(value).toLowerCase();

type AdminCommunicationAudience =
  | "all_clients"
  | "active_clients"
  | "suspended_clients"
  | "all_vendors"
  | "active_vendors"
  | "suspended_vendors"
  | "selected_clients"
  | "selected_vendors"
  | "individual_client"
  | "individual_vendor"
  | "admins";

type AdminCommunicationType = "info" | "success" | "warning" | "error";

type CommunicationRecipientRole = "client" | "vendor" | "admin";

type CommunicationRecipient = {
  uid: string;
  role: CommunicationRecipientRole;
  label: string;
  email: string;
};

const ALLOWED_COMMUNICATION_AUDIENCES = new Set<AdminCommunicationAudience>([
  "all_clients",
  "active_clients",
  "suspended_clients",
  "all_vendors",
  "active_vendors",
  "suspended_vendors",
  "selected_clients",
  "selected_vendors",
  "individual_client",
  "individual_vendor",
  "admins",
]);

const ALLOWED_COMMUNICATION_TYPES = new Set<AdminCommunicationType>([
  "info",
  "success",
  "warning",
  "error",
]);

const dedupeCommunicationRecipients = (
  recipients: CommunicationRecipient[]
): CommunicationRecipient[] => {
  const map = new Map<string, CommunicationRecipient>();
  for (const recipient of recipients) {
    const uid = toText(recipient.uid);
    if (!uid) continue;
    if (!map.has(uid)) {
      map.set(uid, {
        uid,
        role: recipient.role,
        label: toText(recipient.label, uid),
        email: normalizeEmail(recipient.email),
      });
    }
  }
  return Array.from(map.values());
};

const toCommunicationLink = (value: unknown): string => {
  const raw = toText(value);
  if (!raw) return "";
  if (/^https?:\/\//i.test(raw)) return raw;
  if (raw.startsWith("/")) return raw;
  return `/${raw}`;
};

const resolveVendorUid = (
  docId: string,
  data: PlainObject
): string => toText(data.userId || data.uid || docId);

const fetchRecipientsByIds = async (opts: {
  collectionName: "users" | "vendors" | "adminUsers";
  ids: string[];
  role: CommunicationRecipientRole;
  labelField: string;
  emailFields?: string[];
  uidResolver?: (docId: string, data: PlainObject) => string;
}): Promise<CommunicationRecipient[]> => {
  const ids = Array.from(new Set(opts.ids.map((value) => toText(value)).filter(Boolean)));
  if (ids.length === 0) return [];

  const snaps = await Promise.all(
    ids.map((id) => db.collection(opts.collectionName).doc(id).get())
  );

  return snaps
    .filter((snap) => snap.exists)
    .map((snap) => {
      const data = (snap.data() || {}) as PlainObject;
      const uid = opts.uidResolver ? opts.uidResolver(snap.id, data) : snap.id;
      const email = opts.emailFields && opts.emailFields.length > 0 ?
        normalizeEmail(opts.emailFields.map((field) => data[field]).find((value) => toText(value).length > 0)) :
        normalizeEmail(data.email);
      return {
        uid,
        role: opts.role,
        label: toText(data[opts.labelField], uid),
        email,
      };
    })
    .filter((recipient) => recipient.uid.length > 0);
};

const resolveCommunicationRecipients = async (
  audience: AdminCommunicationAudience,
  recipientIds: string[]
): Promise<CommunicationRecipient[]> => {
  if (audience === "selected_clients" || audience === "individual_client") {
    return dedupeCommunicationRecipients(
      await fetchRecipientsByIds({
        collectionName: "users",
        ids: recipientIds,
        role: "client",
        labelField: "name",
      })
    );
  }

  if (audience === "selected_vendors" || audience === "individual_vendor") {
    return dedupeCommunicationRecipients(
      await fetchRecipientsByIds({
        collectionName: "vendors",
        ids: recipientIds,
        role: "vendor",
        labelField: "businessName",
        emailFields: ["email", "contactEmail"],
        uidResolver: resolveVendorUid,
      })
    );
  }

  if (audience === "admins") {
    const adminsSnap = await db.collection("adminUsers").get();
    return dedupeCommunicationRecipients(
      adminsSnap.docs.map((docSnap) => {
        const data = (docSnap.data() || {}) as PlainObject;
        return {
          uid: docSnap.id,
          role: "admin" as const,
          label: toText(data.displayName, docSnap.id),
          email: normalizeEmail(data.email),
        };
      })
    );
  }

  if (
    audience === "all_clients" ||
    audience === "active_clients" ||
    audience === "suspended_clients"
  ) {
    const usersSnap = await db.collection("users").get();
    return dedupeCommunicationRecipients(
      usersSnap.docs
        .filter((docSnap) => {
          const isSuspended = docSnap.data().isSuspended === true;
          if (audience === "all_clients") return true;
          if (audience === "active_clients") return !isSuspended;
          return isSuspended;
        })
        .map((docSnap) => {
          const data = (docSnap.data() || {}) as PlainObject;
          return {
            uid: docSnap.id,
            role: "client" as const,
            label: toText(data.name, docSnap.id),
            email: normalizeEmail(data.email),
          };
        })
    );
  }

  const vendorsSnap = await db.collection("vendors").get();
  return dedupeCommunicationRecipients(
    vendorsSnap.docs
      .filter((docSnap) => {
        const data = (docSnap.data() || {}) as PlainObject;
        const isSuspended = data.isSuspended === true;
        const isApproved = toText(data.status) === "approved";
        if (audience === "all_vendors") return true;
        if (audience === "active_vendors") return isApproved && !isSuspended;
        return isSuspended;
      })
      .map((docSnap) => {
        const data = (docSnap.data() || {}) as PlainObject;
        const uid = resolveVendorUid(docSnap.id, data);
        return {
          uid,
          role: "vendor" as const,
          label: toText(data.businessName, docSnap.id),
          email: normalizeEmail(data.email || data.contactEmail),
        };
      })
      .filter((recipient) => recipient.uid.length > 0)
  );
};

const ensureAdminCanSendCommunications = async (uid: string): Promise<void> => {
  const adminSnap = await db.collection("adminUsers").doc(uid).get();
  if (!adminSnap.exists) {
    throw new HttpsError(
      "permission-denied",
      "Only admin users can send communications."
    );
  }

  const data = (adminSnap.data() || {}) as PlainObject;
  const role = toText(data.role, "viewer").toLowerCase();
  const isActive = data.is_active !== false;
  const pendingActivation = data.pending_activation === true;

  if (!isActive || pendingActivation || role === "viewer") {
    throw new HttpsError(
      "permission-denied",
      "Your account is not allowed to send communications."
    );
  }
};

const mergeRootDocument = async (opts: {
  sourcePath: string;
  targetPath: string;
  targetEmail?: string;
  mergedFromUid: string;
}): Promise<boolean> => {
  const sourceRef = db.doc(opts.sourcePath);
  const targetRef = db.doc(opts.targetPath);

  const [sourceSnap, targetSnap] = await Promise.all([
    sourceRef.get(),
    targetRef.get(),
  ]);
  if (!sourceSnap.exists) return false;

  const sourceData = (sourceSnap.data() || {}) as PlainObject;
  const targetData = (targetSnap.data() || {}) as PlainObject;
  const patch: Record<string, unknown> = {};

  for (const [key, sourceValue] of Object.entries(sourceData)) {
    if (key === "updatedAt") continue;
    const targetValue = targetData[key];
    const targetMissing =
      targetValue === undefined ||
      targetValue === null ||
      (typeof targetValue === "string" && targetValue.trim().length === 0);
    const targetIsPlaceholderName =
      key === "name" &&
      typeof targetValue === "string" &&
      ["user", "sparewo user"].includes(targetValue.trim().toLowerCase()) &&
      typeof sourceValue === "string" &&
      sourceValue.trim().length > 0;

    if (targetMissing || targetIsPlaceholderName) {
      patch[key] = sourceValue;
    }
  }

  if (opts.targetEmail) {
    patch.email = opts.targetEmail;
  }

  patch.mergedFromUids = admin.firestore.FieldValue.arrayUnion(opts.mergedFromUid);
  patch.updatedAt = admin.firestore.FieldValue.serverTimestamp();
  await targetRef.set(patch, {merge: true});
  return true;
};

const mergeSubcollectionIntoTarget = async (opts: {
  sourceParentPath: string;
  targetParentPath: string;
  subcollection: string;
}): Promise<{copied: number; merged: number}> => {
  const sourceCol = db.doc(opts.sourceParentPath).collection(opts.subcollection);
  const targetCol = db.doc(opts.targetParentPath).collection(opts.subcollection);
  const sourceSnap = await sourceCol.get();
  if (sourceSnap.empty) return {copied: 0, merged: 0};

  let copied = 0;
  let merged = 0;
  let targetHasDefaultCar = false;

  if (opts.subcollection === "cars") {
    const targetDefault = await targetCol.where("isDefault", "==", true).limit(1).get();
    targetHasDefaultCar = !targetDefault.empty;
  }

  for (let i = 0; i < sourceSnap.docs.length; i += BATCH_WRITE_LIMIT) {
    const chunk = sourceSnap.docs.slice(i, i + BATCH_WRITE_LIMIT);
    const targetRefs = chunk.map((doc) => targetCol.doc(doc.id));
    const targetSnaps = await db.getAll(...targetRefs);
    const targetSnapByPath = new Map(
      targetSnaps.map((snap) => [snap.ref.path, snap])
    );

    const batch = db.batch();
    for (const sourceDoc of chunk) {
      const targetRef = targetCol.doc(sourceDoc.id);
      const targetDoc = targetSnapByPath.get(targetRef.path);
      const exists = !!targetDoc?.exists;
      const sourceData = sourceDoc.data() as PlainObject;
      const payload: Record<string, unknown> = {...sourceData};

      if (opts.subcollection === "cart") {
        const sourceQty = Number(sourceData.quantity || 0);
        const targetQty = Number((targetDoc?.data() as PlainObject | undefined)?.quantity || 0);
        payload.quantity = Number.isFinite(sourceQty) && Number.isFinite(targetQty) ?
          Math.max(0, sourceQty + targetQty) :
          sourceData.quantity;
      }

      if (opts.subcollection === "cars" && sourceData.isDefault === true) {
        if (targetHasDefaultCar) {
          payload.isDefault = false;
        } else {
          targetHasDefaultCar = true;
        }
      }

      payload.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      batch.set(targetRef, payload, {merge: true});
      if (exists) {
        merged += 1;
      } else {
        copied += 1;
      }
    }

    await batch.commit();
  }

  return {copied, merged};
};

const reassignUidReferences = async (
  collectionName: string,
  fieldNames: string[],
  sourceUid: string,
  targetUid: string
): Promise<number> => {
  const docs = await uniqueDocsByFieldMatch(collectionName, fieldNames, sourceUid);
  return updateDocsInBatches(
    docs,
    (doc) => {
      const patch: Record<string, unknown> = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      const data = doc.data() as PlainObject;
      for (const fieldName of fieldNames) {
        if (toText(data[fieldName]) === sourceUid) {
          patch[fieldName] = targetUid;
        }
      }
      return patch as admin.firestore.UpdateData<admin.firestore.DocumentData>;
    }
  );
};

const deletionMarker = (uid: string): string => `deleted:${uid}`;

const orderAnonymizationPatch = (
  uid: string
): admin.firestore.UpdateData<admin.firestore.DocumentData> => ({
  userId: deletionMarker(uid),
  customerId: deletionMarker(uid),
  userName: "Deleted User",
  customerName: "Deleted User",
  userEmail: admin.firestore.FieldValue.delete(),
  customerEmail: admin.firestore.FieldValue.delete(),
  customerPhone: admin.firestore.FieldValue.delete(),
  contactPhone: admin.firestore.FieldValue.delete(),
  deliveryAddress: admin.firestore.FieldValue.delete(),
  deliveryAddressDetails: admin.firestore.FieldValue.delete(),
  accountDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
  accountDeletionMarker: deletionMarker(uid),
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
});

const bookingAnonymizationPatch = (
  uid: string
): admin.firestore.UpdateData<admin.firestore.DocumentData> => ({
  userId: deletionMarker(uid),
  userName: "Deleted User",
  userEmail: admin.firestore.FieldValue.delete(),
  userPhone: admin.firestore.FieldValue.delete(),
  pickupLocation: admin.firestore.FieldValue.delete(),
  vehiclePlate: admin.firestore.FieldValue.delete(),
  notes: admin.firestore.FieldValue.delete(),
  accountDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
  accountDeletionMarker: deletionMarker(uid),
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
});

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
        `<tr><td style="padding: 6px 0; color:#64748b; width:170px; vertical-align:top;">${line.label}</td>` +
        `<td style="padding: 6px 0; color:#0f172a; font-weight:600;">${line.value}</td></tr>`
    )
    .join("");

  return `
  <div style="font-family: 'Poppins', Arial, sans-serif; max-width:680px; margin:0 auto; background:#fff; 
  border:1px solid #e2e8f0; border-radius:12px; overflow:hidden;">
    <div style="background:#1A1B4B; color:#fff; padding:24px;">
      <h1 style="margin:0; font-size:22px;">SpareWo Ops Alert</h1>
      <p style="margin:8px 0 0; opacity:0.9; font-size:13px;">Action required in Admin Dashboard</p>
    </div>

    <div style="padding:24px;">
      <h2 style="margin:0 0 10px; color:#0f172a; font-size:20px;">${opts.title}</h2>
      <p style="margin:0 0 18px; color:#334155;">${opts.summary}</p>

      <table style="width:100%; border-collapse:collapse; background:#f8fafc; border:1px solid #e2e8f0; 
      border-radius:10px; padding:14px;">
        ${lineHtml}
      </table>

      <div style="margin-top:24px;">
        <a href="${opts.ctaUrl}" style="display:inline-block; background:#f97316; color:#fff; 
        text-decoration:none; font-weight:700; padding:12px 18px; border-radius:10px;">
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

const renderAudienceCommunicationEmail = (opts: {
  title: string;
  message: string;
  link?: string;
}): string => {
  const actionHtml = opts.link ?
    `<p style="margin:20px 0 0;">
      <a href="${opts.link}" style="display:inline-block; background:#1A1B4B; color:#ffffff; text-decoration:none; font-weight:600; padding:10px 16px; border-radius:8px;">
        Open Message
      </a>
    </p>` :
    "";

  return `
  <div style="font-family: 'Poppins', Arial, sans-serif; max-width:620px; margin:0 auto; border:1px solid #e2e8f0; border-radius:12px; overflow:hidden;">
    <div style="background:#1A1B4B; color:#ffffff; padding:20px 24px;">
      <h2 style="margin:0; font-size:20px;">SpareWo Update</h2>
    </div>
    <div style="padding:24px;">
      <h3 style="margin:0 0 10px; color:#0f172a; font-size:18px;">${opts.title}</h3>
      <p style="margin:0; color:#334155; white-space:pre-wrap;">${opts.message}</p>
      ${actionHtml}
    </div>
    <div style="padding:14px 24px; border-top:1px solid #e2e8f0; color:#64748b; font-size:12px;">
      SpareWo Team • ${SUPPORT_EMAIL}
    </div>
  </div>
  `;
};

const sendResendEmailBatch = async (opts: {
  to: string[];
  subject: string;
  html: string;
}): Promise<boolean> => {
  const recipients = opts.to.map((email) => normalizeEmail(email)).filter(Boolean);
  if (recipients.length === 0) return true;

  const key = RESEND_API_KEY.value();
  if (!key) {
    functions.logger.warn("RESEND_API_KEY is missing; skipping communication email", {
      recipientCount: recipients.length,
      subject: opts.subject,
    });
    return false;
  }

  const sender = process.env.SENDER_EMAIL || "SpareWo <no-reply@sparewo.ug>";
  const response = await postJson(
    "api.resend.com",
    "/emails",
    {
      from: sender,
      to: recipients,
      subject: opts.subject,
      html: opts.html,
    },
    {
      Authorization: `Bearer ${key}`,
    }
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    functions.logger.error("sendResendEmailBatch failed", {
      statusCode: response.statusCode,
      body: response.body,
      recipientCount: recipients.length,
      subject: opts.subject,
    });
    return false;
  }

  return true;
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
    mode === "created" ?
      `New AutoHub booking ${bookingNumber}` :
      `AutoHub booking updated ${bookingNumber}`;

  const summary =
    mode === "created" ?
      `A new AutoHub booking was created by ${customerName}.` :
      `AutoHub booking ${bookingNumber} was updated${changed && changed.length ? ` (${changed.join(", ")})` : ""}.`;

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
  const customerPhone = toText(orderData.customerPhone || orderData.contactPhone, "N/A");
  const totalAmount = toCurrency(orderData.totalAmount);
  const deliveryAddress = toAddressText(
    orderData.deliveryAddressDetails || orderData.deliveryAddress
  );

  const items = Array.isArray(orderData.items) ? orderData.items : [];
  const itemCount = items.length;

  const ctaUrl = `${DASHBOARD_BASE_URL}/dashboard/orders/${orderId}`;
  const title =
    mode === "created" ?
      `New purchase order ${orderNumber}` :
      `Purchase order updated ${orderNumber}`;
  const summary =
    mode === "created" ?
      `A new client purchase order was created by ${customerName}.` :
      `Order ${orderNumber} was updated${changed && changed.length ? ` (${changed.join(", ")})` : ""}.`;

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
          categories: Array.isArray(vendorProduct.categories) ?
            vendorProduct.categories :
            [vendorProduct.category || "Uncategorized"],
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


const notificationPayload = (
  notificationId: string,
  notification: PlainObject,
  badgeCount: number
): {title: string; body: string; data: Record<string, string>} => {
  const entityType = toText(notification.entityType || notification.type, "update");
  const entityId = toText(
    notification.id || notification.orderId || notification.bookingId,
    notificationId
  );
  const title = toText(notification.title, "SpareWo Update");
  const body = toText(notification.message, "You have a new update.");
  const rawLink = toText(notification.link);
  const normalizedLink = (() => {
    if (!rawLink) return "";
    if (!rawLink.startsWith("/")) return rawLink;
    try {
      const uri = new URL(`https://sparewo.local${rawLink}`);
      if (uri.pathname === "/notifications" && !uri.searchParams.has("openId")) {
        uri.searchParams.set("openId", notificationId);
      }
      return `${uri.pathname}${uri.search}`;
    } catch {
      if (rawLink === "/notifications") {
        return `/notifications?openId=${encodeURIComponent(notificationId)}`;
      }
      return rawLink;
    }
  })();
  const status = toText(notification.status);

  return {
    title,
    body,
    data: {
      type: entityType,
      id: entityId,
      link: normalizedLink,
      status,
      badge: String(badgeCount),
      notificationId,
    },
  };
};

export const fanOutPushOnNotificationCreate = functions.firestore.onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    try {
      const notificationId = event.params.notificationId as string;
      const payload = (event.data?.data() || {}) as PlainObject;
      const recipientId = toText(
        payload.recipientId ||
          payload.userId ||
          payload.recipientUid ||
          payload.clientId ||
          payload.customerId
      );
      if (!recipientId) return;

      const [userTokenSnap, clientTokenSnap, adminTokenSnap, vendorTokenSnap] = await Promise.all([
        db.collection("users").doc(recipientId).collection("tokens").get(),
        db.collection("clients").doc(recipientId).collection("tokens").get(),
        db.collection("adminUsers").doc(recipientId).collection("tokens").get(),
        db.collection("vendors").doc(recipientId).collection("tokens").get(),
      ]);

      if (
        userTokenSnap.empty &&
        clientTokenSnap.empty &&
        adminTokenSnap.empty &&
        vendorTokenSnap.empty
      ) {
        functions.logger.info("No tokens for notification recipient", {
          recipientId,
          notificationId,
        });
        return;
      }

      const tokenRefs = new Map<string, admin.firestore.DocumentReference[]>();
      const tokenMeta = new Map<string, {
        deviceId: string;
        platform: string;
        appVersion: string;
        buildNumber: string;
        tokenPath: string;
      }>();
      const allTokenDocs = [
        ...userTokenSnap.docs,
        ...clientTokenSnap.docs,
        ...adminTokenSnap.docs,
        ...vendorTokenSnap.docs,
      ];
      for (const doc of allTokenDocs) {
        const data = doc.data();
        const token = toText(data.token || doc.id);
        if (!token) continue;
        const existing = tokenRefs.get(token) || [];
        existing.push(doc.ref);
        tokenRefs.set(token, existing);
        if (!tokenMeta.has(token)) {
          tokenMeta.set(token, {
            deviceId: toText(data.deviceId, "unknown"),
            platform: toText(data.platform, "unknown"),
            appVersion: toText(data.appVersion, "unknown"),
            buildNumber: toText(data.buildNumber, "unknown"),
            tokenPath: doc.ref.path,
          });
        }
      }

      const tokens = Array.from(tokenRefs.keys());
      if (tokens.length === 0) return;

      const parsedBadgeFromPayload = Number(
        payload.badgeCount || payload.badge || payload.unreadCount || 0
      );
      const badgeCount = Number.isFinite(parsedBadgeFromPayload) && parsedBadgeFromPayload > 0 ?
        Math.floor(parsedBadgeFromPayload) :
        1;

      const deepLink = toText(payload.link);
      const webPushLink = (() => {
        if (!deepLink) return `${DASHBOARD_BASE_URL}/dashboard/notifications`;
        if (/^https?:\/\//i.test(deepLink)) return deepLink;
        if (deepLink.startsWith("/dashboard")) return `${DASHBOARD_BASE_URL}${deepLink}`;
        if (deepLink.startsWith("/")) return `${CLIENT_APP_BASE_URL}${deepLink}`;
        return `${DASHBOARD_BASE_URL}/dashboard/notifications`;
      })();

      const notif = notificationPayload(notificationId, payload, badgeCount);
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: notif.title,
          body: notif.body,
        },
        data: notif.data,
        android: {
          priority: "high",
          ttl: 60 * 60 * 1000,
          notification: {
            channelId: "sparewo_updates",
            sound: "default",
            notificationCount: badgeCount,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
            tag: notificationId,
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
            "apns-push-type": "alert",
          },
          payload: {
            aps: {
              sound: "default",
              badge: badgeCount,
              mutableContent: true,
            },
          },
        },
        webpush: {
          headers: {
            Urgency: "high",
          },
          notification: {
            title: notif.title,
            body: notif.body,
            icon: `${DASHBOARD_BASE_URL}/images/logo.png`,
            badge: `${DASHBOARD_BASE_URL}/images/logo.png`,
            data: notif.data,
          },
          fcmOptions: {
            link: webPushLink,
          },
        },
      });

      if (response.failureCount > 0) {
        const staleRefs: admin.firestore.DocumentReference[] = [];
        response.responses.forEach((result, index) => {
          if (result.success) return;
          const code = result.error?.code;
          if (
            code === "messaging/invalid-registration-token" ||
            code === "messaging/registration-token-not-registered"
          ) {
            const token = tokens[index];
            const refs = tokenRefs.get(token) || [];
            staleRefs.push(...refs);
          }
        });

        if (staleRefs.length > 0) {
          const batch = db.batch();
          staleRefs.forEach((ref) => batch.delete(ref));
          await batch.commit();
        }
      }

      const deliveryErrors = response.responses
        .map((result, index) => {
          if (result.success) return null;
          return {
            token: tokens[index],
            code: result.error?.code || "unknown",
            message: result.error?.message || "",
            ...(tokenMeta.get(tokens[index]) || {
              deviceId: "unknown",
              platform: "unknown",
              appVersion: "unknown",
              buildNumber: "unknown",
              tokenPath: "unknown",
            }),
          };
        })
        .filter(Boolean)
        .slice(0, 20);

      await db.collection("notifications").doc(notificationId).set({
        pushFanoutAt: admin.firestore.FieldValue.serverTimestamp(),
        pushTotalTokens: tokens.length,
        pushSuccessCount: response.successCount,
        pushFailureCount: response.failureCount,
        pushDeliveryErrors: deliveryErrors,
        pushDeepLink: notif.data.link || null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      await db.collection("system_diagnostics_events").add({
        source: "function",
        service: "push_fanout",
        severity: response.failureCount > 0 ? "warn" : "info",
        code: "fanout_complete",
        message: `Push fanout completed for notification ${notificationId}`,
        fingerprint: `fanout_complete|${notificationId}|${response.successCount}|${response.failureCount}`,
        context: {
          notificationId,
          recipientId,
          totalTokens: tokens.length,
          successCount: response.successCount,
          failureCount: response.failureCount,
          deliveryErrors,
          tokenTargets: tokens
            .map((token) => {
              const meta = tokenMeta.get(token);
              return {
                token,
                ...(meta || {
                  deviceId: "unknown",
                  platform: "unknown",
                  appVersion: "unknown",
                  buildNumber: "unknown",
                  tokenPath: "unknown",
                }),
              };
            })
            .slice(0, 50),
        },
        platform: "functions",
        uid: recipientId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isoTimestamp: new Date().toISOString(),
        createdAtMs: Date.now(),
      });

      functions.logger.info("Notification push fanout complete", {
        notificationId,
        recipientId,
        badgeCount,
        userTokenDocs: userTokenSnap.size,
        clientTokenDocs: clientTokenSnap.size,
        adminTokenDocs: adminTokenSnap.size,
        vendorTokenDocs: vendorTokenSnap.size,
        webPushLink,
        totalTokens: tokens.length,
        successCount: response.successCount,
        failureCount: response.failureCount,
      });
    } catch (error) {
      functions.logger.error("fanOutPushOnNotificationCreate failed", error);
      await db.collection("system_diagnostics_events").add({
        source: "function",
        service: "push_fanout",
        severity: "error",
        code: "fanout_failed",
        message: "fanOutPushOnNotificationCreate failed",
        fingerprint: `fanout_failed|${String(error)}`,
        context: {
          error: String(error),
        },
        platform: "functions",
        uid: null,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isoTimestamp: new Date().toISOString(),
        createdAtMs: Date.now(),
      });
    }
  }
);


const orderStatusNotificationTitle: Record<string, string> = {
  pending: "Order Received",
  confirmed: "Order Confirmed",
  processing: "Order Processing",
  shipped: "Order Shipped",
  delivered: "Order Delivered",
  completed: "Order Completed",
  cancelled: "Order Cancelled",
};

const bookingStatusNotificationTitle: Record<string, string> = {
  pending: "AutoHub Request Pending",
  confirmed: "AutoHub Request Confirmed",
  mechanic_assigned: "Mechanic Assigned",
  in_progress: "AutoHub Service In Progress",
  completed: "AutoHub Service Completed",
  cancelled: "AutoHub Request Cancelled",
};

const orderStatusMessage = (status: string, orderNumber: string): string => {
  switch (status) {
  case "pending":
    return `Order ${orderNumber} has been received.`;
  case "confirmed":
    return `Order ${orderNumber} has been confirmed.`;
  case "processing":
    return `Order ${orderNumber} is now being prepared.`;
  case "shipped":
    return `Order ${orderNumber} has been shipped and is on the way.`;
  case "delivered":
    return `Order ${orderNumber} has been delivered.`;
  case "completed":
    return `Order ${orderNumber} has been completed.`;
  case "cancelled":
    return `Order ${orderNumber} was cancelled. Contact support if needed.`;
  default:
    return `Order ${orderNumber} status is now ${status}.`;
  }
};

const bookingStatusMessage = (status: string, bookingNumber: string): string => {
  switch (status) {
  case "pending":
    return `AutoHub request ${bookingNumber} is pending review.`;
  case "confirmed":
    return `AutoHub request ${bookingNumber} has been confirmed.`;
  case "mechanic_assigned":
    return `A mechanic has been assigned to AutoHub request ${bookingNumber}.`;
  case "in_progress":
    return `AutoHub request ${bookingNumber} is now in progress.`;
  case "completed":
    return `AutoHub request ${bookingNumber} has been completed.`;
  case "cancelled":
    return `AutoHub request ${bookingNumber} was cancelled.`;
  default:
    return `AutoHub request ${bookingNumber} status is now ${status}.`;
  }
};

export const notifyClientOnOrderStatusChange = functions.firestore.onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {
    try {
      const orderId = event.params.orderId as string;
      const before = (event.data?.before.data() || {}) as PlainObject;
      const after = (event.data?.after.data() || {}) as PlainObject;

      const beforeStatus = toText(before.status);
      const status = toText(after.status);
      if (!status || beforeStatus === status) return;

      const recipientId = toText(after.userId || after.customerId);
      if (!recipientId) return;

      const orderNumber = toText(after.orderNumber, orderId).toUpperCase();
      const statusLabel = status.replace(/_/g, " ");
      const notificationId = `order_${orderId}_${status}`;

      await db.collection("notifications").doc(notificationId).set({
        userId: recipientId,
        recipientId,
        title: orderStatusNotificationTitle[status] || "Order Update",
        message: orderStatusMessage(status, orderNumber),
        type: status === "cancelled" ? "warning" : "info",
        entityType: "order",
        id: orderId,
        orderId,
        orderNumber,
        status,
        statusLabel,
        link: `/order/${orderId}`,
        read: false,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    } catch (error) {
      functions.logger.error("notifyClientOnOrderStatusChange failed", error);
    }
  }
);

export const notifyClientOnBookingStatusChange = functions.firestore.onDocumentUpdated(
  "service_bookings/{bookingId}",
  async (event) => {
    try {
      const bookingId = event.params.bookingId as string;
      const before = (event.data?.before.data() || {}) as PlainObject;
      const after = (event.data?.after.data() || {}) as PlainObject;

      const beforeStatus = toText(before.status);
      const status = toText(after.status);
      if (!status || beforeStatus === status) return;

      const recipientId = toText(after.userId);
      if (!recipientId) return;

      const bookingNumber = toText(after.bookingNumber, bookingId).toUpperCase();
      const statusLabel = status.replace(/_/g, " ");
      const notificationId = `booking_${bookingId}_${status}`;

      await db.collection("notifications").doc(notificationId).set({
        userId: recipientId,
        recipientId,
        title: bookingStatusNotificationTitle[status] || "AutoHub Update",
        message: bookingStatusMessage(status, bookingNumber),
        type: status === "cancelled" ? "warning" : "success",
        entityType: "booking",
        id: bookingId,
        bookingId,
        bookingNumber,
        status,
        statusLabel,
        link: `/booking/${bookingId}`,
        read: false,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    } catch (error) {
      functions.logger.error("notifyClientOnBookingStatusChange failed", error);
    }
  }
);

export const sendClientTransactionalEmail = onCall(
  {
    timeoutSeconds: 20,
    memory: "256MiB",
    secrets: [RESEND_API_KEY],
    region: "us-central1",
  },
  async (request) => {
    const payload = (request.data || {}) as PlainObject;
    const subject = toText(payload.subject);
    const html = toText(payload.html);
    const kind = toText(payload.kind, "generic");
    const rawRecipients = Array.isArray(payload.recipients) ? payload.recipients : [];

    if (!subject || !html || rawRecipients.length === 0) {
      throw new HttpsError("invalid-argument", "Missing recipients, subject, or html");
    }

    if (html.length > 180000) {
      throw new HttpsError("invalid-argument", "Email content too large");
    }

    const allowedKinds = new Set([
      "verification",
      "order_confirmation",
      "booking_confirmation",
      "booking_admin_copy",
      "welcome",
      "generic",
    ]);

    if (!allowedKinds.has(kind)) {
      throw new HttpsError("invalid-argument", "Unsupported email type");
    }

    if (!request.auth && kind !== "verification") {
      throw new HttpsError("unauthenticated", "Sign in required for this email action");
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    let recipients = rawRecipients
      .map((item) => toText(item).toLowerCase())
      .filter((value) => value && emailRegex.test(value));

    if (kind === "booking_admin_copy") {
      recipients = [ADMIN_EMAIL, GARAGE_EMAIL];
    }

    if (recipients.length === 0 || recipients.length > 5) {
      throw new HttpsError("invalid-argument", "Invalid recipient list");
    }

    const key = RESEND_API_KEY.value();
    if (!key) {
      throw new HttpsError("internal", "RESEND_API_KEY is not configured");
    }

    const sender = process.env.SENDER_EMAIL || "SpareWo <no-reply@sparewo.ug>";

    const response = await postJson(
      "api.resend.com",
      "/emails",
      {
        from: sender,
        to: recipients,
        subject,
        html,
      },
      {
        Authorization: `Bearer ${key}`,
      }
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      functions.logger.error("sendClientTransactionalEmail failed", {
        statusCode: response.statusCode,
        body: response.body,
        kind,
      });
      throw new HttpsError("internal", "Email provider rejected the request");
    }

    functions.logger.info("sendClientTransactionalEmail sent", {
      kind,
      recipientCount: recipients.length,
      actorUid: request.auth?.uid || null,
    });

    return {ok: true};
  }
);

export const sendAdminCommunication = onCall(
  {
    timeoutSeconds: 300,
    memory: "512MiB",
    secrets: [RESEND_API_KEY],
    region: "us-central1",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    await ensureAdminCanSendCommunications(request.auth.uid);

    const payload = (request.data || {}) as PlainObject;
    const title = toText(payload.title);
    const message = toText(payload.message);
    const audience = toText(payload.audience) as AdminCommunicationAudience;
    const type = toText(payload.type, "info") as AdminCommunicationType;
    const link = toCommunicationLink(payload.link);
    const sendEmail = payload.sendEmail === true;
    const recipientIds = Array.isArray(payload.recipientIds) ?
      payload.recipientIds.map((value) => toText(value)).filter(Boolean) :
      [];

    if (!title || !message) {
      throw new HttpsError("invalid-argument", "Title and message are required.");
    }

    if (!ALLOWED_COMMUNICATION_AUDIENCES.has(audience)) {
      throw new HttpsError("invalid-argument", "Unsupported audience.");
    }

    if (!ALLOWED_COMMUNICATION_TYPES.has(type)) {
      throw new HttpsError("invalid-argument", "Unsupported communication type.");
    }

    const needsExplicitRecipients =
      audience === "selected_clients" ||
      audience === "selected_vendors" ||
      audience === "individual_client" ||
      audience === "individual_vendor";

    if (needsExplicitRecipients && recipientIds.length === 0) {
      throw new HttpsError("invalid-argument", "Select at least one recipient.");
    }

    if (
      (audience === "individual_client" || audience === "individual_vendor") &&
      recipientIds.length > 1
    ) {
      throw new HttpsError("invalid-argument", "Only one recipient can be selected.");
    }

    const recipients = await resolveCommunicationRecipients(audience, recipientIds);
    if (recipients.length === 0) {
      return {
        communicationId: null,
        attempted: 0,
        delivered: 0,
        emailAttempted: 0,
        emailDelivered: 0,
      };
    }

    const commRef = db.collection("admin_communications").doc();
    await commRef.set({
      title,
      message,
      type,
      audience,
      link: link || null,
      recipientIds,
      attemptedCount: recipients.length,
      deliveredCount: 0,
      emailAttemptedCount: 0,
      emailDeliveredCount: 0,
      sendEmail,
      status: "processing",
      createdBy: request.auth.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const batchSize = BATCH_WRITE_LIMIT;
    let deliveredCount = 0;

    for (let i = 0; i < recipients.length; i += batchSize) {
      const chunk = recipients.slice(i, i + batchSize);
      const batch = db.batch();
      for (const recipient of chunk) {
        const notificationRef = db.collection("notifications").doc();
        batch.set(notificationRef, {
          userId: recipient.uid,
          recipientId: recipient.uid,
          recipientUid: recipient.uid,
          recipientRole: recipient.role,
          title,
          message,
          type,
          ...(link ? {link} : {}),
          isRead: false,
          read: false,
          source: "admin_communication",
          communicationId: commRef.id,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      deliveredCount += chunk.length;
    }

    let emailAttempted = 0;
    let emailDelivered = 0;
    if (sendEmail) {
      const emails = Array.from(
        new Set(
          recipients
            .map((recipient) => normalizeEmail(recipient.email))
            .filter((email) => email.length > 0)
        )
      );

      const emailChunkSize = 40;
      const emailHtml = renderAudienceCommunicationEmail({
        title,
        message,
        link: link && !/^https?:\/\//i.test(link) ? `${CLIENT_APP_BASE_URL}${link}` : link,
      });

      for (let i = 0; i < emails.length; i += emailChunkSize) {
        const chunk = emails.slice(i, i + emailChunkSize);
        emailAttempted += chunk.length;
        const success = await sendResendEmailBatch({
          to: chunk,
          subject: `[SpareWo] ${title}`,
          html: emailHtml,
        });
        if (success) {
          emailDelivered += chunk.length;
        }
      }
    }

    const status = deliveredCount === recipients.length ? "sent" : "partial";
    await commRef.set(
      {
        deliveredCount,
        emailAttemptedCount: emailAttempted,
        emailDeliveredCount: emailDelivered,
        status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    functions.logger.info("sendAdminCommunication completed", {
      communicationId: commRef.id,
      actorUid: request.auth.uid,
      audience,
      attempted: recipients.length,
      delivered: deliveredCount,
      sendEmail,
      emailAttempted,
      emailDelivered,
    });

    return {
      communicationId: commRef.id,
      attempted: recipients.length,
      delivered: deliveredCount,
      emailAttempted,
      emailDelivered,
    };
  }
);

export const deleteClientAccount = onCall(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
    region: "us-central1",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "You must be signed in to delete your account.");
    }

    const uid = request.auth.uid;
    const authTimeMs = toAuthTimeMillis(request.auth.token.auth_time);
    if (!authTimeMs) {
      throw new HttpsError(
        "failed-precondition",
        "Please sign in again before deleting your account."
      );
    }

    const elapsedSeconds = Math.floor((Date.now() - authTimeMs) / 1000);
    if (elapsedSeconds > ACCOUNT_DELETION_RECENT_AUTH_SECONDS) {
      throw new HttpsError(
        "failed-precondition",
        "Recent login required. Please reauthenticate and try again."
      );
    }

    try {
      const [notificationDocs, orderDocs, bookingDocs] = await Promise.all([
        uniqueDocsByFieldMatch("notifications", ["userId", "recipientId", "recipientUid"], uid),
        uniqueDocsByFieldMatch("orders", ["userId", "customerId"], uid),
        uniqueDocsByFieldMatch("service_bookings", ["userId"], uid),
      ]);

      const [notificationsDeleted, ordersAnonymized, bookingsAnonymized] = await Promise.all([
        deleteDocsInBatches(notificationDocs),
        updateDocsInBatches(orderDocs, () => orderAnonymizationPatch(uid)),
        updateDocsInBatches(bookingDocs, () => bookingAnonymizationPatch(uid)),
      ]);

      await Promise.all([
        recursiveDeleteDocument(`users/${uid}`),
        recursiveDeleteDocument(`clients/${uid}`),
        recursiveDeleteDocument(`settings/${uid}`),
        recursiveDeleteDocument(`user_settings/${uid}`),
      ]);

      const deletionTimestamp = new Date().toISOString();
      await db.collection("account_deletion_audit").add({
        uid,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        deletedAtIso: deletionTimestamp,
        actorUid: uid,
        notificationsDeleted,
        ordersAnonymized,
        bookingsAnonymized,
        deletedCollections: ["users", "clients", "settings", "user_settings"],
      });

      await admin.auth().deleteUser(uid);

      functions.logger.info("deleteClientAccount completed", {
        uid,
        notificationsDeleted,
        ordersAnonymized,
        bookingsAnonymized,
      });

      return {
        ok: true,
        deletedAt: deletionTimestamp,
      };
    } catch (error) {
      functions.logger.error("deleteClientAccount failed", {
        uid,
        error,
      });
      if (error instanceof HttpsError) throw error;
      throw new HttpsError(
        "internal",
        "Failed to delete account. Please try again or contact support."
      );
    }
  }
);

export const mergeClientAccounts = onCall(
  {
    timeoutSeconds: 540,
    memory: "1GiB",
    region: "us-central1",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "You must be signed in to merge accounts.");
    }

    const actorUid = request.auth.uid;
    const authTimeMs = toAuthTimeMillis(request.auth.token.auth_time);
    if (!authTimeMs) {
      throw new HttpsError(
        "failed-precondition",
        "Please sign in again before merging accounts."
      );
    }
    const elapsedSeconds = Math.floor((Date.now() - authTimeMs) / 1000);
    if (elapsedSeconds > ACCOUNT_DELETION_RECENT_AUTH_SECONDS) {
      throw new HttpsError(
        "failed-precondition",
        "Recent login required. Please reauthenticate and try again."
      );
    }

    const payload = (request.data || {}) as PlainObject;
    const targetUid = toText(payload.targetUid, actorUid) || actorUid;
    const sourceUidInput = toText(payload.sourceUid);
    const deleteSourceAuthUser = payload.deleteSourceAuthUser !== false;

    if (sourceUidInput && sourceUidInput === targetUid) {
      throw new HttpsError("invalid-argument", "Source and target accounts cannot be the same.");
    }

    if (actorUid !== targetUid && actorUid !== sourceUidInput) {
      throw new HttpsError(
        "permission-denied",
        "You can only merge into your own account, or merge a newly created duplicate."
      );
    }

    const targetAuthUser = await admin.auth().getUser(targetUid).catch((error) => {
      throw new HttpsError("not-found", `Target account not found: ${error}`);
    });

    const targetEmail = normalizeEmail(targetAuthUser.email);
    if (!targetEmail) {
      throw new HttpsError(
        "failed-precondition",
        "The target account does not have a valid email."
      );
    }

    let sourceUids: string[] = [];
    if (sourceUidInput) {
      sourceUids = [sourceUidInput];
    } else {
      const duplicateDocs = await db
        .collection("users")
        .where("email", "==", targetEmail)
        .limit(20)
        .get();
      sourceUids = duplicateDocs.docs
        .map((doc) => doc.id)
        .filter((uid) => uid !== targetUid);
    }
    sourceUids = Array.from(new Set(sourceUids.filter((uid) => uid.length > 0)));

    if (sourceUids.length === 0) {
      return {
        ok: true,
        targetUid,
        mergedCount: 0,
        mergedSourceUids: [],
      };
    }

    const mergedSourceUids: string[] = [];
    const summary = {
      usersRootMerged: 0,
      clientsRootMerged: 0,
      userSubDocsCopied: 0,
      userSubDocsMerged: 0,
      clientSubDocsCopied: 0,
      clientSubDocsMerged: 0,
      notificationsReassigned: 0,
      ordersReassigned: 0,
      bookingsReassigned: 0,
      sourceAuthUsersDeleted: 0,
    };

    for (const sourceUid of sourceUids) {
      let sourceAuthEmail = "";
      try {
        const sourceAuthUser = await admin.auth().getUser(sourceUid);
        sourceAuthEmail = normalizeEmail(sourceAuthUser.email);
      } catch (error) {
        const code = toText((error as {code?: unknown})?.code);
        if (code !== "auth/user-not-found") {
          throw error;
        }
      }

      if (sourceAuthEmail && sourceAuthEmail !== targetEmail) {
        throw new HttpsError(
          "failed-precondition",
          `Cannot merge ${sourceUid}. Email does not match the target account.`
        );
      }

      const [userMerged, clientMerged] = await Promise.all([
        mergeRootDocument({
          sourcePath: `users/${sourceUid}`,
          targetPath: `users/${targetUid}`,
          targetEmail,
          mergedFromUid: sourceUid,
        }),
        mergeRootDocument({
          sourcePath: `clients/${sourceUid}`,
          targetPath: `clients/${targetUid}`,
          targetEmail,
          mergedFromUid: sourceUid,
        }),
      ]);
      if (userMerged) summary.usersRootMerged += 1;
      if (clientMerged) summary.clientsRootMerged += 1;

      const userSubcollections = ["cars", "addresses", "cart", "wishlist", "tokens"];
      for (const subcollection of userSubcollections) {
        const subSummary = await mergeSubcollectionIntoTarget({
          sourceParentPath: `users/${sourceUid}`,
          targetParentPath: `users/${targetUid}`,
          subcollection,
        });
        summary.userSubDocsCopied += subSummary.copied;
        summary.userSubDocsMerged += subSummary.merged;
      }

      const clientSubcollections = ["cart", "cars", "addresses", "wishlist", "tokens"];
      for (const subcollection of clientSubcollections) {
        const subSummary = await mergeSubcollectionIntoTarget({
          sourceParentPath: `clients/${sourceUid}`,
          targetParentPath: `clients/${targetUid}`,
          subcollection,
        });
        summary.clientSubDocsCopied += subSummary.copied;
        summary.clientSubDocsMerged += subSummary.merged;
      }

      const [notificationsReassigned, ordersReassigned, bookingsReassigned] = await Promise.all([
        reassignUidReferences(
          "notifications",
          ["userId", "recipientId", "recipientUid"],
          sourceUid,
          targetUid
        ),
        reassignUidReferences("orders", ["userId", "customerId"], sourceUid, targetUid),
        reassignUidReferences("service_bookings", ["userId"], sourceUid, targetUid),
      ]);
      summary.notificationsReassigned += notificationsReassigned;
      summary.ordersReassigned += ordersReassigned;
      summary.bookingsReassigned += bookingsReassigned;

      await Promise.all([
        safeRecursiveDeleteDocument(`users/${sourceUid}`),
        safeRecursiveDeleteDocument(`clients/${sourceUid}`),
        safeRecursiveDeleteDocument(`settings/${sourceUid}`),
        safeRecursiveDeleteDocument(`user_settings/${sourceUid}`),
      ]);

      if (deleteSourceAuthUser && sourceUid !== targetUid) {
        try {
          await admin.auth().deleteUser(sourceUid);
          summary.sourceAuthUsersDeleted += 1;
        } catch (error) {
          const code = toText((error as {code?: unknown})?.code);
          if (code !== "auth/user-not-found") {
            throw error;
          }
        }
      }

      mergedSourceUids.push(sourceUid);
    }

    await db.collection("account_merge_audit").add({
      actorUid,
      targetUid,
      targetEmail,
      mergedSourceUids,
      mergedCount: mergedSourceUids.length,
      deleteSourceAuthUser,
      ...summary,
      mergedAt: admin.firestore.FieldValue.serverTimestamp(),
      mergedAtIso: new Date().toISOString(),
    });

    functions.logger.info("mergeClientAccounts completed", {
      actorUid,
      targetUid,
      mergedSourceUids,
      summary,
    });

    return {
      ok: true,
      actorUid,
      targetUid,
      targetEmail,
      mergedCount: mergedSourceUids.length,
      mergedSourceUids,
      ...summary,
      mergedAt: new Date().toISOString(),
    };
  }
);
