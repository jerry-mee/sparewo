import React from 'react';
import { ShoppingCart, Wrench, CarProfile } from '@phosphor-icons/react';

const WhatYouCanDo: React.FC = () => {
    const features = [
        {
            icon: ShoppingCart,
            title: "Buy parts",
            desc: "Find genuine spare parts by car, brand, or part number, with clear pricing and availability."
        },
        {
            icon: Wrench,
            title: "Fit parts",
            desc: "When you buy a spare part, fitting is arranged alongside the purchase so the job is done right."
        },
        {
            icon: CarProfile,
            title: "Care for your car",
            desc: "Book additional car care services through AutoHub when your car needs attention beyond parts."
        }
    ];

    return (
        <section className="py-20 bg-dark">
            <div className="max-w-7xl mx-auto px-6">
                <div className="mb-16">
                    <h2 className="font-display font-bold text-3xl md:text-4xl text-white mb-6">
                        What you can do with SpareWo
                    </h2>
                    <p className="text-neutral-400 text-lg max-w-2xl">
                        This is not marketing fluff. It is capability-led.
                    </p>
                </div>

                <div className="grid md:grid-cols-3 gap-8">
                    {features.map((feature, idx) => (
                        <div key={idx} className="bg-white/5 border border-white/5 rounded-3xl p-8 hover:bg-white/10 transition-all group">
                            <div className="w-14 h-14 bg-primary/10 rounded-2xl flex items-center justify-center text-primary mb-6 group-hover:scale-110 transition-transform">
                                <feature.icon size={32} weight="fill" />
                            </div>
                            <h3 className="text-xl font-bold font-display text-white mb-3">
                                {feature.title}
                            </h3>
                            <p className="text-neutral-400 leading-relaxed">
                                {feature.desc}
                            </p>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    );
};

export default WhatYouCanDo;
