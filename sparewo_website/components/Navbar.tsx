import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { List, X, Wrench, ShoppingCart } from '@phosphor-icons/react';

const Navbar: React.FC = () => {
  const [isOpen, setIsOpen] = useState(false);
  const location = useLocation();

  const navLinks = [
    { name: 'Home', path: '/' },
    { name: 'Services', path: '/services' },
    { name: 'The App', path: '/app' },
    { name: 'FAQ', path: '/faq' },
    { name: 'Support', path: '/support' },
  ];

  const isActive = (path: string) => location.pathname === path;

  return (
    <nav className="fixed top-0 w-full z-50 bg-dark backdrop-blur-xl">
      <div className="max-w-7xl mx-auto px-6 h-24 flex items-center justify-between">

        {/* Logo */}
        <Link to="/" className="flex items-center gap-3 group">
          <img src="/splash_logo.png" alt="SpareWo Logo" className="h-10 lg:h-12 w-auto object-contain group-hover:scale-105 transition-transform" />
        </Link>

        {/* Desktop Nav */}
        <div className="hidden lg:flex items-center gap-1 bg-white/5 px-2 py-1.5 rounded-full border border-white/5">
          {navLinks.map((link) => (
            <Link
              key={link.name}
              to={link.path}
              className={`font-display font-medium text-sm px-6 py-2.5 rounded-full transition-all duration-300 relative ${isActive(link.path)
                ? 'text-white bg-white/10 shadow-lg shadow-black/20'
                : 'text-white hover:bg-white/5'
                }`}
            >
              {link.name}
            </Link>
          ))}
        </div>

        {/* Actions */}
        <div className="hidden lg:flex items-center gap-6">
          <a
            href="https://store.sparewo.ug"
            target="_blank"
            rel="noreferrer"
            className="bg-primary text-white px-6 py-3 rounded-xl font-display font-bold text-sm hover:bg-orange-600 transition-all shadow-lg shadow-primary/25 hover:shadow-primary/40 hover:-translate-y-0.5"
          >
            Web Store
          </a>
        </div>

        {/* Mobile Toggle */}
        <button onClick={() => setIsOpen(!isOpen)} className="lg:hidden text-white p-2">
          {isOpen ? <X size={32} /> : <List size={32} />}
        </button>
      </div>

      {/* Mobile Menu Overlay */}
      <div
        className={`lg:hidden absolute top-full left-0 w-full bg-dark p-8 shadow-2xl transition-all duration-300 ease-in-out transform origin-top ${isOpen ? 'opacity-100 translate-y-0 visible' : 'opacity-0 -translate-y-2 invisible'
          }`}
      >
        <div className="flex flex-col gap-6 items-center">
          {navLinks.map((link) => (
            <Link
              key={link.name}
              to={link.path}
              onClick={() => setIsOpen(false)}
              className="text-3xl font-display font-extrabold text-white hover:text-primary py-3 text-center transition-all hover:scale-105 active:scale-95"
            >
              {link.name}
            </Link>
          ))}
          <a
            href="https://store.sparewo.ug"
            target="_blank"
            rel="noreferrer"
            className="bg-primary text-center py-4 px-12 rounded-2xl font-display font-bold text-white mt-6 hover:bg-orange-600 transition-all shadow-lg shadow-primary/20 w-full max-w-xs"
          >
            Visit Store
          </a>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;