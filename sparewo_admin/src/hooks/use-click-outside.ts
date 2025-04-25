import { RefObject, useEffect } from 'react';

/**
 * Hook that handles click outside of the passed refs
 * @param refs - Array of refs to elements that should not trigger the handler
 * @param handler - Function to call when a click outside occurs
 */
export const useClickOutside = (refs: RefObject<HTMLElement>[], handler: () => void): void => {
  useEffect(() => {
    const listener = (event: MouseEvent | TouchEvent) => {
      // Do nothing if any of the refs contains the target
      if (!event.target) return;
      
      const clickedInside = refs.some(ref => 
        ref.current && ref.current.contains(event.target as Node)
      );
      
      if (clickedInside) return;
      
      handler();
    };
    
    document.addEventListener('mousedown', listener);
    document.addEventListener('touchstart', listener);
    
    return () => {
      document.removeEventListener('mousedown', listener);
      document.removeEventListener('touchstart', listener);
    };
  }, [refs, handler]);
};