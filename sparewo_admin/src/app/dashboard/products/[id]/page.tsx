// src/app/dashboard/products/[id]/page.tsx

"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import { getProductById, updateProductStatus } from "@/lib/firebase/products";
import { auth } from "@/lib/firebase/config";
import { getVendorById } from "@/lib/firebase/vendors";
import { Product } from "@/lib/types/product";
import { Vendor } from "@/lib/types/vendor";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Textarea } from "@/components/ui/textarea";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { ProductStatusBadge } from "@/components/product/product-status-badge";
import { VendorStatusBadge } from "@/components/vendor/vendor-status-badge";
import { formatCurrency, formatDateTime } from "@/lib/utils";
import Link from "next/link";
import { CheckCircle, XCircle, ArrowLeft } from "lucide-react";
import { toast } from "sonner";
import Image from "next/image";

export default function ProductDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [product, setProduct] = useState<Product | null>(null);
  const [vendor, setVendor] = useState<Vendor | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeImage, setActiveImage] = useState<string | null>(null);
  
  const [dialogOpen, setDialogOpen] = useState(false);
  const [dialogAction, setDialogAction] = useState<"approve" | "reject">("approve");
  const [rejectionReason, setRejectionReason] = useState("");
  const [retailPrice, setRetailPrice] = useState<number | string>("");

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const productData = await getProductById(id as string);
        setProduct(productData);
        
        if (productData) {
          const productImages = productData.images || productData.imageUrls || [];
          if (productImages.length > 0) {
            setActiveImage(productImages[0]);
          }
          setRetailPrice(productData.price || productData.unitPrice || "");
        }
        
        if (productData && productData.vendorId) {
          const vendorData = await getVendorById(productData.vendorId);
          setVendor(vendorData);
        }
      } catch (error) {
        console.error("Error fetching product data:", error);
        toast.error("Failed to load product data");
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [id]);

  const openApproveDialog = () => {
    if (!product) return;
    setDialogAction("approve");
    setRetailPrice(product.price || product.unitPrice || "");
    setDialogOpen(true);
  };

  const openRejectDialog = () => {
    setDialogAction("reject");
    setRejectionReason("");
    setDialogOpen(true);
  };

  const handleConfirm = async () => {
    if (!product) return;
    
    try {
      if (dialogAction === "approve") {
        const price = Number(retailPrice);
        if (isNaN(price) || price <= 0) {
          toast.error("Please enter a valid retail price.");
          return;
        }

        const token = await auth.currentUser?.getIdToken();
        if (!token) {
          toast.error("You are not authenticated.");
          return;
        }

        const response = await fetch("/api/admin/products/approve", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            productId: product.id,
            retailPrice: price,
          }),
        });

        const payload = await response.json();
        if (!response.ok || payload?.success !== true) {
          throw new Error(payload?.error || "Failed to approve product");
        }
        
        setProduct({ ...product, status: "approved", showInCatalog: true });
        toast.success(`Product ${product.name || product.partName} approved and added to catalog`);
      } else {
        await updateProductStatus(product.id, "rejected", false, rejectionReason);
        setProduct({ 
          ...product, 
          status: "rejected", 
          showInCatalog: false,
          rejectionReason 
        });
        toast.success(`Product ${product.name || product.partName} has been rejected`);
      }
    } catch (error) {
      console.error(`Error ${dialogAction}ing product:`, error);
      toast.error(`Failed to ${dialogAction} product`);
    } finally {
      setDialogOpen(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-96">
        <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="text-center py-12">
        <h2 className="text-xl font-semibold mb-2">Product Not Found</h2>
        <p className="text-muted-foreground mb-6">
          The product you are looking for does not exist or has been removed.
        </p>
        <Link href="/dashboard/products">
          <Button>
            <ArrowLeft size={16} className="mr-2" />
            Back to Products
          </Button>
        </Link>
      </div>
    );
  }

  const productImages = Array.isArray(product.images) ? product.images : 
                        Array.isArray(product.imageUrls) ? product.imageUrls : [];
  const productName = product.name || product.partName || 'Unnamed Product';
  const productPrice = product.price || product.unitPrice || 0;
  const productQuantity = product.quantity || product.stockQuantity || 0;

  const specifications = product.specifications && typeof product.specifications === 'object'
    ? Object.entries(product.specifications).map(([key, value]) => ({
        key,
        value: value || '',
      }))
    : [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center">
          <Link href="/dashboard/products">
            <Button variant="ghost" size="icon" className="mr-2">
              <ArrowLeft size={20} />
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-semibold">{productName}</h1>
            <p className="text-muted-foreground">
              {product.brand} | {product.category}
            </p>
          </div>
        </div>
        
        {product.status === "pending" && (
          <div className="flex space-x-2">
            <Button
              onClick={openApproveDialog}
              variant="default"
              className="bg-green-600 hover:bg-green-700"
            >
              <CheckCircle size={16} className="mr-2" />
              Approve
            </Button>
            <Button
              onClick={openRejectDialog}
              variant="destructive"
            >
              <XCircle size={16} className="mr-2" />
              Reject
            </Button>
          </div>
        )}
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <Tabs defaultValue="details">
            <TabsList>
              <TabsTrigger value="details">Details</TabsTrigger>
              <TabsTrigger value="images">Images</TabsTrigger>
              <TabsTrigger value="specifications">Specifications</TabsTrigger>
            </TabsList>
            
            <TabsContent value="details" className="pt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Product Information</CardTitle>
                  <CardDescription>
                    Detailed information about the product
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground">
                        Product Name
                      </h3>
                      <p>{productName}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground">
                        Brand
                      </h3>
                      <p>{product.brand}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground">
                        Model
                      </h3>
                      <p>{product.model}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground">
                        Year
                      </h3>
                      <p>{product.year}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground">
                        Category
                      </h3>
                      <p>{product.category}</p>
                    </div>
                    {product.subcategory && (
                      <div>
                        <h3 className="text-sm font-medium text-muted-foreground">
                          Subcategory
                        </h3>
                        <p>{product.subcategory}</p>
                      </div>
                    )}
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground">
                        Price
                      </h3>
                      <p>{formatCurrency(productPrice)}</p>
                    </div>
                    {product.discountPrice !== undefined && (
                      <div>
                        <h3 className="text-sm font-medium text-muted-foreground">
                          Discount Price
                        </h3>
                        <p>{formatCurrency(product.discountPrice)}</p>
                      </div>
                    )}
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground">
                        Condition
                      </h3>
                      <p className="capitalize">{product.condition}</p>
                    </div>
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground">
                        Quantity
                      </h3>
                      <p>{productQuantity}</p>
                    </div>
                    {product.partNumber && (
                      <div>
                        <h3 className="text-sm font-medium text-muted-foreground">
                          Part Number
                        </h3>
                        <p>{product.partNumber}</p>
                      </div>
                    )}
                    {product.qualityGrade && (
                      <div>
                        <h3 className="text-sm font-medium text-muted-foreground">
                          Quality Grade
                        </h3>
                        <p>{product.qualityGrade}</p>
                      </div>
                    )}
                  </div>
                  
                  <div>
                    <h3 className="text-sm font-medium text-muted-foreground mb-2">
                      Description
                    </h3>
                    <p className="text-sm whitespace-pre-line">{product.description}</p>
                  </div>
                  
                  {product.compatibility && product.compatibility.vehicles && product.compatibility.vehicles.length > 0 && (
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground mb-2">
                        Vehicle Compatibility
                      </h3>
                      <div className="space-y-2">
                        {product.compatibility.vehicles.map((vehicle, index) => (
                          <div key={index} className="flex items-center space-x-2 text-sm">
                            <span className="font-medium">{vehicle.make} {vehicle.model}</span>
                            <span className="text-muted-foreground">({vehicle.years?.join(', ') || 'N/A'})</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                  
                  {vendor && (
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground mb-2">
                        Vendor
                      </h3>
                      <Link 
                        href={`/dashboard/vendors/${vendor.id}`}
                        className="text-primary hover:underline"
                      >
                        {vendor.businessName}
                      </Link>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
            
            <TabsContent value="images" className="pt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Product Images</CardTitle>
                  <CardDescription>
                    Images uploaded for this product
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {!productImages || productImages.length === 0 ? (
                    <p className="text-center py-8 text-muted-foreground">
                      No images have been uploaded for this product.
                    </p>
                  ) : (
                    <div>
                      <div className="aspect-video relative bg-gray-100 rounded-lg overflow-hidden mb-4">
                        {activeImage && (
                          <Image 
                            src={activeImage} 
                            alt={productName}
                            fill
                            sizes="(max-width: 1024px) 100vw, 66vw"
                            className="object-contain"
                            onError={() => {
                              console.error('Image failed to load:', activeImage);
                            }}
                          />
                        )}
                      </div>
                      
                      <div className="grid grid-cols-4 sm:grid-cols-5 gap-2">
                        {productImages && productImages.length > 0 && productImages.map((url, index) => (
                          <div 
                            key={index} 
                            className={`
                              aspect-square relative bg-gray-100 rounded-md overflow-hidden cursor-pointer
                              ${url === activeImage ? 'ring-2 ring-primary' : ''}
                            `}
                            onClick={() => setActiveImage(url)}
                          >
                            <Image 
                              src={url} 
                              alt={`${productName} - Image ${index + 1}`}
                              fill
                              sizes="(max-width: 640px) 25vw, 12vw"
                              className="object-cover"
                              onError={() => {
                                console.error('Thumbnail failed to load:', url);
                              }}
                            />
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
            
            <TabsContent value="specifications" className="pt-4">
              <Card>
                <CardHeader>
                  <CardTitle>Product Specifications</CardTitle>
                  <CardDescription>
                    Technical details and specifications
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {specifications.length === 0 ? (
                    <p className="text-center py-8 text-muted-foreground">
                      No specifications have been added for this product.
                    </p>
                  ) : (
                    <div className="border rounded-lg overflow-hidden">
                      <table className="w-full">
                        <tbody>
                          {specifications.map(({ key, value }, index) => (
                            <tr 
                              key={index}
                              className={`
                                ${index % 2 === 0 ? 'bg-gray-50 dark:bg-gray-800' : ''}
                              `}
                            >
                              <td className="px-4 py-3 border-b dark:border-gray-700 font-medium">
                                {key}
                              </td>
                              <td className="px-4 py-3 border-b dark:border-gray-700">
                                {value}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>
        
        <div>
          <Card>
            <CardHeader>
              <CardTitle>Status</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex justify-between items-center">
                <div>
                  <h3 className="text-sm font-medium text-muted-foreground">
                    Current Status
                  </h3>
                  <div className="mt-1">
                    <ProductStatusBadge status={product.status} />
                  </div>
                </div>
                
                {product.status !== "pending" && (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => {
                      if (product.status === "approved") {
                        openRejectDialog();
                      } else {
                        openApproveDialog();
                      }
                    }}
                  >
                    {product.status === "approved" ? "Reject" : "Approve"}
                  </Button>
                )}
              </div>
              
              <div>
                <h3 className="text-sm font-medium text-muted-foreground">
                  Show in Client Catalog
                </h3>
                <div className="flex items-center space-x-2 mt-1">
                  <Checkbox
                    id="catalog-status"
                    checked={product.showInCatalog}
                    disabled={product.status !== "approved"}
                    onCheckedChange={async (checked: boolean) => {
                      try {
                        await updateProductStatus(
                          product.id, 
                          product.status, 
                          checked
                        );
                        setProduct({ ...product, showInCatalog: checked });
                        toast.success("Catalog status updated");
                      } catch (error) {
                        console.error("Error updating catalog status:", error);
                        toast.error("Failed to update catalog status");
                      }
                    }}
                  />
                  <label
                    htmlFor="catalog-status"
                    className={`text-sm ${product.status !== "approved" ? 'text-muted-foreground' : ''}`}
                  >
                    {product.showInCatalog ? "Visible to clients" : "Hidden from clients"}
                  </label>
                </div>
              </div>
              
              <div>
                <h3 className="text-sm font-medium text-muted-foreground">
                  Date Added
                </h3>
                <p>{formatDateTime(product.createdAt)}</p>
              </div>
              
              {product.status === "approved" && product.approvedAt && (
                <div>
                  <h3 className="text-sm font-medium text-muted-foreground">
                    Approval Date
                  </h3>
                  <p>{formatDateTime(product.approvedAt)}</p>
                </div>
              )}
              
              {product.status === "rejected" && product.rejectedAt && (
                <>
                  <div>
                    <h3 className="text-sm font-medium text-muted-foreground">
                      Rejection Date
                    </h3>
                    <p>{formatDateTime(product.rejectedAt)}</p>
                  </div>
                  
                  {product.rejectionReason && (
                    <div>
                      <h3 className="text-sm font-medium text-muted-foreground">
                        Rejection Reason
                      </h3>
                      <p className="text-sm mt-1">{product.rejectionReason}</p>
                    </div>
                  )}
                </>
              )}
            </CardContent>
          </Card>
          
          {vendor && (
            <Card className="mt-4">
              <CardHeader>
                <CardTitle>Vendor Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <h3 className="text-sm font-medium text-muted-foreground">
                    Business Name
                  </h3>
                  <p>{vendor.businessName}</p>
                </div>
                <div>
                  <h3 className="text-sm font-medium text-muted-foreground">
                    Contact
                  </h3>
                  <p>{vendor.name}</p>
                </div>
                <div>
                  <h3 className="text-sm font-medium text-muted-foreground">
                    Email
                  </h3>
                  <p>{vendor.email}</p>
                </div>
                <div>
                  <h3 className="text-sm font-medium text-muted-foreground">
                    Status
                  </h3>
                  <div className="mt-1">
                    <VendorStatusBadge status={vendor.status} />
                  </div>
                </div>
                <div>
                  <Link href={`/dashboard/vendors/${vendor.id}`}>
                    <Button variant="outline" className="w-full">
                      View Vendor
                    </Button>
                  </Link>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
      
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {dialogAction === "approve" ? "Approve Product" : "Reject Product"}
            </DialogTitle>
            <DialogDescription>
              {dialogAction === "approve"
                ? "Set the final retail price for the client catalog. This will make the product visible to customers."
                : "Please provide a reason for rejecting this product."}
            </DialogDescription>
          </DialogHeader>
          
          {dialogAction === "approve" && (
            <div className="space-y-4 mt-2">
              <div>
                <label htmlFor="retail-price" className="text-sm font-medium">
                  Client Retail Price (UGX)
                </label>
                <Input
                  id="retail-price"
                  type="number"
                  placeholder="e.g., 350000"
                  value={retailPrice}
                  onChange={(e) => setRetailPrice(e.target.value)}
                  className="mt-1"
                />
              </div>
            </div>
          )}
          
          {dialogAction === "reject" && (
            <Textarea
              placeholder="Reason for rejection (e.g., poor image quality, incorrect details)"
              value={rejectionReason}
              onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setRejectionReason(e.target.value)}
              className="min-h-[100px] mt-2"
            />
          )}
          
          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleConfirm}
              variant={dialogAction === "approve" ? "default" : "destructive"}
              disabled={(dialogAction === "reject" && !rejectionReason.trim()) || (dialogAction === "approve" && !retailPrice)}
            >
              {dialogAction === "approve" ? "Approve & Add to Catalog" : "Confirm Rejection"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
