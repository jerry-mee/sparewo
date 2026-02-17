import { NextResponse } from 'next/server';
import { db, auth } from '@/lib/firebase/admin';
import { isAdministratorRole, normalizeRole } from '@/lib/auth/roles';
import { getProductApprovedEmailHtml, sendEmail } from '@/lib/mail';

interface ApproveProductBody {
  productId?: string;
  retailPrice?: number;
}

export async function POST(req: Request) {
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const token = authHeader.split('Bearer ')[1];
    const decodedToken = await auth.verifyIdToken(token);

    const adminRef = db.collection('adminUsers').doc(decodedToken.uid);
    const adminSnap = await adminRef.get();
    const callerRole = normalizeRole(adminSnap.data()?.role);

    if (!adminSnap.exists || !isAdministratorRole(callerRole)) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const body = (await req.json()) as ApproveProductBody;
    const productId = body.productId?.trim();
    const retailPrice = Number(body.retailPrice);

    if (!productId) {
      return NextResponse.json({ error: 'Product ID is required' }, { status: 400 });
    }

    if (!Number.isFinite(retailPrice) || retailPrice <= 0) {
      return NextResponse.json({ error: 'Retail price must be greater than zero' }, { status: 400 });
    }

    const now = new Date();

    const result = await db.runTransaction(async (transaction) => {
      const vendorProductRef = db.collection('vendor_products').doc(productId);
      const vendorProductSnap = await transaction.get(vendorProductRef);

      if (!vendorProductSnap.exists) {
        throw new Error('Vendor product not found');
      }

      const vendorProduct = vendorProductSnap.data() || {};

      const existingCatalogProductId = typeof vendorProduct.catalogProductId === 'string'
        ? vendorProduct.catalogProductId
        : null;

      const catalogRef = existingCatalogProductId
        ? db.collection('catalog_products').doc(existingCatalogProductId)
        : db.collection('catalog_products').doc();

      const catalogSnap = await transaction.get(catalogRef);

      const catalogPayload = {
        partName: vendorProduct.partName || vendorProduct.name || 'N/A',
        description: vendorProduct.description || '',
        brand: vendorProduct.brand || 'N/A',
        unitPrice: retailPrice,
        stockQuantity: vendorProduct.stockQuantity || vendorProduct.quantity || 0,
        imageUrls: vendorProduct.images || vendorProduct.imageUrls || [],
        partNumber: vendorProduct.partNumber || null,
        condition: vendorProduct.condition || 'New',
        category: vendorProduct.category || 'Uncategorized',
        categories: Array.isArray(vendorProduct.categories)
          ? vendorProduct.categories
          : [vendorProduct.category || 'Uncategorized'],
        updatedAt: now,
        isActive: true,
        isFeatured: false,
      };

      if (catalogSnap.exists) {
        transaction.update(catalogRef, catalogPayload);
      } else {
        transaction.set(catalogRef, {
          ...catalogPayload,
          createdAt: now,
        });
      }

      transaction.update(vendorProductRef, {
        status: 'approved',
        showInCatalog: true,
        approvedAt: now,
        updatedAt: now,
        catalogProductId: catalogRef.id,
        rejectionReason: null,
      });

      return {
        vendorId: vendorProduct.vendorId as string | undefined,
        productName: (vendorProduct.name || vendorProduct.partName || 'your product') as string,
      };
    });

    if (result.vendorId) {
      await db.collection('notifications').add({
        userId: result.vendorId,
        recipientId: result.vendorId,
        vendorId: result.vendorId,
        title: 'Product Approved',
        message: `Your product "${result.productName}" has been approved and added to the SpareWo catalog.`,
        type: 'success',
        link: '/products',
        read: false,
        createdAt: now,
        updatedAt: now,
      });

      const vendorSnap = await db.collection('vendors').doc(result.vendorId).get();
      const vendorData = vendorSnap.data();
      const vendorEmail = typeof vendorData?.email === 'string' ? vendorData.email : null;
      const vendorName = (vendorData?.businessName || vendorData?.name || 'Partner') as string;

      if (vendorEmail) {
        await sendEmail({
          to: vendorEmail,
          subject: 'Your SpareWo Product Has Been Approved',
          html: getProductApprovedEmailHtml(vendorName, result.productName),
        });
      }
    }

    return NextResponse.json({ success: true });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Internal Server Error';
    console.error('Approve product API error:', error);
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
