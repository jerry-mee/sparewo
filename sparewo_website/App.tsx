import React from 'react';
import { Routes, Route, useLocation } from 'react-router-dom';
import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import Hero from '@/components/Hero';
import Services from '@/components/Services';
import TheApp from '@/components/TheApp';
import FAQ from '@/components/FAQ';
import Support from '@/components/Support';
import PrivacyPolicy from '@/components/PrivacyPolicy';
import TermsOfService from '@/components/TermsOfService';
import HowItWorks from '@/components/HowItWorks';
import WhatYouCanDo from '@/components/WhatYouCanDo';
import DataPrivacy from '@/components/DataPrivacy';

// Page components wrappers
const HomePage = () => (
  <>
    <Hero />
    <WhatYouCanDo />
  </>
);



const App: React.FC = () => {
  const location = useLocation();

  // Scroll to top on route change
  React.useEffect(() => {
    window.scrollTo(0, 0);
  }, [location]);

  return (
    <div className="min-h-screen w-full flex flex-col bg-dark text-white font-sans overflow-x-hidden">
      <Navbar />

      {/* Optimized padding and transitions */}
      <main className="flex-grow pt-28">
        <div key={location.pathname} className="animate-fade-in">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/services" element={<Services />} />
            <Route path="/app" element={<TheApp />} />
            <Route path="/faq" element={<FAQ />} />
            <Route path="/support" element={<Support />} />
            <Route path="/privacy-policy" element={<PrivacyPolicy />} />
            <Route path="/data-privacy" element={<DataPrivacy />} />
            <Route path="/terms-of-service" element={<TermsOfService />} />
            <Route path="/how-it-works" element={<HowItWorks />} />
            {/* Fallback route to catch any mismatches */}
            <Route path="*" element={<HomePage />} />
          </Routes>
        </div>
      </main>

      <Footer />
    </div>
  );
};

export default App;
