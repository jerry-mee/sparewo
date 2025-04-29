import { Badge } from "@/components/ui/badge";
import { PRODUCT_STATUSES } from "@/lib/types";

interface ProductStatusBadgeProps {
  status: 'pending' | 'approved' | 'rejected';
}

export function ProductStatusBadge({ status }: ProductStatusBadgeProps) {
  const statusConfig = PRODUCT_STATUSES.find(s => s.value === status);

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
