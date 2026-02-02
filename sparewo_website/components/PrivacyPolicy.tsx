import React from 'react';

const PrivacyPolicy: React.FC = () => {
    return (
        <div className="bg-dark min-h-screen">
            <section className="py-24 px-6">
                <div className="max-w-4xl mx-auto">
                    <h1 className="font-display font-extrabold text-4xl lg:text-5xl text-white mb-16">
                        Privacy Policy
                    </h1>

                    <div className="space-y-12 text-neutral-400 leading-relaxed font-sans">

                        <section>
                            <h2 className="text-white font-bold text-xl mb-4">Information we collect</h2>
                            <p>
                                We collect information you provide directly to us, such as when you create an account, make a purchase, or contact support.
                                This may include your name, email address, phone number, vehicle information, and payment details.
                                We also collect usage data automatically when you interact with our services.
                            </p>
                        </section>

                        <section>
                            <h2 className="text-white font-bold text-xl mb-4">How we use it</h2>
                            <p>
                                We use your information to facilitate order processing, deliver spare parts, arrange fitting services, and manage your account.
                                Additionally, we use data to improve our platform, communicate with you regarding your orders or account status, and for internal analytics.
                            </p>
                        </section>

                        <section>
                            <h2 className="text-white font-bold text-xl mb-4">Payments and security</h2>
                            <p>
                                Payment processing is handled by secure third-party payment providers. We do not store your full credit card details on our servers.
                                We implement industry-standard security measures to protect your personal information from unauthorized access or disclosure.
                            </p>
                        </section>

                        <section>
                            <h2 className="text-white font-bold text-xl mb-4">Third-party services</h2>
                            <p>
                                We may share your information with third-party service providers who assist us in our operations, such as logistics partners for delivery,
                                mechanics for fitting services, and cloud hosting providers. These parties are authorized to use your data only as necessary to provide these services to us.
                            </p>
                        </section>

                        <section>
                            <h2 className="text-white font-bold text-xl mb-4">Your rights</h2>
                            <p>
                                You have the right to access, correct, or delete your personal information held by us.
                                You may also object to the processing of your data or request data portability.
                                To exercise these rights, please contact us.
                            </p>
                        </section>

                        <section>
                            <h2 className="text-white font-bold text-xl mb-4">Contact information</h2>
                            <p>
                                If you have any questions about this Privacy Policy, please contact us at <a href="mailto:support@sparewo.ug" className="text-primary hover:text-white">support@sparewo.ug</a>.
                            </p>
                        </section>

                    </div>
                </div>
            </section>
        </div>
    );
};

export default PrivacyPolicy;
