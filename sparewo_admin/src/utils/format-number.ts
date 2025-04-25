/**
 * Format a number with commas as thousands separators and fixed decimal places
 * @param value - Number to format
 * @param decimalPlaces - Number of decimal places to display (default: 2)
 * @returns Formatted number string
 */
export function formatNumber(value: number, decimalPlaces: number = 2): string {
    if (value === undefined || value === null) return '0.00';
    
    // Convert to fixed decimal places and handle potential rounding
    const fixedValue = value.toFixed(decimalPlaces);
    
    // Format with commas as thousands separators
    const parts = fixedValue.split('.');
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    
    return parts.join('.');
  }