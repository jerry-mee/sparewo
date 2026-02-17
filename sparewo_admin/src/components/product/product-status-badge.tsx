import { StatusPill } from "@/components/ui/status-pill";
import { PRODUCT_STATUSES } from "@/lib/types";

interface ProductStatusBadgeProps {
  status: 'pending' | 'approved' | 'rejected';
}

export function ProductStatusBadge({ status }: ProductStatusBadgeProps) {
  const statusConfig = PRODUCT_STATUSES.find(s => s.value === status);

  if (!statusConfig) {
    return null;
  }

  return <StatusPill status={status} label={statusConfig.label} />;
}
