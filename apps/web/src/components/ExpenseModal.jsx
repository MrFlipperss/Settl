import React, { useState, useEffect } from 'react';
import { X, Check, AlertCircle, Percent, Hash, Equal, DollarSign, User, Users as UsersIcon } from 'lucide-react';
import { rupeesToPaise, paiseToRupees, formatCurrency, calculateSplits } from '../utils/splitMath';

export default function ExpenseModal({ isOpen, onClose, onSaveExpense, user, friends = [], groups = [], initialPreset = null }) {
  const [amountRupees, setAmountRupees] = useState('');
  const [note, setNote] = useState('');
  const [category, setCategory] = useState('Food');
  
  // Split Target Scope: 'group' | 'friend' | 'personal'
  const [splitScope, setSplitScope] = useState('friend');
  const [selectedGroupId, setSelectedGroupId] = useState('');
  const [selectedFriendId, setSelectedFriendId] = useState(friends.length > 0 ? friends[0].id : '');

  const [payerId, setPayerId] = useState(user.id);
  const [splitMode, setSplitMode] = useState('equal'); // 'equal' | 'exact' | 'percentage' | 'shares'

  // List of participants in split
  const [participants, setParticipants] = useState([]);

  useEffect(() => {
    if (initialPreset) {
      setAmountRupees(paiseToRupees(initialPreset.amountPaise).toString());
      setNote(initialPreset.note || initialPreset.name);
      setCategory(initialPreset.category || 'Food');
    }
  }, [initialPreset]);

  // Determine active participant list based on scope (Group vs 1:1 Friend vs Personal)
  useEffect(() => {
    let list = [];

    if (splitScope === 'group' && selectedGroupId) {
      const g = groups.find(item => item.id === selectedGroupId);
      if (g) {
        list = [user, ...friends.filter(f => g.members.includes(f.id))];
      } else {
        list = [user];
      }
    } else if (splitScope === 'friend' && selectedFriendId) {
      const f = friends.find(item => item.id === selectedFriendId);
      list = f ? [user, f] : [user];
    } else {
      // Personal solo expense
      list = [user];
    }

    setParticipants(list.map(p => ({
      id: p.id,
      name: p.name,
      val: splitMode === 'equal' ? '' : (splitMode === 'percentage' ? (100 / list.length).toFixed(0) : (splitMode === 'shares' ? '1' : '0'))
    })));
  }, [splitScope, selectedGroupId, selectedFriendId, friends, user, groups, splitMode]);

  if (!isOpen) return null;

  const totalPaise = rupeesToPaise(parseFloat(amountRupees) || 0);

  // Calculate live splits using math utility
  const { splits, isValid, errorMsg } = calculateSplits(totalPaise, participants, splitMode);

  const handleParticipantValChange = (id, newVal) => {
    setParticipants(participants.map(p => p.id === id ? { ...p, val: newVal } : p));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!isValid || totalPaise <= 0 || !note.trim()) return;

    const newExpense = {
      id: `exp_${Date.now()}`,
      group_id: splitScope === 'group' ? selectedGroupId : null,
      payer_id: payerId,
      amount_paise: totalPaise,
      currency: 'INR',
      category,
      note: note.trim(),
      timestamp: new Date().toISOString(),
      idempotency_key: `idemp-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      splits
    };

    onSaveExpense(newExpense);
    onClose();
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
          maxWidth: '440px',
          maxHeight: '90vh',
          overflowY: 'auto',
          padding: '20px',
          background: 'var(--bg-surface)'
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <h3 className="font-heading" style={{ fontSize: '18px', fontWeight: 700 }}>
            Log New Expense
          </h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }}>
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          
          {/* Amount input in Rupees */}
          <div>
            <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Amount (₹)</label>
            <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
              <span className="font-heading" style={{ position: 'absolute', left: '12px', fontSize: '20px', color: 'var(--accent-gold)', fontWeight: 700 }}>₹</span>
              <input
                type="number"
                step="0.01"
                placeholder="0.00"
                value={amountRupees}
                onChange={(e) => setAmountRupees(e.target.value)}
                required
                className="font-mono"
                style={{
                  width: '100%',
                  padding: '10px 12px 10px 32px',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border-subtle)',
                  background: 'rgba(255,255,255,0.05)',
                  color: 'var(--text-main)',
                  fontSize: '20px',
                  fontWeight: 700,
                  outline: 'none'
                }}
              />
            </div>
          </div>

          {/* Description & Category */}
          <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: '10px' }}>
            <div>
              <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Note / Description</label>
              <input
                type="text"
                placeholder="e.g. Dinner, Taxi fare"
                value={note}
                onChange={(e) => setNote(e.target.value)}
                required
                style={{
                  width: '100%',
                  padding: '9px 12px',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border-subtle)',
                  background: 'rgba(255,255,255,0.05)',
                  color: 'var(--text-main)',
                  outline: 'none',
                  fontSize: '13px'
                }}
              />
            </div>

            <div>
              <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Category</label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                style={{
                  width: '100%',
                  padding: '9px 10px',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border-subtle)',
                  background: 'var(--bg-surface)',
                  color: 'var(--text-main)',
                  outline: 'none',
                  fontSize: '13px'
                }}
              >
                <option value="Food">Food</option>
                <option value="Rent">Rent</option>
                <option value="Transport">Transport</option>
                <option value="Entertainment">Entertainment</option>
                <option value="Shopping">Shopping</option>
              </select>
            </div>
          </div>

          {/* Split Scope Picker: Group vs 1:1 Friend vs Personal */}
          <div>
            <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Split With</label>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '4px', background: 'rgba(255,255,255,0.04)', padding: '3px', borderRadius: '8px' }}>
              {[
                { scope: 'friend', label: '1:1 Friend', icon: User },
                { scope: 'group', label: 'Group', icon: UsersIcon },
                { scope: 'personal', label: 'Personal (Solo)', icon: User }
              ].map(item => {
                const isSelected = splitScope === item.scope;
                return (
                  <button
                    key={item.scope}
                    type="button"
                    onClick={() => {
                      setSplitScope(item.scope);
                      if (item.scope === 'group' && !selectedGroupId && groups.length > 0) setSelectedGroupId(groups[0].id);
                      if (item.scope === 'friend' && !selectedFriendId && friends.length > 0) setSelectedFriendId(friends[0].id);
                    }}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '4px',
                      padding: '6px 4px',
                      borderRadius: '6px',
                      border: 'none',
                      fontSize: '11px',
                      fontWeight: isSelected ? 600 : 400,
                      background: isSelected ? 'var(--accent-gold)' : 'transparent',
                      color: isSelected ? '#0F172A' : 'var(--text-muted)',
                      cursor: 'pointer'
                    }}
                  >
                    {item.label}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Contextual Target Dropdown (Selected Friend or Selected Group) */}
          {splitScope === 'friend' && (
            <div>
              <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Select Friend</label>
              <select
                value={selectedFriendId}
                onChange={(e) => setSelectedFriendId(e.target.value)}
                style={{
                  width: '100%',
                  padding: '9px 10px',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border-subtle)',
                  background: 'var(--bg-surface)',
                  color: 'var(--text-main)',
                  outline: 'none',
                  fontSize: '13px'
                }}
              >
                {friends.map(f => (
                  <option key={f.id} value={f.id}>{f.name}</option>
                ))}
              </select>
            </div>
          )}

          {splitScope === 'group' && (
            <div>
              <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Select Group Passbook</label>
              <select
                value={selectedGroupId}
                onChange={(e) => setSelectedGroupId(e.target.value)}
                style={{
                  width: '100%',
                  padding: '9px 10px',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border-subtle)',
                  background: 'var(--bg-surface)',
                  color: 'var(--text-main)',
                  outline: 'none',
                  fontSize: '13px'
                }}
              >
                {groups.map(g => (
                  <option key={g.id} value={g.id}>{g.account_number} - {g.name}</option>
                ))}
              </select>
            </div>
          )}

          {/* Paid By Selection */}
          <div>
            <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Paid By</label>
            <select
              value={payerId}
              onChange={(e) => setPayerId(e.target.value)}
              style={{
                width: '100%',
                padding: '9px 10px',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--border-subtle)',
                background: 'var(--bg-surface)',
                color: 'var(--text-main)',
                outline: 'none',
                fontSize: '13px'
              }}
            >
              <option value={user.id}>You ({user.name})</option>
              {participants.filter(p => p.id !== user.id).map(f => (
                <option key={f.id} value={f.id}>{f.name}</option>
              ))}
            </select>
          </div>

          {/* Split Mode Selector (Equal, Exact, Percentage, Shares) */}
          {splitScope !== 'personal' && (
            <div>
              <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '6px' }}>
                Split Method
              </label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '4px', background: 'rgba(255,255,255,0.04)', padding: '3px', borderRadius: '8px' }}>
                {[
                  { mode: 'equal', label: 'Equal', icon: Equal },
                  { mode: 'exact', label: 'Exact ₹', icon: DollarSign },
                  { mode: 'percentage', label: '% Share', icon: Percent },
                  { mode: 'shares', label: 'Shares', icon: Hash }
                ].map(item => {
                  const Icon = item.icon;
                  const isSelected = splitMode === item.mode;
                  return (
                    <button
                      key={item.mode}
                      type="button"
                      onClick={() => setSplitMode(item.mode)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '4px',
                        padding: '6px 4px',
                        borderRadius: '6px',
                        border: 'none',
                        fontSize: '11px',
                        fontWeight: isSelected ? 600 : 400,
                        background: isSelected ? 'var(--accent-gold)' : 'transparent',
                        color: isSelected ? '#0F172A' : 'var(--text-muted)',
                        cursor: 'pointer'
                      }}
                    >
                      <Icon size={12} />
                      {item.label}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Individual Split Breakdown */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginTop: '4px' }}>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'flex', justifyContent: 'space-between' }}>
              <span>Split Participants ({participants.length})</span>
              {splitMode !== 'equal' && splitScope !== 'personal' && (
                <span>Enter {splitMode === 'exact' ? 'Rupees' : (splitMode === 'percentage' ? '%' : 'Shares')}</span>
              )}
            </div>

            {participants.map((p) => {
              const splitMatch = splits.find(s => s.id === p.id);
              const allocatedAmount = splitMatch ? splitMatch.amountPaise : 0;

              return (
                <div
                  key={p.id}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '8px 10px',
                    borderRadius: '8px',
                    background: 'rgba(255,255,255,0.03)',
                    border: '1px solid var(--border-subtle)'
                  }}
                >
                  <span style={{ fontSize: '13px', fontWeight: 500 }}>{p.name}</span>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    {splitMode !== 'equal' && splitScope !== 'personal' && (
                      <input
                        type="number"
                        placeholder="0"
                        value={p.val}
                        onChange={(e) => handleParticipantValChange(p.id, e.target.value)}
                        className="font-mono"
                        style={{
                          width: '60px',
                          padding: '4px 6px',
                          fontSize: '12px',
                          borderRadius: '4px',
                          border: '1px solid var(--border-subtle)',
                          background: 'rgba(0,0,0,0.2)',
                          color: 'var(--text-main)',
                          textAlign: 'center'
                        }}
                      />
                    )}

                    <span className="font-mono" style={{ fontSize: '13px', fontWeight: 600, color: 'var(--accent-gold)', minWidth: '70px', textAlign: 'right' }}>
                      {formatCurrency(allocatedAmount, true)}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Validation Errors */}
          {!isValid && errorMsg && (
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', color: 'var(--accent-red)', background: 'rgba(239, 68, 68, 0.1)', padding: '8px 10px', borderRadius: '6px' }}>
              <AlertCircle size={14} />
              <span>{errorMsg}</span>
            </div>
          )}

          <div style={{ display: 'flex', gap: '10px', marginTop: '10px' }}>
            <button
              type="button"
              onClick={onClose}
              className="btn-secondary"
              style={{ flex: 1, justifyContent: 'center' }}
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={!isValid || totalPaise <= 0}
              className="btn-primary"
              style={{ flex: 1, justifyContent: 'center', opacity: (!isValid || totalPaise <= 0) ? 0.5 : 1 }}
            >
              Save Expense
            </button>
          </div>

        </form>
      </div>
    </div>
  );
}
