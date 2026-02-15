// functions/src/index.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

/**
 * FINAL, SIMPLIFIED VERSION: A one-time-use HTTP Request function.
 *
 * To run, set permissions to "Allow public access" and then simply
 * open the trigger URL in your browser.
 */
export const migrateApprovedProductsToCatalog = functions.https.onRequest(async (request, response) => {
    // Manually set CORS headers to allow browser invocation.
    response.set('Access-Control-Allow-Origin', '*');

    if (request.method === 'OPTIONS') {
        // Handle preflight CORS requests.
        response.set('Access-Control-Allow-Methods', 'GET');
        response.set('Access-Control-Allow-Headers', 'Content-Type');
        response.status(204).send('');
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

        // Filter for documents that are missing the 'catalogProductId' field.
        const productsToMigrate = snapshot.docs.filter(doc => !doc.data().catalogProductId);

        if (productsToMigrate.length === 0) {
            functions.logger.info("All approved products have already been migrated.");
            response.status(200).send("SUCCESS: All approved products have already been migrated.");
            return;
        }

        const batch = db.batch();
        let processedCount = 0;

        productsToMigrate.forEach(doc => {
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
                    categories: Array.isArray(vendorProduct.categories) ? vendorProduct.categories : [vendorProduct.category || "Uncategorized"],
                    createdAt: vendorProduct.createdAt || admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    isActive: true,
                    isFeatured: false,
                });

                batch.update(doc.ref, { catalogProductId: newCatalogDocRef.id });
                processedCount++;
            } else {
                 functions.logger.warn(`Skipping product ${doc.id} due to zero price.`);
            }
        });

        await batch.commit();

        functions.logger.info(`Successfully migrated ${processedCount} products.`);
        response.status(200).send(`SUCCESS: Successfully migrated ${processedCount} products to the catalog.`);

    } catch (error) {
        functions.logger.error("Migration failed:", error);
        response.status(500).send("ERROR: Migration failed. Check the function logs in the Firebase console for details.");
    }
});