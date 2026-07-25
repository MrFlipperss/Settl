import React, { useState, useEffect } from 'react';
import Navigation from './components/Navigation';
import SpotlightBar from './components/SpotlightBar';
import Dashboard from './components/Dashboard';
import ExpenseModal from './components/ExpenseModal';
import UpiQrModal from './components/UpiQrModal';
import ReceiptOcrModal from './components/ReceiptOcrModal';
import TipCalculatorModal from './components/TipCalculatorModal';
import { SettlApi } from './services/api';
import { computeFriendBalances, calculateSplits } from './utils/splitMath';

import {
  CURRENT_USER,
  FRIENDS,
  INITIAL_GROUPS,
  INITIAL_EXPENSES,
  INITIAL_BUDGETS,
  INITIAL_SUBSCRIPTIONS,
  INITIAL_TICKETS,
  QUICK_PRESETS
} from './data/mockData';

export default function App() {
  const [theme, setTheme] = useState('dark');

  // Application Data State
  const [user] = useState(CURRENT_USER);
  const [friends, setFriends] = useState(FRIENDS);
  const [groups, setGroups] = useState(INITIAL_GROUPS);
  const [expenses, setExpenses] = useState(INITIAL_EXPENSES);
  const [budgets, setBudgets] = useState(INITIAL_BUDGETS);
  const [subscriptions, setSubscriptions] = useState(INITIAL_SUBSCRIPTIONS);
  const [tickets, setTickets] = useState(INITIAL_TICKETS);
  const [presets] = useState(QUICK_PRESETS);

  // Backend Sync Status State
  const [apiConnected, setApiConnected] = useState(false);

  // Modal Controls State
  const [showExpenseModal, setShowExpenseModal] = useState(false);
  const [presetForExpense, setPresetForExpense] = useState(null);
  const [settleQrState, setSettleQrState] = useState({ isOpen: false, targetPerson: null, amountPaise: 0, type: 'PAY' });
  const [showOcrModal, setShowOcrModal] = useState(false);
  const [showTipCalcModal, setShowTipCalcModal] = useState(false);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);

  // Dynamically compute net balances on expense change
  useEffect(() => {
    const updatedFriends = computeFriendBalances(friends, expenses, user.id);
    setFriends(updatedFriends);
  }, [expenses, user.id]);

  // Sync with live Render backend
  useEffect(() => {
    async function initBackendSync() {
      try {
        const health = await SettlApi.checkHealth();
        if (health && health.status === 'ok') {
          setApiConnected(true);

          const [remoteGroups, remoteExpenses] = await Promise.allSettled([
            SettlApi.listGroups(),
            SettlApi.listExpenses()
          ]);

          if (remoteGroups.status === 'fulfilled' && Array.isArray(remoteGroups.value) && remoteGroups.value.length > 0) {
            setGroups(remoteGroups.value);
          }
          if (remoteExpenses.status === 'fulfilled' && Array.isArray(remoteExpenses.value) && remoteExpenses.value.length > 0) {
            setExpenses(remoteExpenses.value);
          }
        }
      } catch (err) {
        setApiConnected(false);
      }
    }
    initBackendSync();
  }, []);

  const toggleTheme = () => {
    setTheme(prev => prev === 'dark' ? 'light' : 'dark');
  };

  // Save new expense
  const handleSaveExpense = async (newExpense) => {
    const updatedExpenses = [newExpense, ...expenses];
    setExpenses(updatedExpenses);

    if (newExpense.group_id) {
      setGroups(groups.map(g => g.id === newExpense.group_id ? { ...g, totalSpendPaise: g.totalSpendPaise + newExpense.amount_paise } : g));
    }

    if (newExpense.category) {
      setBudgets(budgets.map(b => b.category === newExpense.category ? { ...b, spentPaise: b.spentPaise + newExpense.amount_paise } : b));
    }

    if (apiConnected) {
      try {
        await SettlApi.createExpense({
          group_id: newExpense.group_id,
          payer_id: newExpense.payer_id || user.id,
          amount: newExpense.amount_paise / 100,
          currency: 'INR',
          category: newExpense.category,
          note: newExpense.note,
          timestamp: newExpense.timestamp,
          idempotency_key: newExpense.idempotency_key,
          splits: newExpense.splits
        });
      } catch (err) {
        console.warn('Backend sync failed:', err);
      }
    }
  };

  // Create new group
  const handleCreateGroup = async (newGroup) => {
    setGroups([newGroup, ...groups]);

    if (apiConnected) {
      try {
        await SettlApi.createGroup(newGroup.name, 'INR');
      } catch (err) {
        console.warn('Backend group sync failed:', err);
      }
    }
  };

  // Execute Spotlight NLP Action
  const handleExecuteSpotlightAction = (actionResult) => {
    if (!actionResult) return;

    switch (actionResult.type) {
      case 'CREATE_EXPENSE': {
        const payload = actionResult.previewChip.payload;
        const totalPaise = Math.round(payload.amount * 100);
        let participantsList = [user];

        if (payload.group_id) {
          const g = groups.find(item => item.id === payload.group_id);
          if (g) participantsList = [user, ...friends.filter(f => g.members.includes(f.id))];
        } else if (payload.person_id) {
          const f = friends.find(item => item.id === payload.person_id);
          if (f) participantsList = [user, f];
        } else if (actionResult.targetPerson) {
          participantsList = [user, actionResult.targetPerson];
        }

        const { splits } = calculateSplits(totalPaise, participantsList, 'equal');

        handleSaveExpense({
          id: `exp_${Date.now()}`,
          group_id: payload.group_id || null,
          payer_id: user.id,
          amount_paise: totalPaise,
          currency: 'INR',
          category: payload.category,
          note: payload.note,
          timestamp: new Date().toISOString(),
          idempotency_key: `idemp-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`,
          splits
        });
        break;
      }

      case 'SET_BUDGET': {
        const { category, amount } = actionResult.previewChip.payload;
        setBudgets(budgets.map(b => b.category.toLowerCase() === category.toLowerCase() ? { ...b, targetPaise: amount * 100 } : b));
        break;
      }

      case 'UPI_ACTION': {
        const { person, amount, isPay } = actionResult.previewChip.payload;
        setSettleQrState({
          isOpen: true,
          targetPerson: person,
          amountPaise: amount * 100,
          type: isPay ? 'PAY' : 'REQUEST'
        });
        break;
      }

      case 'ADD_SUBSCRIPTION': {
        const { name, amount, cycle } = actionResult.previewChip.payload;
        setSubscriptions([
          { id: `sub_${Date.now()}`, name, amountPaise: amount * 100, cycle, nextRenewal: '2026-08-20', category: 'Entertainment', isTrial: false },
          ...subscriptions
        ]);
        break;
      }

      default:
        break;
    }
  };

  return (
    <div className="console-container">
      {/* Top Header */}
      <Navigation
        theme={theme}
        toggleTheme={toggleTheme}
        onOpenNewExpense={() => { setPresetForExpense(null); setShowExpenseModal(true); }}
        onOpenOcr={() => setShowOcrModal(true)}
        onOpenTipCalc={() => setShowTipCalcModal(true)}
      />

      {/* Spotlight Command Bar */}
      <SpotlightBar
        onExecuteAction={handleExecuteSpotlightAction}
        users={friends}
        groups={groups}
        expenses={expenses}
      />

      {/* Main Studio Console Layout (4 Quad Panels fitting on screen, 100vh) */}
      <div style={{ flex: 1, overflow: 'hidden' }}>
        <Dashboard
          user={user}
          friends={friends}
          groups={groups}
          expenses={expenses}
          budgets={budgets}
          subscriptions={subscriptions}
          tickets={tickets}
          presets={presets}
          onOpenSettleQr={(friend, amountPaise, type) => setSettleQrState({ isOpen: true, targetPerson: friend, amountPaise, type })}
          onOpenNewExpense={() => { setPresetForExpense(null); setShowExpenseModal(true); }}
          onApplyPreset={(preset) => { setPresetForExpense(preset); setShowExpenseModal(true); }}
          onCreateGroup={handleCreateGroup}
          onConvertTicketToExpense={handleSaveExpense}
        />
      </div>

      {/* Modals & Overlays */}
      <ExpenseModal
        isOpen={showExpenseModal}
        onClose={() => { setShowExpenseModal(false); setPresetForExpense(null); }}
        onSaveExpense={handleSaveExpense}
        user={user}
        friends={friends}
        groups={groups}
        initialPreset={presetForExpense}
      />

      <UpiQrModal
        isOpen={settleQrState.isOpen}
        onClose={() => setSettleQrState({ ...settleQrState, isOpen: false })}
        targetPerson={settleQrState.targetPerson}
        amountPaise={settleQrState.amountPaise}
        type={settleQrState.type}
      />

      <ReceiptOcrModal
        isOpen={showOcrModal}
        onClose={() => setShowOcrModal(false)}
        onSaveExpense={handleSaveExpense}
      />

      <TipCalculatorModal
        isOpen={showTipCalcModal}
        onClose={() => setShowTipCalcModal(false)}
        onSaveExpense={handleSaveExpense}
      />

    </div>
  );
}
