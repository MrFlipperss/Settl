import React from 'react';
import { Home, Users, PieChart, Ticket, Sun, Moon, Plus, Receipt, Calculator, Bookmark } from 'lucide-react';

export default function Navigation({ activeTab, setActiveTab, theme, toggleTheme, onOpenNewExpense, onOpenOcr, onOpenTipCalc }) {
  return (
    <>
      {/* Top Header */}
      <header
        style={{
          padding: '16px 20px 12px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          borderBottom: '1px solid var(--border-subtle)',
          background: 'var(--bg-surface)'
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div 
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '8px',
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
            <h1 className="font-heading" style={{ fontSize: '18px', fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.1 }}>
              Settl <span style={{ fontSize: '11px', color: 'var(--accent-gold)', fontWeight: 500 }} className="font-mono">ledger</span>
            </h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <p style={{ fontSize: '11px', color: 'var(--text-muted)' }}>UPI-First Smart Tracker</p>
              <span className="badge-green font-mono" style={{ fontSize: '9px', padding: '1px 5px', borderRadius: '3px' }}>
                RENDER LIVE
              </span>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <button
            onClick={onOpenTipCalc}
            className="btn-secondary"
            title="Tip Calculator"
            style={{ padding: '6px 10px', fontSize: '12px' }}
          >
            <Calculator size={15} />
            <span style={{ display: 'none', minWidth: '0' }}>Tip</span>
          </button>

          <button
            onClick={onOpenOcr}
            className="btn-secondary"
            title="Scan Receipt OCR"
            style={{ padding: '6px 10px', fontSize: '12px' }}
          >
            <Receipt size={15} />
          </button>

          <button
            onClick={toggleTheme}
            className="btn-secondary"
            style={{ padding: '6px 10px' }}
          >
            {theme === 'dark' ? <Sun size={15} color="var(--accent-gold)" /> : <Moon size={15} />}
          </button>
        </div>
      </header>

      {/* Floating Action Button for Quick Add Expense */}
      <button
        onClick={onOpenNewExpense}
        className="btn-primary"
        style={{
          position: 'absolute',
          bottom: '76px',
          right: '20px',
          zIndex: 40,
          borderRadius: '50px',
          padding: '12px 20px',
          boxShadow: '0 8px 25px var(--accent-gold-glow)'
        }}
      >
        <Plus size={20} />
        <span>Log Expense</span>
      </button>

      {/* Bottom Navigation Bar */}
      <nav
        style={{
          marginTop: 'auto',
          display: 'grid',
          gridTemplateColumns: 'repeat(4, 1fr)',
          background: 'var(--bg-surface)',
          borderTop: '1px solid var(--border-subtle)',
          padding: '8px 0',
          zIndex: 30
        }}
      >
        <button
          onClick={() => setActiveTab('dashboard')}
          style={{
            background: 'none',
            border: 'none',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '4px',
            color: activeTab === 'dashboard' ? 'var(--accent-gold)' : 'var(--text-muted)',
            cursor: 'pointer',
            padding: '6px 0'
          }}
        >
          <Home size={20} />
          <span style={{ fontSize: '10.5px', fontWeight: activeTab === 'dashboard' ? 600 : 400 }}>Ledger</span>
        </button>

        <button
          onClick={() => setActiveTab('groups')}
          style={{
            background: 'none',
            border: 'none',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '4px',
            color: activeTab === 'groups' ? 'var(--accent-gold)' : 'var(--text-muted)',
            cursor: 'pointer',
            padding: '6px 0'
          }}
        >
          <Users size={20} />
          <span style={{ fontSize: '10.5px', fontWeight: activeTab === 'groups' ? 600 : 400 }}>Groups</span>
        </button>

        <button
          onClick={() => setActiveTab('budget')}
          style={{
            background: 'none',
            border: 'none',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '4px',
            color: activeTab === 'budget' ? 'var(--accent-gold)' : 'var(--text-muted)',
            cursor: 'pointer',
            padding: '6px 0'
          }}
        >
          <PieChart size={20} />
          <span style={{ fontSize: '10.5px', fontWeight: activeTab === 'budget' ? 600 : 400 }}>Budget</span>
        </button>

        <button
          onClick={() => setActiveTab('wallet')}
          style={{
            background: 'none',
            border: 'none',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: '4px',
            color: activeTab === 'wallet' ? 'var(--accent-gold)' : 'var(--text-muted)',
            cursor: 'pointer',
            padding: '6px 0'
          }}
        >
          <Ticket size={20} />
          <span style={{ fontSize: '10.5px', fontWeight: activeTab === 'wallet' ? 600 : 400 }}>Wallet</span>
        </button>
      </nav>
    </>
  );
}
