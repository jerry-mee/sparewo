
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
import { Loader2, Check, Eye, EyeOff } from 'lucide-react';

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

function ActionPageContent() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const mode = searchParams.get('mode');
    const oobCode = searchParams.get('oobCode');

    const [isLoading, setIsLoading] = useState(false);
    const [isVerifying, setIsVerifying] = useState(true);
    const [email, setEmail] = useState<string | null>(null);
    const [showPassword, setShowPassword] = useState(false);

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

        if (mode === 'resetPassword') {
            verifyPasswordResetCode(auth, oobCode)
                .then((email) => {
                    setEmail(email);
                    setIsVerifying(false);
                })
                .catch((error) => {
                    console.error(error);
                    toast.error('Invalid or expired link.');
                    setIsVerifying(false);
                });
        } else {
            setIsVerifying(false);
        }
    }, [oobCode, mode]);


    const onSubmit = async (data: PasswordFormValues) => {
        if (!oobCode) return;
        setIsLoading(true);
        try {
            if (mode === 'resetPassword') {
                await confirmPasswordReset(auth, oobCode, data.password);
                toast.success('Password reset successfully. You can now login.');
                setTimeout(() => router.push('/login'), 2000);
            }
        } catch (error: any) {
            console.error(error);
            const msg = error.code === 'auth/expired-action-code' ? 'Link has expired.' : (error.message || 'Failed to reset password.');
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

    if (!oobCode || (mode !== 'resetPassword' && mode !== 'verifyEmail')) {
        return (
            <div className="flex min-h-screen items-center justify-center bg-gray-50 dark:bg-gray-900 p-4">
                <Card className="w-full max-w-md">
                    <CardHeader>
                        <CardTitle className="text-center text-destructive">Invalid Link</CardTitle>
                        <CardDescription className="text-center">This link is invalid or malformed.</CardDescription>
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
        <div className="flex min-h-screen items-center justify-center bg-white dark:bg-gray-950 p-4 relative overflow-hidden">
            {/* Branded Background Element */}
            <div className="absolute top-0 left-0 w-full h-full bg-[radial-gradient(circle_at_30%_20%,rgba(59,130,246,0.05)_0%,transparent_50%),radial-gradient(circle_at_70%_80%,rgba(59,130,246,0.05)_0%,transparent_50%)] pointer-events-none" />

            <Card className="w-full max-w-md relative z-10 border-none shadow-2xl bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm">
                <CardHeader className="space-y-4">
                    <div className="mx-auto flex justify-center mb-4">
                        <Image
                            src="/images/logo.png"
                            alt="SpareWo"
                            width={100}
                            height={100}
                            className="h-20 w-auto"
                            style={{ width: "auto", height: "auto" }}
                            priority
                        />
                    </div>
                    <CardTitle className="text-2xl font-bold text-center">
                        {mode === 'resetPassword' ? 'Reset Password' : 'Verify Email'}
                    </CardTitle>
                    <CardDescription className="text-center">
                        {mode === 'resetPassword'
                            ? `Create a new password for ${email}`
                            : 'Verifying your email address...'}
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    {mode === 'resetPassword' && (
                        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                            <div className="space-y-2">
                                <Label htmlFor="password">New Password</Label>
                                <div className="relative">
                                    <Input
                                        id="password"
                                        type={showPassword ? "text" : "password"}
                                        autoComplete="new-password"
                                        {...register('password')}
                                        className={errors.password ? 'border-destructive pr-10' : 'pr-10'}
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

                            {/* Password Strength Meter */}
                            <div className="space-y-2 rounded-lg bg-muted/50 p-3 text-sm">
                                <p className="font-medium text-xs mb-2">Password Requirements:</p>
                                <ul className="space-y-1">
                                    {requirements.map((req, i) => (
                                        <li key={i} className="flex items-center gap-2">
                                            {req.met ? (
                                                <Check className="h-3 w-3 text-green-500" />
                                            ) : (
                                                <div className="h-1.5 w-1.5 rounded-full bg-muted-foreground/30" />
                                            )}
                                            <span className={req.met ? "text-green-600 line-through decoration-green-600/50" : "text-muted-foreground"}>
                                                {req.label}
                                            </span>
                                        </li>
                                    ))}
                                </ul>
                            </div>

                            <div className="space-y-2">
                                <Label htmlFor="confirmPassword">Confirm Password</Label>
                                <Input
                                    id="confirmPassword"
                                    type="password"
                                    autoComplete="new-password"
                                    {...register('confirmPassword')}
                                    className={errors.confirmPassword ? 'border-destructive' : ''}
                                />
                                {errors.confirmPassword && (
                                    <p className="text-xs text-destructive">{errors.confirmPassword.message}</p>
                                )}
                            </div>

                            <Button type="submit" className="w-full" disabled={isLoading}>
                                {isLoading ? (
                                    <>
                                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                        Resetting Password...
                                    </>
                                ) : (
                                    'Set New Password'
                                )}
                            </Button>
                        </form>
                    )}
                </CardContent>
                <CardFooter className="flex justify-center text-sm text-gray-500">
                    Protected by SpareWo Security
                </CardFooter>
            </Card>
        </div>
    );
}

export default function ActionPage() {
    return (
        <Suspense fallback={
            <div className="flex min-h-screen items-center justify-center bg-white dark:bg-gray-950">
                <Loader2 className="w-10 h-10 animate-spin text-primary" />
            </div>
        }>
            <ActionPageContent />
        </Suspense>
    );
}
