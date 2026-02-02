import React from 'react';
import { EnvelopeSimple, ChatCircle, Phone } from '@phosphor-icons/react';

const Support: React.FC = () => {
    return (
        <div className="bg-dark min-h-screen">
            <section className="pt-4 pb-16 lg:pt-16 lg:pb-24 px-6">
                <div className="max-w-3xl mx-auto text-center">
                    <div className="w-20 h-20 bg-primary/10 rounded-3xl flex items-center justify-center text-primary mx-auto mb-10 animate-fade-in">
                        <ChatCircle size={40} weight="fill" />
                    </div>

                    <h1 className="font-display font-extrabold text-[2rem] lg:text-[3rem] leading-[1.1] text-white tracking-tight mb-8">
                        Need help?
                    </h1>

                    <p className="text-lg lg:text-xl text-neutral-400 mb-12 leading-relaxed max-w-2xl mx-auto">
                        Whether you need help with a part, a fitting, or a service booking, our team is ready to assist.
                    </p>

                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                        <a
                            href="mailto:garage@sparewo.ug"
                            className="bg-white/5 border border-white/5 p-8 rounded-3xl hover:bg-white/10 transition-all hover:-translate-y-1 group"
                        >
                            <EnvelopeSimple size={32} className="text-primary mb-4 mx-auto group-hover:scale-110 transition-transform" />
                            <p className="font-bold text-white mb-1">Email Us</p>
                            <p className="text-sm text-neutral-400">garage@sparewo.ug</p>
                        </a>

                        <a
                            href="tel:+256700000000"
                            className="bg-white/5 border border-white/5 p-8 rounded-3xl hover:bg-white/10 transition-all hover:-translate-y-1 group"
                        >
                            <Phone size={32} className="text-primary mb-4 mx-auto group-hover:scale-110 transition-transform" />
                            <p className="font-bold text-white mb-1">Call Us</p>
                            <p className="text-sm text-neutral-400">+256 700 000 000</p>
                        </a>

                        <a
                            href="/app"
                            className="bg-primary p-8 rounded-3xl hover:bg-orange-600 transition-all hover:-translate-y-1 shadow-lg shadow-primary/20 group md:col-span-2 lg:col-span-1"
                        >
                            <ChatCircle size={32} weight="fill" className="text-white mb-4 mx-auto group-hover:scale-110 transition-transform" />
                            <p className="font-bold text-white mb-1">In-App Chat</p>
                            <p className="text-sm text-white/80">Recommended for support</p>
                        </a>
                    </div>
                </div>
            </section>
        </div>
    );
};

export default Support;
