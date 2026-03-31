"use client";

import React, { useEffect, useMemo, useRef, useState } from "react";
import dynamic from "next/dynamic";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  CircleAlert,
  ServerCrash,
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
import { auth } from "@/lib/firebase/config";
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
  const roleForNavigation = currentRole ?? "Administrator";

  const [isDesktopSidebarExpanded, setIsDesktopSidebarExpanded] = useState(true);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);
  const [searchValue, setSearchValue] = useState("");
  const [searching, setSearching] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchResults, setSearchResults] = useState<
    Array<{ id: string; type: "order" | "client" | "vendor" | "product"; title: string; subtitle: string; href: string }>
  >([]);
  const searchBoxRef = useRef<HTMLDivElement | null>(null);

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
      { title: "Issues", href: "/dashboard/issues", icon: CircleAlert, roles: ["Administrator", "Manager"] },
      { title: "Comms", href: "/dashboard/comms", icon: MessageSquareWarning, roles: ["Administrator", "Manager"] },
      { title: "System Status", href: "/dashboard/system-status", icon: ServerCrash, roles: ["Administrator", "Manager"] },
      { title: "Settings", href: "/dashboard/settings", icon: Settings, roles: ["Administrator"] },
    ],
    []
  );
  const visibleNavItems = useMemo(
    () => navItems.filter((item) => item.roles.includes(roleForNavigation)),
    [roleForNavigation, navItems]
  );

  useEffect(() => {
    if (loading) return;
    if (!pathname.startsWith("/dashboard")) return;
    if (canAccessDashboardPath(roleForNavigation, pathname)) return;
    router.replace(getDefaultDashboardPath(roleForNavigation));
  }, [roleForNavigation, loading, pathname, router]);

  useEffect(() => {
    if (!searchOpen) return;
    const handleOutside = (event: MouseEvent) => {
      if (!searchBoxRef.current) return;
      if (!searchBoxRef.current.contains(event.target as Node)) {
        setSearchOpen(false);
      }
    };
    document.addEventListener("mousedown", handleOutside);
    return () => {
      document.removeEventListener("mousedown", handleOutside);
    };
  }, [searchOpen]);

  useEffect(() => {
    const query = searchValue.trim();
    if (query.length < 2) {
      setSearchResults([]);
      setSearching(false);
      return;
    }

    let cancelled = false;
    const timer = setTimeout(async () => {
      try {
        setSearching(true);
        const token = await auth.currentUser?.getIdToken();
        if (!token) {
          if (!cancelled) setSearchResults([]);
          return;
        }
        const res = await fetch(`/api/dashboard/search?q=${encodeURIComponent(query)}`, {
          headers: { Authorization: `Bearer ${token}` },
          cache: "no-store",
        });
        if (!res.ok) {
          if (!cancelled) setSearchResults([]);
          return;
        }
        const payload = (await res.json()) as {
          results?: Array<{
            id: string;
            type: "order" | "client" | "vendor" | "product";
            title: string;
            subtitle: string;
            href: string;
          }>;
        };
        if (!cancelled) {
          setSearchResults(payload.results || []);
          setSearchOpen(true);
        }
      } catch {
        if (!cancelled) setSearchResults([]);
      } finally {
        if (!cancelled) setSearching(false);
      }
    }, 220);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [searchValue]);

  const currentTitle = useMemo(() => {
    if (pathname === "/dashboard") return "Operations Overview";
    const item = visibleNavItems.find((nav) => pathname.startsWith(nav.href));
    return item?.title ?? "Dashboard";
  }, [visibleNavItems, pathname]);

  const onSearch = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const query = searchValue.trim();
    if (!query) return;
    const firstMatch = searchResults[0];
    if (firstMatch?.href) {
      setSearchOpen(false);
      router.push(firstMatch.href);
      return;
    }
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
          <div className="flex h-20 items-center justify-between border-b border-sidebar-border px-4 lg:px-5">
            <Link href="/dashboard" className="flex min-w-0 flex-1 items-center gap-3">
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
              className="ml-2 hidden shrink-0 lg:inline-flex"
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
                  {roleForNavigation || adminData?.role || "Unknown"}
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
          <div className="flex min-h-20 flex-wrap items-center justify-between gap-3 py-3 md:flex-nowrap">
            <div className="flex min-w-0 flex-1 items-center gap-3 md:gap-6">
              <Button
                variant="ghost"
                size="icon"
                className="lg:hidden"
                onClick={() => setIsMobileSidebarOpen((open) => !open)}
              >
                {isMobileSidebarOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
              </Button>

              <div className="hidden min-w-[160px] md:block md:max-w-[18rem] lg:max-w-[20rem] xl:max-w-[24rem]">
                <p className="truncate text-base font-semibold font-display">{currentTitle}</p>
                <p className="truncate text-xs text-muted-foreground">Platform command and monitoring</p>
              </div>

              <div
                ref={searchBoxRef}
                className="relative hidden md:block md:min-w-[280px] md:flex-1 md:max-w-[760px]"
              >
                <form onSubmit={onSearch}>
                  <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <input
                    value={searchValue}
                    onFocus={() => setSearchOpen(true)}
                    onChange={(event) => setSearchValue(event.target.value)}
                    placeholder="Search orders, clients, vendors..."
                    className="h-11 w-full rounded-xl border border-border bg-background pl-10 pr-4 text-sm outline-none ring-primary/30 transition focus:border-primary focus:ring-2"
                  />
                </form>
                {searchOpen && searchValue.trim().length >= 2 ? (
                  <div className="absolute left-0 right-0 top-[calc(100%+8px)] z-50 max-h-[360px] overflow-y-auto rounded-xl border border-border bg-card p-2 shadow-xl">
                    {searching ? (
                      <div className="px-3 py-2 text-xs text-muted-foreground">Searching...</div>
                    ) : searchResults.length === 0 ? (
                      <div className="px-3 py-2 text-xs text-muted-foreground">No live results found.</div>
                    ) : (
                      searchResults.map((result) => (
                        <button
                          key={`${result.type}-${result.id}`}
                          type="button"
                          className="flex w-full flex-col rounded-lg px-3 py-2 text-left transition hover:bg-muted/50"
                          onClick={() => {
                            setSearchOpen(false);
                            setSearchValue("");
                            router.push(result.href);
                          }}
                        >
                          <span className="text-sm font-medium">{result.title}</span>
                          <span className="text-xs text-muted-foreground">
                            {result.type.toUpperCase()} • {result.subtitle}
                          </span>
                        </button>
                      ))
                    )}
                  </div>
                ) : null}
              </div>
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
