import React from 'react';
import { Car, ShoppingCart, CreditCard } from '@phosphor-icons/react';

const HowItWorks: React.FC = () => {
  const steps = [
    {
      id: "01",
      icon: Car,
      title: "Tell us about your car",
      desc: "Add your car in the app so parts and services match your vehicle."
    },
    {
      id: "02",
      icon: ShoppingCart,
      title: "Choose what you need",
      desc: "Buy a spare part with fitting, or book a car care service."
    },
    {
      id: "03",
      icon: CreditCard,
      title: "Pay and relax",
      desc: "Pay securely and let us handle the rest. No jargon. No hidden steps."
    }
  ];

  return (
    <section className="bg-secondary py-20">
      <div className="max-w-7xl mx-auto px-6">
        <div className="mb-12 text-center">
          <h2 className="font-display font-bold text-3xl md:text-4xl text-white mb-4">How It Works</h2>
          <p className="text-neutral-400">Straightforward and reassuring.</p>
        </div>
        <div className="grid lg:grid-cols-3 gap-8">
          {steps.map((step, index) => (
            <div key={index} className="relative p-10 bg-white/5 rounded-3xl hover:bg-white/10 transition-colors group">
              <div className="mb-8 flex justify-between items-start">
                <step.icon size={48} className="text-primary" weight="duotone" />
                <span className="font-display font-bold text-3xl text-white/10">
                  {step.id}
                </span>
              </div>

              <h3 className="font-display font-bold text-xl text-white mb-3">
                {step.title}
              </h3>
              <p className="text-neutral-400 text-sm leading-relaxed">
                {step.desc}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default HowItWorks;