// Client-side navigation
document.addEventListener('DOMContentLoaded', function() {
  const vendorId = window.location.pathname.split('/').filter(Boolean).pop();
  const placeholder = document.getElementById('vendor-content-placeholder');
  
  if (placeholder) {
    // Show loading state initially
    placeholder.innerHTML = '<div class="animate-pulse bg-gray-200 h-32 rounded-md my-4"></div>';
    
    // After a brief delay, redirect to the client route
    setTimeout(() => {
      window.location.href = `/vendors/client/${vendorId}`;
    }, 500);
  }
});
