/**
 * Settl API Service Client
 * Connects to live Render Backend at https://settl-kru1.onrender.com
 * Handles authentication headers, Idempotency-Keys & explicit logging.
 */

const API_BASE = import.meta.env.VITE_API_URL || 'https://settl-kru1.onrender.com';

let authToken = localStorage.getItem('settl_jwt_token') || 'dev_token';

export function setAuthToken(token) {
  authToken = token || 'dev_token';
  if (token) {
    localStorage.setItem('settl_jwt_token', token);
  } else {
    localStorage.removeItem('settl_jwt_token');
  }
}

export function getAuthToken() {
  return authToken;
}

async function request(endpoint, options = {}) {
  const url = `${API_BASE}${endpoint}`;
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${authToken}`,
    ...options.headers,
  };

  console.log(`[API Call] ${options.method || 'GET'} ${url}`, options.body || '');

  try {
    const res = await fetch(url, { ...options, headers });
    if (!res.ok) {
      const errorText = await res.text().catch(() => res.statusText);
      console.error(`[API Error ${res.status}] ${endpoint}:`, errorText);
      throw new Error(`API Error ${res.status}: ${errorText}`);
    }
    const data = await res.json();
    console.log(`[API Response ${res.status}] ${endpoint}:`, data);
    return data;
  } catch (err) {
    console.warn(`[Settl API Failure] ${endpoint}:`, err.message);
    throw err;
  }
}

export const SettlApi = {
  // Check live API health status
  async checkHealth() {
    return await request('/health');
  },

  // Groups API
  async listGroups() {
    return await request('/api/v1/groups');
  },

  async createGroup(name, currency = 'INR') {
    return await request('/api/v1/groups', {
      method: 'POST',
      body: JSON.stringify({ name, currency }),
    });
  },

  async addGroupMember(groupID, userId) {
    return await request(`/api/v1/groups/${groupID}/members`, {
      method: 'POST',
      body: JSON.stringify({ user_id: userId }),
    });
  },

  // Expenses API
  async listExpenses(groupID = null) {
    const query = groupID ? `?groupID=${encodeURIComponent(groupID)}` : '';
    return await request(`/api/v1/expenses${query}`);
  },

  async createExpense(expenseData) {
    const idempotencyKey = expenseData.idempotency_key || `idemp-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;

    return await request('/api/v1/expenses', {
      method: 'POST',
      headers: {
        'Idempotency-Key': idempotencyKey,
      },
      body: JSON.stringify(expenseData),
    });
  },

  // Balances API
  async getBalances(groupID = null, personID = null) {
    const params = new URLSearchParams();
    if (groupID) params.append('groupID', groupID);
    if (personID) params.append('personID', personID);
    const query = params.toString() ? `?${params.toString()}` : '';
    return await request(`/api/v1/balances${query}`);
  }
};
