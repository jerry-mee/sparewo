export type DashboardRole = 'Administrator' | 'Manager' | 'Mechanic';

const ADMIN_ALIASES = new Set(['administrator', 'admin', 'superadmin', 'super_admin']);
const MANAGER_ALIASES = new Set(['manager']);
const MECHANIC_ALIASES = new Set(['mechanic', 'viewer']);

export const normalizeRole = (role?: string | null): DashboardRole | null => {
  if (!role) return null;
  const normalized = role.trim().toLowerCase();

  if (ADMIN_ALIASES.has(normalized)) return 'Administrator';
  if (MANAGER_ALIASES.has(normalized)) return 'Manager';
  if (MECHANIC_ALIASES.has(normalized)) return 'Mechanic';
  return null;
};

export const isAdministratorRole = (role?: string | null): boolean =>
  normalizeRole(role) === 'Administrator';

export const canAccessDashboardPath = (role: DashboardRole | null, path: string): boolean => {
  if (!role) return false;

  if (role === 'Administrator') return true;

  const managerBlocked = ['/dashboard/settings'];
  if (role === 'Manager') {
    return !managerBlocked.some((blocked) => path === blocked || path.startsWith(`${blocked}/`));
  }

  const mechanicAllowed = ['/dashboard', '/dashboard/orders', '/dashboard/products', '/dashboard/autohub'];
  return mechanicAllowed.some((allowed) => path === allowed || path.startsWith(`${allowed}/`));
};

export const getDefaultDashboardPath = (role: DashboardRole | null): string => {
  if (!role) return '/dashboard';
  if (role === 'Mechanic') return '/dashboard/orders';
  return '/dashboard';
};
