/**
 * Mock Seed Data for Settl Web Prototype
 * Reflects specs in docs/finance-app-spec.md & docs/flutter_app_context.md
 */

export const CURRENT_USER = {
  id: 'usr_me_001',
  name: 'Advaith (You)',
  phone: '+919876543210', // E.164 normalized
  upi_vpa: 'advaith@okaxis',
  avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80'
};

export const FRIENDS = [
  { id: 'usr_sarah_002', name: 'Sarah', phone: '+919812345678', upi_vpa: 'sarah@upi', avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80', balancePaise: 45000 }, // +₹450 owed to me
  { id: 'usr_rahul_003', name: 'Rahul', phone: '+919876012345', upi_vpa: 'rahul@paytm', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80', balancePaise: -32000 }, // -₹320 I owe Rahul
  { id: 'usr_priya_004', name: 'Priyanshu', phone: '+919988776655', upi_vpa: 'priyanshu@ybl', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80', balancePaise: 125000 }, // +₹1250 owed to me
  { id: 'usr_ananya_005', name: 'Ananya', phone: '+919123456789', upi_vpa: 'ananya@icici', avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80', balancePaise: 0 },
];

export const INITIAL_GROUPS = [
  {
    id: 'grp_0042',
    account_number: 'GRP-0042',
    name: 'Goa Trip 2026',
    currency: 'INR',
    created_at: '2026-06-10T10:00:00Z',
    members: ['usr_me_001', 'usr_sarah_002', 'usr_rahul_003', 'usr_priya_004'],
    totalSpendPaise: 4850000,
    coverImage: 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=600&auto=format&fit=crop&q=80'
  },
  {
    id: 'grp_0043',
    account_number: 'GRP-0043',
    name: 'Flatmates 402',
    currency: 'INR',
    created_at: '2026-01-01T00:00:00Z',
    members: ['usr_me_001', 'usr_rahul_003', 'usr_ananya_005'],
    totalSpendPaise: 12400000,
    coverImage: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600&auto=format&fit=crop&q=80'
  },
  {
    id: 'grp_0044',
    account_number: 'GRP-0044',
    name: 'Weekend Foodies',
    currency: 'INR',
    created_at: '2026-05-15T18:30:00Z',
    members: ['usr_me_001', 'usr_sarah_002', 'usr_ananya_005'],
    totalSpendPaise: 1845000,
    coverImage: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600&auto=format&fit=crop&q=80'
  }
];

export const INITIAL_EXPENSES = [
  {
    id: 'exp_101',
    group_id: 'grp_0042',
    payer_id: 'usr_me_001',
    amount_paise: 360000, // ₹3,600
    currency: 'INR',
    category: 'Food',
    note: 'Beachside Seafood Dinner at Baga',
    timestamp: '2026-07-22T20:45:00Z',
    receipt_url: 'https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?w=500&auto=format&fit=crop&q=80',
    idempotency_key: 'idemp-101-uuid',
    splits: [
      { user_id: 'usr_me_001', split_type: 'equal', share_amount: 900 },
      { user_id: 'usr_sarah_002', split_type: 'equal', share_amount: 900 },
      { user_id: 'usr_rahul_003', split_type: 'equal', share_amount: 900 },
      { user_id: 'usr_priya_004', split_type: 'equal', share_amount: 900 }
    ]
  },
  {
    id: 'exp_102',
    group_id: 'grp_0043',
    payer_id: 'usr_rahul_003',
    amount_paise: 2400000, // ₹24,000
    currency: 'INR',
    category: 'Rent',
    note: 'July House Rent & Maintenance',
    timestamp: '2026-07-01T09:00:00Z',
    receipt_url: null,
    idempotency_key: 'idemp-102-uuid',
    splits: [
      { user_id: 'usr_me_001', split_type: 'exact', share_amount: 8000 },
      { user_id: 'usr_rahul_003', split_type: 'exact', share_amount: 8000 },
      { user_id: 'usr_ananya_005', split_type: 'exact', share_amount: 8000 }
    ]
  },
  {
    id: 'exp_103',
    group_id: 'grp_0044',
    payer_id: 'usr_me_001',
    amount_paise: 145000, // ₹1,450
    currency: 'INR',
    category: 'Food',
    note: 'Artisanal Pizza & Drinks',
    timestamp: '2026-07-20T19:30:00Z',
    receipt_url: null,
    idempotency_key: 'idemp-103-uuid',
    splits: [
      { user_id: 'usr_me_001', split_type: 'percentage', share_amount: 435, percentage: 30 },
      { user_id: 'usr_sarah_002', split_type: 'percentage', share_amount: 725, percentage: 50 },
      { user_id: 'usr_ananya_005', split_type: 'percentage', share_amount: 290, percentage: 20 }
    ]
  },
  {
    id: 'exp_104',
    group_id: null, // 1:1 friend expense
    payer_id: 'usr_sarah_002',
    amount_paise: 90000, // ₹900
    currency: 'INR',
    category: 'Entertainment',
    note: 'Movie IMAX Tickets (Interstellar)',
    timestamp: '2026-07-18T16:00:00Z',
    receipt_url: null,
    idempotency_key: 'idemp-104-uuid',
    splits: [
      { user_id: 'usr_me_001', split_type: 'shares', share_amount: 450, share_count: 1 },
      { user_id: 'usr_sarah_002', split_type: 'shares', share_amount: 450, share_count: 1 }
    ]
  }
];

export const INITIAL_BUDGETS = [
  { category: 'Food', targetPaise: 1500000, spentPaise: 1180000, historicalSuggested: 1400000 }, // ₹15,000 target, ₹11,800 spent (78.6%)
  { category: 'Rent', targetPaise: 2500000, spentPaise: 2400000, historicalSuggested: 2500000 }, // ₹25,000 target, ₹24,000 spent (96%)
  { category: 'Transport', targetPaise: 500000, spentPaise: 210000, historicalSuggested: 450000 },
  { category: 'Entertainment', targetPaise: 600000, spentPaise: 490000, historicalSuggested: 550000 },
  { category: 'Shopping', targetPaise: 800000, spentPaise: 320000, historicalSuggested: 750000 }
];

export const INITIAL_SUBSCRIPTIONS = [
  { id: 'sub_1', name: 'Netflix Premium 4K', amountPaise: 64900, cycle: 'Monthly', nextRenewal: '2026-08-03', category: 'Entertainment', isTrial: false },
  { id: 'sub_2', name: 'Spotify Duo', amountPaise: 14900, cycle: 'Monthly', nextRenewal: '2026-08-12', category: 'Entertainment', isTrial: false },
  { id: 'sub_3', name: 'Claude Pro AI', amountPaise: 199900, cycle: 'Monthly', nextRenewal: '2026-07-27', category: 'Utilities', isTrial: true, trialEndsDays: 3 },
  { id: 'sub_4', name: 'Amazon Prime India', amountPaise: 149900, cycle: 'Yearly', nextRenewal: '2026-11-20', category: 'Shopping', isTrial: false }
];

export const INITIAL_TICKETS = [
  {
    id: 'tkt_1',
    type: 'Train',
    title: 'Vande Bharat Express',
    route: 'Mumbai Central → Goa (Madgaon)',
    datetime: '2026-08-05T06:15:00',
    pnr: '8421-9503-11',
    seat: 'Coach C4 • Seat 28 (Window)',
    qrCodeValue: 'PNR:8421950311|TRAIN:22223|SEAT:C4-28',
    amountPaise: 165000,
    status: 'Confirmed'
  },
  {
    id: 'tkt_2',
    type: 'Movie',
    title: 'Interstellar 10th Anniversary (IMAX 70mm)',
    route: 'PVR INOX Palladium, Screen 1',
    datetime: '2026-07-28T19:30:00',
    pnr: 'PVR-890412',
    seat: 'Recliner E-12, E-13',
    qrCodeValue: 'PVR:890412|SEAT:E12-E13|IMAX',
    amountPaise: 120000,
    status: 'Booked'
  },
  {
    id: 'tkt_3',
    type: 'Flight',
    title: 'IndiGo 6E-204',
    route: 'BOM (Mumbai) → DEL (Delhi)',
    datetime: '2026-08-18T14:10:00',
    pnr: '6E-7X9P4',
    seat: 'Seat 14F',
    qrCodeValue: 'FLIGHT:6E204|PNR:7X9P4|BOM-DEL',
    amountPaise: 489000,
    status: 'Upcoming'
  }
];

export const QUICK_PRESETS = [
  { id: 'p1', name: 'Cutting Chai', amountPaise: 1500, category: 'Food', note: 'Chai stall near office' },
  { id: 'p2', name: 'Metro Recharge', amountPaise: 20000, category: 'Transport', note: 'Daily commute' },
  { id: 'p3', name: 'Swiggy Lunch Split', amountPaise: 35000, category: 'Food', note: 'Team lunch' },
  { id: 'p4', name: 'Flatmaid Monthly', amountPaise: 150000, category: 'Rent', note: 'Maid split' }
];
