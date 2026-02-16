"use client";

import { useCallback, useEffect, useMemo, useState } from 'react';
import { BellRing, Megaphone, SendHorizontal, ShieldAlert, Users } from 'lucide-react';
import { toast } from 'sonner';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { useAuth } from '@/lib/context/auth-context';
import {
  CommunicationAudience,
  CommunicationType,
  getCommunicationAudienceCounts,
  getRecentCommunications,
  previewCommunicationAudience,
  sendAdminCommunication,
} from '@/lib/firebase/comms';
import { formatDateTime } from '@/lib/utils';

const audienceOptions: Array<{ value: CommunicationAudience; label: string }> = [
  { value: 'all_clients', label: 'All Clients' },
  { value: 'active_clients', label: 'Active Clients' },
  { value: 'suspended_clients', label: 'Suspended Clients' },
  { value: 'all_vendors', label: 'All Vendors' },
  { value: 'active_vendors', label: 'Active Vendors' },
  { value: 'suspended_vendors', label: 'Suspended Vendors' },
  { value: 'admins', label: 'Admins' },
];

const typeOptions: Array<{ value: CommunicationType; label: string }> = [
  { value: 'info', label: 'Info' },
  { value: 'success', label: 'Success' },
  { value: 'warning', label: 'Warning' },
  { value: 'error', label: 'Critical' },
];

