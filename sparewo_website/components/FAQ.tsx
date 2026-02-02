import React, { useState } from 'react';
import { CaretDown } from '@phosphor-icons/react';

const FAQItem = ({ question, answer }: { question: string, answer: string }) => {
    const [isOpen, setIsOpen] = useState(false);

    return (
        <div className="border border-white/5 rounded-2xl bg-white/5 overflow-hidden transition-all hover:bg-white/10">
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="w-full flex items-center justify-between p-6 text-left"
            >
                <span className="font-display font-bold text-white text-lg">{question}</span>
                <CaretDown
                    size={20}
                    className={`text-neutral-400 transition-transform duration-300 ${isOpen ? 'rotate-180' : ''}`}
                />
            </button>
            <div
                className={`px-6 text-neutral-400 leading-relaxed transition-all duration-300 overflow-hidden ${isOpen ? 'max-h-40 pb-6 opacity-100' : 'max-h-0 pb-0 opacity-0'
                    }`}
            >
                {answer}
            </div>
        </div>
    );
};

const FAQ: React.FC = () => {
    const questions = [
        {
            q: "Are the spare parts genuine?",
            a: "Yes. All parts are sourced from vetted suppliers and checked before delivery."
        },
        {
            q: "Do you provide part fitting?",
            a: "Yes. Part fitting is offered alongside spare part purchases."
        },
        {
            q: "Is part fitting done through AutoHub?",
            a: "No. AutoHub is for other car care services only."
        },
        {
            q: "What services does AutoHub cover?",
            a: "Diagnostics, servicing, maintenance, inspections, and other non-part services."
        },
        {
            q: "What extra benefits do I get from the app?",
            a: "You can track your car’s health, service history, and important dates in one place."
        }
    ];

    return (
        <div className="bg-dark min-h-screen">
            <section className="py-24 px-6 md:px-12 lg:px-24">
                <div className="max-w-3xl mx-auto">
                    <div className="text-center mb-16">
                        <h1 className="font-display font-extrabold text-4xl lg:text-5xl text-white mb-6">
                            Frequently Asked Questions
                        </h1>
                        <p className="text-neutral-400 text-lg">
                            Short answers to common questions.
                        </p>
                    </div>

                    <div className="space-y-4">
                        {questions.map((item, idx) => (
                            <FAQItem key={idx} question={item.q} answer={item.a} />
                        ))}
                    </div>
                </div>
            </section>
        </div>
    );
};

export default FAQ;
