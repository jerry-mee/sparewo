import React from 'react';
import { CheckCircle, DeviceMobile, GooglePlayLogo, AppStoreLogo, ShoppingCart } from '@phosphor-icons/react';

const TheApp: React.FC = () => {
    return (
        <div className="bg-dark min-h-screen">
            <section className="py-24 px-6">
                <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 items-center">

                    {/* Text Content */}
                    <div>
                        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/5 text-primary font-medium text-xs mb-8">
                            <DeviceMobile size={16} weight="fill" />
                            Mobile App
                        </div>
                        <h1 className="font-display font-extrabold text-5xl lg:text-6xl text-white mb-6">
                            More than buying parts.
                        </h1>
                        <p className="text-xl text-neutral-400 mb-10 leading-relaxed">
                            The SpareWo app helps you stay on top of your car, not just your purchases.
                        </p>

                        <ul className="space-y-4 mb-12">
                            {[
                                "Track your car’s service history",
                                "Keep a record of insurance and important dates",
                                "Know when your car last received attention",
                                "Manage spare part purchases and fittings",
                                "Book AutoHub services when needed"
                            ].map((item, idx) => (
                                <li key={idx} className="flex items-center gap-3 text-white font-medium">
                                    <div className="w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center text-primary shrink-0">
                                        <CheckCircle size={14} weight="fill" />
                                    </div>
                                    {item}
                                </li>
                            ))}
                        </ul>

                        <div className="space-y-6">
                            <p className="font-display font-bold text-white text-lg">Get the App</p>
                            <div className="flex flex-wrap gap-4">
                                <button className="bg-white text-dark px-6 py-3 rounded-xl font-bold flex items-center gap-2 hover:bg-neutral-200 transition-colors">
                                    <AppStoreLogo size={24} weight="fill" />
                                    App Store
                                </button>
                                <button className="bg-white/10 text-white px-6 py-3 rounded-xl font-bold flex items-center gap-2 hover:bg-white/20 transition-colors">
                                    <GooglePlayLogo size={24} weight="fill" />
                                    Google Play
                                </button>
                                <a
                                    href="https://store.sparewo.ug"
                                    target="_blank"
                                    rel="noreferrer"
                                    className="bg-primary/10 text-primary px-6 py-3 rounded-xl font-bold flex items-center gap-2 hover:bg-primary/20 transition-colors"
                                >
                                    <ShoppingCart size={24} weight="fill" />
                                    Web Store
                                </a>
                            </div>
                            <p className="text-sm text-neutral-500">
                                The web store covers parts. The app gives you the full picture.
                            </p>
                        </div>
                    </div>

                    {/* Visual / Mockup */}
                    <div className="relative">
                        <div className="aspect-[3/4] bg-white/5 rounded-3xl border border-white/5 relative overflow-hidden flex items-center justify-center">
                            {/* Abstract Phone Representation */}
                            <div className="w-[60%] h-[80%] bg-dark rounded-[3rem] border-8 border-neutral-800 shadow-2xl relative overflow-hidden">
                                <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-br from-neutral-900 to-black p-6">
                                    {/* Mock UI */}
                                    <div className="flex justify-between items-center mb-8">
                                        <div className="w-8 h-8 rounded-full bg-white/10"></div>
                                        <div className="w-8 h-8 rounded-full bg-white/10"></div>
                                    </div>
                                    <div className="w-2/3 h-4 rounded-full bg-white/10 mb-4"></div>
                                    <div className="w-full h-32 rounded-2xl bg-primary/20 mb-4 border border-primary/20 flex items-center justify-center text-primary/50 text-xs">
                                        Car Health Stats
                                    </div>
                                    <div className="space-y-3">
                                        <div className="w-full h-16 rounded-xl bg-white/5"></div>
                                        <div className="w-full h-16 rounded-xl bg-white/5"></div>
                                        <div className="w-full h-16 rounded-xl bg-white/5"></div>
                                    </div>
                                </div>
                            </div>

                            {/* Floating Badge */}
                            <div className="absolute -bottom-6 -left-6 bg-card p-6 rounded-2xl border border-white/5 shadow-xl">
                                <div className="flex items-center gap-4">
                                    <div className="w-12 h-12 bg-green-500/20 rounded-full flex items-center justify-center text-green-500">
                                        <CheckCircle size={24} weight="fill" />
                                    </div>
                                    <div>
                                        <p className="text-white font-bold">Service Due</p>
                                        <p className="text-neutral-400 text-xs"> notified 2 days ago</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </section>
        </div>
    );
};

export default TheApp;
