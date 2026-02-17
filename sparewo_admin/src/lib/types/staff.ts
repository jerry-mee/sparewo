
export type StaffRole = "Administrator" | "Manager" | "Mechanic";

export type StaffMember = {
    id: string;
    user_id: string;
    username?: string | null;
    email?: string | null;
    first_name: string;
    last_name: string;
    role: StaffRole;
    is_active: boolean;
    pending_activation?: boolean;
    auth_suspended?: boolean;
    auth_account_missing?: boolean;
    last_sign_in_at?: string | null;
    created_at: string;
};

export type StaffAuditLog = {
    id: string;
    actor_user_id: string | null;
    actor_name?: string | null;
    actor_role?: string | null;
    target_user_id: string | null;
    target_name?: string | null;
    target_role?: string | null;
    action: string;
    details: Record<string, unknown>;
    created_at: string;
};
