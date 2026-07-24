import React, { useEffect, useRef, useState } from 'react';
import QRCode from 'qrcode';
import { X, Copy, Share2, Check, QrCode as QrIcon } from 'lucide-react';
import { formatCurrency, paiseToRupees } from '../utils/splitMath';

export default function UpiQrModal({ isOpen, onClose, targetPerson, amountPaise = 0, type = 'PAY' }) {
  const canvasRef = useRef(null);
  const [copied, setCopied] = useState(false);

  // Construct UPI deep-link protocol URL
  const vpa = targetPerson ? targetPerson.upi_vpa : 'advaith@okaxis';
  const personName = targetPerson ? targetPerson.name : 'Advaith';
  const amountRupees = amountPaise > 0 ? paiseToRupees(amountPaise).toFixed(2) : '';
  const note = amountPaise > 0 ? `Settl payment to ${personName}` : 'Settl UPI Request';

  const upiUrl = `upi://pay?pa=${encodeURIComponent(vpa)}&pn=${encodeURIComponent(personName)}${amountRupees ? `&am=${amountRupees}` : ''}&tn=${encodeURIComponent(note)}&cu=INR`;

  useEffect(() => {
    if (isOpen && canvasRef.current) {
      QRCode.toCanvas(canvasRef.current, upiUrl, {
        width: 200,
        margin: 2,
        color: {
          dark: '#0F172A',
          light: '#FFFDF8'
        }
      }, (error) => {
        if (error) console.error('QR code generation error:', error);
      });
    }
  }, [isOpen, upiUrl]);

  if (!isOpen) return null;

  const handleCopyLink = () => {
    navigator.clipboard.writeText(upiUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.7)',
        backdropFilter: 'blur(8px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 100,
        padding: '16px'
      }}
    >
      <div 
        className="glass-card fade-in" 
        style={{
          width: '100%',
          maxWidth: '360px',
          padding: '20px',
          background: 'var(--bg-surface)',
          textAlign: 'center'
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
          <span className="font-mono badge-gold" style={{ fontSize: '11px', padding: '2px 8px', borderRadius: '4px' }}>
            {type === 'PAY' ? 'PAY VIA UPI' : 'REQUEST UPI'}
          </span>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>
            <X size={20} />
          </button>
        </div>

        {/* Amount display */}
        {amountPaise > 0 ? (
          <div>
            <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Settle Up Amount</div>
            <div className="font-heading" style={{ fontSize: '28px', fontWeight: 700, color: 'var(--accent-gold)', margin: '2px 0 12px' }}>
              {formatCurrency(amountPaise, true)}
            </div>
          </div>
        ) : (
          <div style={{ fontSize: '14px', fontWeight: 600, margin: '6px 0 12px' }}>
            Static Profile Payment QR
          </div>
        )}

        {/* QR Canvas */}
        <div style={{ background: '#FFFDF8', padding: '16px', borderRadius: 'var(--radius-md)', display: 'inline-block', boxShadow: '0 4px 16px rgba(0,0,0,0.2)' }}>
          <canvas ref={canvasRef} />
          <div className="font-mono" style={{ fontSize: '11px', color: '#1E2432', marginTop: '6px', fontWeight: 600 }}>
            {vpa}
          </div>
        </div>

        {/* Deep link copy button */}
        <div style={{ display: 'flex', gap: '8px', marginTop: '16px' }}>
          <button
            onClick={handleCopyLink}
            className="btn-secondary"
            style={{ flex: 1, justifyContent: 'center', fontSize: '12px' }}
          >
            {copied ? <Check size={14} color="var(--accent-green)" /> : <Copy size={14} />}
            {copied ? 'Copied Link' : 'Copy UPI Link'}
          </button>
        </div>

        <p style={{ fontSize: '10.5px', color: 'var(--text-muted)', marginTop: '10px' }}>
          Scan with GPay, PhonePe, Paytm, or BHIM to settle up instantly.
        </p>
      </div>
    </div>
  );
}
