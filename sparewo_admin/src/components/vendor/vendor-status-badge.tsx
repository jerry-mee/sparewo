import { Badge } from "@/components/ui/badge";
import { VENDOR_STATUSES } from "@/lib/types";

interface VendorStatusBadgeProps {
  status: 'pending' | 'approved' | 'rejected';
  isSuspended?: boolean;
}

export function VendorStatusBadge({ status, isSuspended }: VendorStatusBadgeProps) {
  const effectiveStatus = isSuspended ? 'suspended' : status;
  const statusConfig = VENDOR_STATUSES.find((s) => s.value === effectiveStatus);

  if (!statusConfig) {
    return null;
  }

  return <Badge className={`${statusConfig.color} text-white`}>{statusConfig.label}</Badge>;
}
