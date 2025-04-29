import { Badge } from "@/components/ui/badge";
import { VENDOR_STATUSES } from "@/lib/types";

interface VendorStatusBadgeProps {
  status: 'pending' | 'approved' | 'rejected';
}

export function VendorStatusBadge({ status }: VendorStatusBadgeProps) {
  const statusConfig = VENDOR_STATUSES.find(s => s.value === status);

  if (!statusConfig) {
    return null;
  }

  return (
    <Badge
      className={`${statusConfig.color} text-white`}
    >
      {statusConfig.label}
    </Badge>
  );
}
