"use client";

import { useState } from "react";
import { Bell } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "./dropdown-menu";
import { useNotifications } from "@/lib/context/notification-context";
import { Button } from "./button";
import { cn } from "@/lib/utils";
import Link from "next/link";

export function NotificationDropdown() {
  const { notifications, unreadCount, markAsRead } = useNotifications();
  const [open, setOpen] = useState(false);

  const handleMarkAsRead = async (id: string) => {
    await markAsRead(id);
  };

  const getNotificationIcon = (type: string) => {
    const colors = {
      info: "text-blue-500",
      success: "text-green-500",
      warning: "text-amber-500",
      error: "text-red-500",
    } as Record<string, string>;

    return <div className={`w-2 h-2 rounded-full ${colors[type] || colors.info}`} />;
  };

  return (
    <DropdownMenu open={open} onOpenChange={setOpen}>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" className="relative">
          <Bell size={20} />
          {unreadCount > 0 && (
            <span className="absolute top-0 right-0 w-3 h-3 bg-red-500 rounded-full" />
          )}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="w-80" align="end">
        <DropdownMenuLabel>Notifications</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <div className="max-h-[600px] overflow-y-auto">
          {notifications.length === 0 ? (
            <div className="py-6 text-center text-sm text-gray-500 dark:text-gray-400">
              No notifications yet
            </div>
          ) : (
            notifications.map((notification) => (
              <DropdownMenuItem
                key={notification.id}
                className={cn(
                  "flex items-start gap-3 p-3 cursor-default",
                  !notification.read && "bg-gray-50 dark:bg-gray-900"
                )}
                onClick={() => handleMarkAsRead(notification.id)}
              >
                <div className="mt-1 flex-shrink-0">
                  {getNotificationIcon(notification.type)}
                </div>
                <div className="flex-1 space-y-1">
                  <div className="font-medium text-sm">
                    {notification.title}
                  </div>
                  <div className="text-xs text-gray-500 dark:text-gray-400">
                    {notification.message}
                  </div>
                  {notification.link && (
                    <Link
                      href={notification.link}
                      className="text-xs text-primary hover:underline"
                      onClick={() => setOpen(false)}
                    >
                      View details
                    </Link>
                  )}
                </div>
              </DropdownMenuItem>
            ))
          )}
        </div>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
