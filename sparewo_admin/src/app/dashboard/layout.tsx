"use client";

import React, { useEffect, useMemo, useState } from "react";
import dynamic from "next/dynamic";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  LogOut,
  Menu,
  MessageSquareWarning,
  Package,
  Search,
  Settings,
  ShoppingCart,
  Store,
  Users,
  Wrench,
  X,
} from "lucide-react";
import { toast } from "sonner";

import { NotificationDropdown } from "@/components/ui/notification-dropdown";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/context/auth-context";
import { logOut } from "@/lib/firebase/auth";
import { cn, getInitials } from "@/lib/utils";
import { canAccessDashboardPath, getDefaultDashboardPath, normalizeRole } from "@/lib/auth/roles";

const ThemeToggleButton = dynamic(
  () => import("@/components/ui/theme-toggle-button").then((module) => module.ThemeToggleButton),
  { ssr: false }
);

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, adminData, loading } = useAuth();
  const currentRole = normalizeRole(adminData?.role);

  const [isDesktopSidebarExpanded, setIsDesktopSidebarExpanded] = useState(true);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);
  const [searchValue, setSearchValue] = useState("");

  useEffect(() => {
    setIsMobileSidebarOpen(false);
  }, [pathname]);

  const navItems = useMemo(
    () => [
      { title: "Dashboard", href: "/dashboard", icon: LayoutDashboard, roles: ["Administrator", "Manager", "Mechanic"] },
      { title: "Clients", href: "/dashboard/clients", icon: Users, roles: ["Administrator", "Manager"] },
      { title: "AutoHub", href: "/dashboard/autohub", icon: Wrench, roles: ["Administrator", "Manager", "Mechanic"] },
      { title: "Vendors", href: "/dashboard/vendors", icon: Store, roles: ["Administrator", "Manager"] },
      { title: "Products", href: "/dashboard/products", icon: Package, roles: ["Administrator", "Manager", "Mechanic"] },
      { title: "Orders", href: "/dashboard/orders", icon: ShoppingCart, roles: ["Administrator", "Manager", "Mechanic"] },
      { title: "Comms", href: "/dashboard/comms", icon: MessageSquareWarning, roles: ["Administrator", "Manager"] },
      { title: "Settings", href: "/dashboard/settings", icon: Settings, roles: ["Administrator"] },
    ],
    []
  );
  const visibleNavItems = useMemo(
    () => navItems.filter((item) => currentRole && item.roles.includes(currentRole)),
    [currentRole, navItems]
  );

  useEffect(() => {
    if (loading) return;
    if (!pathname.startsWith("/dashboard")) return;
    if (canAccessDashboardPath(currentRole, pathname)) return;
    router.replace(getDefaultDashboardPath(currentRole));
  }, [currentRole, loading, pathname, router]);

  const currentTitle = useMemo(() => {
    if (pathname === "/dashboard") return "Operations Overview";
    const item = visibleNavItems.find((nav) => pathname.startsWith(nav.href));
    return item?.title ?? "Dashboard";
  }, [visibleNavItems, pathname]);

  const onSearch = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const query = searchValue.trim();
    if (!query) return;
    router.push(`/dashboard/orders?query=${encodeURIComponent(query)}`);
  };

  const handleLogout = async () => {
    try {
      await logOut();
      toast.success("Signed out successfully");
    } catch {
      toast.error("Failed to sign out");
    }
  };

  return (
    <div className="min-h-screen bg-background text-foreground">
      {isMobileSidebarOpen && (
        <button
          aria-label="Close sidebar"
          className="fixed inset-0 z-30 bg-black/45 backdrop-blur-sm lg:hidden"
          onClick={() => setIsMobileSidebarOpen(false)}
          type="button"
        />
      )}

      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-40 w-72 border-r border-sidebar-border bg-sidebar transition-transform duration-300 ease-out lg:translate-x-0 lg:transition-[width] lg:duration-300",
          isMobileSidebarOpen ? "translate-x-0" : "-translate-x-full",
          isDesktopSidebarExpanded ? "lg:w-72" : "lg:w-20"
        )}
      >
        <div className="flex h-full flex-col">
          <div className="flex h-20 items-center justify-between border-b border-sidebar-border px-5">
            <Link href="/dashboard" className="flex min-w-0 items-center gap-3">
              <Image
                src="/images/logo.png"
                alt="SpareWo"
                width={36}
                height={36}
                className="rounded-lg"
                style={{ width: "auto", height: "auto" }}
              />
              <div className={cn("min-w-0", !isDesktopSidebarExpanded && "lg:hidden")}>
                <p className="truncate text-sm font-semibold tracking-tight">SpareWo Admin</p>
                <p className="truncate text-xs text-muted-foreground">Operations Control Panel</p>
              </div>
            </Link>

            <Button
              variant="ghost"
              size="icon"
              onClick={() => setIsDesktopSidebarExpanded((open) => !open)}
              className="hidden lg:inline-flex"
            >
              {isDesktopSidebarExpanded ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
            </Button>
          </div>

          <nav className="flex-1 space-y-2 overflow-y-auto px-3 py-6">
            {visibleNavItems.map((item) => {
              const Icon = item.icon;
              const active = pathname === item.href || pathname.startsWith(`${item.href}/`);

              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => {
                    setIsMobileSidebarOpen(false);
                  }}
                  className={cn(
                    "group flex items-center gap-3 rounded-xl px-4 py-3 text-sm transition-all duration-150",
                    active
                      ? "bg-primary text-primary-foreground shadow-soft"
                      : "text-sidebar-foreground hover:bg-sidebar-accent hover:text-foreground",
                    !isDesktopSidebarExpanded && "lg:justify-center lg:px-2"
                  )}
                >
                  <Icon className="h-5 w-5 shrink-0" />
                  <span className={cn("truncate", !isDesktopSidebarExpanded && "lg:hidden")}>{item.title}</span>
                </Link>
              );
            })}
          </nav>

          <div className="border-t border-sidebar-border p-4">
            <div className={cn("flex items-center gap-3", !isDesktopSidebarExpanded && "lg:justify-center")}>
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary font-semibold text-primary-foreground">
                {getInitials(user?.displayName || user?.email || "Admin")}
              </div>

              <div className={cn("min-w-0 flex-1", !isDesktopSidebarExpanded && "lg:hidden")}>
                <p className="truncate text-sm font-semibold">{user?.displayName || "Admin User"}</p>
                <p className="truncate text-xs text-muted-foreground">
                  {currentRole || adminData?.role || "Unknown"}
                </p>
              </div>
            </div>
          </div>
        </div>
      </aside>

      <div
        className={cn(
          "min-h-screen transition-[padding] duration-300",
          isDesktopSidebarExpanded ? "lg:pl-72" : "lg:pl-20"
        )}
      >
        <header className="sticky top-0 z-20 border-b border-border/70 bg-card/90 px-4 backdrop-blur-sm md:px-6 lg:px-8">
          <div className="flex h-20 items-center justify-between gap-3">
            <div className="flex min-w-0 items-center gap-3 md:gap-6">
              <Button
                variant="ghost"
                size="icon"
                className="lg:hidden"
                onClick={() => setIsMobileSidebarOpen((open) => !open)}
              >
                {isMobileSidebarOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
              </Button>

              <div className="hidden min-w-0 md:block">
                <p className="truncate text-base font-semibold font-display">{currentTitle}</p>
                <p className="truncate text-xs text-muted-foreground">Platform command and monitoring</p>
              </div>

              <form onSubmit={onSearch} className="relative hidden w-full max-w-xl md:block">
                <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <input
                  value={searchValue}
                  onChange={(event) => setSearchValue(event.target.value)}
                  placeholder="Search orders, clients, vendors..."
                  className="h-11 w-full rounded-xl border border-border bg-background pl-10 pr-4 text-sm outline-none ring-primary/30 transition focus:border-primary focus:ring-2"
                />
              </form>
            </div>

            <div className="flex items-center gap-1 md:gap-2">
              <ThemeToggleButton />

              <NotificationDropdown />

              <Button variant="ghost" size="icon" onClick={handleLogout} className="rounded-xl" aria-label="Sign out">
                <LogOut className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </header>

        <main className="px-4 pb-8 pt-6 md:px-6 lg:px-8">{children}</main>
      </div>
    </div>
  );
}
