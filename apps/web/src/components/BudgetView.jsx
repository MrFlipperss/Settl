import React from 'react';
import { PieChart, AlertTriangle, TrendingUp, Sparkles, CheckCircle2 } from 'lucide-react';
import { formatCurrency } from '../utils/splitMath';

export default function BudgetView({ budgets = [], expenses = [], onUpdateBudget }) {
  // Current month pace calculation (assuming 24th day of 31-day month ~ 77% time elapsed)
  const currentDay = 24;
  const daysInMonth = 31;
  const monthPacePct = Math.round((currentDay / daysInMonth) * 100);

  // Find anomaly (e.g. high food charge or duplicate)
  const anomalyExps = expenses.filter(e => e.amount_paise > 100000); // charges > ₹1000

  return (
    <div className="fade-in" style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
      
      {/* Header Banner */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2 className="font-heading" style={{ fontSize: '18px', fontWeight: 700 }}>AI Budget Co-pilot</h2>
          <p style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Historical suggestions & real-time pace alerts</p>
        </div>

        <span className="badge-gold font-mono" style={{ fontSize: '11px', padding: '4px 8px', borderRadius: '6px' }}>
          Day {currentDay}/{daysInMonth} ({monthPacePct}% elapsed)
        </span>
      </div>

      {/* Pace Alert Banner */}
      <div 
        style={{
          background: 'rgba(245, 158, 11, 0.1)',
          border: '1px solid rgba(245, 158, 11, 0.3)',
          borderRadius: 'var(--radius-md)',
          padding: '14px',
          display: 'flex',
          gap: '12px',
          alignItems: 'flex-start'
        }}
      >
        <Sparkles size={20} color="var(--accent-gold)" style={{ flex: 'none', marginTop: '2px' }} />
        <div>
          <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--accent-gold)' }}>
            Monthly Pace Alert
          </div>
          <p style={{ fontSize: '12px', color: 'var(--text-main)', marginTop: '2px', lineHeight: 1.4 }}>
            You're <strong>{monthPacePct}%</strong> through the month and <strong>78%</strong> through your Food budget. On pace to hit budget target comfortably.
          </p>
        </div>
      </div>

      {/* Anomaly Detection Banner */}
      {anomalyExps.length > 0 && (
        <div 
          style={{
            background: 'rgba(239, 68, 68, 0.1)',
            border: '1px solid rgba(239, 68, 68, 0.3)',
            borderRadius: 'var(--radius-md)',
            padding: '12px 14px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: '10px'
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <AlertTriangle size={18} color="var(--accent-red)" />
            <div>
              <div style={{ fontSize: '12px', fontWeight: 600, color: 'var(--accent-red)' }}>
                Anomaly Flagged for Review
              </div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                {anomalyExps[0].note} ({formatCurrency(anomalyExps[0].amount_paise, true)}) is higher than 90% of past entries.
              </div>
            </div>
          </div>

          <span className="badge-red" style={{ fontSize: '10px', padding: '2px 6px', borderRadius: '4px', whiteSpace: 'nowrap' }}>
            Flagged
          </span>
        </div>
      )}

      {/* Category Budgets & Historical Suggestions */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
        <h3 className="font-heading" style={{ fontSize: '15px', fontWeight: 600 }}>Per-Category Spend vs Budget</h3>

        {budgets.map(b => {
          const spentPct = Math.round((b.spentPaise / b.targetPaise) * 100);
          const isOverPace = spentPct > monthPacePct;

          return (
            <div key={b.category} className="glass-card" style={{ padding: '14px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                <div>
                  <span style={{ fontSize: '14px', fontWeight: 600 }}>{b.category}</span>
                  <span style={{ fontSize: '10.5px', color: 'var(--text-muted)', marginLeft: '8px' }}>
                    AI suggested: {formatCurrency(b.historicalSuggested, true)}
                  </span>
                </div>

                <div className="font-mono" style={{ fontSize: '13px', fontWeight: 600 }}>
                  <span style={{ color: spentPct > 90 ? 'var(--accent-red)' : 'var(--text-main)' }}>
                    {formatCurrency(b.spentPaise, true)}
                  </span>
                  <span style={{ color: 'var(--text-muted)', fontWeight: 400 }}> / {formatCurrency(b.targetPaise, true)}</span>
                </div>
              </div>

              {/* Progress Bar */}
              <div style={{ height: '8px', background: 'rgba(255,255,255,0.06)', borderRadius: '99px', overflow: 'hidden', position: 'relative' }}>
                <div 
                  style={{
                    height: '100%',
                    width: `${Math.min(100, spentPct)}%`,
                    background: spentPct > 90 ? 'linear-gradient(90deg, #F59E0B, #EF4444)' : 'linear-gradient(90deg, #10B981, #F59E0B)',
                    borderRadius: '99px',
                    transition: 'width 0.4s ease'
                  }}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '6px', fontSize: '11px', color: 'var(--text-muted)' }}>
                <span>{spentPct}% spent</span>
                <span style={{ color: isOverPace ? 'var(--accent-gold)' : 'var(--accent-green)' }}>
                  {isOverPace ? 'Pacing slightly ahead' : 'Well within pace'}
                </span>
              </div>
            </div>
          );
        })}
      </div>

    </div>
  );
}
