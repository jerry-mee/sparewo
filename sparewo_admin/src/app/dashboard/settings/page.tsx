
"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { useAuth } from "@/lib/context/auth-context";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Separator } from "@/components/ui/separator";
import { getInitials } from "@/lib/utils";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import {
  Users,
  Plus,
  Download,
  RefreshCw,
  Save,
  Ban,
  UserCheck,
  KeyRound,
  Trash2,
  ShieldEllipsis,
  Eye,
  EyeOff,
  Copy
} from "lucide-react";

import {
  listStaff,
  inviteStaff,
  updateStaff,
  deleteStaff,
  sendStaffPasswordReset
} from "@/lib/api/staff";
import { StaffRole, type StaffMember } from "@/lib/types/staff";
import { isAdministratorRole, normalizeRole } from "@/lib/auth/roles";

// Reuse logic from reference dashboard
const ROLE_OPTIONS: Array<{ value: StaffRole; label: string; description: string }> = [
  { value: "Administrator", label: "Administrator", description: "Full access across operations, security, and platform controls." },
  { value: "Manager", label: "Manager", description: "Trip operations oversight, assignment, and dispatch controls." },
  { value: "Mechanic", label: "Mechanic", description: "Fleet maintenance logging and vehicle status updates." },
];

function roleLabel(role: string) {
  const normalized = role.trim();
  const option = ROLE_OPTIONS.find((opt) => opt.value === normalized);
  return option ? option.label : role;
}

function formatDate(value?: string | null) {
  if (!value) return "Never";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "Unknown";
  return date.toLocaleString();
}

type InviteFormState = {
  email: string;
  firstName: string;
  lastName: string;
  username: string;
  role: StaffRole;
};

type EditFormState = {
  firstName: string;
  lastName: string;
  username: string;
  role: StaffRole;
  isActive: boolean;
  suspendAuthAccess: boolean;
};


