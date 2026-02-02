import React from 'react';
import { EnvelopeSimple, ChatCircle } from '@phosphor-icons/react';

const Support: React.FC = () => {
    return (
        <div className="bg-dark min-h-screen flex items-center justify-center">
            <section className="py-24 px-6 w-full">
                <div className="max-w-2xl mx-auto text-center">
                    <div className="w-20 h-20 bg-primary/10 rounded-3xl flex items-center justify-center text-primary mx-auto mb-8">
                        <ChatCircle size={40} weight="fill" />
                    </div>

                    <h1 className="font-display font-extrabold text-5xl text-white mb-6">
                        Need help?
                    </h1>

                    <p className="text-xl text-neutral-400 mb-12 leading-relaxed">
                        If you need assistance with a part order, fitting, a service booking, or your account, our support team is ready to help.
                    </p>

                    <div className="grid md:grid-cols-2 gap-6">
                        <a
                            href="mailto:support@sparewo.ug"
                            className="bg-white/5 border border-white/5 p-8 rounded-2xl hover:bg-white/10 transition-colors group"
                        >
                            <div className="flex flex-col items-center gap-4">
                                <EnvelopeSimple size={32} className="text-white group-hover:scale-110 transition-transform" />
                                <div className="text-center">
                                    <p className="font-bold text-white">Email Us</p>
                                    <p className="text-primary mt-1">support@sparewo.ug</p>
                                </div>
                            </div>
                        </a>

                        <a
                            href="/app"
                            className="bg-primary p-8 rounded-2xl hover:bg-orange-600 transition-colors shadow-lg shadow-primary/20 group"
                        >
                            <div className="flex flex-col items-center gap-4">
                                <ChatCircle size={32} className="text-white group-hover:scale-110 transition-transform" weight="fill" />
                                <div className="text-center">
                                    <p className="font-bold text-white">In-App Support</p>
                                    <p className="text-white/80 mt-1">Recommended for faster help</p>
                                </div>
                            </div>
                        </a>
                    </div>
                </div>
            </section>
        </div>
    );
};

export default Support;
