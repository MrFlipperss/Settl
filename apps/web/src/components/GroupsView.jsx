import React, { useState } from 'react';
import { Users, Plus, ShieldCheck, CreditCard, ChevronRight, CheckCircle2 } from 'lucide-react';
import { formatCurrency } from '../utils/splitMath';

export default function GroupsView({ groups = [], friends = [], user, onCreateGroup }) {
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newGroupName, setNewGroupName] = useState('');
  const [selectedMemberIds, setSelectedMemberIds] = useState([]);

  const handleCreateGroupSubmit = (e) => {
    e.preventDefault();
    if (!newGroupName.trim()) return;

    // Generate next sequential GRP account number
    const nextNum = groups.length + 42;
    const account_number = `GRP-${String(nextNum).padStart(4, '0')}`;

    const newGroup = {
      id: `grp_${Date.now()}`,
      account_number,
      name: newGroupName.trim(),
      currency: 'INR',
      created_at: new Date().toISOString(),
      members: ['00000000-0000-0000-0000-000000000001', ...selectedMemberIds],
      totalSpendPaise: 0,
      coverImage: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600&auto=format&fit=crop&q=80'
    };

    onCreateGroup(newGroup);
    setNewGroupName('');
    setSelectedMemberIds([]);
    setShowCreateModal(false);
  };

  const toggleMemberSelection = (friendId) => {
    if (selectedMemberIds.includes(friendId)) {
      setSelectedMemberIds(selectedMemberIds.filter(id => id !== friendId));
    } else {
      setSelectedMemberIds([...selectedMemberIds, friendId]);
    }
  };

  return (
    <div className="fade-in" style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2 className="font-heading" style={{ fontSize: '18px', fontWeight: 700 }}>Numbered Group Passbooks</h2>
          <p style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Track shared expenses with sequential account IDs</p>
        </div>

        <button
          onClick={() => setShowCreateModal(true)}
          className="btn-primary"
          style={{ padding: '8px 12px', fontSize: '12px' }}
        >
          <Plus size={15} />
          New Group
        </button>
      </div>

      {/* Groups List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {groups.map(group => {
          const groupMembers = friends.filter(f => group.members.includes(f.id));
          
          return (
            <div key={group.id} className="glass-card" style={{ padding: '16px', position: 'relative', overflow: 'hidden' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '10px' }}>
                <div>
                  <span className="font-mono badge-gold" style={{ fontSize: '11px', padding: '2px 8px', borderRadius: '4px', fontWeight: 600 }}>
                    {group.account_number}
                  </span>
                  <h3 className="font-heading" style={{ fontSize: '16px', fontWeight: 700, marginTop: '6px' }}>
                    {group.name}
                  </h3>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <span style={{ fontSize: '10.5px', color: 'var(--text-muted)' }}>Total Group Volume</span>
                  <div className="font-mono" style={{ fontSize: '15px', fontWeight: 700, color: 'var(--accent-gold)' }}>
                    {formatCurrency(group.totalSpendPaise, true)}
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingTop: '10px', borderTop: '1px solid var(--border-subtle)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <div style={{ display: 'flex', marginLeft: '6px' }}>
                    <img
                      src={user.avatar}
                      alt="You"
                      style={{ width: '24px', height: '24px', borderRadius: '50%', border: '2px solid var(--bg-surface)' }}
                    />
                    {groupMembers.slice(0, 3).map(m => (
                      <img
                        key={m.id}
                        src={m.avatar}
                        alt={m.name}
                        style={{ width: '24px', height: '24px', borderRadius: '50%', border: '2px solid var(--bg-surface)', marginLeft: '-8px' }}
                      />
                    ))}
                  </div>
                  <span style={{ fontSize: '11px', color: 'var(--text-muted)', marginLeft: '4px' }}>
                    {group.members.length} members
                  </span>
                </div>

                <span style={{ fontSize: '11px', color: 'var(--accent-green)', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '2px' }}>
                  Active Ledger <ChevronRight size={14} />
                </span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Modal: Create Group */}
      {showCreateModal && (
        <div 
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0,0,0,0.65)',
            backdropFilter: 'blur(8px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 100,
            padding: '16px'
          }}
        >
          <div className="glass-card fade-in" style={{ width: '100%', maxWidth: '400px', padding: '20px', background: 'var(--bg-surface)' }}>
            <h3 className="font-heading" style={{ fontSize: '18px', fontWeight: 700, marginBottom: '14px' }}>
              Create New Group Passbook
            </h3>

            <form onSubmit={handleCreateGroupSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div>
                <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Group Name</label>
                <input
                  type="text"
                  placeholder="e.g. Goa Trip 2026 or Flatmates 402"
                  value={newGroupName}
                  onChange={(e) => setNewGroupName(e.target.value)}
                  required
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--border-subtle)',
                    background: 'rgba(255,255,255,0.05)',
                    color: 'var(--text-main)',
                    outline: 'none'
                  }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', color: 'var(--text-muted)', display: 'block', marginBottom: '6px' }}>Select Members to Include</label>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', maxHeight: '180px', overflowY: 'auto' }}>
                  {friends.map(f => {
                    const isSelected = selectedMemberIds.includes(f.id);
                    return (
                      <div
                        key={f.id}
                        onClick={() => toggleMemberSelection(f.id)}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          padding: '8px 10px',
                          borderRadius: '8px',
                          background: isSelected ? 'rgba(245, 158, 11, 0.15)' : 'rgba(255,255,255,0.03)',
                          border: `1px solid ${isSelected ? 'var(--accent-gold)' : 'var(--border-subtle)'}`,
                          cursor: 'pointer'
                        }}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <img src={f.avatar} alt={f.name} style={{ width: '28px', height: '28px', borderRadius: '50%' }} />
                          <span style={{ fontSize: '13px', fontWeight: 500 }}>{f.name}</span>
                        </div>
                        {isSelected && <CheckCircle2 size={16} color="var(--accent-gold)" />}
                      </div>
                    );
                  })}
                </div>
              </div>

              <div style={{ display: 'flex', gap: '10px', marginTop: '10px' }}>
                <button
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="btn-secondary"
                  style={{ flex: 1, justifyContent: 'center' }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-primary"
                  style={{ flex: 1, justifyContent: 'center' }}
                >
                  Create Group
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}
