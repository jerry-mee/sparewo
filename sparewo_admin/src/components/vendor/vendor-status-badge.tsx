import { StatusPill } from "@/components/ui/status-pill";
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

  return <StatusPill status={effectiveStatus} label={statusConfig.label} />;
}
