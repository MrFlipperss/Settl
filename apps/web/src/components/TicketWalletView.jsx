import React, { useEffect, useRef, useState } from 'react';
import QRCode from 'qrcode';
import { Ticket, Train, Film, Plane, Calendar, MapPin, QrCode, Plus, Check } from 'lucide-react';
import { formatCurrency } from '../utils/splitMath';

function TicketQrItem({ value }) {
  const canvasRef = useRef(null);

  useEffect(() => {
    if (canvasRef.current && value) {
      QRCode.toCanvas(canvasRef.current, value, {
        width: 110,
        margin: 1,
        color: { dark: '#0F172A', light: '#FFFFFF' }
      }, (err) => { if (err) console.error(err); });
    }
  }, [value]);

  return <canvas ref={canvasRef} style={{ borderRadius: '6px' }} />;
}

export default function TicketWalletView({ tickets = [], onConvertTicketToExpense }) {
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [convertedIds, setConvertedIds] = useState([]);

  const getIcon = (type) => {
    switch (type) {
      case 'Train': return Train;
      case 'Movie': return Film;
      case 'Flight': return Plane;
      default: return Ticket;
    }
  };

  const handleConvert = (tkt) => {
    const exp = {
      amount_paise: tkt.amountPaise,
      category: tkt.type === 'Movie' ? 'Entertainment' : 'Transport',
      note: `${tkt.title} (${tkt.pnr})`,
      timestamp: new Date().toISOString()
    };
    onConvertTicketToExpense(exp);
    setConvertedIds([...convertedIds, tkt.id]);
  };

  return (
    <div className="fade-in" style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
      
      {/* Header Banner */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2 className="font-heading" style={{ fontSize: '18px', fontWeight: 700 }}>Ticket & Boarding Pass Wallet</h2>
          <p style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Train, Flight, and Movie QRs in one place</p>
        </div>

        <span className="badge-gold font-mono" style={{ fontSize: '11px', padding: '4px 8px', borderRadius: '6px' }}>
          {tickets.length} Passes
        </span>
      </div>

      {/* Tickets List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        {tickets.map(tkt => {
          const Icon = getIcon(tkt.type);
          const isConverted = convertedIds.includes(tkt.id);

          return (
            <div
              key={tkt.id}
              className="glass-card"
              style={{
                padding: '16px',
                background: 'linear-gradient(135deg, rgba(30, 41, 59, 0.85), rgba(15, 23, 42, 0.95))',
                border: '1px solid var(--border-subtle)',
                position: 'relative'
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
                  <div 
                    style={{
                      width: '36px',
                      height: '36px',
                      borderRadius: '10px',
                      background: 'var(--accent-gold-glow)',
                      color: 'var(--accent-gold)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center'
                    }}
                  >
                    <Icon size={20} />
                  </div>

                  <div>
                    <span className="badge-gold font-mono" style={{ fontSize: '9.5px', padding: '1px 6px', borderRadius: '4px' }}>
                      {tkt.type.toUpperCase()} • {tkt.status}
                    </span>
                    <h3 className="font-heading" style={{ fontSize: '15px', fontWeight: 700, marginTop: '4px' }}>
                      {tkt.title}
                    </h3>
                    <div style={{ fontSize: '11.5px', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '4px', marginTop: '2px' }}>
                      <MapPin size={12} /> {tkt.route}
                    </div>
                  </div>
                </div>

                {/* QR Code thumbnail */}
                <div style={{ background: '#FFFFFF', padding: '6px', borderRadius: '8px' }}>
                  <TicketQrItem value={tkt.qrCodeValue} />
                </div>
              </div>

              {/* Ticket Details & Action */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginTop: '14px', paddingTop: '10px', borderTop: '1px dashed var(--border-subtle)' }}>
                <div>
                  <div style={{ fontSize: '10.5px', color: 'var(--text-muted)' }}>PNR / Booking Ref</div>
                  <div className="font-mono" style={{ fontSize: '12.5px', fontWeight: 600, color: 'var(--accent-gold)' }}>
                    {tkt.pnr}
                  </div>
                </div>

                <div>
                  <div style={{ fontSize: '10.5px', color: 'var(--text-muted)' }}>Seat / Class</div>
                  <div style={{ fontSize: '12px', fontWeight: 500 }}>
                    {tkt.seat}
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '12px' }}>
                <div className="font-mono" style={{ fontSize: '14px', fontWeight: 700 }}>
                  {formatCurrency(tkt.amountPaise, true)}
                </div>

                <button
                  onClick={() => handleConvert(tkt)}
                  disabled={isConverted}
                  className="btn-secondary"
                  style={{ fontSize: '11px', padding: '4px 8px', opacity: isConverted ? 0.6 : 1 }}
                >
                  {isConverted ? <Check size={12} color="var(--accent-green)" /> : <Plus size={12} />}
                  {isConverted ? 'Added to Ledger' : 'Log as Expense'}
                </button>
              </div>
            </div>
          );
        })}
      </div>

    </div>
  );
}
