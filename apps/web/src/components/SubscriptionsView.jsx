import React, { useState } from 'react';
import { Bookmark, BellRing, Plus, Calendar, AlertCircle } from 'lucide-react';
import { formatCurrency } from '../utils/splitMath';

export default function SubscriptionsView({ subscriptions = [], onAddSubscription }) {
  const [showModal, setShowModal] = useState(false);
  const [name, setName] = useState('');
  const [amountRupees, setAmountRupees] = useState('');
  const [cycle, setCycle] = useState('Monthly');
  const [category, setCategory] = useState('Entertainment');

  // Compute monthly subscription load
  const monthlyLoadPaise = subscriptions.reduce((acc, s) => {
    if (s.cycle === 'Monthly') return acc + s.amountPaise;
    if (s.cycle === 'Yearly') return acc + Math.round(s.amountPaise / 12);
    return acc;
  }, 0);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!name.trim() || !amountRupees) return;

    const newSub = {
      id: `sub_${Date.now()}`,
      name: name.trim(),
      amountPaise: Math.round(parseFloat(amountRupees) * 100),
      cycle,
      nextRenewal: new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0],
      category,
      isTrial: false
    };

    onAddSubscription(newSub);
    setName('');
    setAmountRupees('');
    setShowModal(false);
  };

  return (
    <div className="fade-in" style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
      
      {/* Top Banner */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2 className="font-heading" style={{ fontSize: '18px', fontWeight: 700 }}>Recurring Subscriptions</h2>
          <p style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Automated trial alerts & monthly load tracking</p>
        </div>

        <button onClick={() => setShowModal(true)} className="btn-primary" style={{ padding: '8px 12px', fontSize: '12px' }}>
          <Plus size={15} />
          Add Sub
        </button>
      </div>

      {/* Monthly Load Passbook Card */}
      <div className="passbook-banner" style={{ background: 'linear-gradient(135deg, #1E293B, #0F172A)', color: '#F8FAFC', border: '1px solid var(--border-subtle)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span className="font-mono badge-purple" style={{ fontSize: '11px', padding: '2px 8px', borderRadius: '4px' }}>
            SUBSCRIPTION LOAD
          </span>
          <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>{subscriptions.length} active Mandates</span>
        </div>

        <div style={{ marginTop: '8px' }}>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Estimated Monthly Commitment</div>
          <div className="font-heading" style={{ fontSize: '28px', fontWeight: 700, color: 'var(--accent-purple)', margin: '2px 0' }}>
            {formatCurrency(monthlyLoadPaise, true)}<span style={{ fontSize: '14px', color: 'var(--text-muted)' }}> / mo</span>
          </div>
        </div>
      </div>

      {/* Trial Alert Cards (Spec 1.10: trial alert 2-3 days before paid charge) */}
      {subscriptions.filter(s => s.isTrial).map(sub => (
        <div
          key={sub.id}
          style={{
            background: 'rgba(139, 92, 246, 0.12)',
            border: '1px solid rgba(139, 92, 246, 0.4)',
            borderRadius: 'var(--radius-md)',
            padding: '12px 14px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between'
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <BellRing size={18} color="var(--accent-purple)" />
            <div>
              <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--accent-purple)' }}>
                Free Trial Expiring Soon ({sub.name})
              </div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                Converts to paid charge ({formatCurrency(sub.amountPaise, true)}) in <strong>{sub.trialEndsDays} days</strong>.
              </div>
            </div>
          </div>

          <span className="badge-purple font-mono" style={{ fontSize: '10px', padding: '3px 6px', borderRadius: '4px', whiteSpace: 'nowrap' }}>
            TRIAL ALERT
          </span>
        </div>
      ))}

      {/* Subscriptions List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
        {subscriptions.map(sub => (
          <div key={sub.id} className="glass-card" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px' }}>
            <div>
              <div style={{ fontWeight: 600, fontSize: '14px' }}>{sub.name}</div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)', display: 'flex', gap: '8px', marginTop: '2px' }}>
                <span className="badge-gold" style={{ fontSize: '9.5px', padding: '1px 5px', borderRadius: '3px' }}>{sub.category}</span>
                <span>• Renews {sub.nextRenewal}</span>
              </div>
            </div>

            <div className="font-mono" style={{ fontSize: '14px', fontWeight: 700, textAlign: 'right' }}>
              {formatCurrency(sub.amountPaise, true)}
              <div style={{ fontSize: '10px', color: 'var(--text-muted)', fontWeight: 400 }}>{sub.cycle}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Modal: Add Subscription */}
      {showModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '16px' }}>
          <div className="glass-card fade-in" style={{ width: '100%', maxWidth: '380px', padding: '20px', background: 'var(--bg-surface)' }}>
            <h3 className="font-heading" style={{ fontSize: '18px', fontWeight: 700, marginBottom: '14px' }}>Add Subscription</h3>

            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div>
                <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Service Name</label>
                <input
                  type="text"
                  placeholder="e.g. Netflix, Spotify, Claude Pro"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                  style={{ width: '100%', padding: '9px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-subtle)', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)', outline: 'none' }}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                <div>
                  <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Amount (₹)</label>
                  <input
                    type="number"
                    placeholder="499"
                    value={amountRupees}
                    onChange={(e) => setAmountRupees(e.target.value)}
                    required
                    style={{ width: '100%', padding: '9px 12px', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-subtle)', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)', outline: 'none' }}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Cycle</label>
                  <select
                    value={cycle}
                    onChange={(e) => setCycle(e.target.value)}
                    style={{ width: '100%', padding: '9px 10px', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-subtle)', background: 'var(--bg-surface)', color: 'var(--text-main)', outline: 'none' }}
                  >
                    <option value="Monthly">Monthly</option>
                    <option value="Yearly">Yearly</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '10px', marginTop: '10px' }}>
                <button type="button" onClick={() => setShowModal(false)} className="btn-secondary" style={{ flex: 1, justifyContent: 'center' }}>Cancel</button>
                <button type="submit" className="btn-primary" style={{ flex: 1, justifyContent: 'center' }}>Save Subscription</button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
