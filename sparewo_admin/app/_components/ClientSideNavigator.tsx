'use client';

import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';

export default function ClientSideNavigator() {
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    // Add event listener for clicks on links
    const handleClick = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      const link = target.closest('a');
      
      if (link && link.href && link.href.startsWith(window.location.origin) && 
          !link.target && !link.download && !link.rel?.includes('external')) {
        e.preventDefault();
        const href = link.href.replace(window.location.origin, '');
        router.push(href);
      }
    };

    document.addEventListener('click', handleClick);
    
    return () => {
      document.removeEventListener('click', handleClick);
    };
  }, [router]);

  return null;
}
