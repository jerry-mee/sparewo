// SpareWo Admin Dashboard Theme Configuration
// This file defines consistent theme colors and styles across the application

import { createTheme, ThemeOptions } from '@mui/material/styles';

// Define color palette
const lightPalette = {
  primary: {
    main: '#FF9800', // SpareWo Orange
    light: '#FFB74D',
    dark: '#F57C00',
    contrastText: '#FFFFFF'
  },
  secondary: {
    main: '#1A1B4B', // Matching the vendor app secondary color
    light: '#3F51B5',
    dark: '#0D0E24',
    contrastText: '#FFFFFF'
  },
  error: {
    main: '#D32F2F',
    light: '#EF5350',
    dark: '#C62828',
    contrastText: '#FFFFFF'
  },
  warning: {
    main: '#FFA726',
    light: '#FFB74D',
    dark: '#F57C00',
    contrastText: '#FFFFFF'
  },
  info: {
    main: '#2878EB',
    light: '#64B5F6',
    dark: '#1976D2',
    contrastText: '#FFFFFF'
  },
  success: {
    main: '#388E3C',
    light: '#66BB6A',
    dark: '#2E7D32',
    contrastText: '#FFFFFF'
  },
  background: {
    default: '#F5F5F5',
    paper: '#FFFFFF'
  },
  text: {
    primary: '#2D2D2D',
    secondary: '#757575',
    disabled: '#9E9E9E'
  },
  divider: '#E0E0E0'
};

// Dark mode palette
const darkPalette = {
  primary: {
    main: '#FF9800',
    light: '#FFB74D',
    dark: '#E65100',
    contrastText: '#FFFFFF'
  },
  secondary: {
    main: '#1A1B4B',
    light: '#3F51B5',
    dark: '#0D0E24',
    contrastText: '#FFFFFF'
  },
  error: {
    main: '#D32F2F',
    light: '#EF5350',
    dark: '#C62828',
    contrastText: '#FFFFFF'
  },
  warning: {
    main: '#FFA726',
    light: '#FFB74D',
    dark: '#F57C00',
    contrastText: '#FFFFFF'
  },
  info: {
    main: '#2878EB',
    light: '#64B5F6',
    dark: '#1976D2',
    contrastText: '#FFFFFF'
  },
  success: {
    main: '#388E3C',
    light: '#66BB6A',
    dark: '#2E7D32',
    contrastText: '#FFFFFF'
  },
  background: {
    default: '#121212',
    paper: '#1E1E1E'
  },
  text: {
    primary: '#FFFFFF',
    secondary: '#BBBBBB',
    disabled: '#757575'
  },
  divider: '#424242'
};

const baseThemeOptions: ThemeOptions = {
  shape: {
    borderRadius: 8
  },
  typography: {
    fontFamily: '"Poppins", sans-serif',
    h1: {
      fontWeight: 700,
      fontSize: '2.5rem',
      lineHeight: 1.3
    },
    h2: {
      fontWeight: 700,
      fontSize: '2rem',
      lineHeight: 1.3
    },
    h3: {
      fontWeight: 600,
      fontSize: '1.75rem',
      lineHeight: 1.3
    },
    h4: {
      fontWeight: 600,
      fontSize: '1.5rem',
      lineHeight: 1.3
    },
    h5: {
      fontWeight: 600,
      fontSize: '1.25rem',
      lineHeight: 1.3
    },
    h6: {
      fontWeight: 600,
      fontSize: '1rem',
      lineHeight: 1.3
    },
    subtitle1: {
      fontWeight: 500,
      fontSize: '1rem',
      lineHeight: 1.5
    },
    subtitle2: {
      fontWeight: 500,
      fontSize: '0.875rem',
      lineHeight: 1.5
    },
    body1: {
      fontWeight: 400,
      fontSize: '1rem',
      lineHeight: 1.5
    },
    body2: {
      fontWeight: 400,
      fontSize: '0.875rem',
      lineHeight: 1.5
    },
    button: {
      fontWeight: 600,
      fontSize: '0.875rem',
      lineHeight: 1.5,
      textTransform: 'none' as const
    },
    caption: {
      fontWeight: 400,
      fontSize: '0.75rem',
      lineHeight: 1.5
    },
    overline: {
      fontWeight: 400,
      fontSize: '0.75rem',
      lineHeight: 2.5,
      textTransform: 'uppercase' as const
    }
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          borderRadius: 8,
          fontWeight: 600,
          boxShadow: 'none',
          padding: '12px 24px',
          minHeight: '48px',
          '&:hover': {
            boxShadow: 'none'
          }
        },
        contained: {
          boxShadow: 'none',
          '&:hover': {
            boxShadow: 'none'
          }
        }
      }
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          boxShadow: '0px 2px 8px rgba(0, 0, 0, 0.1)',
          padding: 16,
          margin: '8px 0'
        }
      }
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 8
        }
      }
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          '& .MuiOutlinedInput-root': {
            borderRadius: 8,
            '& fieldset': {
              borderColor: '#E0E0E0'
            },
            '&:hover fieldset': {
              borderColor: '#FF9800'
            },
            '&.Mui-focused fieldset': {
              borderColor: '#FF9800',
              borderWidth: 2
            }
          }
        }
      }
    },
    MuiTableCell: {
      styleOverrides: {
        root: {
          borderBottom: '1px solid #E0E0E0',
          padding: '16px'
        },
        head: {
          fontWeight: 600,
          backgroundColor: '#F5F5F5'
        }
      }
    },
    MuiTableRow: {
      styleOverrides: {
        root: {
          '&:last-child td': {
            borderBottom: 0
          },
          '&:hover': {
            backgroundColor: 'rgba(0, 0, 0, 0.04)'
          }
        }
      }
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          boxShadow: 'none',
          borderBottom: '1px solid #E0E0E0'
        }
      }
    },
    MuiListItem: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          '&:hover': {
            backgroundColor: 'rgba(0, 0, 0, 0.04)'
          }
        }
      }
    },
    MuiDialog: {
      styleOverrides: {
        paper: {
          borderRadius: 12,
          boxShadow: '0px 8px 24px rgba(0, 0, 0, 0.15)'
        }
      }
    },
    MuiChip: {
      styleOverrides: {
        root: {
          borderRadius: 16,
          fontWeight: 500
        }
      }
    }
  }
};

// Create the light theme
export const lightTheme = createTheme({
  ...baseThemeOptions,
  palette: lightPalette
});

// Create the dark theme
export const darkTheme = createTheme({
  ...baseThemeOptions,
  palette: darkPalette,
  components: {
    ...baseThemeOptions.components,
    MuiCard: {
      styleOverrides: {
        root: {
          backgroundColor: '#1E1E1E',
          borderRadius: 12,
          boxShadow: '0px 2px 8px rgba(0, 0, 0, 0.3)',
          padding: 16,
          margin: '8px 0'
        }
      }
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundColor: '#1E1E1E',
          borderRadius: 8
        }
      }
    },
    MuiTableCell: {
      styleOverrides: {
        root: {
          borderBottom: '1px solid #424242'
        },
        head: {
          fontWeight: 600,
          backgroundColor: '#121212'
        }
      }
    },
    MuiTableRow: {
      styleOverrides: {
        root: {
          '&:hover': {
            backgroundColor: 'rgba(255, 255, 255, 0.04)'
          }
        }
      }
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          borderBottom: '1px solid #424242'
        }
      }
    }
  }
});

export default lightTheme;