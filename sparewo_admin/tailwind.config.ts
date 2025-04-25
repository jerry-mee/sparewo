import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#FF9800',
          dark: '#F57C00',
          light: '#FFE0B2',
        },
        secondary: {
          DEFAULT: '#1A1B4B',
          dark: '#0D0E24',
          light: '#3F51B5',
        },
        success: {
          DEFAULT: '#22c55e',
          dark: '#15803d',
          light: '#86efac',
        },
        danger: {
          DEFAULT: '#ef4444',
          dark: '#b91c1c',
          light: '#fca5a5',
        },
        warning: {
          DEFAULT: '#f59e0b',
          dark: '#b45309',
          light: '#fcd34d',
        },
        info: {
          DEFAULT: '#3b82f6',
          dark: '#1d4ed8',
          light: '#93c5fd',
        },
        pending: '#f59e0b',
        boxdark: '#1A1D2C',
        'boxdark-2': '#161A2C',
        stroke: '#E2E8F0',
        strokedark: '#2E3446',
        bodydark: '#AEB7C0',
        'bodydark-2': '#8A99AF',
        'gray-2': '#F7F9FC',
        'gray-3': '#EFF3F9',
      },
      fontFamily: {
        sans: ['Poppins', 'sans-serif'],
      },
      screens: {
        xs: '400px',
        sm: '640px',
        md: '768px',
        lg: '1024px',
        xl: '1280px',
        '2xl': '1536px',
      },
      boxShadow: {
        DEFAULT: '0 1px 3px 0 rgba(0, 0, 0, 0.08), 0 1px 2px 0 rgba(0, 0, 0, 0.02)',
        md: '0 4px 6px -1px rgba(0, 0, 0, 0.08), 0 2px 4px -1px rgba(0, 0, 0, 0.02)',
        lg: '0 10px 15px -3px rgba(0, 0, 0, 0.08), 0 4px 6px -2px rgba(0, 0, 0, 0.01)',
        xl: '0 20px 25px -5px rgba(0, 0, 0, 0.08), 0 10px 10px -5px rgba(0, 0, 0, 0.01)',
      },
      borderRadius: {
        DEFAULT: '0.375rem',
        full: '9999px',
        lg: '0.5rem',
        xl: '0.75rem',
        '2xl': '1rem',
      },
      fontSize: {
        'title-xxl': ['44px', '55px'],
        'title-xl': ['36px', '45px'],
        'title-lg': ['28px', '35px'],
        'title-md': ['24px', '30px'],
        'title-sm': ['20px', '26px'],
        'title-xsm': ['18px', '24px'],
      },
      gridTemplateColumns: {
        'dashboard-cards': 'repeat(auto-fit, minmax(240px, 1fr))',
        'dashboard-stats': 'repeat(auto-fit, minmax(200px, 1fr))',
      },
      spacing: {
        'dashboard-padding': '24px',
        'card-padding': '20px',
        'header-height': '72px',
        'sidebar-width': '280px',
        'sidebar-collapsed': '80px',
      }
    },
  },
  plugins: [],
};

export default config;