"use client";

import React, { useEffect, useMemo, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  LogOut,
  Menu,
  MessageSquareWarning,
  Moon,
  Package,
  Search,
  Settings,
  ShoppingCart,
  Store,
  Sun,
  Users,
  Wrench,
  X,
} from "lucide-react";
import { useTheme } from "next-themes";
import { toast } from "sonner";

import { NotificationDropdown } from "@/components/ui/notification-dropdown";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/context/auth-context";
import { logOut } from "@/lib/firebase/auth";
import { cn, getInitials } from "@/lib/utils";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { resolvedTheme, setTheme } = useTheme();
  const { user, adminData } = useAuth();

  const [mounted, setMounted] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [searchValue, setSearchValue] = useState("");

  useEffect(() => {
    const media = window.matchMedia("(max-width: 1023px)");

    const syncLayout = (mobile: boolean) => {
      setIsMobile(mobile);
      setIsSidebarOpen(!mobile);
    };

    syncLayout(media.matches);
    const handleChange = (event: MediaQueryListEvent) => syncLayout(event.matches);
    media.addEventListener("change", handleChange);
    setMounted(true);

    return () => media.removeEventListener("change", handleChange);
  }, []);

  const navItems = useMemo(
    () => [
      { title: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
      { title: "Clients", href: "/dashboard/clients", icon: Users },
      { title: "AutoHub", href: "/dashboard/autohub", icon: Wrench },
      { title: "Vendors", href: "/dashboard/vendors", icon: Store },
      { title: "Products", href: "/dashboard/products", icon: Package },
      { title: "Orders", href: "/dashboard/orders", icon: ShoppingCart },
      { title: "Comms", href: "/dashboard/comms", icon: MessageSquareWarning },
      { title: "Settings", href: "/dashboard/settings", icon: Settings },
    ],
    []
  );

  const currentTitle = useMemo(() => {
    if (pathname === "/dashboard") return "Operations Overview";
    const item = navItems.find((nav) => pathname.startsWith(nav.href));
    return item?.title ?? "Dashboard";
  }, [navItems, pathname]);

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

  const isDark = resolvedTheme === "dark";

  return (
    <div className="min-h-screen bg-background text-foreground">
      {isMobile && isSidebarOpen && (
        <button
          aria-label="Close sidebar"
          className="fixed inset-0 z-30 bg-black/45 backdrop-blur-sm"
          onClick={() => setIsSidebarOpen(false)}
          type="button"
        />
      )}

      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-40 border-r border-sidebar-border bg-sidebar transition-all duration-300 ease-out",
          isMobile
            ? isSidebarOpen
              ? "w-72 translate-x-0"
              : "w-72 -translate-x-full"
            : isSidebarOpen
              ? "w-72 translate-x-0"
              : "w-20 translate-x-0"
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
              {isSidebarOpen && (
                <div className="min-w-0">
                  <p className="truncate text-sm font-semibold tracking-tight">SpareWo Admin</p>
                  <p className="truncate text-xs text-muted-foreground">Operations Control Panel</p>
                </div>
              )}
            </Link>

            <Button
              variant="ghost"
              size="icon"
              onClick={() => setIsSidebarOpen((open) => !open)}
              className="hidden lg:inline-flex"
            >
              {isSidebarOpen ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
            </Button>
          </div>

          <nav className="flex-1 space-y-2 overflow-y-auto px-3 py-6">
            {navItems.map((item) => {
              const Icon = item.icon;
              const active = pathname === item.href || pathname.startsWith(`${item.href}/`);

              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => {
                    if (isMobile) setIsSidebarOpen(false);
                  }}
                  className={cn(
                    "group flex items-center gap-3 rounded-xl px-4 py-3 text-sm transition-all duration-150",
                    active
                      ? "bg-primary text-primary-foreground shadow-soft"
                      : "text-sidebar-foreground hover:bg-sidebar-accent hover:text-foreground",
                    !isSidebarOpen && !isMobile && "justify-center px-2"
                  )}
                >
                  <Icon className="h-5 w-5 shrink-0" />
                  {isSidebarOpen && <span className="truncate">{item.title}</span>}
                </Link>
              );
            })}
          </nav>

          <div className="border-t border-sidebar-border p-4">
            <div className={cn("flex items-center gap-3", !isSidebarOpen && !isMobile && "justify-center")}>
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary font-semibold text-primary-foreground">
                {getInitials(user?.displayName || user?.email || "Admin")}
              </div>

              {isSidebarOpen && (
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold">{user?.displayName || "Admin User"}</p>
                  <p className="truncate text-xs text-muted-foreground">
                    {adminData?.role || "admin"}
                    {adminData?.role === "viewer" && " (read-only)"}
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      </aside>

      <div className={cn("min-h-screen transition-all duration-300", isSidebarOpen ? "lg:pl-72" : "lg:pl-20")}>
        <header className="sticky top-0 z-20 border-b border-border/70 bg-card/90 px-4 backdrop-blur-sm md:px-6 lg:px-8">
          <div className="flex h-20 items-center justify-between gap-3">
            <div className="flex min-w-0 items-center gap-3 md:gap-6">
              <Button
                variant="ghost"
                size="icon"
                className="lg:hidden"
                onClick={() => setIsSidebarOpen((open) => !open)}
              >
                <Menu className="h-5 w-5" />
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
              <Button
                variant="ghost"
                size="icon"
                onClick={() => setTheme(isDark ? "light" : "dark")}
                aria-label="Toggle theme"
                className="rounded-xl"
              >
                {mounted ? (
                  isDark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />
                ) : (
                  <Moon className="h-4 w-4" />
                )}
              </Button>

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
