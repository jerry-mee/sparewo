'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import {
    productService,
    ProductStatus,
    Product,
    Unsubscribe,
    Timestamp // Import Timestamp if used
} from '@/services/firebase.service';
import { Eye, Edit, Filter, Package, Check, X, Plus, Grid3X3, List, Search } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import LoadingScreen from '@/components/LoadingScreen';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Pagination, PaginationContent, PaginationEllipsis, PaginationItem, PaginationLink, PaginationNext, PaginationPrevious } from "@/components/ui/pagination";
// Removed duplicate Product interface

interface FilterOptions {
  status: ProductStatus | 'all';
  searchTerm: string;
}

export default function CatalogsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [catalogType, setCatalogType] = useState<'general' | 'store'>('general');
  const [filters, setFilters] = useState<FilterOptions>({ status: 'all', searchTerm: '' });
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('list'); // Corrected state name usage
  const [statusUpdating, setStatusUpdating] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{message: string, type: 'success' | 'error'} | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(20);

  useEffect(() => {
    let unsubscribe: Unsubscribe = () => {};
    try {
      setLoading(true);
      unsubscribe = productService.listenToProducts(
        (productsList: Product[]) => { setProducts(productsList || []); setLoading(false); },
        (err: Error) => { console.error("Listener error:", err); /* ... */ }
      );
    } catch (error: any) { /* ... */ }
    return () => { unsubscribe(); };
  }, []);

  const filteredProducts = (() => { /* ... filtering logic ensuring properties exist ... */
        let filtered = products;
        if (catalogType === 'store') filtered = filtered.filter(p => p && p.status === ProductStatus.APPROVED);
        if (filters.status !== 'all') filtered = filtered.filter(p => p && p.status === filters.status);
        if (filters.searchTerm) { /* ... search logic ... */ }
        return filtered;
   })();

  const totalItems = filteredProducts.length;
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  const currentItems = filteredProducts.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

  const handleStatusChange = async (id: string, newStatus: string) => { /* ... implementation ... */ };
  const handleFilterChange = (key: keyof FilterOptions, value: string | ProductStatus) => { /* ... */ };

  // --- Helper Functions (Ensure correct return types) ---
  const formatUGX = (amount: number): string => {
      return new Intl.NumberFormat('en-UG', { style: 'currency', currency: 'UGX', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(amount);
  };
  const getStatusClass = (status: ProductStatus | string): string => {
      switch (status) { /* ... cases using ProductStatus enum ... */ default: return 'bg-gray-100...'; }
  };
  const getStatusIcon = (status: ProductStatus | string): React.ReactNode => {
      switch (status) { /* ... cases using ProductStatus enum ... */ default: return null; }
  };

  if (loading) { return <LoadingScreen />; }

  // --- RENDER ---
  return (
    <div className="space-y-6">
        {/* Header, Controls, Feedback */}
        {/* ... */}

        {/* Content Area */}
        {currentItems.length === 0 ? ( /* Empty State */
             <div className="flex flex-col items-center justify-center ..."> {/* Fixed closing tag */}
                 <Package size={48} className="..." />
                 <h3 className="...">No products found</h3>
                 <p className="..."> {filters.searchTerm ? 'Try adjusting search criteria.' : 'No products match filters.'} </p>
             </div>
         ) : viewMode === 'list' ? ( // Corrected ternary syntax
            // --- List View ---
            <div className="rounded-lg border border-border ...">
                 {/* ... Table ... */}
                 {/* Pagination - Fixed syntax errors */}
                 {totalPages > 1 && (
                    <div className="border-t border-border px-4 py-3 dark:border-gray-700">
                         <Pagination>
                            <PaginationContent>
                                <PaginationItem>
                                    <PaginationPrevious href="#" onClick={(e: React.MouseEvent<HTMLAnchorElement>) => { e.preventDefault(); setCurrentPage(p => Math.max(1, p - 1)); }} aria-disabled={currentPage === 1} className={currentPage === 1 ? "pointer-events-none opacity-50" : ""} />
                                </PaginationItem>
                                {/* Simplified Page Number Logic (Example) */}
                                {[...Array(totalPages)].map((_, index) => { const pageNum = index + 1; const showPage = Math.abs(pageNum - currentPage) <= 1 || pageNum === 1 || pageNum === totalPages; const showEllipsis = (pageNum === 2 && currentPage > 3) || (pageNum === totalPages - 1 && currentPage < totalPages - 2); if (showEllipsis) { return <PaginationItem key={`ellipsis-${pageNum}`}><PaginationEllipsis /></PaginationItem>; } if (showPage) { return (<PaginationItem key={pageNum}><PaginationLink href="#" onClick={(e: React.MouseEvent<HTMLAnchorElement>) => { e.preventDefault(); setCurrentPage(pageNum); }} isActive={currentPage === pageNum}>{pageNum}</PaginationLink></PaginationItem>); } return null; })}
                                <PaginationItem>
                                    <PaginationNext href="#" onClick={(e: React.MouseEvent<HTMLAnchorElement>) => { e.preventDefault(); setCurrentPage(p => Math.min(totalPages, p + 1)); }} aria-disabled={currentPage === totalPages} className={currentPage === totalPages ? "pointer-events-none opacity-50" : ""} />
                                </PaginationItem>
                            </PaginationContent>
                         </Pagination>
                    </div>
                 )}
             </div> // Closing List View div
         ) : (
             // --- Grid View ---
            <> {/* Added Fragment */}
                <div className="grid ...">
                    {currentItems.map((product: Product) => (
                        <div key={product.id} className="...">
                            {/* ... Grid Item content ensuring all properties exist ... */}
                        </div>
                    ))}
                </div>
                {/* Pagination for Grid View - Fixed syntax errors */}
                {totalPages > 1 && (
                    <div className="mt-6">
                         <Pagination>
                            <PaginationContent>
                                <PaginationItem>
                                    <PaginationPrevious href="#" onClick={(e: React.MouseEvent<HTMLAnchorElement>) => { e.preventDefault(); setCurrentPage(p => Math.max(1, p - 1)); }} aria-disabled={currentPage === 1} className={currentPage === 1 ? "pointer-events-none opacity-50" : ""} />
                                </PaginationItem>
                                 {/* Simplified Page Number Logic (Example) */}
                                 {[...Array(totalPages)].map((_, index) => { const pageNum = index + 1; const showPage = Math.abs(pageNum - currentPage) <= 1 || pageNum === 1 || pageNum === totalPages; const showEllipsis = (pageNum === 2 && currentPage > 3) || (pageNum === totalPages - 1 && currentPage < totalPages - 2); if (showEllipsis) { return <PaginationItem key={`ellipsis-${pageNum}`}><PaginationEllipsis /></PaginationItem>; } if (showPage) { return (<PaginationItem key={pageNum}><PaginationLink href="#" onClick={(e: React.MouseEvent<HTMLAnchorElement>) => { e.preventDefault(); setCurrentPage(pageNum); }} isActive={currentPage === pageNum}>{pageNum}</PaginationLink></PaginationItem>); } return null; })}
                                <PaginationItem>
                                    <PaginationNext href="#" onClick={(e: React.MouseEvent<HTMLAnchorElement>) => { e.preventDefault(); setCurrentPage(p => Math.min(totalPages, p + 1)); }} aria-disabled={currentPage === totalPages} className={currentPage === totalPages ? "pointer-events-none opacity-50" : ""} />
                                </PaginationItem>
                            </PaginationContent>
                         </Pagination>
                    </div>
                )}
            </> // Closing Fragment
        )}
    </div> // Closing main div
  ); // Closing return
} // Closing component function