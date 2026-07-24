import React, { useState } from 'react';
import { X, Calculator, Plus, Users } from 'lucide-react';
import { rupeesToPaise, formatCurrency } from '../utils/splitMath';

export default function TipCalculatorModal({ isOpen, onClose, onSaveExpense }) {
  const [billRupees, setBillRupees] = useState('1200');
  const [tipPct, setTipPct] = useState(10);
  const [peopleCount, setPeopleCount] = useState(3);

  if (!isOpen) return null;

  const bill = parseFloat(billRupees) || 0;
  const tipAmount = (bill * tipPct) / 100;
  const totalAmount = bill + tipAmount;
  const perPersonTotal = peopleCount > 0 ? totalAmount / peopleCount : totalAmount;

  const handleLogExpense = () => {
    if (totalAmount <= 0) return;
    onSaveExpense({
      amount_paise: rupeesToPaise(totalAmount),
      category: 'Food',
      note: `Bill split (₹${bill} + ${tipPct}% tip for ${peopleCount} people)`,
      timestamp: new Date().toISOString()
    });
    onClose();
  };

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '16px' }}>
      <div className="glass-card fade-in" style={{ width: '100%', maxWidth: '360px', padding: '20px', background: 'var(--bg-surface)' }}>
        
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Calculator size={18} color="var(--accent-gold)" />
            <h3 className="font-heading" style={{ fontSize: '17px', fontWeight: 700 }}>Tip & Split Calculator</h3>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}><X size={20} /></button>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <div>
            <label style={{ fontSize: '11px', color: 'var(--text-muted)', display: 'block', marginBottom: '2px' }}>Bill Subtotal (₹)</label>
            <input
              type="number"
              value={billRupees}
              onChange={(e) => setBillRupees(e.target.value)}
              className="font-mono"
              style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: '1px solid var(--border-subtle)', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)', fontSize: '16px', fontWeight: 700 }}
            />
          </div>

          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: 'var(--text-muted)', marginBottom: '4px' }}>
              <span>Tip Percentage</span>
              <span className="font-mono" style={{ color: 'var(--accent-gold)', fontWeight: 600 }}>{tipPct}% (₹{tipAmount.toFixed(2)})</span>
            </div>
            <div style={{ display: 'flex', gap: '6px' }}>
              {[0, 5, 10, 15, 20].map(pct => (
                <button
                  key={pct}
                  type="button"
                  onClick={() => setTipPct(pct)}
                  style={{
                    flex: 1,
                    padding: '6px 0',
                    borderRadius: '6px',
                    border: '1px solid var(--border-subtle)',
                    background: tipPct === pct ? 'var(--accent-gold)' : 'rgba(255,255,255,0.04)',
                    color: tipPct === pct ? '#0F172A' : 'var(--text-main)',
                    fontWeight: 600,
                    fontSize: '12px',
                    cursor: 'pointer'
                  }}
                >
                  {pct}%
                </button>
              ))}
            </div>
          </div>

          <div>
            <label style={{ fontSize: '11px', color: 'var(--text-muted)', display: 'block', marginBottom: '2px' }}>Number of People</label>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <input
                type="number"
                min="1"
                value={peopleCount}
                onChange={(e) => setPeopleCount(parseInt(e.target.value, 10) || 1)}
                className="font-mono"
                style={{ width: '80px', padding: '8px', borderRadius: '6px', border: '1px solid var(--border-subtle)', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)', textAlign: 'center', fontSize: '14px', fontWeight: 600 }}
              />
              <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>people sharing bill</span>
            </div>
          </div>

          {/* Computed Summary Card */}
          <div style={{ background: 'rgba(245, 158, 11, 0.1)', border: '1px solid rgba(245, 158, 11, 0.3)', padding: '12px', borderRadius: '8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '4px' }}>
            <div>
              <div style={{ fontSize: '10.5px', color: 'var(--text-muted)' }}>Per Person Pay</div>
              <div className="font-heading" style={{ fontSize: '20px', fontWeight: 700, color: 'var(--accent-gold)' }}>
                ₹{perPersonTotal.toFixed(2)}
              </div>
            </div>

            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: '10.5px', color: 'var(--text-muted)' }}>Total incl. tip</div>
              <div className="font-mono" style={{ fontSize: '14px', fontWeight: 600 }}>
                ₹{totalAmount.toFixed(2)}
              </div>
            </div>
          </div>

          <button onClick={handleLogExpense} className="btn-primary" style={{ marginTop: '10px', justifyContent: 'center' }}>
            <Plus size={16} />
            Log as Group Expense
          </button>
        </div>

      </div>
    </div>
  );
}
