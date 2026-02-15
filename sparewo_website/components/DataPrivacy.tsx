import React, { useMemo, useState } from 'react';
import {
  CheckCircle,
  EnvelopeSimple,
  ShieldCheck,
  Trash,
  WarningCircle,
  Wrench,
} from '@phosphor-icons/react';

type DeletionScope = 'account_all' | 'specific_data';

interface DeleteRequestForm {
  fullName: string;
  email: string;
  phone: string;
  accountIdentifier: string;
  deletionScope: DeletionScope;
  details: string;
  confirmIrreversible: boolean;
  confirmPhrase: string;
}

const INITIAL_FORM: DeleteRequestForm = {
  fullName: '',
  email: '',
  phone: '',
  accountIdentifier: '',
  deletionScope: 'account_all',
  details: '',
  confirmIrreversible: false,
  confirmPhrase: '',
};

const REQUIRED_CONFIRM_PHRASE = 'DELETE MY DATA';

const DataPrivacy: React.FC = () => {
  const [form, setForm] = useState<DeleteRequestForm>(INITIAL_FORM);
  const [error, setError] = useState<string>('');
  const [submitted, setSubmitted] = useState(false);

  const canSubmit = useMemo(() => {
    return Boolean(
      form.fullName.trim() &&
        form.email.trim() &&
        form.accountIdentifier.trim() &&
        form.confirmIrreversible &&
        form.confirmPhrase.trim().toUpperCase() === REQUIRED_CONFIRM_PHRASE,
    );
  }, [form]);

  const onFieldChange =
    (field: keyof DeleteRequestForm) =>
    (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
      const value =
        event.target.type === 'checkbox'
          ? (event.target as HTMLInputElement).checked
          : event.target.value;
      setForm((prev) => ({ ...prev, [field]: value as never }));
      setError('');
    };

  const onScopeChange = (scope: DeletionScope) => {
    setForm((prev) => ({ ...prev, deletionScope: scope }));
    setError('');
  };

  const onSubmit = (event: React.FormEvent) => {
    event.preventDefault();

    if (!canSubmit) {
      setError(
        'Please complete all required fields and type "DELETE MY DATA" to confirm.',
      );
      return;
    }

    const mailSubject = encodeURIComponent(
      'SpareWo Data Deletion Request - User Submission',
    );
    const mailBody = encodeURIComponent(
      [
        'A user has requested data deletion from https://www.sparewo.ug/data-privacy',
        '',
        `Full name: ${form.fullName}`,
        `Email: ${form.email}`,
        `Phone: ${form.phone || 'Not provided'}`,
        `Account identifier: ${form.accountIdentifier}`,
        `Deletion scope: ${
          form.deletionScope === 'account_all'
            ? 'Delete account + associated data'
            : 'Delete specific data only'
        }`,
        `Additional details: ${form.details || 'None'}`,
        '',
        'User confirmation:',
        '- Irreversible confirmation checkbox: YES',
        `- Typed phrase: ${form.confirmPhrase}`,
      ].join('\n'),
    );

    const mailto = `mailto:garage@sparewo.ug?subject=${mailSubject}&body=${mailBody}`;
    window.location.href = mailto;
    setSubmitted(true);
  };

  return (
    <div className="min-h-screen bg-[#1d2041] text-white">
      <section className="px-6 pt-4 pb-16 lg:pt-16 lg:pb-24">
        <div className="max-w-5xl mx-auto">
          <div className="mb-10 lg:mb-14">
            <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs font-semibold tracking-wide text-white/80">
              <ShieldCheck size={16} weight="fill" className="text-primary" />
              DATA PRIVACY
            </div>
            <h1 className="mt-4 font-display font-extrabold text-[2rem] leading-[1.1] text-white tracking-tight lg:text-[3rem]">
              Request account and data deletion
            </h1>
            <p className="mt-4 max-w-3xl text-neutral-300 leading-relaxed">
              Use this page to request deletion of your SpareWo account and
              associated personal data. For security, we verify ownership before
              processing deletion requests.
            </p>
          </div>

          <div className="grid gap-8 lg:grid-cols-[1.2fr_0.8fr]">
            <form
              onSubmit={onSubmit}
              className="rounded-3xl border border-white/10 bg-white/5 p-6 shadow-2xl backdrop-blur-sm lg:p-8"
            >
              <div className="mb-6 flex items-center gap-3">
                <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-primary/20">
                  <Trash size={22} className="text-primary" />
                </div>
                <div>
                  <h2 className="font-display text-xl font-bold text-white">
                    Deletion request form
                  </h2>
                  <p className="text-sm text-neutral-300">
                    Step 1: Share account details. Step 2: Confirm deletion.
                  </p>
                </div>
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <div className="sm:col-span-1">
                  <label className="mb-2 block text-sm font-semibold text-white/90">
                    Full name <span className="text-primary">*</span>
                  </label>
                  <input
                    value={form.fullName}
                    onChange={onFieldChange('fullName')}
                    className="w-full rounded-2xl border border-white/10 bg-[#161936] px-4 py-3 text-white placeholder:text-neutral-500 outline-none transition focus:border-primary/70 focus:ring-2 focus:ring-primary/30"
                    placeholder="Jane Doe"
                    autoComplete="name"
                    required
                  />
                </div>

                <div className="sm:col-span-1">
                  <label className="mb-2 block text-sm font-semibold text-white/90">
                    Email address <span className="text-primary">*</span>
                  </label>
                  <input
                    type="email"
                    value={form.email}
                    onChange={onFieldChange('email')}
                    className="w-full rounded-2xl border border-white/10 bg-[#161936] px-4 py-3 text-white placeholder:text-neutral-500 outline-none transition focus:border-primary/70 focus:ring-2 focus:ring-primary/30"
                    placeholder="you@example.com"
                    autoComplete="email"
                    required
                  />
                </div>

                <div className="sm:col-span-1">
                  <label className="mb-2 block text-sm font-semibold text-white/90">
                    Phone number
                  </label>
                  <input
                    value={form.phone}
                    onChange={onFieldChange('phone')}
                    className="w-full rounded-2xl border border-white/10 bg-[#161936] px-4 py-3 text-white placeholder:text-neutral-500 outline-none transition focus:border-primary/70 focus:ring-2 focus:ring-primary/30"
                    placeholder="+256..."
                    autoComplete="tel"
                  />
                </div>

                <div className="sm:col-span-1">
                  <label className="mb-2 block text-sm font-semibold text-white/90">
                    Account identifier <span className="text-primary">*</span>
                  </label>
                  <input
                    value={form.accountIdentifier}
                    onChange={onFieldChange('accountIdentifier')}
                    className="w-full rounded-2xl border border-white/10 bg-[#161936] px-4 py-3 text-white placeholder:text-neutral-500 outline-none transition focus:border-primary/70 focus:ring-2 focus:ring-primary/30"
                    placeholder="Account email, user ID, or phone used in app"
                    required
                  />
                </div>
              </div>

              <div className="mt-5">
                <p className="mb-3 text-sm font-semibold text-white/90">
                  Deletion scope <span className="text-primary">*</span>
                </p>
                <div className="grid gap-3 sm:grid-cols-2">
                  <button
                    type="button"
                    onClick={() => onScopeChange('account_all')}
                    className={`rounded-2xl border px-4 py-3 text-left text-sm transition ${
                      form.deletionScope === 'account_all'
                        ? 'border-primary bg-primary/15 text-white'
                        : 'border-white/10 bg-[#161936] text-neutral-300 hover:border-primary/50'
                    }`}
                  >
                    Delete account + associated personal data
                  </button>
                  <button
                    type="button"
                    onClick={() => onScopeChange('specific_data')}
                    className={`rounded-2xl border px-4 py-3 text-left text-sm transition ${
                      form.deletionScope === 'specific_data'
                        ? 'border-primary bg-primary/15 text-white'
                        : 'border-white/10 bg-[#161936] text-neutral-300 hover:border-primary/50'
                    }`}
                  >
                    Delete only specific data categories
                  </button>
                </div>
              </div>

              <div className="mt-5">
                <label className="mb-2 block text-sm font-semibold text-white/90">
                  Additional details
                </label>
                <textarea
                  value={form.details}
                  onChange={onFieldChange('details')}
                  rows={4}
                  className="w-full rounded-2xl border border-white/10 bg-[#161936] px-4 py-3 text-white placeholder:text-neutral-500 outline-none transition focus:border-primary/70 focus:ring-2 focus:ring-primary/30"
                  placeholder="Tell us exactly what you want deleted (optional)."
                />
              </div>

              <div className="mt-6 rounded-2xl border border-primary/40 bg-primary/10 p-4">
                <p className="text-sm font-semibold text-white">
                  Final confirmation (required)
                </p>
                <label className="mt-3 flex items-start gap-3 text-sm text-neutral-200">
                  <input
                    type="checkbox"
                    checked={form.confirmIrreversible}
                    onChange={onFieldChange('confirmIrreversible')}
                    className="mt-1 h-4 w-4 rounded border-white/30 bg-transparent text-primary focus:ring-primary"
                    required
                  />
                  I confirm this request is intentional and understand that data
                  deletion may be irreversible after processing.
                </label>
                <div className="mt-3">
                  <label className="mb-2 block text-xs font-semibold tracking-wide text-white/80">
                    Type <span className="text-primary">{REQUIRED_CONFIRM_PHRASE}</span> to confirm
                  </label>
                  <input
                    value={form.confirmPhrase}
                    onChange={onFieldChange('confirmPhrase')}
                    className="w-full rounded-2xl border border-white/10 bg-[#161936] px-4 py-3 text-white placeholder:text-neutral-500 outline-none transition focus:border-primary/70 focus:ring-2 focus:ring-primary/30"
                    placeholder={REQUIRED_CONFIRM_PHRASE}
                    required
                  />
                </div>
              </div>

              {error && (
                <div className="mt-4 flex items-start gap-2 rounded-xl border border-red-400/30 bg-red-500/10 p-3 text-sm text-red-200">
                  <WarningCircle size={18} className="mt-0.5 flex-shrink-0" />
                  <span>{error}</span>
                </div>
              )}

              {submitted && (
                <div className="mt-4 flex items-start gap-2 rounded-xl border border-emerald-400/30 bg-emerald-500/10 p-3 text-sm text-emerald-200">
                  <CheckCircle size={18} className="mt-0.5 flex-shrink-0" />
                  <span>
                    Your email app should open now with your request details.
                    Please send the email to complete your deletion request.
                  </span>
                </div>
              )}

              <button
                type="submit"
                disabled={!canSubmit}
                className="mt-6 inline-flex w-full items-center justify-center gap-2 rounded-2xl bg-primary px-6 py-3.5 font-display text-sm font-bold text-white transition hover:bg-orange-600 disabled:cursor-not-allowed disabled:opacity-60"
              >
                <EnvelopeSimple size={18} weight="fill" />
                Submit deletion request
              </button>

              <p className="mt-3 text-xs text-neutral-400">
                This currently opens your email app addressed to{' '}
                <a
                  className="text-primary hover:text-white transition-colors"
                  href="mailto:garage@sparewo.ug"
                >
                  garage@sparewo.ug
                </a>
                . Backend API integration can be plugged in later without changing
                this page URL.
              </p>
            </form>

            <aside className="space-y-5">
              <div className="rounded-3xl border border-white/10 bg-white/5 p-6">
                <h3 className="font-display text-lg font-bold text-white">
                  How deletion requests work
                </h3>
                <ol className="mt-4 space-y-3 text-sm text-neutral-300">
                  <li>1. Submit the form with your account identifiers.</li>
                  <li>2. We verify ownership and request legitimacy.</li>
                  <li>
                    3. We process deletion and confirm completion via email.
                  </li>
                </ol>
              </div>

              <div className="rounded-3xl border border-white/10 bg-white/5 p-6">
                <h3 className="font-display text-lg font-bold text-white">
                  Data deleted after approval
                </h3>
                <ul className="mt-4 space-y-2 text-sm text-neutral-300">
                  <li>• Account profile data</li>
                  <li>• Saved addresses and vehicle details</li>
                  <li>• Order history linked to your account (operational view)</li>
                  <li>• Support history tied to the account</li>
                </ul>
              </div>

              <div className="rounded-3xl border border-white/10 bg-white/5 p-6">
                <h3 className="font-display text-lg font-bold text-white">
                  Data we may retain
                </h3>
                <ul className="mt-4 space-y-2 text-sm text-neutral-300">
                  <li>• Records required by tax, fraud, or legal obligations</li>
                  <li>• Security logs and transaction traces</li>
                </ul>
                <p className="mt-3 text-xs text-neutral-400">
                  Retained compliance records are typically restricted and held
                  for up to <span className="text-white font-semibold">90 days</span> unless a longer legal period is required.
                </p>
              </div>

              <div className="rounded-3xl border border-primary/30 bg-primary/10 p-6">
                <div className="flex items-center gap-2">
                  <Wrench size={18} weight="bold" className="text-primary" />
                  <span className="font-display text-sm font-bold text-white">
                    Need help right now?
                  </span>
                </div>
                <p className="mt-2 text-sm text-neutral-300">
                  Email{' '}
                  <a
                    href="mailto:garage@sparewo.ug"
                    className="text-primary hover:text-white transition-colors"
                  >
                    garage@sparewo.ug
                  </a>{' '}
                  and mention “Data Deletion Request”.
                </p>
              </div>
            </aside>
          </div>
        </div>
      </section>
    </div>
  );
};

export default DataPrivacy;
