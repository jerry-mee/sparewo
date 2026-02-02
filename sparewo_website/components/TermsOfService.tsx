import React from 'react';

const TermsOfService: React.FC = () => {
    return (
        <div className="bg-dark min-h-screen">
            <section className="pt-4 pb-16 lg:pt-16 lg:pb-24 px-6">
                <div className="max-w-4xl mx-auto">
                    <h1 className="font-display font-extrabold text-[2rem] lg:text-[3rem] leading-[1.1] text-white tracking-tight mb-8 lg:mb-16 text-center lg:text-left">
                        Terms and Conditions
                    </h1>

                    <div className="space-y-12 text-neutral-400 leading-relaxed font-sans">

                        <p className="animate-fade-in" style={{ animationDelay: '0.05s' }}>
                            These Terms and Conditions apply to the use of SpareWo’s platform, including the purchase of spare parts, part fitting, and car care services. By using SpareWo, you agree to the terms set out below.
                        </p>

                        <section className="animate-fade-in" style={{ animationDelay: '0.1s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">1. About SpareWo</h2>
                            <p>
                                SpareWo (U) Ltd provides:
                            </p>
                            <ul className="list-disc pl-6 mt-4 space-y-2">
                                <li>Genuine auto spare parts</li>
                                <li>Fitting services provided alongside spare part purchases</li>
                                <li>Additional car care services, including diagnostics and maintenance</li>
                            </ul>
                            <p className="mt-4">Some services may be carried out by approved third-party service providers.</p>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.15s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">2. Spare Parts and Services</h2>
                            <ul className="list-disc pl-6 space-y-2">
                                <li>All spare parts are supplied based on the information provided by the customer.</li>
                                <li>Services are provided as agreed at the time of booking or purchase.</li>
                                <li>SpareWo takes reasonable care to ensure quality parts and workmanship.</li>
                            </ul>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.2s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">3. Payments</h2>
                            <ul className="list-disc pl-6 space-y-2">
                                <li>Prices are communicated before payment is made.</li>
                                <li>Payment may be made using Mobile Money, cards, or other approved methods.</li>
                                <li>Some services may require partial or full payment before work begins.</li>
                            </ul>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.25s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">4. Warranty</h2>
                            <ul className="list-disc pl-6 space-y-2">
                                <li>Spare parts supplied by SpareWo are covered by a <strong>90-day warranty</strong> from the date of delivery or fitting.</li>
                                <li>The warranty covers defects related to the part supplied or fitting provided by SpareWo.</li>
                                <li>The warranty does not cover damage caused by misuse, accidents, neglect, or normal wear and tear.</li>
                            </ul>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.3s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">5. Replacements and Free Fitting</h2>
                            <ul className="list-disc pl-6 space-y-2">
                                <li>If a spare part is found to be defective within the warranty period, SpareWo will replace it where applicable.</li>
                                <li><strong>Fitting for approved replacements is provided free of charge.</strong></li>
                                <li>Replacement is subject to inspection and confirmation by SpareWo.</li>
                            </ul>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.35s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">6. Refunds</h2>
                            <ul className="list-disc pl-6 space-y-2">
                                <li>Refunds may be requested <strong>within 30 days</strong> of purchase.</li>
                                <li>Refunds are subject to the condition that the part has not been misused or damaged.</li>
                                <li>Where applicable, refunds may be processed after inspection and verification.</li>
                            </ul>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.4s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">7. Customer Responsibilities</h2>
                            <p className="mb-4">Customers are responsible for:</p>
                            <ul className="list-disc pl-6 space-y-2">
                                <li>Providing accurate information about their vehicle</li>
                                <li>Disclosing relevant service or repair history</li>
                                <li>Making the vehicle available at the agreed time</li>
                                <li>Following reasonable care and maintenance guidance</li>
                            </ul>
                            <p className="mt-4">SpareWo is not responsible for issues arising from incorrect or incomplete information provided by the customer.</p>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.45s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">8. Limitation of Liability</h2>
                            <ul className="list-disc pl-6 space-y-2">
                                <li>SpareWo’s liability is limited to the value of the parts or services provided.</li>
                                <li>SpareWo is not liable for indirect or consequential losses.</li>
                                <li>SpareWo is not responsible for pre-existing vehicle conditions or faults outside the agreed scope of work.</li>
                            </ul>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.5s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">9. Delays and Risk</h2>
                            <ul className="list-disc pl-6 space-y-2">
                                <li>While SpareWo aims to deliver services on time, delays may occur due to availability of parts or other factors beyond reasonable control.</li>
                                <li>Vehicles and components are handled with reasonable care, but remain at the customer’s risk unless loss or damage is caused by SpareWo’s negligence.</li>
                            </ul>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.55s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">10. Disputes</h2>
                            <p>Any disputes will first be addressed in good faith. If unresolved, disputes may be referred to arbitration in accordance with the laws of Uganda.</p>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.6s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">11. Governing Law</h2>
                            <p>These Terms and Conditions are governed by the laws of the Republic of Uganda.</p>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.65s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">12. Privacy</h2>
                            <p>Customer information is handled with reasonable care and confidentiality. Information may be used to provide services, support, and relevant communication in line with SpareWo’s Privacy Policy.</p>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.7s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">13. Changes to These Terms</h2>
                            <p>SpareWo may update these Terms and Conditions from time to time. Continued use of the platform means you accept the updated terms.</p>
                        </section>

                        <section className="animate-fade-in" style={{ animationDelay: '0.75s' }}>
                            <h2 className="text-white font-bold text-xl mb-4">Contact</h2>
                            <p>
                                If you have questions about these terms, please contact us at <a href="mailto:garage@sparewo.ug" className="text-primary hover:text-white transition-colors">garage@sparewo.ug</a>.
                            </p>
                        </section>

                    </div>
                </div>
            </section>
        </div>
    );
};

export default TermsOfService;
