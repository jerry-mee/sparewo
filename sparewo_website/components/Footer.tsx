import React from 'react';

const Footer: React.FC = () => {
    const currentYear = new Date().getFullYear();

    return (
        <footer className="bg-dark text-white py-12">
            <div className="max-w-7xl mx-auto px-6 flex flex-col md:flex-row justify-between items-center gap-6">

                {/* Copyright */}
                <div className="text-white font-medium text-sm">
                    © {currentYear} SpareWo (U) Ltd
                </div>

                {/* Links */}
                <div className="flex flex-wrap justify-center gap-8">
                    <a href="/privacy-policy" className="text-white hover:text-primary transition-colors text-sm font-medium">Privacy Policy</a>
                    <a href="/support" className="text-white hover:text-primary transition-colors text-sm font-medium">Support</a>
                    <a href="#" className="text-white hover:text-primary transition-colors text-sm font-medium">App Store</a>
                    <a href="#" className="text-white hover:text-primary transition-colors text-sm font-medium">Google Play</a>
                </div>

            </div>
        </footer>
    );
};

export default Footer;