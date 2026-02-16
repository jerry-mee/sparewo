import { Forum, Plus_Jakarta_Sans } from "next/font/google";
import { Providers } from "@/components/providers/providers";
import { Toaster } from "sonner";
import "./globals.css";

import type { Metadata } from "next";

const forum = Forum({
  subsets: ["latin"],
  weight: ["400"],
  variable: "--font-forum",
});

const plusJakartaSans = Plus_Jakarta_Sans({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-plus-jakarta",
});

export const metadata: Metadata = {
  title: "SpareWo Admin Control Panel",
  description: "Operations dashboard for SpareWo platform management",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${forum.variable} ${plusJakartaSans.variable} font-sans antialiased`}>
        <Providers>
          {children}
          <Toaster position="bottom-right" />
        </Providers>
      </body>
    </html>
  );
}
