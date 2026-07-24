import React, { useState } from 'react';
import { X, Camera, Upload, Sparkles, Check, RefreshCw } from 'lucide-react';
import { rupeesToPaise, formatCurrency } from '../utils/splitMath';

const SAMPLE_RECEIPTS = [
  { name: 'Starbucks Coffee Receipt', merchant: 'Starbucks Coffee', amountRupees: 680, category: 'Food', date: '2026-07-24' },
  { name: 'DMart Grocery Bill', merchant: 'DMart Supermarket', amountRupees: 2450, category: 'Shopping', date: '2026-07-23' },
  { name: 'HP Fuel Station Receipt', merchant: 'HP Auto Fuel', amountRupees: 1500, category: 'Transport', date: '2026-07-22' }
];

export default function ReceiptOcrModal({ isOpen, onClose, onSaveExpense }) {
  const [isScanning, setIsScanning] = useState(false);
  const [extractedData, setExtractedData] = useState(null);

  if (!isOpen) return null;

  const handleSimulateOcr = (sample) => {
    setIsScanning(true);
    setExtractedData(null);

    // Simulate multi-stage OCR extraction delay
    setTimeout(() => {
      setIsScanning(false);
      setExtractedData({
        merchant: sample.merchant,
        amountRupees: sample.amountRupees.toString(),
        category: sample.category,
        note: `Receipt from ${sample.merchant}`
      });
    }, 1200);
  };

  const handleConfirmOcr = () => {
    if (!extractedData) return;

    const amount_paise = rupeesToPaise(parseFloat(extractedData.amountRupees) || 0);
    onSaveExpense({
      amount_paise,
      category: extractedData.category,
      note: extractedData.note,
      timestamp: new Date().toISOString()
    });

    onClose();
  };

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '16px' }}>
      <div className="glass-card fade-in" style={{ width: '100%', maxWidth: '400px', padding: '20px', background: 'var(--bg-surface)' }}>
        
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Camera size={18} color="var(--accent-gold)" />
            <h3 className="font-heading" style={{ fontSize: '17px', fontWeight: 700 }}>Receipt Photo OCR</h3>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}><X size={20} /></button>
        </div>

        {/* OCR Sample Selector */}
        {!extractedData && !isScanning && (
          <div>
            <p style={{ fontSize: '12px', color: 'var(--text-muted)', marginBottom: '10px' }}>
              Select a receipt sample or upload to test the AI OCR scanner:
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {SAMPLE_RECEIPTS.map((sample, idx) => (
                <button
                  key={idx}
                  onClick={() => handleSimulateOcr(sample)}
                  className="glass-card"
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '10px 12px',
                    border: '1px solid var(--border-subtle)',
                    textAlign: 'left',
                    cursor: 'pointer'
                  }}
                >
                  <div>
                    <div style={{ fontSize: '13px', fontWeight: 600 }}>{sample.name}</div>
                    <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>{sample.merchant} • ₹{sample.amountRupees}</div>
                  </div>
                  <Upload size={16} color="var(--accent-gold)" />
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Scanning State */}
        {isScanning && (
          <div style={{ textAlign: 'center', padding: '30px 10px' }}>
            <RefreshCw size={28} className="ai-pulse" color="var(--accent-gold)" style={{ margin: '0 auto 12px' }} />
            <div style={{ fontSize: '14px', fontWeight: 600 }}>AI OCR Processing...</div>
            <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '4px' }}>Extracting merchant, totals, and category fields</div>
          </div>
        )}

        {/* Editable Form Draft */}
        {extractedData && !isScanning && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <div style={{ background: 'rgba(16, 185, 129, 0.1)', border: '1px solid rgba(16, 185, 129, 0.3)', padding: '8px 12px', borderRadius: '8px', fontSize: '12px', color: 'var(--accent-green)', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Sparkles size={14} /> OCR Draft Ready. Verify or edit fields below:
            </div>

            <div>
              <label style={{ fontSize: '11px', color: 'var(--text-muted)', display: 'block', marginBottom: '2px' }}>Merchant Name</label>
              <input
                type="text"
                value={extractedData.merchant}
                onChange={(e) => setExtractedData({ ...extractedData, merchant: e.target.value })}
                style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: '1px solid var(--border-subtle)', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)', fontSize: '13px' }}
              />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
              <div>
                <label style={{ fontSize: '11px', color: 'var(--text-muted)', display: 'block', marginBottom: '2px' }}>Total Amount (₹)</label>
                <input
                  type="number"
                  value={extractedData.amountRupees}
                  onChange={(e) => setExtractedData({ ...extractedData, amountRupees: e.target.value })}
                  style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: '1px solid var(--border-subtle)', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)', fontSize: '13px' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '11px', color: 'var(--text-muted)', display: 'block', marginBottom: '2px' }}>Category</label>
                <input
                  type="text"
                  value={extractedData.category}
                  onChange={(e) => setExtractedData({ ...extractedData, category: e.target.value })}
                  style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: '1px solid var(--border-subtle)', background: 'rgba(255,255,255,0.05)', color: 'var(--text-main)', fontSize: '13px' }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', gap: '10px', marginTop: '10px' }}>
              <button onClick={() => setExtractedData(null)} className="btn-secondary" style={{ flex: 1, justifyContent: 'center' }}>Rescan</button>
              <button onClick={handleConfirmOcr} className="btn-primary" style={{ flex: 1, justifyContent: 'center' }}>Save Expense</button>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
