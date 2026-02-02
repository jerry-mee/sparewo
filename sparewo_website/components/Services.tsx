import React from 'react';
import { ShoppingCart, Wrench, CheckCircle, Car } from '@phosphor-icons/react';

const Services: React.FC = () => {
    return (
        <div className="bg-dark min-h-screen">
            {/* Header */}
            <section className="pt-4 pb-8 px-6 border-b border-white/5">
                <div className="max-w-7xl mx-auto">
                    <h1 className="font-display font-extrabold text-[2.5rem] text-white">
                        Our Services
                    </h1>
                </div>
            </section>

            {/* Spare Parts and Fitting */}
            <section className="pt-8 pb-16 px-6 border-b border-white/5">
                <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 items-center">
                    <div>
                        <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center text-primary mb-8">
                            <ShoppingCart size={32} weight="fill" />
                        </div>
                        <h2 className="font-display font-bold text-[2.5rem] text-white mb-6">
                            Buy the right part. <br />
                            <span className="text-primary">Get it fitted properly.</span>
                        </h2>
                        <p className="text-neutral-400 text-lg leading-relaxed mb-8">
                            SpareWo lets you buy genuine spare parts with the option to have them fitted as part of the same process.
                            This reduces guesswork, prevents mistakes, and saves time.
                        </p>
                        <ul className="space-y-4">
                            {[
                                "Verified spare parts",
                                "Clear pricing",
                                "Optional fitting arranged with the purchase",
                                "One process from order to completion"
                            ].map((item, idx) => (
                                <li key={idx} className="flex items-center gap-3 text-white">
                                    <CheckCircle size={20} className="text-primary" weight="fill" />
                                    {item}
                                </li>
                            ))}
                        </ul>
                    </div>
                    <div className="bg-white/5 rounded-3xl p-8 lg:p-12 border border-white/5">
                        <div className="space-y-6">
                            <div className="flex items-start gap-4 p-4 bg-white/5 rounded-xl">
                                <Wrench size={24} className="text-primary mt-1" />
                                <div>
                                    <p className="font-bold text-white">Fit Parts</p>
                                    <p className="text-sm text-neutral-400 mt-1">Fitting arranged alongside purchase.</p>
                                </div>
                            </div>

                        </div>
                    </div>
                </div>
            </section>

            {/* AutoHub */}
            <section className="pt-8 pb-16 px-6">
                <div className="max-w-7xl mx-auto grid lg:grid-cols-2 gap-16 items-center">
                    <div className="order-2 lg:order-1 bg-white/5 rounded-3xl p-8 lg:p-12 border border-white/5">
                        <div className="flex items-center gap-4 mb-8">
                            <div className="w-12 h-12 bg-white/10 rounded-full flex items-center justify-center">
                                <Car size={24} className="text-white" />
                            </div>
                            <span className="font-display font-bold text-xl text-white">AutoHub</span>
                        </div>
                        <div className="p-6 bg-red-500/10 rounded-xl border border-red-500/20">
                            <p className="text-red-400 font-medium text-sm">
                                <span className="font-bold block mb-1 text-white">Important Clarification</span>
                                AutoHub does not handle spare part fitting. Fitting is provided with spare part purchases.
                            </p>
                        </div>
                    </div>

                    <div className="order-1 lg:order-2">
                        <div className="w-16 h-16 bg-white/10 rounded-2xl flex items-center justify-center text-white mb-8">
                            <Car size={32} weight="fill" />
                        </div>
                        <h2 className="font-display font-bold text-[2.5rem] text-white mb-6">
                            AutoHub: car care <br />
                            <span className="text-neutral-500">beyond spare parts.</span>
                        </h2>
                        <p className="text-neutral-400 text-lg leading-relaxed mb-8">
                            AutoHub covers automotive services that are not tied to spare part purchases.
                            It is designed for ongoing car care and general vehicle needs.
                        </p>
                        <h3 className="text-white font-bold mb-4">Examples of AutoHub services:</h3>
                        <ul className="space-y-4">
                            {[
                                "Vehicle diagnostics",
                                "Routine servicing",
                                "Maintenance and repairs",
                                "Inspections and assessments"
                            ].map((item, idx) => (
                                <li key={idx} className="flex items-center gap-3 text-white">
                                    <CheckCircle size={20} className="text-neutral-500" weight="fill" />
                                    {item}
                                </li>
                            ))}
                        </ul>
                    </div>
                </div>
            </section>
        </div>
    );
};

export default Services;