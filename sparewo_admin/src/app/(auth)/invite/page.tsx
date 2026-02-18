
'use client';

import React, { useState, useEffect, Suspense } from 'react';
import Image from 'next/image';
import { useRouter, useSearchParams } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { toast } from 'sonner';
import { confirmPasswordReset, verifyPasswordResetCode } from 'firebase/auth';
import { auth } from '@/lib/firebase/config';
import { signIn } from '@/lib/firebase/auth';
import { Loader2, Check, Eye, EyeOff } from 'lucide-react';
import { collection, query, where, getDocs } from 'firebase/firestore';
import { db } from '@/lib/firebase/config';

const passwordSchema = z.object({
    password: z.string()
        .min(8, 'Password must be at least 8 characters')
        .regex(/[A-Z]/, 'Must contain at least one uppercase letter')
        .regex(/[a-z]/, 'Must contain at least one lowercase letter')
        .regex(/[0-9]/, 'Must contain at least one number')
        .regex(/[^A-Za-z0-9]/, 'Must contain at least one special character'),
    confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
    message: "Passwords don't match",
    path: ["confirmPassword"],
});

type PasswordFormValues = z.infer<typeof passwordSchema>;

function InvitePageContent() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const oobCode = searchParams.get('oobCode');

    const [isLoading, setIsLoading] = useState(false);
    const [isVerifying, setIsVerifying] = useState(true);
    const [email, setEmail] = useState<string | null>(null);
    const [firstName, setFirstName] = useState<string | null>(null);
    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);

    const {
        register,
        handleSubmit,
        watch,
        formState: { errors },
    } = useForm<PasswordFormValues>({
        resolver: zodResolver(passwordSchema),
    });

    const password = watch('password', '');

    useEffect(() => {
        if (!oobCode) {
            setIsVerifying(false);
            return;
        }

        // Get name from query params if available (preferred to avoid permission errors)
        const nameFromUrl = searchParams.get('name');
        if (nameFromUrl) {
            setFirstName(nameFromUrl);
        }

        verifyPasswordResetCode(auth, oobCode)
            .then(async (userEmail) => {
                setEmail(userEmail);

                // Only fetch name if not already set from URL
                if (!nameFromUrl) {
                    try {
                        const q = query(collection(db, 'adminUsers'), where('email', '==', userEmail));
                        const querySnapshot = await getDocs(q);
                        if (!querySnapshot.empty) {
                            const userData = querySnapshot.docs[0].data();
                            setFirstName(userData.first_name || null);
                        }
                    } catch (error) {
                        // Silently catch permission errors for unauthenticated users
                        console.log('Note: Permission restricted for name lookup - using email salutation.');
                    }
                }

                setIsVerifying(false);
            })
            .catch((error) => {
                console.error(error);
                toast.error('Invitation link is invalid or expired.');
                setIsVerifying(false);
            });
    }, [oobCode, searchParams]);


    const onSubmit = async (data: PasswordFormValues) => {
        if (!oobCode || !email) return;
        setIsLoading(true);
        try {
            await confirmPasswordReset(auth, oobCode, data.password);
            await signIn(email, data.password);
            toast.success('Account setup complete. Signing you in...');
            setTimeout(() => {
                window.location.href = '/dashboard';
            }, 800);
        } catch (error: unknown) {
            console.error(error);
            const msg =
                (typeof error === 'object' && error !== null && 'code' in error && (error as { code?: string }).code === 'auth/expired-action-code')
                    ? 'Link has expired.'
                    : (error instanceof Error ? error.message : 'Failed to set password.');
            toast.error(msg);
        } finally {
            setIsLoading(false);
        }
    };

    const requirements = [
        { label: 'At least 8 characters', met: password.length >= 8 },
        { label: 'Uppercase letter', met: /[A-Z]/.test(password) },
        { label: 'Lowercase letter', met: /[a-z]/.test(password) },
        { label: 'Number', met: /[0-9]/.test(password) },
        { label: 'Special character', met: /[^A-Za-z0-9]/.test(password) },
    ];

    if (!oobCode) {
        return (
            <div className="flex min-h-screen items-center justify-center bg-gray-50 dark:bg-gray-900 p-4">
                <Card className="w-full max-w-md">
                    <CardHeader>
                        <CardTitle className="text-center text-destructive">Invalid Link</CardTitle>
                        <CardDescription className="text-center">This invitation link is missing required security tokens.</CardDescription>
                    </CardHeader>
                    <CardFooter className="flex justify-center">
                        <Button onClick={() => router.push('/login')}>Back to Login</Button>
                    </CardFooter>
                </Card>
            </div>
        );
    }

    if (isVerifying) {
        return (
            <div className="flex min-h-screen items-center justify-center bg-gray-50 dark:bg-gray-900 p-4">
                <Loader2 className="w-10 h-10 animate-spin text-primary" />
            </div>
        );
    }

    return (
        <div className="relative flex min-h-screen items-start justify-center overflow-y-auto bg-white p-4 py-6 dark:bg-gray-950 sm:items-center sm:py-10">
            <div className="absolute top-0 left-0 w-full h-full bg-[radial-gradient(circle_at_30%_20%,rgba(59,130,246,0.05)_0%,transparent_50%),radial-gradient(circle_at_70%_80%,rgba(59,130,246,0.05)_0%,transparent_50%)] pointer-events-none" />

            <Card className="relative z-10 w-full max-w-md border-none bg-white/80 shadow-2xl backdrop-blur-sm dark:bg-gray-900/80">
                <CardHeader className="space-y-3 px-5 pb-2 pt-5 sm:space-y-4 sm:px-6 sm:pt-6">
                    <div className="mx-auto flex justify-center mb-6">
                        <Image
                            src="/images/logo.png"
                            alt="SpareWo"
                            width={240}
                            height={80}
                            className="h-16 w-auto dark:hidden sm:h-20"
                            priority
                        />
                        <Image
                            src="/images/logo_light.png"
                            alt="SpareWo"
                            width={240}
                            height={80}
                            className="h-16 w-auto hidden dark:block sm:h-20"
                            priority
                        />
                    </div>
                    <CardTitle className="text-2xl font-bold text-center text-blue-600 dark:text-blue-400">
                        Welcome to SpareWo
                    </CardTitle>
                    <CardDescription className="break-words text-center text-sm sm:text-base dark:text-gray-300">
                        Hi <strong>{firstName || email}</strong>, set up your password to activate your admin account.
                    </CardDescription>
                </CardHeader>
                <CardContent className="px-5 pb-5 sm:px-6 sm:pb-6">
                    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" method="POST">
                        {/* Hidden username field for browser password managers */}
                        <input
                            type="text"
                            name="email"
                            value={email || ''}
                            readOnly
                            autoComplete="username"
                            className="hidden"
                            aria-hidden="true"
                        />

                        <div className="space-y-2">
                            <Label htmlFor="password" id="password-label" className="dark:text-white">Create Password</Label>
                            <div className="relative">
                                <Input
                                    id="password"
                                    type={showPassword ? "text" : "password"}
                                    autoComplete="new-password"
                                    {...register('password')}
                                    name="password"
                                    className={errors.password ? 'border-destructive pr-10' : 'pr-10 dark:bg-gray-800 dark:text-white'}
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    className="absolute right-3 top-2.5 text-muted-foreground hover:text-foreground"
                                >
                                    {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                                </button>
                            </div>
                            {errors.password && (
                                <p className="text-xs text-destructive">{errors.password.message}</p>
                            )}
                        </div>

                        <div className="space-y-2">
                            <Label htmlFor="confirmPassword" id="confirm-password-label" className="dark:text-white">Confirm Password</Label>
                            <div className="relative">
                                <Input
                                    id="confirmPassword"
                                    type={showConfirmPassword ? "text" : "password"}
                                    autoComplete="new-password"
                                    {...register('confirmPassword')}
                                    name="confirm-password"
                                    className={errors.confirmPassword ? 'border-destructive pr-10' : 'pr-10 dark:bg-gray-800 dark:text-white'}
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                                    className="absolute right-3 top-2.5 text-muted-foreground hover:text-foreground"
                                >
                                    {showConfirmPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                                </button>
                            </div>
                            {errors.confirmPassword && (
                                <p className="text-xs text-destructive">{errors.confirmPassword.message}</p>
                            )}
                        </div>

                        {/* Password Strength Meter */}
                        <div className="space-y-2 rounded-lg bg-muted/50 p-3 text-sm">
                            <p className="font-medium text-xs mb-2 dark:text-gray-200">Password Requirements:</p>
                            <ul className="space-y-1">
                                {requirements.map((req, i) => (
                                    <li key={i} className="flex items-center gap-2">
                                        {req.met ? (
                                            <Check className="h-3 w-3 text-green-500" />
                                        ) : (
                                            <div className="h-1.5 w-1.5 rounded-full bg-muted-foreground/30" />
                                        )}
                                        <span className={req.met ? "text-green-600 line-through decoration-green-600/50" : "text-muted-foreground dark:text-gray-400"}>
                                            {req.label}
                                        </span>
                                    </li>
                                ))}
                            </ul>
                        </div>

                        <Button type="submit" className="w-full bg-blue-600 hover:bg-blue-700" disabled={isLoading}>
                            {isLoading ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    Creating Account...
                                </>
                            ) : (
                                'Activate Account'
                            )}
                        </Button>
                    </form>
                </CardContent>
                <CardFooter className="flex justify-center text-sm text-gray-500 dark:text-gray-400">
                    Your account is protected by SpareWo Security
                </CardFooter>
            </Card>
        </div>
    );
}

export default function InvitePage() {
    return (
        <Suspense fallback={
            <div className="flex min-h-screen items-center justify-center bg-white dark:bg-gray-950">
                <Loader2 className="w-10 h-10 animate-spin text-primary" />
            </div>
        }>
            <InvitePageContent />
        </Suspense>
    );
}
