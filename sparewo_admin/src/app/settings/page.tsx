'use client';

import React, { useState } from 'react';
import { Save, RefreshCw, Database, Activity } from 'lucide-react';
import Breadcrumb from '@/components/Breadcrumbs/Breadcrumb';

interface AppSettings {
  siteName: string;
  siteDescription: string;
  contactEmail: string;
  supportPhone: string;
  vendorApprovalRequired: boolean;
  productApprovalRequired: boolean;
  maintenanceMode: boolean;
}

export default function SettingsPage() {
  const [settings, setSettings] = useState<AppSettings>({
    siteName: 'SpareWo Admin',
    siteDescription: 'Admin dashboard for SpareWo platform',
    contactEmail: 'admin@sparewo.ug',
    supportPhone: '+256 712345678',
    vendorApprovalRequired: true,
    productApprovalRequired: true,
    maintenanceMode: false
  });
  
  const [loading, setLoading] = useState(false);

  const saveSettings = async () => {
    setLoading(true);
    
    try {
      // In a real implementation, you would save to Firebase here
      await new Promise(resolve => setTimeout(resolve, 1000));
      alert('Settings saved successfully');
    } catch (error) {
      console.error('Failed to save settings:', error);
      alert('Failed to save settings');
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Breadcrumb pageName="Settings" />
      
      <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
        {/* System Status */}
        <div className="rounded-lg bg-white p-6 shadow-md dark:bg-boxdark">
          <h2 className="mb-4 text-lg font-semibold">System Status</h2>
          
          <div className="mb-6">
            <div className="flex items-center justify-between mb-2">
              <span>Database Connection</span>
              <span className="text-success">Connected</span>
            </div>
            
            <div className="flex items-center justify-between mb-2">
              <span>Storage Connection</span>
              <span className="text-success">Connected</span>
            </div>
            
            <div className="flex items-center justify-between mb-2">
              <span>Authentication Connection</span>
              <span className="text-success">Connected</span>
            </div>
            
            <div className="flex items-center justify-between mt-4 text-sm">
              <span>Last Checked</span>
              <span>{new Date().toLocaleString()}</span>
            </div>
          </div>
          
          <h2 className="mb-4 text-lg font-semibold">Sync Status</h2>
          
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <span className="font-medium">Vendors</span>
                <div className="text-sm">Last synced: {new Date().toLocaleString()}</div>
              </div>
              
              <button className="px-4 py-2 border border-gray-300 rounded-lg flex items-center gap-2 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800">
                <RefreshCw size={16} />
                Sync
              </button>
            </div>
            
            <div className="flex items-center justify-between">
              <div>
                <span className="font-medium">Products</span>
                <div className="text-sm">Last synced: {new Date().toLocaleString()}</div>
              </div>
              
              <button className="px-4 py-2 border border-gray-300 rounded-lg flex items-center gap-2 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800">
                <RefreshCw size={16} />
                Sync
              </button>
            </div>
            
            <div className="flex items-center justify-between">
              <div>
                <span className="font-medium">Orders</span>
                <div className="text-sm">Last synced: {new Date().toLocaleString()}</div>
              </div>
              
              <button className="px-4 py-2 border border-gray-300 rounded-lg flex items-center gap-2 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800">
                <RefreshCw size={16} />
                Sync
              </button>
            </div>
          </div>
        </div>
        
        {/* Traffic Overview */}
        <div className="rounded-lg bg-white p-6 shadow-md dark:bg-boxdark">
          <h2 className="mb-4 text-lg font-semibold">Traffic Overview</h2>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 rounded-lg bg-gray-50 dark:bg-gray-800">
              <div className="text-3xl font-bold text-primary">12,543</div>
              <div className="text-sm">Total Visitors</div>
            </div>
            
            <div className="p-4 rounded-lg bg-gray-50 dark:bg-gray-800">
              <div className="text-3xl font-bold text-success">286</div>
              <div className="text-sm">Active Users</div>
            </div>
            
            <div className="p-4 rounded-lg bg-gray-50 dark:bg-gray-800">
              <div className="text-3xl font-bold text-warning">45,921</div>
              <div className="text-sm">Page Views</div>
            </div>
            
            <div className="p-4 rounded-lg bg-gray-50 dark:bg-gray-800">
              <div className="text-3xl font-bold text-info">3m 7s</div>
              <div className="text-sm">Avg. Time on Site</div>
            </div>
          </div>
          
          <div className="mt-4 flex items-center justify-between">
            <span className="text-sm">Data refreshed automatically every 5 minutes</span>
            <button className="px-4 py-2 border border-gray-300 rounded-lg flex items-center gap-2 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800">
              <RefreshCw size={16} />
              Refresh Now
            </button>
          </div>
        </div>
        
        {/* App Settings */}
        <div className="md:col-span-2 rounded-lg bg-white p-6 shadow-md dark:bg-boxdark">
          <h2 className="mb-6 text-lg font-semibold">SpareWo Application Settings</h2>
          
          <form onSubmit={(e) => { e.preventDefault(); saveSettings(); }}>
            <div className="grid gap-6 md:grid-cols-2">
              <div>
                <label className="block mb-2 text-sm font-medium" htmlFor="siteName">Site Name</label>
                <input
                  id="siteName"
                  type="text"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-primary dark:border-gray-700 dark:bg-gray-800"
                  value={settings.siteName}
                  onChange={(e) => setSettings({...settings, siteName: e.target.value})}
                />
              </div>
              
              <div>
                <label className="block mb-2 text-sm font-medium" htmlFor="siteDescription">Site Description</label>
                <input
                  id="siteDescription"
                  type="text"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-primary dark:border-gray-700 dark:bg-gray-800"
                  value={settings.siteDescription}
                  onChange={(e) => setSettings({...settings, siteDescription: e.target.value})}
                />
              </div>
              
              <div>
                <label className="block mb-2 text-sm font-medium" htmlFor="contactEmail">Contact Email</label>
                <input
                  id="contactEmail"
                  type="email"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-primary dark:border-gray-700 dark:bg-gray-800"
                  value={settings.contactEmail}
                  onChange={(e) => setSettings({...settings, contactEmail: e.target.value})}
                />
              </div>
              
              <div>
                <label className="block mb-2 text-sm font-medium" htmlFor="supportPhone">Support Phone</label>
                <input
                  id="supportPhone"
                  type="tel"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-primary dark:border-gray-700 dark:bg-gray-800"
                  value={settings.supportPhone}
                  onChange={(e) => setSettings({...settings, supportPhone: e.target.value})}
                />
              </div>
            </div>
            
            <div className="mt-6">
              <h3 className="mb-3 font-medium">Approval Settings</h3>
              
              <div className="space-y-3">
                <div className="flex items-center">
                  <input
                    id="vendorApproval"
                    type="checkbox"
                    className="mr-2 h-4 w-4"
                    checked={settings.vendorApprovalRequired}
                    onChange={(e) => setSettings({...settings, vendorApprovalRequired: e.target.checked})}
                  />
                  <label htmlFor="vendorApproval">Require admin approval for new vendor registrations</label>
                </div>
                
                <div className="flex items-center">
                  <input
                    id="productApproval"
                    type="checkbox"
                    className="mr-2 h-4 w-4"
                    checked={settings.productApprovalRequired}
                    onChange={(e) => setSettings({...settings, productApprovalRequired: e.target.checked})}
                  />
                  <label htmlFor="productApproval">Require admin approval for new product listings</label>
                </div>
              </div>
            </div>
            
            <div className="mt-6">
              <h3 className="mb-3 font-medium">Maintenance</h3>
              
              <div className="flex items-center">
                <input
                  id="maintenanceMode"
                  type="checkbox"
                  className="mr-2 h-4 w-4"
                  checked={settings.maintenanceMode}
                  onChange={(e) => setSettings({...settings, maintenanceMode: e.target.checked})}
                />
                <label htmlFor="maintenanceMode">Enable maintenance mode (all users except admins will see a maintenance page)</label>
              </div>
            </div>
            
            <div className="mt-6 flex justify-end">
              <button
                type="submit"
                className="px-6 py-2 bg-primary text-white rounded-lg flex items-center gap-2 hover:bg-primary-dark"
                disabled={loading}
              >
                {loading ? (
                  <>
                    <div className="h-4 w-4 animate-spin rounded-full border-2 border-dashed border-white"></div>
                    Saving...
                  </>
                ) : (
                  <>
                    <Save size={16} />
                    Save Settings
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    </>
  );
}