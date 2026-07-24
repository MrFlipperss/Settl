import React, { useState, useEffect } from 'react';
import { Sparkles, ArrowRight, CheckCircle, X, HelpCircle, CornerDownLeft } from 'lucide-react';
import { parseSpotlightQuery } from '../utils/nlpParser';

export default function SpotlightBar({ onExecuteAction, users = [], groups = [] }) {
  const [query, setQuery] = useState('');
  const [parsedResult, setParsedResult] = useState(null);
  const [isFocused, setIsFocused] = useState(false);

  useEffect(() => {
    if (query.trim()) {
      const result = parseSpotlightQuery(query, users, groups);
      setParsedResult(result);
    } else {
      setParsedResult(null);
    }
  }, [query, users, groups]);

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && parsedResult && parsedResult.type !== 'UNKNOWN') {
      commitAction();
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
      case 'green': return 'badge-green';
      case 'blue': return 'badge-blue';
      case 'purple': return 'badge-purple';
      default: return 'badge-gold';
    }
  };

  return (
    <div className="spotlight-wrapper" style={{ padding: '14px 18px 10px', borderBottom: '1px solid var(--border-subtle)' }}>
      {/* Input bar */}
      <div 
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          background: isFocused ? 'rgba(245, 158, 11, 0.08)' : 'rgba(255, 255, 255, 0.04)',
          border: `1px solid ${isFocused ? 'var(--accent-gold)' : 'var(--border-subtle)'}`,
          borderRadius: 'var(--radius-md)',
          padding: '10px 14px',
          transition: 'all 0.2s ease',
          boxShadow: isFocused ? '0 0 16px var(--accent-gold-glow)' : 'none'
        }}
      >
        <Sparkles size={18} color="var(--accent-gold)" className={query ? 'ai-pulse' : ''} />
        
        <input
          type="text"
          className="font-mono"
          placeholder='Spotlight: "₹100 dinner with Sarah" or "set food budget 6000"'
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
            fontSize: '13.5px',
          }}
        />

        {query && (
          <button
            onClick={() => { setQuery(''); setParsedResult(null); }}
            style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}
          >
            <X size={16} />
          </button>
        )}
      </div>

      {/* Dynamic Preview Chip (Rule: AI co-pilot preview before committing) */}
      {parsedResult && parsedResult.previewChip && (
        <div 
          className="fade-in"
          style={{
            marginTop: '10px',
            background: 'var(--bg-card)',
            border: '1px solid var(--border-subtle)',
            borderRadius: 'var(--radius-md)',
            padding: '12px 14px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: '12px'
          }}
        >
          <div style={{ flex: 1, overflow: 'hidden' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
              <span 
                className={`font-mono ${getBadgeClass(parsedResult.previewChip.badgeColor)}`}
                style={{ fontSize: '10px', fontWeight: 600, padding: '2px 6px', borderRadius: '4px' }}
              >
                {parsedResult.previewChip.badge}
              </span>
              <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Editable Co-pilot Draft</span>
            </div>
            <div style={{ fontSize: '13px', fontWeight: 500, color: 'var(--text-main)', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap' }}>
              {parsedResult.previewChip.details}
            </div>
          </div>

          <button
            onClick={commitAction}
            className="btn-primary"
            style={{ padding: '6px 12px', fontSize: '12px' }}
          >
            Confirm
            <CornerDownLeft size={14} />
          </button>
        </div>
      )}
    </div>
  );
}
