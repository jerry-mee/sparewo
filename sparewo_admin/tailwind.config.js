/** @type {import('tailwindcss').Config} */
 
import animatePlugin from "tailwindcss-animate";

module.exports = {
  darkMode: ["class"],
  content: [
    './pages/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        // SpareWo Theme Colors from theme.dart
        primary: {
          DEFAULT: "#FF9800", // VendorColors.primary
          foreground: "#ffffff",
        },
        secondary: {
          DEFAULT: "#1A1B4B", // VendorColors.secondary
          foreground: "#ffffff",
        },
        background: "#F5F5F5", // VendorColors.background
        card: "#FFFFFF", // VendorColors.cardBackground
        text: {
          DEFAULT: "#2D2D2D", // VendorColors.text
          light: "#757575", // VendorColors.textLight
        },
        status: {
          error: "#D32F2F", // VendorColors.error
          success: "#388E3C", // VendorColors.success
          pending: "#FFA726", // VendorColors.pending
          approved: "#66BB6A", // VendorColors.approved
          rejected: "#EF5350", // VendorColors.rejected
        },
        border: "#E0E0E0", // VendorColors.divider
        input: "#FFFFFF",
        ring: "#FF9800",
        destructive: {
          DEFAULT: "#D32F2F",
          foreground: "#FFFFFF",
        },
        muted: {
          DEFAULT: "#F5F5F5",
          foreground: "#757575",
        },
        accent: {
          DEFAULT: "#1A1B4B",
          foreground: "#FFFFFF",
        },
        popover: {
          DEFAULT: "#FFFFFF",
          foreground: "#2D2D2D",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      fontFamily: {
        sans: ["var(--font-poppins)"],
      },
      keyframes: {
        "accordion-down": {
          from: { height: 0 },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: 0 },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [animatePlugin],
}