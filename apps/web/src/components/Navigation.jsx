import React from 'react';
import { Plus, Receipt, Calculator, Sun, Moon, Sparkles } from 'lucide-react';

export default function Navigation({ theme, toggleTheme, onOpenNewExpense, onOpenOcr, onOpenTipCalc }) {
  return (
    <header
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '8px 12px',
        background: 'var(--bg-surface)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-md)',
        backdropFilter: 'blur(16px)'
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
        <div 
          style={{
            width: '28px',
            height: '28px',
            borderRadius: '6px',
            background: 'linear-gradient(135deg, #F59E0B, #D97706)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#0F172A',
            fontWeight: 700,
            fontFamily: 'Space Grotesk'
          }}
        >
          ₹
        </div>

        <div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '6px' }}>
            <h1 className="font-heading" style={{ fontSize: '15px', fontWeight: 700, lineHeight: 1 }}>
              Settl <span style={{ fontSize: '10px', color: 'var(--accent-gold)' }} className="font-mono">studio</span>
            </h1>
            <span className="badge-green font-mono" style={{ fontSize: '8.5px', padding: '1px 5px', borderRadius: '3px' }}>
              RENDER LIVE
            </span>
          </div>
          <span style={{ fontSize: '10px', color: 'var(--text-muted)' }}>UPI-First Financial Console</span>
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
        <button onClick={onOpenNewExpense} className="btn-primary" style={{ padding: '5px 10px', fontSize: '11.5px' }}>
          <Plus size={13} /> Log Expense
        </button>

        <button onClick={onOpenTipCalc} className="btn-secondary" title="Tip Calculator" style={{ padding: '5px 8px' }}>
          <Calculator size={14} />
        </button>

        <button onClick={onOpenOcr} className="btn-secondary" title="Scan Receipt OCR" style={{ padding: '5px 8px' }}>
          <Receipt size={14} />
        </button>

        <button onClick={toggleTheme} className="btn-secondary" style={{ padding: '5px 8px' }}>
          {theme === 'dark' ? <Sun size={14} color="var(--accent-gold)" /> : <Moon size={14} />}
        </button>
      </div>
    </header>
  );
}
