import React from 'react';
import { ArrowRight, Globe } from '@phosphor-icons/react';

const Hero: React.FC = () => {
  const handleAppDownload = (e: React.MouseEvent) => {
    e.preventDefault();
    const userAgent = navigator.userAgent || navigator.vendor || (window as any).opera;

    // Simple detection for Android vs iOS
    if (/android/i.test(userAgent)) {
      // Redirect to Google Play
      window.location.href = "https://play.google.com/store/search?q=sparewo";
    } else if (/iPad|iPhone|iPod/.test(userAgent) && !(window as any).MSStream) {
      // Redirect to App Store
      window.location.href = "https://apps.apple.com/ug/search?term=sparewo";
    } else {
      // Fallback for desktop or other devices -> Go to App page
      window.location.href = "/app";
    }
  };

  return (
    <>
      <section className="relative pt-4 pb-8 lg:pt-16 lg:pb-24 px-6 overflow-hidden">
        <div className="max-w-7xl mx-auto grid lg:grid-cols-12 gap-8 lg:gap-16 items-center">

          {/* Visual Side (First on Mobile) */}
          <div className="lg:col-span-5 relative order-first lg:order-last">
            <div className="relative rounded-3xl overflow-hidden shadow-2xl bg-card max-h-[40vh] lg:max-h-none">
              <div className="aspect-video lg:aspect-[4/5] relative">
                <img
                  src="/banner_home.png"
                  alt="SpareWo Hero Banner"
                  className="w-full h-full object-cover opacity-80"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-dark via-transparent to-transparent"></div>
              </div>
            </div>

            {/* Global Sourcing Info (Below Image) */}
            <div className="mt-6 bg-white/5 border border-white/5 p-4 lg:p-6 rounded-2xl backdrop-blur-sm">
              <div className="flex items-center gap-4">
                <div className="w-10 h-10 lg:w-12 lg:h-12 bg-primary rounded-xl flex items-center justify-center text-white shrink-0">
                  <Globe size={20} className="lg:hidden" weight="fill" />
                  <Globe size={24} className="hidden lg:block" weight="fill" />
                </div>
                <div>
                  <p className="text-white font-bold font-display text-sm lg:text-base">Global Sourcing</p>
                  <p className="text-neutral-400 text-xs lg:text-sm">Parts from Japan, UK & Germany</p>
                </div>
              </div>
            </div>

            {/* Background Glow */}
            <div className="absolute -top-20 -right-20 w-64 h-64 bg-primary/20 rounded-full blur-[100px] -z-10"></div>
          </div>

          {/* Main Text Area */}
          <div className="lg:col-span-7 text-center lg:text-left">

            <h1 className="font-display font-extrabold text-[2rem] lg:text-[2.5rem] leading-[1.1] text-white tracking-tight mb-4 lg:mb-8">
              Spare parts, fitting, <br />
              and <span className="text-primary">car care.</span> <br />
              All sorted.
            </h1>

            <p className="text-base lg:text-lg text-neutral-400 leading-relaxed mb-6 lg:mb-10 max-w-lg mx-auto lg:mx-0">
              SpareWo makes it easy to buy genuine spare parts, get them fitted correctly, and take care of your car without the usual back and forth.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 mb-6 lg:mb-8 justify-center lg:justify-start items-center">
              <a
                href="/app"
                onClick={handleAppDownload}
                className="bg-primary text-white px-8 py-3 rounded-2xl font-display font-bold text-base lg:text-lg hover:bg-orange-600 transition-all transform hover:-translate-y-1 shadow-lg shadow-primary/25 inline-flex items-center justify-center"
              >
                Download the App
              </a>
              <a
                href="https://store.sparewo.ug"
                target="_blank"
                rel="noreferrer"
                className="bg-white/5 text-white px-8 py-3 rounded-2xl font-display font-bold text-base lg:text-lg hover:bg-white/10 transition-colors inline-flex items-center justify-center border border-white/5"
              >
                Use the Web Store
              </a>
            </div>

            <a href="/how-it-works" className="text-neutral-400 hover:text-white font-medium text-sm transition-colors flex items-center justify-center lg:justify-start gap-2">
              See how it works <ArrowRight size={16} />
            </a>
          </div>

        </div>
      </section>
    </>
  );
};

export default Hero;