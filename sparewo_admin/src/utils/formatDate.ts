/**
 * Format a date with a friendly relative time or standard format
 * @param date - Date to format (can be Date object, Firestore timestamp, or any date-like value)
 * @returns Formatted date string
 */
export function formatDate(date: any): string {
  if (!date) return 'Unknown date';
  
  // Convert Firestore timestamp to JS Date if needed
  const dateObj = date.toDate ? date.toDate() : new Date(date);
  
  // Check if valid date
  if (isNaN(dateObj.getTime())) {
    return 'Invalid date';
  }
  
  const now = new Date();
  const diffMs = now.getTime() - dateObj.getTime();
  const diffSecs = Math.floor(diffMs / 1000);
  const diffMins = Math.floor(diffSecs / 60);
  const diffHours = Math.floor(diffMins / 60);
  const diffDays = Math.floor(diffHours / 24);
  
  // Relative time formatting for recent dates
  if (diffSecs < 60) {
    return 'Just now';
  } else if (diffMins < 60) {
    return `${diffMins} min${diffMins === 1 ? '' : 's'} ago`;
  } else if (diffHours < 24) {
    return `${diffHours} hour${diffHours === 1 ? '' : 's'} ago`;
  } else if (diffDays < 7) {
    return `${diffDays} day${diffDays === 1 ? '' : 's'} ago`;
  }
  
  // Standard date format for older dates
  return dateObj.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}