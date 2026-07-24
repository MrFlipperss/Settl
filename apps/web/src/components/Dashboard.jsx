import React, { useState } from 'react';
import { ArrowUpRight, ArrowDownLeft, QrCode, Filter, Plus, Zap, CheckCircle2, ChevronRight } from 'lucide-react';
import { formatCurrency } from '../utils/splitMath';

export default function Dashboard({
  user,
  friends = [],
  groups = [],
  expenses = [],
  presets = [],
  onOpenSettleQr,
  onOpenNewExpense,
  onApplyPreset
}) {
  const [filterType, setFilterType] = useState('all'); // 'all' | 'owed' | 'owing'

  // Calculate Net Balances across all friends
  let totalOwedPaise = 0; // People owe me
  let totalOwingPaise = 0; // I owe people

  friends.forEach(f => {
    if (f.balancePaise > 0) {
      totalOwedPaise += f.balancePaise;
    } else if (f.balancePaise < 0) {
      totalOwingPaise += Math.abs(f.balancePaise);
    }
  });

  const netBalancePaise = totalOwedPaise - totalOwingPaise;

  // Filter friends list
  const filteredFriends = friends.filter(f => {
    if (filterType === 'owed') return f.balancePaise > 0;
    if (filterType === 'owing') return f.balancePaise < 0;
    return true;
  });

  return (
    <div className="fade-in" style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
      
      {/* Global Net Balance Consolidation Passbook Banner */}
      <div className="passbook-banner">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
          <span className="passbook-stamp font-mono">NET LEDGER CONSOLIDATION</span>
          <span className="font-mono" style={{ fontSize: '11px', color: 'var(--paper-sub)' }}>
            ACC: {user.phone}
          </span>
        </div>

        <div style={{ marginTop: '6px' }}>
          <div style={{ fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--paper-sub)', fontWeight: 600 }}>
            Overall Net Position
          </div>
          <div className="font-heading" style={{ fontSize: '30px', fontWeight: 700, color: netBalancePaise >= 0 ? '#15803D' : '#B91C1C', margin: '2px 0 10px' }}>
            {netBalancePaise >= 0 ? `+${formatCurrency(netBalancePaise, true)}` : `-${formatCurrency(Math.abs(netBalancePaise), true)}`}
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', paddingTop: '10px', borderTop: '1px dashed var(--paper-border)' }}>
          <div style={{ background: 'rgba(255, 255, 255, 0.6)', padding: '8px 12px', borderRadius: '8px' }}>
            <div style={{ fontSize: '10.5px', color: '#166534', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px' }}>
              <ArrowDownLeft size={12} /> You are Owed
            </div>
            <div className="font-mono" style={{ fontSize: '14px', fontWeight: 700, color: '#14532D' }}>
              {formatCurrency(totalOwedPaise, true)}
            </div>
          </div>

          <div style={{ background: 'rgba(255, 255, 255, 0.6)', padding: '8px 12px', borderRadius: '8px' }}>
            <div style={{ fontSize: '10.5px', color: '#991B1B', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px' }}>
              <ArrowUpRight size={12} /> You Owe
            </div>
            <div className="font-mono" style={{ fontSize: '14px', fontWeight: 700, color: '#7F1D1D' }}>
              {formatCurrency(totalOwingPaise, true)}
            </div>
          </div>
        </div>
      </div>

      {/* Preset Quick-Add Strip */}
      <div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '8px' }}>
          <Zap size={14} color="var(--accent-gold)" />
          <span className="font-heading" style={{ fontSize: '13px', fontWeight: 600 }}>One-Tap Expense Presets</span>
        </div>
        <div style={{ display: 'flex', gap: '8px', overflowX: 'auto', paddingBottom: '4px' }}>
          {presets.map(preset => (
            <button
              key={preset.id}
              onClick={() => onApplyPreset(preset)}
              className="glass-card"
              style={{
                padding: '8px 12px',
                borderRadius: 'var(--radius-md)',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                whiteSpace: 'nowrap',
                cursor: 'pointer',
                border: '1px solid var(--border-subtle)'
              }}
            >
              <span style={{ fontSize: '12px', fontWeight: 500 }}>{preset.name}</span>
              <span className="font-mono badge-gold" style={{ fontSize: '11px', padding: '2px 6px', borderRadius: '4px' }}>
                {formatCurrency(preset.amountPaise, true)}
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* Friends Balance Rollup & Settle UP */}
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
          <h3 className="font-heading" style={{ fontSize: '15px', fontWeight: 600 }}>Balances & Settlements</h3>
          
          <div style={{ display: 'flex', gap: '4px', background: 'rgba(255,255,255,0.05)', padding: '2px', borderRadius: '6px' }}>
            <button
              onClick={() => setFilterType('all')}
              style={{
                background: filterType === 'all' ? 'var(--accent-gold)' : 'none',
                color: filterType === 'all' ? '#0F172A' : 'var(--text-muted)',
                border: 'none',
                padding: '3px 8px',
                borderRadius: '4px',
                fontSize: '11px',
                cursor: 'pointer',
                fontWeight: 600
              }}
            >
              All
            </button>
            <button
              onClick={() => setFilterType('owed')}
              style={{
                background: filterType === 'owed' ? 'var(--accent-green)' : 'none',
                color: filterType === 'owed' ? '#0F172A' : 'var(--text-muted)',
                border: 'none',
                padding: '3px 8px',
                borderRadius: '4px',
                fontSize: '11px',
                cursor: 'pointer',
                fontWeight: 600
              }}
            >
              Owed
            </button>
            <button
              onClick={() => setFilterType('owing')}
              style={{
                background: filterType === 'owing' ? 'var(--accent-red)' : 'none',
                color: filterType === 'owing' ? '#FFFFFF' : 'var(--text-muted)',
                border: 'none',
                padding: '3px 8px',
                borderRadius: '4px',
                fontSize: '11px',
                cursor: 'pointer',
                fontWeight: 600
              }}
            >
              Owing
            </button>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
          {filteredFriends.map(friend => {
            const isOwed = friend.balancePaise > 0;
            const isOwing = friend.balancePaise < 0;
            const absBal = Math.abs(friend.balancePaise);

            return (
              <div
                key={friend.id}
                className="glass-card"
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '12px 14px'
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <img
                    src={friend.avatar}
                    alt={friend.name}
                    style={{ width: '40px', height: '40px', borderRadius: '50%', objectFit: 'cover' }}
                  />
                  <div>
                    <div style={{ fontWeight: 600, fontSize: '14px' }}>{friend.name}</div>
                    <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                      {isOwed ? `owes you ${formatCurrency(absBal, true)}` : isOwing ? `you owe ${formatCurrency(absBal, true)}` : 'Settled up'}
                    </div>
                  </div>
                </div>

                {friend.balancePaise !== 0 ? (
                  <button
                    onClick={() => onOpenSettleQr(friend, absBal, isOwing ? 'PAY' : 'REQUEST')}
                    className="btn-secondary font-mono"
                    style={{
                      fontSize: '12px',
                      padding: '6px 10px',
                      borderColor: isOwing ? 'rgba(239, 68, 68, 0.4)' : 'rgba(16, 185, 129, 0.4)',
                      color: isOwing ? 'var(--accent-red)' : 'var(--accent-green)'
                    }}
                  >
                    <QrCode size={14} />
                    {isOwing ? 'Pay UPI' : 'Request UPI'}
                  </button>
                ) : (
                  <span style={{ fontSize: '11px', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <CheckCircle2 size={13} color="var(--accent-green)" /> Settled
                  </span>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Recent Ledger Transactions */}
      <div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
          <h3 className="font-heading" style={{ fontSize: '15px', fontWeight: 600 }}>Recent Ledger History</h3>
          <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>{expenses.length} entries</span>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
          {expenses.map(exp => {
            const groupMatch = groups.find(g => g.id === exp.group_id);
            const isMyExpense = exp.payer_id === user.id;

            return (
              <div
                key={exp.id}
                className="glass-card"
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '12px 14px'
                }}
              >
                <div>
                  <div style={{ fontWeight: 600, fontSize: '13.5px' }}>{exp.note}</div>
                  <div style={{ fontSize: '11px', color: 'var(--text-muted)', display: 'flex', gap: '6px', marginTop: '2px' }}>
                    <span className="badge-gold" style={{ fontSize: '9.5px', padding: '1px 5px', borderRadius: '3px' }}>
                      {exp.category}
                    </span>
                    {groupMatch && <span>• {groupMatch.account_number}</span>}
                    <span>• {new Date(exp.timestamp).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}</span>
                  </div>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <div className="font-mono" style={{ fontSize: '14px', fontWeight: 700 }}>
                    {formatCurrency(exp.amount_paise, true)}
                  </div>
                  <div style={{ fontSize: '10.5px', color: isMyExpense ? 'var(--accent-green)' : 'var(--text-muted)' }}>
                    {isMyExpense ? 'You paid' : 'Someone paid'}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

    </div>
  );
}
