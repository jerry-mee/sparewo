
import { auth } from '@/lib/firebase/config';
import { StaffMember, StaffAuditLog } from '@/lib/types/staff';

async function withAuthHeaders() {
    const user = auth.currentUser;
    if (!user) throw new Error("No active user session.");
    const token = await user.getIdToken();
    return {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
    };
}

export async function listStaff(): Promise<StaffMember[]> {
    const headers = await withAuthHeaders();
    const response = await fetch("/api/admin/staff/list", {
        method: "POST", // Use POST to match server route if defined as POST
        headers,
    });
    if (!response.ok) {
        const payload = await response.json().catch(() => ({}));
        throw new Error(payload.error || "Failed to load staff.");
    }
    const json = await response.json();
    return json.staff || [];
}

export async function inviteStaff(payload: {
    email: string;
    first_name: string;
    last_name: string;
    role: string;
    username?: string;
}) {
    const headers = await withAuthHeaders();
    const response = await fetch("/api/admin/staff/invite", {
        method: "POST",
        headers,
        body: JSON.stringify(payload),
    });
    if (!response.ok) {
        const json = await response.json().catch(() => ({}));
        throw new Error(json.error || "Failed to invite staff.");
    }
    return response.json();
}

export async function updateStaff(payload: {
    staff_id: string;
    username?: string;
    first_name?: string;
    last_name?: string;
    role?: string;
    is_active?: boolean;
    suspend_auth_access?: boolean;
}) {
    const headers = await withAuthHeaders();
    const response = await fetch("/api/admin/staff/update", {
        method: "POST",
        headers,
        body: JSON.stringify(payload),
    });
    if (!response.ok) {
        const json = await response.json().catch(() => ({}));
        throw new Error(json.error || "Failed to update staff.");
    }
    return response.json();
}

export async function deleteStaff(staffId: string) {
    const headers = await withAuthHeaders();
    const response = await fetch("/api/admin/staff/delete", {
        method: "POST",
        headers,
        body: JSON.stringify({ staff_id: staffId }),
    });
    if (!response.ok) {
        const json = await response.json().catch(() => ({}));
        throw new Error(json.error || "Failed to delete staff member.");
    }
    return response.json();
}

export async function listStaffAudit(limit = 100): Promise<StaffAuditLog[]> {
    // Audit implementation pending backend
    return [];
}

export async function sendStaffPasswordReset(staffId: string) {
    // Password reset implementation pending
    // Could implemented via sending email via firebase auth
    return { success: true, message: "Use Firebase Console to send password reset email for now." };
}
