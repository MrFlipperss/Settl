import React, { useState } from 'react';
import {
  ArrowUpRight,
  ArrowDownLeft,
  QrCode,
  Zap,
  CheckCircle2,
  Users,
  Plus,
  PieChart,
  Ticket,
  Sparkles,
  AlertTriangle,
  Train,
  Film,
  Plane,
  ChevronRight
} from 'lucide-react';
import { formatCurrency } from '../utils/splitMath';

export default function Dashboard({
  user,
  friends = [],
  groups = [],
  expenses = [],
  budgets = [],
  subscriptions = [],
  tickets = [],
  presets = [],
  onOpenSettleQr,
  onOpenNewExpense,
  onApplyPreset,
  onCreateGroup,
  onConvertTicketToExpense
}) {
  const [filterType, setFilterType] = useState('all');
  const [showCreateGroupModal, setShowCreateGroupModal] = useState(false);
  const [newGroupName, setNewGroupName] = useState('');
  const [selectedMemberIds, setSelectedMemberIds] = useState([]);

  // Calculate Net Balances
  let totalOwedPaise = 0;
  let totalOwingPaise = 0;

  friends.forEach(f => {
    if (f.balancePaise > 0) {
      totalOwedPaise += f.balancePaise;
    } else if (f.balancePaise < 0) {
      totalOwingPaise += Math.abs(f.balancePaise);
    }
  });

  const netBalancePaise = totalOwedPaise - totalOwingPaise;

  const filteredFriends = friends.filter(f => {
    if (filterType === 'owed') return f.balancePaise > 0;
    if (filterType === 'owing') return f.balancePaise < 0;
    return true;
  });

  const handleCreateGroupSubmit = (e) => {
    e.preventDefault();
    if (!newGroupName.trim()) return;

    const nextNum = groups.length + 42;
    const account_number = `GRP-${String(nextNum).padStart(4, '0')}`;

    const newGroup = {
      id: `grp_${Date.now()}`,
      account_number,
      name: newGroupName.trim(),
      currency: 'INR',
      created_at: new Date().toISOString(),
      members: ['usr_me_001', ...selectedMemberIds],
      totalSpendPaise: 0
    };

    onCreateGroup(newGroup);
    setNewGroupName('');
    setSelectedMemberIds([]);
    setShowCreateGroupModal(false);
  };

  const toggleMemberSelection = (friendId) => {
    if (selectedMemberIds.includes(friendId)) {
      setSelectedMemberIds(selectedMemberIds.filter(id => id !== friendId));
    } else {
      setSelectedMemberIds([...selectedMemberIds, friendId]);
    }
  };

  // Pace math
  const currentDay = 24;
  const daysInMonth = 31;
  const monthPacePct = Math.round((currentDay / daysInMonth) * 100);

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gridTemplateRows: '1fr 1fr', gap: '10px', height: '100%', width: '100%', overflow: 'hidden' }}>
      
      {/* ================= QUADRANT 1 (Top-Left): Net Position & Ledger Activity ================= */}
      <div className="panel-card" style={{ gridColumn: '1', gridRow: '1' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span className="badge-gold font-mono" style={{ fontSize: '9px', padding: '1px 6px', borderRadius: '3px' }}>NET POSITION</span>
            <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Consolidated Ledger</span>
          </div>
          <div className="font-heading" style={{ fontSize: '22px', fontWeight: 700, color: netBalancePaise >= 0 ? '#10B981' : '#EF4444' }}>
            {netBalancePaise >= 0 ? `+${formatCurrency(netBalancePaise, true)}` : `-${formatCurrency(Math.abs(netBalancePaise), true)}`}
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px', marginBottom: '10px' }}>
          <div style={{ background: 'rgba(16, 185, 129, 0.08)', padding: '6px 10px', borderRadius: '6px', border: '1px solid rgba(16, 185, 129, 0.2)' }}>
            <div style={{ fontSize: '10px', color: '#10B981', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px' }}>
              <ArrowDownLeft size={11} /> You are Owed
            </div>
            <div className="font-mono" style={{ fontSize: '13.5px', fontWeight: 700, color: '#10B981' }}>
              {formatCurrency(totalOwedPaise, true)}
            </div>
          </div>

          <div style={{ background: 'rgba(239, 68, 68, 0.08)', padding: '6px 10px', borderRadius: '6px', border: '1px solid rgba(239, 68, 68, 0.2)' }}>
            <div style={{ fontSize: '10px', color: '#EF4444', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px' }}>
              <ArrowUpRight size={11} /> You Owe
            </div>
            <div className="font-mono" style={{ fontSize: '13.5px', fontWeight: 700, color: '#EF4444' }}>
              {formatCurrency(totalOwingPaise, true)}
            </div>
          </div>
        </div>

        {/* Presets Strip */}
        <div style={{ display: 'flex', gap: '6px', overflowX: 'auto', paddingBottom: '6px', marginBottom: '8px' }}>
          {presets.map(p => (
            <button key={p.id} onClick={() => onApplyPreset(p)} className="btn-secondary" style={{ padding: '4px 8px', fontSize: '11px', whiteSpace: 'nowrap' }}>
              <Zap size={11} color="var(--accent-gold)" /> {p.name} ({formatCurrency(p.amountPaise, true)})
            </button>
          ))}
        </div>

        {/* Recent Activity List */}
        <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--text-muted)', marginBottom: '4px' }}>RECENT EXPENSES</div>
        <div className="inner-scroll" style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
          {expenses.slice(0, 5).map(exp => (
            <div key={exp.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '6px 8px', borderRadius: '6px', background: 'rgba(255,255,255,0.03)', border: '1px solid var(--border-subtle)' }}>
              <div>
                <div style={{ fontSize: '12px', fontWeight: 600 }}>{exp.note}</div>
                <div style={{ fontSize: '10px', color: 'var(--text-muted)' }}>{exp.category} • {new Date(exp.timestamp).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}</div>
              </div>
              <div className="font-mono" style={{ fontSize: '12px', fontWeight: 700 }}>
                {formatCurrency(exp.amount_paise, true)}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ================= QUADRANT 2 (Top-Right): Numbered Group Passbooks ================= */}
      <div className="panel-card" style={{ gridColumn: '2', gridRow: '1' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Users size={15} color="var(--accent-cyan)" />
            <span className="font-heading" style={{ fontSize: '14px', fontWeight: 700 }}>Group Passbooks</span>
          </div>
          <button onClick={() => setShowCreateGroupModal(true)} className="btn-primary" style={{ padding: '4px 8px', fontSize: '11px' }}>
            <Plus size={12} /> New Group
          </button>
        </div>

        <div className="inner-scroll" style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
          {groups.map(g => (
            <div key={g.id} style={{ padding: '10px 12px', borderRadius: '8px', background: 'rgba(255,255,255,0.03)', border: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <span className="badge-gold font-mono" style={{ fontSize: '9px', padding: '1px 5px', borderRadius: '3px' }}>{g.account_number}</span>
                <div style={{ fontSize: '13px', fontWeight: 700, marginTop: '2px' }}>{g.name}</div>
                <div style={{ fontSize: '10.5px', color: 'var(--text-muted)' }}>{g.member_count ?? g.members?.length ?? 0} members</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div className="font-mono" style={{ fontSize: '13px', fontWeight: 700, color: 'var(--accent-gold)' }}>
                  {formatCurrency(g.totalSpendPaise, true)}
                </div>
                <span style={{ fontSize: '10px', color: 'var(--text-muted)' }}>Volume</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* ================= QUADRANT 3 (Bottom-Left): Contacts & UPI Settle Up ================= */}
      <div className="panel-card" style={{ gridColumn: '1', gridRow: '2' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
          <h3 className="font-heading" style={{ fontSize: '14px', fontWeight: 700 }}>Contacts & Settlements</h3>
          <div style={{ display: 'flex', gap: '3px', background: 'rgba(255,255,255,0.04)', padding: '2px', borderRadius: '4px' }}>
            {['all', 'owed', 'owing'].map(t => (
              <button key={t} onClick={() => setFilterType(t)} style={{ background: filterType === t ? 'var(--accent-gold)' : 'transparent', color: filterType === t ? '#0F172A' : 'var(--text-muted)', border: 'none', padding: '2px 6px', borderRadius: '3px', fontSize: '10px', fontWeight: 600 }}>{t}</button>
            ))}
          </div>
        </div>

        <div className="inner-scroll" style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
          {filteredFriends.map(f => {
            const isOwed = f.balancePaise > 0;
            const isOwing = f.balancePaise < 0;
            const absBal = Math.abs(f.balancePaise);

            return (
              <div key={f.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px 10px', borderRadius: '6px', background: 'rgba(255,255,255,0.03)', border: '1px solid var(--border-subtle)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <img src={f.avatar} alt={f.name} style={{ width: '28px', height: '28px', borderRadius: '50%', objectFit: 'cover' }} />
                  <div>
                    <div style={{ fontSize: '12.5px', fontWeight: 600 }}>{f.name}</div>
                    <div style={{ fontSize: '10px', color: 'var(--text-muted)' }}>
                      {isOwed ? `owes you ${formatCurrency(absBal, true)}` : isOwing ? `you owe ${formatCurrency(absBal, true)}` : 'Settled'}
                    </div>
                  </div>
                </div>

                {f.balancePaise !== 0 ? (
                  <button onClick={() => onOpenSettleQr(f, absBal, isOwing ? 'PAY' : 'REQUEST')} className="btn-secondary font-mono" style={{ fontSize: '11px', padding: '4px 8px', color: isOwing ? 'var(--accent-red)' : 'var(--accent-green)' }}>
                    <QrCode size={12} /> {isOwing ? 'Pay UPI' : 'Request UPI'}
                  </button>
                ) : (
                  <span style={{ fontSize: '10px', color: 'var(--accent-green)', display: 'flex', alignItems: 'center', gap: '3px' }}>
                    <CheckCircle2 size={12} /> Settled
                  </span>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* ================= QUADRANT 4 (Bottom-Right): AI Budget & Ticket Wallet ================= */}
      <div className="panel-card" style={{ gridColumn: '2', gridRow: '2' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <PieChart size={15} color="var(--accent-purple)" />
            <h3 className="font-heading" style={{ fontSize: '14px', fontWeight: 700 }}>AI Co-Pilot & Wallet</h3>
          </div>
          <span className="badge-purple font-mono" style={{ fontSize: '9px', padding: '1px 5px', borderRadius: '3px' }}>Pace: {monthPacePct}%</span>
        </div>

        <div className="inner-scroll" style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
          {/* Pace Alert */}
          <div style={{ background: 'rgba(245, 158, 11, 0.08)', border: '1px solid rgba(245, 158, 11, 0.2)', padding: '6px 8px', borderRadius: '6px', fontSize: '11px' }}>
            <span style={{ fontWeight: 600, color: 'var(--accent-gold)' }}>Monthly Pace Alert: </span>
            <span>78% spent on Food budget vs 77% time elapsed.</span>
          </div>

          {/* Budget Progress Bars */}
          {budgets.slice(0, 3).map(b => {
            const pct = Math.round((b.spentPaise / b.targetPaise) * 100);
            return (
              <div key={b.category} style={{ fontSize: '11px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '2px' }}>
                  <span style={{ fontWeight: 600 }}>{b.category}</span>
                  <span className="font-mono">{formatCurrency(b.spentPaise, true)} / {formatCurrency(b.targetPaise, true)}</span>
                </div>
                <div style={{ height: '5px', background: 'rgba(255,255,255,0.06)', borderRadius: '99px', overflow: 'hidden' }}>
                  <div style={{ height: '100%', width: `${Math.min(100, pct)}%`, background: pct > 90 ? 'var(--accent-red)' : 'var(--accent-green)' }} />
                </div>
              </div>
            );
          })}

          {/* Wallet Pass Thumbnail */}
          {tickets.length > 0 && (
            <div style={{ padding: '6px 8px', borderRadius: '6px', background: 'rgba(255,255,255,0.03)', border: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '2px' }}>
              <div>
                <div style={{ fontSize: '11.5px', fontWeight: 600 }}>{tickets[0].title}</div>
                <div style={{ fontSize: '10px', color: 'var(--text-muted)' }}>{tickets[0].pnr} • {tickets[0].seat}</div>
              </div>
              <button onClick={() => onConvertTicketToExpense(tickets[0])} className="btn-secondary" style={{ fontSize: '10px', padding: '3px 6px' }}>
                + Log
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Modal: Create Group */}
      {showCreateGroupModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '16px' }}>
          <div className="panel-card fade-in" style={{ width: '100%', maxWidth: '380px', padding: '20px', background: 'var(--bg-surface)' }}>
            <h3 className="font-heading" style={{ fontSize: '17px', fontWeight: 700, marginBottom: '12px' }}>Create Group Passbook</h3>
            <form onSubmit={handleCreateGroupSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div>
                <label style={{ fontSize: '11px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Group Name</label>
                <input
                  type="text"
                  placeholder="e.g. Goa Trip 2026"
                  value={newGroupName}
                  onChange={(e) => setNewGroupName(e.target.value)}
                  required
                  style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: '1px solid var(--border-subtle)', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)', fontSize: '13px' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '11px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Include Members</label>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', maxHeight: '140px', overflowY: 'auto' }}>
                  {friends.map(f => {
                    const isSel = selectedMemberIds.includes(f.id);
                    return (
                      <div key={f.id} onClick={() => toggleMemberSelection(f.id)} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '6px 8px', borderRadius: '6px', background: isSel ? 'rgba(245, 158, 11, 0.15)' : 'rgba(255,255,255,0.03)', cursor: 'pointer' }}>
                        <span style={{ fontSize: '12px' }}>{f.name}</span>
                        {isSel && <CheckCircle2 size={14} color="var(--accent-gold)" />}
                      </div>
                    );
                  })}
                </div>
              </div>

              <div style={{ display: 'flex', gap: '8px', marginTop: '8px' }}>
                <button type="button" onClick={() => setShowCreateGroupModal(false)} className="btn-secondary" style={{ flex: 1, justifyContent: 'center' }}>Cancel</button>
                <button type="submit" className="btn-primary" style={{ flex: 1, justifyContent: 'center' }}>Create</button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
