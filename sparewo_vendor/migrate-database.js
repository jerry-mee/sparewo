// migrate-database.js
// Script to restructure SpareWo database

const admin = require('firebase-admin');
const readline = require('readline');

// Initialize Firebase Admin
// Using the exact path you provided
const serviceAccount = require('/Users/jeremy/Development/sparewo/sparewo_vendor/sparewoapp-firebase-adminsdk-8eepq-65201d1655.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Terminal interface for confirmation
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function migrateDatabase() {
  console.log('\n🚀 SpareWo Database Migration Script');
  console.log('====================================\n');
  
  console.log('This script will:');
  console.log('✅ KEEP: car_brand, car_models, vendors, users, userRoles');
  console.log('❌ DELETE: ALL vendor_products');
  console.log('✨ CREATE: New collections for proper vendor/client separation');
  console.log('👤 ADD: Jeremy as Super Admin\n');
  
  const confirm = await question('Are you sure you want to proceed? (yes/no): ');
  
  if (confirm.toLowerCase() !== 'yes') {
    console.log('Migration cancelled.');
    process.exit(0);
  }

  try {
    console.log('\n📊 Starting migration...\n');

    // Step 1: Delete all vendor_products
    console.log('1️⃣ Deleting all vendor_products...');
    const vendorProducts = await db.collection('vendor_products').get();
    const batch1 = db.batch();
    let deleteCount = 0;
    
    vendorProducts.forEach(doc => {
      batch1.delete(doc.ref);
      deleteCount++;
    });
    
    if (deleteCount > 0) {
      await batch1.commit();
      console.log(`   ✅ Deleted ${deleteCount} vendor products\n`);
    } else {
      console.log('   ℹ️ No vendor products to delete\n');
    }

    // Step 2: Create Super Admin account
    console.log('2️⃣ Creating Super Admin account for Jeremy...');
    
    // First, create the Firebase Auth user (if not exists)
    let uid;
    try {
      const userRecord = await admin.auth().getUserByEmail('jeremy@matchstick.ug');
      uid = userRecord.uid;
      console.log('   ℹ️ User already exists in Firebase Auth');
    } catch (error) {
      // User doesn't exist, create it
      const newUser = await admin.auth().createUser({
        email: 'jeremy@matchstick.ug',
        displayName: 'Jeremy Buyi',
        password: 'TempPassword123!' // You'll need to reset this
      });
      uid = newUser.uid;
      console.log('   ✅ Created new Firebase Auth user');
    }
    
    // Add to adminUsers collection
    await db.collection('adminUsers').doc(uid).set({
      email: 'jeremy@matchstick.ug',
      name: 'Jeremy Buyi',
      role: 'super_admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Also add to user_roles for redundancy
    await db.collection('user_roles').doc(uid).set({
      uid: uid,
      role: 'super_admin',
      isAdmin: true,
      permissions: ['all'],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('   ✅ Super Admin account created successfully');
    console.log('   ⚠️  IMPORTANT: Reset your password by clicking "Forgot Password" on login\n');

    // Step 3: Create sample catalog_products structure with specific years
    console.log('3️⃣ Creating catalog_products collection structure...');
    const catalogSample = {
      partName: 'Sample Brake Pad',
      partNumber: 'BRK-001',
      brand: 'Toyota',
      description: 'This is a sample product. Delete after testing.',
      retailPrice: 150000,
      currency: 'UGX',
      availability: 'in_stock',
      estimatedDelivery: '2-3 days',
      categories: ['Brakes', 'Safety'],
      tags: ['brake', 'pad', 'toyota'],
      images: [],
      compatibility: [{
        brand: 'Toyota',
        model: 'Camry',
        compatibleYears: [1994, 1998, 2003, 2009] // Specific years as requested
      }, {
        brand: 'Toyota',
        model: 'Corolla',
        compatibleYears: [1994, 1998, 2003, 2009]
      }],
      isActive: true,
      featured: false,
      popularity: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await db.collection('catalog_products').doc('sample').set(catalogSample);
    console.log('   ✅ Created catalog_products with sample document (includes specific years)\n');

    // Step 4: Create product_mappings structure
    console.log('4️⃣ Creating product_mappings collection structure...');
    const mappingSample = {
      catalogProductId: 'sample',
      vendorProductId: 'will-be-linked-later',
      vendorId: 'vendor-id-here',
      qualityScore: 85,
      priceScore: 90,
      reliabilityScore: 88,
      overallScore: 87.67,
      isPreferred: true,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await db.collection('product_mappings').doc('sample').set(mappingSample);
    console.log('   ✅ Created product_mappings with sample document\n');

    // Step 5: Create order_fulfillments structure
    console.log('5️⃣ Creating order_fulfillments collection structure...');
    const fulfillmentSample = {
      orderId: 'ORDER-001',
      orderItemId: 'ITEM-001',
      vendorId: 'vendor-id-here',
      vendorProductId: 'product-id-here',
      vendorName: 'Vendor Name',
      quantityRequested: 1,
      quantityConfirmed: 0,
      quantityDelivered: 0,
      unitCost: 120000,
      totalCost: 120000,
      status: 'pending',
      expectedDelivery: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 3 * 24 * 60 * 60 * 1000) // 3 days from now
      ),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await db.collection('order_fulfillments').doc('sample').set(fulfillmentSample);
    console.log('   ✅ Created order_fulfillments with sample document\n');

    // Step 6: Create vendor_metrics structure
    console.log('6️⃣ Creating vendor_metrics collection structure...');
    const metricsSample = {
      vendorId: 'vendor-id-here',
      totalOrders: 0,
      completedOrders: 0,
      rejectedOrders: 0,
      qualityScore: 0,
      defectRate: 0,
      returnRate: 0,
      onTimeDeliveryRate: 0,
      averageLeadTime: 0,
      totalRevenue: 0,
      averageOrderValue: 0,
      period: 'monthly',
      periodStart: admin.firestore.Timestamp.now(),
      periodEnd: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days from now
      ),
      calculatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await db.collection('vendor_metrics').doc('sample').set(metricsSample);
    console.log('   ✅ Created vendor_metrics with sample document\n');

    // Step 7: Initialize dashboard_stats for existing vendors
    console.log('7️⃣ Initializing dashboard_stats for existing vendors...');
    const vendors = await db.collection('vendors').get();
    const batch2 = db.batch();
    let vendorCount = 0;
    
    vendors.forEach(vendor => {
      const statsDoc = {
        vendorId: vendor.id,
        totalProducts: 0,
        activeProducts: 0,
        totalOrders: 0,
        activeOrders: 0,
        totalSales: 0,
        todaySales: 0,
        averageRating: 0,
        totalReviews: 0,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      };
      
      batch2.set(db.collection('dashboard_stats').doc(vendor.id), statsDoc);
      vendorCount++;
    });
    
    if (vendorCount > 0) {
      await batch2.commit();
      console.log(`   ✅ Initialized stats for ${vendorCount} vendors\n`);
    }

    // Step 8: Verify preserved collections
    console.log('8️⃣ Verifying preserved collections...');
    const carBrands = await db.collection('car_brand').limit(5).get();
    const carModels = await db.collection('car_models').limit(5).get();
    const vendorsCheck = await db.collection('vendors').get();
    const userRoles = await db.collection('userRoles').get();
    
    console.log(`   ✅ car_brand: ${carBrands.size} documents (preserved)`);
    console.log(`   ✅ car_models: ${carModels.size} documents (preserved)`);
    console.log(`   ✅ vendors: ${vendorsCheck.size} documents (preserved)`);
    console.log(`   ✅ userRoles: ${userRoles.size} documents (preserved)\n`);

    console.log('🎉 Migration completed successfully!\n');
    console.log('Next steps:');
    console.log('1. Go to https://admin.sparewo.ug and click "Forgot Password"');
    console.log('2. Reset your password for jeremy@matchstick.ug');
    console.log('3. Update your Firestore security rules');
    console.log('4. Your vendor app is ready with the new structure');
    console.log('5. Update your admin dashboard to create catalog_products when approving');
    console.log('6. Update your client app to read from catalog_products\n');

  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    process.exit(1);
  } finally {
    rl.close();
    process.exit(0);
  }
}

// Run the migration
migrateDatabase();