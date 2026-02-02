import React from 'react';
import { Wrench, CheckCircle, Car, Info } from '@phosphor-icons/react';

const Services: React.FC = () => {
    return (
        <div className="bg-dark min-h-screen">
            {/* Header */}
            <section className="pt-4 pb-8 px-6">
                <div className="max-w-7xl mx-auto">
                    <h1 className="font-display font-extrabold text-[2rem] lg:text-[3rem] leading-[1.1] text-white tracking-tight text-center lg:text-left">
                        Our Services
                    </h1>
                </div>
            </section>

            {/* Spare Parts and Fitting */}
            <section className="pt-8 pb-16 px-6">
                <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 items-center animate-fade-in">
                    <div className="flex flex-col items-center lg:items-start text-center lg:text-left">
                        <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center text-primary mb-8">
                            <Wrench size={32} weight="fill" />
                        </div>
                        <h2 className="font-display font-bold text-[1.75rem] lg:text-[2.5rem] leading-[1.1] text-white mb-6">
                            Buy the right part. <br />
                            <span className="text-primary">Get it fitted properly.</span>
                        </h2>
                        <p className="text-neutral-400 text-lg mb-8 leading-relaxed max-w-lg">
                            We solve the "buying the wrong part" problem. Choose your car, find the genuine part you need, and we'll arrange for a qualified mechanic to fit it for you.
                        </p>

                        {/* Mobile Image */}
                        <div className="lg:hidden w-full mb-8">
                            <div className="rounded-3xl overflow-hidden shadow-2xl">
                                <img
                                    src="https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?q=80&w=2600&auto=format&fit=crop"
                                    alt="Mechanic at work"
                                    className="w-full h-auto"
                                />
                            </div>
                        </div>

                        <div className="space-y-6 w-full max-w-md">
                            <div className="flex items-start gap-4 p-4 rounded-xl bg-white/5 border border-white/5 text-left">
                                <div className="text-primary mt-1">
                                    <CheckCircle size={20} weight="fill" />
                                </div>
                                <div>
                                    <h3 className="text-white font-bold">Genuine Parts Only</h3>
                                    <p className="text-sm text-neutral-400 mt-1">Verified sources, quality checked.</p>
                                </div>
                            </div>
                            <div className="flex items-start gap-4 p-4 rounded-xl bg-white/5 border border-white/5 text-left">
                                <div className="text-primary mt-1">
                                    <CheckCircle size={20} weight="fill" />
                                </div>
                                <div>
                                    <h3 className="text-white font-bold">Guaranteed Fitting</h3>
                                    <p className="text-sm text-neutral-400 mt-1">Fitting arranged alongside purchase.</p>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div className="hidden lg:block relative text-right">
                        <div className="rounded-3xl overflow-hidden shadow-2xl inline-block">
                            <img
                                src="https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?q=80&w=2600&auto=format&fit=crop"
                                alt="Mechanic at work"
                                className="w-[500px] h-auto object-cover rounded-3xl"
                            />
                        </div>
                    </div>
                </div>
            </section>

            {/* AutoHub */}
            <section className="pt-8 pb-16 px-6">
                <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 items-center animate-fade-in-up" style={{ animationDelay: '0.2s' }}>
                    <div className="flex flex-col items-center lg:items-start text-center lg:text-left">
                        <div className="w-16 h-16 bg-white/10 rounded-2xl flex items-center justify-center text-white mb-8">
                            <Car size={32} weight="fill" />
                        </div>
                        <h2 className="font-display font-bold text-[1.75rem] lg:text-[2.5rem] leading-[1.1] text-white mb-6">
                            AutoHub: car care <br />
                            <span className="text-neutral-500">beyond spare parts.</span>
                        </h2>
                        <p className="text-neutral-400 text-lg mb-8 leading-relaxed max-w-lg">
                            AutoHub is our dedicated car care service. From deep diagnostics and full servicing to general maintenance and specialized inspections.
                        </p>

                        {/* Mobile Image */}
                        <div className="lg:hidden w-full mb-8">
                            <div className="rounded-3xl overflow-hidden shadow-2xl">
                                <img
                                    src="/Request Service.jpg"
                                    alt="AutoHub Service"
                                    className="w-full h-auto"
                                />
                            </div>
                        </div>
                    </div>

                    <div className="hidden lg:block relative text-right">
                        <div className="rounded-3xl overflow-hidden shadow-2xl inline-block">
                            <img
                                src="/Request Service.jpg"
                                alt="AutoHub Service"
                                className="w-[500px] h-auto object-cover rounded-3xl"
                            />
                        </div>
                    </div>
                </div>
            </section>
        </div>
    );
};

export default Services;