export default function CommunicationsPage() {
  const { user, adminData } = useAuth();

  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [link, setLink] = useState('');
  const [audience, setAudience] = useState<CommunicationAudience>('all_clients');
  const [type, setType] = useState<CommunicationType>('info');

  const [previewCount, setPreviewCount] = useState(0);
  const [previewSample, setPreviewSample] = useState<Array<{ id: string; label: string; email?: string }>>([]);
  const [audienceCounts, setAudienceCounts] = useState<Record<string, number>>({});
  const [recent, setRecent] = useState<
    Array<{
      id: string;
      title: string;
      audience: string;
      type: CommunicationType;
      deliveredCount: number;
      attemptedCount: number;
      createdAt: unknown;
      createdBy: string;
    }>
  >([]);

  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  const isReadOnly = adminData?.role === 'viewer';

  const loadDashboardData = useCallback(async () => {
    setRefreshing(true);
    try {
      const [counts, recentComms] = await Promise.all([
        getCommunicationAudienceCounts(),
        getRecentCommunications(12),
      ]);

      setAudienceCounts({
        all_clients: counts.allClients,
        active_clients: counts.activeClients,
        suspended_clients: counts.suspendedClients,
        all_vendors: counts.allVendors,
        active_vendors: counts.activeVendors,
        suspended_vendors: counts.suspendedVendors,
        admins: counts.admins,
      });
      setRecent(recentComms);
    } catch (error) {
      console.error(error);
      toast.error('Failed to load communications data');
    } finally {
      setRefreshing(false);
    }
  }, []);

  const loadPreview = useCallback(async () => {
    try {
      const preview = await previewCommunicationAudience(audience, 5);
      setPreviewCount(preview.total);
      setPreviewSample(preview.sample);
    } catch (error) {
      console.error(error);
      setPreviewCount(0);
      setPreviewSample([]);
      toast.error('Failed to preview audience');
    }
  }, [audience]);

  useEffect(() => {
    loadDashboardData();
  }, [loadDashboardData]);

  useEffect(() => {
    loadPreview();
  }, [loadPreview]);

  const selectedAudienceLabel = useMemo(
    () => audienceOptions.find((option) => option.value === audience)?.label ?? 'Audience',
    [audience]
  );

  const handleSend = async () => {
    if (!user) {
      toast.error('You must be logged in to send communications.');
      return;
    }

    const trimmedTitle = title.trim();
    const trimmedMessage = message.trim();

    if (!trimmedTitle || !trimmedMessage) {
      toast.error('Title and message are required.');
      return;
    }

    if (previewCount === 0) {
      toast.error('No recipients found for this audience.');
      return;
    }

    setLoading(true);
    try {
      const result = await sendAdminCommunication(
        {
          title: trimmedTitle,
          message: trimmedMessage,
          audience,
          type,
          link: link.trim() || undefined,
        },
        user.uid
      );

      toast.success(`Sent ${result.delivered} of ${result.attempted} notifications.`);
      setTitle('');
      setMessage('');
      setLink('');
      await Promise.all([loadDashboardData(), loadPreview()]);
    } catch (error) {
      console.error(error);
      toast.error('Failed to send communication');
    } finally {
      setLoading(false);
    }
  };

  const getTypeBadge = (value: CommunicationType) => {
    const classes: Record<CommunicationType, string> = {
      info: 'bg-blue-100 text-blue-800',
      success: 'bg-green-100 text-green-800',
      warning: 'bg-amber-100 text-amber-800',
      error: 'bg-red-100 text-red-800',
    };

    return <Badge className={classes[value]}>{value.toUpperCase()}</Badge>;
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-2xl font-semibold tracking-tight">Communications Center</h1>
        <p className="text-muted-foreground">
          Send broadcast notifications, incident alerts, and lifecycle messages to platform users.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Clients</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-semibold">{audienceCounts.all_clients ?? 0}</div>
            <p className="text-xs text-muted-foreground">{audienceCounts.active_clients ?? 0} active</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Vendors</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-semibold">{audienceCounts.all_vendors ?? 0}</div>
            <p className="text-xs text-muted-foreground">{audienceCounts.active_vendors ?? 0} active</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Suspended Accounts</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-semibold">
              {(audienceCounts.suspended_clients ?? 0) + (audienceCounts.suspended_vendors ?? 0)}
            </div>
            <p className="text-xs text-muted-foreground">Useful for compliance notices</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Admin Operators</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-semibold">{audienceCounts.admins ?? 0}</div>
            <p className="text-xs text-muted-foreground">Internal operations channel</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-3">
        <Card className="xl:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Megaphone className="h-5 w-5" /> Compose Broadcast
            </CardTitle>
            <CardDescription>
              Notifications are stored per-recipient in Firestore and delivered in batched writes.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <label className="text-sm font-medium">Audience</label>
                <Select value={audience} onValueChange={(value) => setAudience(value as CommunicationAudience)}>
                  <SelectTrigger>
                    <SelectValue placeholder="Choose audience" />
                  </SelectTrigger>
                  <SelectContent>
                    {audienceOptions.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Message Type</label>
                <Select value={type} onValueChange={(value) => setType(value as CommunicationType)}>
                  <SelectTrigger>
                    <SelectValue placeholder="Type" />
                  </SelectTrigger>
                  <SelectContent>
                    {typeOptions.map((option) => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Title</label>
              <Input
                placeholder="Example: Planned maintenance window"
                value={title}
                onChange={(event) => setTitle(event.target.value)}
                maxLength={120}
              />
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Message</label>
              <Textarea
                placeholder="Write the exact message users should receive"
                value={message}
                onChange={(event) => setMessage(event.target.value)}
                className="min-h-[140px]"
              />
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium">Optional Deep Link</label>
              <Input
                placeholder="/orders/123 or /help"
                value={link}
                onChange={(event) => setLink(event.target.value)}
              />
            </div>

            <div className="flex flex-wrap items-center justify-between gap-3 rounded-lg border bg-muted/30 px-4 py-3">
              <div className="text-sm">
                <p className="font-medium">
                  Sending to <span className="text-primary">{selectedAudienceLabel}</span>
                </p>
                <p className="text-muted-foreground">
                  Estimated recipients: <strong>{previewCount}</strong>
                </p>
              </div>
              <Button
                onClick={handleSend}
                disabled={loading || isReadOnly || previewCount === 0}
                className="min-w-[180px]"
              >
                <SendHorizontal className="mr-2 h-4 w-4" />
                {loading ? 'Sending...' : 'Send Notification'}
              </Button>
            </div>

            {isReadOnly && (
              <p className="flex items-center gap-2 text-sm text-amber-700">
                <ShieldAlert className="h-4 w-4" />
                Viewer role cannot send communications.
              </p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="h-5 w-5" /> Audience Preview
            </CardTitle>
            <CardDescription>Sample recipients for the selected audience.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {previewSample.length === 0 ? (
              <p className="text-sm text-muted-foreground">No recipients available.</p>
            ) : (
              previewSample.map((recipient) => (
                <div key={recipient.id} className="rounded-md border p-3">
                  <p className="text-sm font-medium truncate">{recipient.label}</p>
                  <p className="text-xs text-muted-foreground truncate">{recipient.email || recipient.id}</p>
                </div>
              ))
            )}

            <Button
              variant="outline"
              onClick={loadPreview}
              disabled={refreshing}
              className="w-full"
            >
              <BellRing className="mr-2 h-4 w-4" /> Refresh Preview
            </Button>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Recent Campaigns</CardTitle>
          <CardDescription>Operational history for sent communications.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          {recent.length === 0 ? (
            <p className="text-sm text-muted-foreground">No campaign history yet.</p>
          ) : (
            recent.map((campaign) => (
              <div key={campaign.id} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border p-3">
                <div className="min-w-0">
                  <p className="text-sm font-medium truncate">{campaign.title}</p>
                  <p className="text-xs text-muted-foreground">
                    {campaign.audience} • {formatDateTime(campaign.createdAt as Date | string | number | { toDate(): Date } | null | undefined)}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  {getTypeBadge(campaign.type)}
                  <Badge variant="outline">
                    {campaign.deliveredCount}/{campaign.attemptedCount}
                  </Badge>
                </div>
              </div>
            ))
          )}
        </CardContent>
      </Card>
    </div>
  );
}
