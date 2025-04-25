
import React, { ReactNode } from "react";
import { Container } from "@/components/ui/container";

interface PageContainerProps {
  children: ReactNode;
  title: string;
  subtitle?: string;
  actions?: ReactNode;
  breadcrumb?: ReactNode;
}

const PageContainer = ({ 
  children, 
  title, 
  subtitle,
  actions,
  breadcrumb
}: PageContainerProps) => {
  return (
    <Container className="py-6 space-y-6">
      {/* Breadcrumb if provided */}
      {breadcrumb && <div className="mb-2">{breadcrumb}</div>}
      
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div className="space-y-1">
          <h1 className="text-2xl font-bold text-foreground">{title}</h1>
          {subtitle && <p className="text-sm text-muted-foreground">{subtitle}</p>}
        </div>
        {actions && (
          <div className="flex flex-wrap items-center gap-3">
            {actions}
          </div>
        )}
      </div>
      
      {/* Page Content */}
      {children}
    </Container>
  );
};

export default PageContainer;

