import React, { useState, useEffect, useRef } from 'react';
import { Sparkles, X, Command, CornerDownLeft, Search, User, Users, Receipt } from 'lucide-react';
import { parseSpotlightQuery } from '../utils/nlpParser';
import { formatCurrency } from '../utils/splitMath';

export default function SpotlightBar({ onExecuteAction, users = [], groups = [], expenses = [] }) {
  const [query, setQuery] = useState('');
  const [parsedResult, setParsedResult] = useState(null);
  const [isFocused, setIsFocused] = useState(false);
  const inputRef = useRef(null);

  useEffect(() => {
    const handleGlobalKeyDown = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        if (inputRef.current) inputRef.current.focus();
      }
    };
    window.addEventListener('keydown', handleGlobalKeyDown);
    return () => window.removeEventListener('keydown', handleGlobalKeyDown);
  }, []);

  useEffect(() => {
    if (query.trim()) {
      const result = parseSpotlightQuery(query, users, groups, expenses);
      setParsedResult(result);
    } else {
      setParsedResult(null);
    }
  }, [query, users, groups, expenses]);

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && parsedResult && parsedResult.type !== 'UNKNOWN' && parsedResult.type !== 'SEARCH') {
      commitAction();
    }
    if (e.key === 'Escape') {
      setQuery('');
      setParsedResult(null);
      if (inputRef.current) inputRef.current.blur();
    }
  };

  const commitAction = () => {
    if (!parsedResult) return;
    onExecuteAction(parsedResult);
    setQuery('');
    setParsedResult(null);
  };

  const getBadgeClass = (color) => {
    switch (color) {
      case 'gold': return 'badge-gold';
      case 'cyan': return 'badge-cyan';
      case 'green': return 'badge-green';
      case 'blue': return 'badge-blue';
      case 'purple': return 'badge-purple';
      default: return 'badge-gold';
    }
  };

  return (
    <div style={{ position: 'relative', width: '100%', zIndex: 50 }}>
      <div 
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          background: isFocused ? 'rgba(245, 158, 11, 0.08)' : 'rgba(255, 255, 255, 0.04)',
          border: `1px solid ${isFocused ? 'var(--accent-gold)' : 'var(--border-subtle)'}`,
          borderRadius: 'var(--radius-md)',
          padding: '8px 14px',
          transition: 'all 0.2s ease',
          boxShadow: isFocused ? '0 0 20px var(--accent-gold-glow)' : 'none'
        }}
      >
        <Sparkles size={16} color="var(--accent-gold)" />
        
        <input
          ref={inputRef}
          type="text"
          className="font-mono"
          placeholder='Spotlight Command: "100 dinner with Sarah" or "set food budget 8000"'
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
          onKeyDown={handleKeyDown}
          style={{
            flex: 1,
            background: 'none',
            border: 'none',
            outline: 'none',
            color: 'var(--text-main)',
            fontSize: '13px',
          }}
        />

        {query ? (
          <button
            onClick={() => { setQuery(''); setParsedResult(null); }}
            style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}
          >
            <X size={15} />
          </button>
        ) : (
          <span className="kbd-pill">
            <Command size={9} /> K
          </span>
        )}
      </div>

      {/* Floating Raycast Preview Chip Overlay */}
      {parsedResult && parsedResult.previewChip && (
        <div 
          className="fade-in"
          style={{
            position: 'absolute',
            top: 'calc(100% + 6px)',
            left: 0,
            right: 0,
            background: 'var(--bg-surface)',
            border: '1px solid var(--border-subtle)',
            borderRadius: 'var(--radius-md)',
            padding: '12px 14px',
            boxShadow: 'var(--shadow-glow)',
            backdropFilter: 'blur(20px)',
            zIndex: 100
          }}
        >
          {parsedResult.type !== 'SEARCH' ? (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px' }}>
              <div style={{ flex: 1, overflow: 'hidden' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '3px' }}>
                  <span 
                    className={`font-mono ${getBadgeClass(parsedResult.previewChip.badgeColor)}`}
                    style={{ fontSize: '9px', fontWeight: 600, padding: '2px 6px', borderRadius: '4px' }}
                  >
                    {parsedResult.previewChip.badge}
                  </span>
                  <span style={{ fontSize: '10.5px', color: 'var(--text-muted)' }}>Press ↵ to confirm</span>
                </div>
                <div style={{ fontSize: '13px', fontWeight: 600, color: 'var(--text-main)' }}>
                  {parsedResult.previewChip.title}
                </div>
                <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>
                  {parsedResult.previewChip.details}
                </div>
              </div>

              <button
                onClick={commitAction}
                className="btn-primary"
                style={{ padding: '6px 12px', fontSize: '12px' }}
              >
                Confirm
                <CornerDownLeft size={13} />
              </button>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', maxHeight: '180px', overflowY: 'auto' }}>
              <div style={{ fontSize: '10.5px', color: 'var(--text-muted)' }}>{parsedResult.previewChip.details}</div>
              
              {parsedResult.searchResults.friends.map(f => (
                <div key={f.id} style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px' }}>
                  <User size={13} color="var(--text-muted)" />
                  <span>{f.name}</span>
                  <span className="font-mono" style={{ marginLeft: 'auto', fontSize: '11px', color: f.balancePaise > 0 ? 'var(--accent-green)' : 'var(--text-muted)' }}>
                    {f.balancePaise > 0 ? `owes ${formatCurrency(f.balancePaise, true)}` : 'settled'}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
