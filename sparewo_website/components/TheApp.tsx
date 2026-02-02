import React from 'react';
import { CheckCircle, DeviceMobile, GooglePlayLogo, AppStoreLogo, ShoppingCart } from '@phosphor-icons/react';

const TheApp: React.FC = () => {
    return (
        <div className="bg-dark min-h-screen">
            <section className="pt-4 pb-16 lg:pt-16 lg:pb-24 px-6">
                <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 items-start">

                    {/* Left Column: Content */}
                    <div className="text-center lg:text-left animate-fade-in">
                        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/5 text-primary font-medium text-xs mb-8 mx-auto lg:mx-0">
                            <DeviceMobile size={16} weight="fill" />
                            Mobile App
                        </div>
                        <h1 className="font-display font-extrabold text-[2rem] lg:text-[3rem] leading-[1.1] text-white tracking-tight mb-6">
                            More than buying parts.
                        </h1>
                        <p className="text-base lg:text-xl text-neutral-400 mb-10 leading-relaxed max-w-2xl mx-auto lg:mx-0">
                            The SpareWo app helps you stay on top of your car, not just your purchases.
                        </p>

                        {/* Mobile Image (Hidden on lg) */}
                        <div className="block lg:hidden mb-12 relative max-w-[280px] mx-auto">
                            <div className="rounded-[2.5rem] overflow-hidden border-8 border-white/5 shadow-2xl bg-white/5">
                                <img
                                    src="/my_car_sample.jpeg"
                                    alt="SpareWo App Screenshot"
                                    className="w-full h-auto block"
                                />
                            </div>
                        </div>

                        <ul className="space-y-6 mb-12 max-w-lg mx-auto lg:mx-0 text-left">
                            {[
                                "Track your car’s service history",
                                "Keep a record of insurance and important dates",
                                "Know when your car last received attention",
                                "Manage spare part purchases and fittings",
                                "Book AutoHub services when needed"
                            ].map((item, idx) => (
                                <li key={idx} className="flex items-start gap-4 text-white font-medium group">
                                    <div className="w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center text-primary shrink-0 mt-0.5">
                                        <CheckCircle size={14} weight="fill" />
                                    </div>
                                    <span className="leading-snug">{item}</span>
                                </li>
                            ))}
                        </ul>

                        <div className="space-y-8">
                            <div className="space-y-4">
                                <p className="font-display font-bold text-white text-lg">Get the App</p>
                                <div className="flex flex-wrap gap-4 justify-center lg:justify-start">
                                    <button className="bg-white text-dark px-6 py-3 rounded-xl font-bold flex items-center gap-2 hover:bg-neutral-200 transition-colors text-sm lg:text-base">
                                        <AppStoreLogo size={24} weight="fill" />
                                        App Store
                                    </button>
                                    <button className="bg-white/10 text-white px-6 py-3 rounded-xl font-bold flex items-center gap-2 hover:bg-white/20 transition-colors text-sm lg:text-base">
                                        <GooglePlayLogo size={24} weight="fill" />
                                        Google Play
                                    </button>
                                    <a
                                        href="https://store.sparewo.ug"
                                        target="_blank"
                                        rel="noreferrer"
                                        className="bg-primary/10 text-primary px-6 py-3 rounded-xl font-bold flex items-center gap-2 hover:bg-primary/20 transition-colors text-sm lg:text-base"
                                    >
                                        <ShoppingCart size={24} weight="fill" />
                                        Web Store
                                    </a>
                                </div>
                            </div>
                            <p className="text-sm text-neutral-500 max-w-sm mx-auto lg:mx-0">
                                The web store covers parts. The app gives you the full picture.
                            </p>
                        </div>
                    </div>

                    {/* Right Column: Visual (Desktop Only) */}
                    <div className="hidden lg:block relative sticky top-32">
                        <div className="max-w-[320px] mx-auto relative">
                            <div className="rounded-[3rem] overflow-hidden border-[12px] border-white/5 shadow-2xl bg-white/5 transform lg:rotate-2 hover:rotate-0 transition-transform duration-500">
                                <img
                                    src="/my_car_sample.jpeg"
                                    alt="SpareWo App Screenshot"
                                    className="w-full h-auto block"
                                />
                            </div>

                            {/* Floating Decorative Elements */}
                            <div className="absolute -bottom-10 -left-10 bg-dark p-6 rounded-2xl border border-white/10 shadow-2xl max-w-[200px] animate-fade-in">
                                <div className="flex items-center gap-4 mb-2">
                                    <div className="w-10 h-10 bg-green-500/20 rounded-xl flex items-center justify-center text-green-500 shrink-0">
                                        <CheckCircle size={20} weight="fill" />
                                    </div>
                                    <p className="text-white font-bold text-sm leading-tight">Service Log Updated</p>
                                </div>
                                <p className="text-neutral-400 text-xs text-left">Oil change and filters replaced Successfully.</p>
                            </div>
                        </div>

                        {/* Background Glow */}
                        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-80 h-80 bg-primary/20 rounded-full blur-[100px] -z-10"></div>
                    </div>

                </div>
            </section>
        </div>
    );
};

export default TheApp;