export default function SettingsPage() {
  const { user, adminData } = useAuth();

  // Tabs state
  // const [activeTab, setActiveTab] = useState("profile"); // Tabs component handles state internally by default, or we can control it.
  // Using uncontrolled for simplicity as per original file, but adding "team" tab.

  // Team state
  const [staffMembers, setStaffMembers] = useState<StaffMember[]>([]);
  const [loadingStaff, setLoadingStaff] = useState(false);
  const [savingInvite, setSavingInvite] = useState(false);
  const [inviteForm, setInviteForm] = useState<InviteFormState>({
    email: "",
    firstName: "",
    lastName: "",
    username: "",
    role: "Manager",
  });

  const [editingStaff, setEditingStaff] = useState<StaffMember | null>(null);
  const [editForm, setEditForm] = useState<EditFormState>({
    firstName: "",
    lastName: "",
    username: "",
    role: "Manager",
    isActive: true,
    suspendAuthAccess: false,
  });
  const [savingEdit, setSavingEdit] = useState(false);
  const [actioningStaffId, setActioningStaffId] = useState<string | null>(null);

  const isCurrentAdmin = isAdministratorRole(adminData?.role);

  const loadStaff = useCallback(async () => {
    setLoadingStaff(true);
    try {
      const data = await listStaff();
      setStaffMembers(data);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to load team members.";
      toast.error(message);
    } finally {
      setLoadingStaff(false);
    }
  }, []);

  // Load team on mount (if we were always on team tab, but since tabs are lazy or switchable, we might want to load when tab is active?
  // For simplicity, load on mount.
  useEffect(() => {
    // Only load if user is logged in
    if (user) {
      void loadStaff();
    }
  }, [loadStaff, user]);

  const teamStats = useMemo(() => {
    const active = staffMembers.filter((member) => member.is_active).length;
    const suspendedLogin = staffMembers.filter((member) => member.auth_suspended).length;
    const pendingInvites = staffMembers.filter((member) => member.pending_activation).length;
    return {
      total: staffMembers.length,
      active,
      suspendedLogin,
      pendingInvites,
    };
  }, [staffMembers]);


  const handleInvite = async () => {
    if (!inviteForm.email || !inviteForm.firstName || !inviteForm.lastName) {
      toast.error("Email, first name, and last name are required.");
      return;
    }
    if (!isCurrentAdmin) {
      toast.error("Only Administrator users can invite team members.");
      // return; // Allow for demo purposes if needed? No, enforce permissions.
      // But wait, the API also enforces it.
    }

    setSavingInvite(true);
    try {
      const res = await inviteStaff({
        email: inviteForm.email.trim().toLowerCase(),
        first_name: inviteForm.firstName.trim(),
        last_name: inviteForm.lastName.trim(),
        username: inviteForm.username.trim() || inviteForm.email.trim().toLowerCase().split('@')[0],
        role: inviteForm.role,
      });

      if (res.inviteLink && (res.message.includes("failed") || res.message.includes("manually"))) {
        setGeneratedLink({
          url: res.inviteLink,
          label: "Invitation Link (Email Failed)",
          email: inviteForm.email
        });
      } else {
        toast.success(res.message || "Team invite sent.");
      }

      setInviteForm({
        email: "",
        firstName: "",
        lastName: "",
        username: "",
        role: "Manager",
      });
      await loadStaff();
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to invite team member.";
      toast.error(message);
    } finally {
      setSavingInvite(false);
    }
  };

  const openEditDialog = (member: StaffMember) => {
    setEditingStaff(member);
    setEditForm({
      firstName: member.first_name || "",
      lastName: member.last_name || "",
      username: member.username || "",
      role: member.role,
      isActive: member.is_active,
      suspendAuthAccess: Boolean(member.auth_suspended),
    });
  };

  const handleSaveEdit = async () => {
    if (!editingStaff) return;
    if (!isCurrentAdmin) {
      toast.error("Only Administrator users can edit team permissions.");
      return;
    }

    setSavingEdit(true);
    try {
      await updateStaff({
        staff_id: editingStaff.id,
        first_name: editForm.firstName.trim(),
        last_name: editForm.lastName.trim(),
        username: editForm.username.trim(),
        role: editForm.role,
        is_active: editForm.isActive,
        suspend_auth_access: editForm.suspendAuthAccess,
      });
      toast.success("Team member updated.");
      setEditingStaff(null);
      await loadStaff();
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to update team member.";
      toast.error(message);
    } finally {
      setSavingEdit(false);
    }
  };

  const handleQuickStatusToggle = async (member: StaffMember, nextActive: boolean) => {
    if (!isCurrentAdmin) {
      toast.error("Only Administrator users can change staff status.");
      return;
    }
    setActioningStaffId(member.id);
    try {
      await updateStaff({
        staff_id: member.id,
        is_active: nextActive,
      });
      toast.success(nextActive ? "Staff member activated." : "Staff member deactivated.");
      await loadStaff();
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to update staff status.";
      toast.error(message);
    } finally {
      setActioningStaffId(null);
    }
  };

  const handleDeleteStaff = async (member: StaffMember) => {
    if (!isCurrentAdmin) {
      toast.error("Only Administrator users can delete staff accounts.");
      return;
    }
    if (member.user_id === user?.uid) {
      toast.error("You cannot delete your own active account.");
      return;
    }

    const confirmed = window.confirm(
      `Delete ${member.first_name || ""} ${member.last_name || ""} (${member.email || member.user_id})?\n\nThis permanently removes dashboard access and auth login.`
    );
    if (!confirmed) return;

    setActioningStaffId(member.id);
    try {
      await deleteStaff(member.id);
      toast.success("Staff member deleted.");
      await loadStaff();
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to delete staff member.";
      toast.error(message);
    } finally {
      setActioningStaffId(null);
    }
  };

  const [isResetDialogOpen, setIsResetDialogOpen] = useState(false);
  const [resetStaff, setResetStaff] = useState<StaffMember | null>(null);
  const [resetOption, setResetOption] = useState<'email' | 'manual'>('email');
  const [manualPassword, setManualPassword] = useState('');
  const [showManualPassword, setShowManualPassword] = useState(false);
  const [resetting, setResetting] = useState(false);

  const [generatedLink, setGeneratedLink] = useState<{ url: string; label: string; email: string } | null>(null);
  const [tempVisiblePassword, setTempVisiblePassword] = useState<string | null>(null);

  const handleExecuteReset = async () => {
    if (!resetStaff || !isCurrentAdmin) return;

    setResetting(true);
    try {
      if (resetOption === 'email') {
        const res = await sendStaffPasswordReset(resetStaff.id);
        if (res.link && (res.message.includes("failed") || res.message.includes("manually"))) {
          setGeneratedLink({
            url: res.link,
            label: "Password Reset Link (Email Failed)",
            email: resetStaff.email || "User"
          });
        } else {
          toast.success(res.message || "Password reset email sent.");
        }
      } else {
        // Manual password
        const passwordToSet = manualPassword || Math.random().toString(36).slice(-10);
        await updateStaff({
          staff_id: resetStaff.id,
          password: passwordToSet,
        });
        setTempVisiblePassword(passwordToSet);
        toast.success("Password updated successfully.");
      }
      setIsResetDialogOpen(false);
      setManualPassword('');
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Failed to reset password");
    } finally {
      setResetting(false);
    }
  };

  const openResetDialog = (member: StaffMember) => {
    setResetStaff(member);
    setIsResetDialogOpen(true);
    setResetOption('email');
    setTempVisiblePassword(null);
  };


  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-2xl font-semibold tracking-tight">Settings</h1>
        <p className="text-muted-foreground">Manage your account and platform preferences.</p>
      </div>

      {/* NEW RESET PASSWORD DIALOG */}
      <Dialog open={isResetDialogOpen} onOpenChange={setIsResetDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-xl font-semibold">
              Reset password for {resetStaff?.first_name} {resetStaff?.last_name}
            </DialogTitle>
            <DialogDescription>
              Choose how you want to reset this user&apos;s password.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-6 py-4">
            <div className="space-y-4">
              <div
                className={`flex items-start gap-4 p-4 rounded-xl border-2 cursor-pointer transition-all ${resetOption === 'email' ? 'border-primary bg-primary/5' : 'border-transparent bg-muted/30'}`}
                onClick={() => setResetOption('email')}
              >
                <div className={`mt-1 flex h-5 w-5 items-center justify-center rounded-full border-2 ${resetOption === 'email' ? 'border-primary' : 'border-muted-foreground'}`}>
                  {resetOption === 'email' && <div className="h-2.5 w-2.5 rounded-full bg-primary" />}
                </div>
                <div className="space-y-1">
                  <p className="font-medium text-sm">Send password reset link</p>
                  <p className="text-xs text-muted-foreground">User will receive an email (via Resend) with a link to choose their own password.</p>
                </div>
              </div>

              <div
                className={`flex items-start gap-4 p-4 rounded-xl border-2 cursor-pointer transition-all ${resetOption === 'manual' ? 'border-primary bg-primary/5' : 'border-transparent bg-muted/30'}`}
                onClick={() => setResetOption('manual')}
              >
                <div className={`mt-1 flex h-5 w-5 items-center justify-center rounded-full border-2 ${resetOption === 'manual' ? 'border-primary' : 'border-muted-foreground'}`}>
                  {resetOption === 'manual' && <div className="h-2.5 w-2.5 rounded-full bg-primary" />}
                </div>
                <div className="space-y-1 w-full">
                  <p className="font-medium text-sm">Create password</p>
                  <p className="text-xs text-muted-foreground">Manually set a new password for the user.</p>

                  {resetOption === 'manual' && (
                    <div className="mt-3 space-y-3 pt-2 animate-in slide-in-from-top-2 duration-200">
                      <div className="relative">
                        <Input
                          placeholder="New password (leave empty to auto-generate)"
                          type={showManualPassword ? "text" : "password"}
                          value={manualPassword}
                          onChange={(e) => setManualPassword(e.target.value)}
                          className="pr-10"
                        />
                        <button
                          type="button"
                          onClick={() => setShowManualPassword(!showManualPassword)}
                          className="absolute right-3 top-2.5 text-muted-foreground hover:text-foreground"
                        >
                          {showManualPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="ghost" onClick={() => setIsResetDialogOpen(false)} disabled={resetting}>
              CANCEL
            </Button>
            <Button onClick={handleExecuteReset} disabled={resetting}>
              {resetting ? "RESETTING..." : "RESET"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* PASSWORD SUCCESS DIALOG */}
      <Dialog open={!!tempVisiblePassword} onOpenChange={() => setTempVisiblePassword(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Password Reset Successful</DialogTitle>
            <DialogDescription>
              The password for {resetStaff?.email} has been updated. Please share this new password with them securely.
            </DialogDescription>
          </DialogHeader>
          <div className="bg-muted p-4 rounded-lg flex items-center justify-between font-mono text-lg break-all">
            <span>{tempVisiblePassword}</span>
            <Button
              size="icon"
              variant="ghost"
              onClick={() => {
                if (tempVisiblePassword) {
                  navigator.clipboard.writeText(tempVisiblePassword);
                  toast.success("Copied to clipboard");
                }
              }}
            >
              <Copy className="h-4 w-4" />
            </Button>
          </div>
          <DialogFooter>
            <Button onClick={() => setTempVisiblePassword(null)}>Done</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={!!generatedLink} onOpenChange={(open) => !open && setGeneratedLink(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{generatedLink?.label}</DialogTitle>
            <DialogDescription>
              Share this link with <strong>{generatedLink?.email}</strong> to help them set their password.
            </DialogDescription>
          </DialogHeader>
          <div className="flex items-center space-x-2">
            <Input readOnly value={generatedLink?.url || ''} />
            <Button size="sm" onClick={() => {
              navigator.clipboard.writeText(generatedLink?.url || '');
              toast.success("Link copied to clipboard");
            }}>
              Copy
            </Button>
          </div>
          <DialogFooter>
            <Button onClick={() => setGeneratedLink(null)}>Done</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={!!editingStaff} onOpenChange={(open) => !open && setEditingStaff(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Team Member</DialogTitle>
            <DialogDescription>Update details and permissions.</DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>First Name</Label>
                <Input
                  value={editForm.firstName}
                  onChange={(e) => setEditForm(prev => ({ ...prev, firstName: e.target.value }))}
                />
              </div>
              <div className="space-y-2">
                <Label>Last Name</Label>
                <Input
                  value={editForm.lastName}
                  onChange={(e) => setEditForm(prev => ({ ...prev, lastName: e.target.value }))}
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label>Username</Label>
              <Input
                value={editForm.username}
                onChange={(e) => setEditForm(prev => ({ ...prev, username: e.target.value }))}
              />
            </div>
            <div className="space-y-2">
              <Label>Role</Label>
              <Select
                value={editForm.role}
                onValueChange={(val) => setEditForm(prev => ({ ...prev, role: val as StaffRole }))}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {ROLE_OPTIONS.map((opt) => (
                    <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="isActive"
                className="h-4 w-4 rounded border-gray-300"
                checked={editForm.isActive}
                onChange={(e) => setEditForm(prev => ({ ...prev, isActive: e.target.checked }))}
              />
              <Label htmlFor="isActive">Dashboard Access Active</Label>
            </div>
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="suspendAuth"
                className="h-4 w-4 rounded border-gray-300"
                checked={editForm.suspendAuthAccess}
                onChange={(e) => setEditForm(prev => ({ ...prev, suspendAuthAccess: e.target.checked }))}
              />
              <Label htmlFor="suspendAuth" className="text-destructive">Suspend Login Access</Label>
            </div>

            <Separator />

            <div className="flex flex-col gap-2">
              <Label>Security Actions</Label>
              <div className="grid grid-cols-1 gap-2">
                <Button
                  variant="outline"
                  className="w-full justify-start h-auto py-2 px-3 text-xs"
                  onClick={() => {
                    if (editingStaff) {
                      setEditingStaff(null); // Close edit dialog
                      openResetDialog(editingStaff);
                    }
                  }}
                >
                  <KeyRound className="w-3.5 h-3.5 mr-2 text-blue-500" />
                  Reset Password Settings
                </Button>
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setEditingStaff(null)}>Cancel</Button>
            <Button onClick={handleSaveEdit} disabled={savingEdit}>
              {savingEdit ? "Saving..." : "Save Changes"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>


      <Tabs defaultValue="profile" className="w-full">
        <TabsList className="grid w-full max-w-xl grid-cols-4">
          <TabsTrigger value="profile">Profile</TabsTrigger>
          <TabsTrigger value="team">Team</TabsTrigger>
          <TabsTrigger value="notifications">Notifications</TabsTrigger>
          <TabsTrigger value="security">Security</TabsTrigger>
        </TabsList>

        <TabsContent value="profile" className="mt-6 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Profile Information</CardTitle>
              <CardDescription>Update your photo and personal details.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center gap-6">
                <Avatar className="h-20 w-20">
                  <AvatarImage src={user?.photoURL || ""} />
                  <AvatarFallback className="text-lg">{user?.displayName ? getInitials(user.displayName) : 'A'}</AvatarFallback>
                </Avatar>
                <div className="space-y-1">
                  <h3 className="font-medium">{user?.displayName}</h3>
                  <p className="text-sm text-muted-foreground">{user?.email}</p>
                  <p className="text-xs text-muted-foreground capitalize">
                    Role: {normalizeRole(adminData?.role) ?? adminData?.role}
                  </p>
                </div>
              </div>
              <Separator />
              <div className="grid gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Display Name</label>
                  <Input defaultValue={user?.displayName || ""} />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Email</label>
                  <Input defaultValue={user?.email || ""} disabled />
                </div>
              </div>
              <div className="flex justify-end">
                <Button>Save Changes</Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="team" className="mt-6 space-y-6">
          {!isCurrentAdmin && (
            <Card className="border-yellow-200 bg-yellow-50 dark:border-yellow-900/50 dark:bg-yellow-900/20">
              <CardContent className="p-4 flex items-start gap-3">
                <ShieldEllipsis className="w-5 h-5 mt-0.5 text-yellow-600 dark:text-yellow-500" />
                <div className="text-sm">
                  <p className="font-medium text-yellow-800 dark:text-yellow-200">Admin-only actions are restricted.</p>
                  <p className="text-yellow-700 dark:text-yellow-300">
                    You can view team status, but role changes, suspension, and invites are reserved for Administrators.
                  </p>
                </div>
              </CardContent>
            </Card>
          )}

          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Card>
              <CardHeader className="pb-2"><CardTitle className="text-sm font-medium">Total Staff</CardTitle></CardHeader>
              <CardContent className="text-2xl font-semibold">{teamStats.total}</CardContent>
            </Card>
            <Card>
              <CardHeader className="pb-2"><CardTitle className="text-sm font-medium">Active Access</CardTitle></CardHeader>
              <CardContent className="text-2xl font-semibold">{teamStats.active}</CardContent>
            </Card>
            <Card>
              <CardHeader className="pb-2"><CardTitle className="text-sm font-medium">Login Suspended</CardTitle></CardHeader>
              <CardContent className="text-2xl font-semibold">{teamStats.suspendedLogin}</CardContent>
            </Card>
            <Card>
              <CardHeader className="pb-2"><CardTitle className="text-sm font-medium">Pending Invites</CardTitle></CardHeader>
              <CardContent className="text-2xl font-semibold">{teamStats.pendingInvites}</CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Invite Team Member</CardTitle>
              <CardDescription>Assign a structured role and send an invite.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
                <div className="space-y-2">
                  <Label>Email</Label>
                  <Input
                    value={inviteForm.email}
                    autoComplete="email"
                    placeholder="email@example.com"
                    onChange={(e) => setInviteForm(prev => ({ ...prev, email: e.target.value }))}
                  />
                </div>
                <div className="space-y-2">
                  <Label>First Name</Label>
                  <Input
                    value={inviteForm.firstName}
                    autoComplete="given-name"
                    onChange={(e) => setInviteForm(prev => ({ ...prev, firstName: e.target.value }))}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Last Name</Label>
                  <Input
                    value={inviteForm.lastName}
                    autoComplete="family-name"
                    onChange={(e) => setInviteForm(prev => ({ ...prev, lastName: e.target.value }))}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Username</Label>
                  <Input
                    value={inviteForm.username}
                    autoComplete="username"
                    placeholder="optional"
                    onChange={(e) => setInviteForm(prev => ({ ...prev, username: e.target.value }))}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Role</Label>
                  <Select
                    value={inviteForm.role}
                    onValueChange={(val) => setInviteForm(prev => ({ ...prev, role: val as StaffRole }))}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {ROLE_OPTIONS.map((opt) => (
                        <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <div className="flex justify-end">
                <Button onClick={handleInvite} disabled={savingInvite || !isCurrentAdmin}>
                  <Plus className="w-4 h-4 mr-2" />
                  {savingInvite ? "Inviting..." : "Add Member"}
                </Button>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <div>
                  <CardTitle>Team Directory</CardTitle>
                  <CardDescription>Manage your team.</CardDescription>
                </div>
                <Button variant="outline" onClick={loadStaff} disabled={loadingStaff}>
                  <RefreshCw className={`w-4 h-4 mr-2 ${loadingStaff ? "animate-spin" : ""}`} />
                  Refresh
                </Button>
              </div>
            </CardHeader>
            <CardContent className="space-y-3">
              {loadingStaff ? (
                <div className="text-sm text-muted-foreground p-4 text-center">Loading team members...</div>
              ) : staffMembers.length === 0 ? (
                <div className="rounded-xl border border-dashed p-8 text-center text-sm text-muted-foreground">
                  No staff records found.
                </div>
              ) : (
                staffMembers.map((member) => (
                  <div key={member.id} className="rounded-xl border p-4 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                    <div className="space-y-1">
                      <div className="font-medium">{member.first_name} {member.last_name}</div>
                      <div className="text-sm text-muted-foreground">{member.email}</div>
                      <div className="text-xs text-muted-foreground">
                        Role: {member.role} • Active: {member.is_active ? 'Yes' : 'No'}
                      </div>
                    </div>
                    <div className="flex flex-wrap items-center gap-2">
                      <Badge variant="outline">{member.role}</Badge>
                      {member.auth_account_missing ? (
                        <Badge variant="destructive" className="bg-orange-500 hover:bg-orange-600">
                          Auth Account Missing
                        </Badge>
                      ) : member.pending_activation || (!member.last_sign_in_at && !member.is_active) ? (
                        <Badge variant="secondary" className="bg-blue-100 text-blue-700 hover:bg-blue-200 border-blue-200">
                          Pending Invite
                        </Badge>
                      ) : (
                        <Badge variant={member.is_active ? "default" : "secondary"}>
                          {member.is_active ? "Active" : "Disabled"}
                        </Badge>
                      )}

                      {member.auth_suspended && (
                        <Badge variant="destructive">Login Suspended</Badge>
                      )}
                    </div>
                    <div className="flex items-center gap-2">
                      <Button size="sm" variant="outline" onClick={() => openEditDialog(member)}>
                        <Save className="w-4 h-4 mr-2" />
                        Edit
                      </Button>
                      <Button
                        size="sm"
                        variant="destructive"
                        disabled={!isCurrentAdmin || member.user_id === user?.uid}
                        onClick={() => handleDeleteStaff(member)}
                      >
                        <Trash2 className="w-4 h-4 mr-2" />
                        Delete
                      </Button>
                    </div>
                  </div>
                ))
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="notifications" className="mt-6">
          <Card>
            <CardHeader>
              <CardTitle>Notification Preferences</CardTitle>
              <CardDescription>Choose what you want to be notified about.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between rounded-lg border p-4">
                <div className="space-y-0.5">
                  <label className="text-sm font-medium">New Orders</label>
                  <p className="text-xs text-muted-foreground">Receive emails when new orders are placed.</p>
                </div>
                {/* Add Switch component here if you have one, or checkbox */}
                <input type="checkbox" defaultChecked className="h-4 w-4 rounded border-gray-300" />
              </div>
              <div className="flex items-center justify-between rounded-lg border p-4">
                <div className="space-y-0.5">
                  <label className="text-sm font-medium">Vendor Registrations</label>
                  <p className="text-xs text-muted-foreground">Get notified for new vendor signups.</p>
                </div>
                <input type="checkbox" defaultChecked className="h-4 w-4 rounded border-gray-300" />
              </div>
              <div className="flex items-center justify-between rounded-lg border p-4">
                <div className="space-y-0.5">
                  <label className="text-sm font-medium">AutoHub Requests</label>
                  <p className="text-xs text-muted-foreground">Alerts for new service bookings.</p>
                </div>
                <input type="checkbox" defaultChecked className="h-4 w-4 rounded border-gray-300" />
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="security" className="mt-6 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Security Settings</CardTitle>
              <CardDescription>Manage your password and session settings.</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">Security settings coming soon.</p>
            </CardContent>
          </Card>
        </TabsContent>

      </Tabs>
    </div>
  );
}
