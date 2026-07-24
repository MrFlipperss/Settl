/**
 * Split Math Utilities for Settl
 * Supports 4 split modes: equal, exact, percentage, shares
 * All monetary calculations handle exact paise precision to prevent loss of funds.
 */

// Convert float rupees to integer paise (e.g., 10.50 -> 1050)
export function rupeesToPaise(rupees) {
  if (isNaN(rupees) || rupees === null || rupees === undefined) return 0;
  return Math.round(parseFloat(rupees) * 100);
}

// Convert integer paise to float rupees (e.g., 1050 -> 10.50)
export function paiseToRupees(paise) {
  if (isNaN(paise) || paise === null || paise === undefined) return 0;
  return paise / 100;
}

// Format paise to currency string (e.g. 1050 -> ₹10.50 or ₹10)
export function formatCurrency(paiseOrRupees, isPaise = false) {
  const val = isPaise ? paiseToRupees(paiseOrRupees) : paiseOrRupees;
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: val % 1 === 0 ? 0 : 2,
    minimumFractionDigits: val % 1 === 0 ? 0 : 2,
  }).format(val);
}

/**
 * Calculate individual split amounts based on mode
 */
export function calculateSplits(totalPaise, participants, mode) {
  if (!totalPaise || totalPaise <= 0 || !participants || participants.length === 0) {
    return { splits: [], isValid: false, errorMsg: 'Invalid amount or participants' };
  }

  const count = participants.length;
  let splits = [];
  let isValid = true;
  let errorMsg = '';

  switch (mode) {
    case 'equal': {
      const baseShare = Math.floor(totalPaise / count);
      let remainder = totalPaise % count;

      splits = participants.map((p, idx) => {
        const addPaise = idx < remainder ? 1 : 0;
        const pPaise = baseShare + addPaise;
        return {
          user_id: p.id,
          id: p.id,
          name: p.name,
          amountPaise: pPaise,
          split_type: 'equal',
          share_amount: paiseToRupees(pPaise),
        };
      });
      break;
    }

    case 'exact': {
      let sumPaise = 0;
      splits = participants.map(p => {
        const pPaise = rupeesToPaise(p.val || 0);
        sumPaise += pPaise;
        return {
          user_id: p.id,
          id: p.id,
          name: p.name,
          amountPaise: pPaise,
          split_type: 'exact',
          share_amount: paiseToRupees(pPaise),
        };
      });

      const diff = totalPaise - sumPaise;
      if (Math.abs(diff) > 1) {
        isValid = false;
        errorMsg = `Exact total (${formatCurrency(sumPaise, true)}) must match bill total (${formatCurrency(totalPaise, true)})`;
      }
      break;
    }

    case 'percentage': {
      let totalPct = 0;
      participants.forEach(p => totalPct += (parseFloat(p.val) || 0));

      if (Math.abs(totalPct - 100) > 0.01) {
        isValid = false;
        errorMsg = `Percentages sum to ${totalPct.toFixed(1)}%, must equal 100%`;
      }

      let allocatedPaise = 0;
      splits = participants.map((p, idx) => {
        const pct = parseFloat(p.val) || 0;
        let pPaise = Math.round((totalPaise * pct) / 100);
        if (idx === count - 1 && isValid) {
          pPaise = totalPaise - allocatedPaise;
        }
        allocatedPaise += pPaise;
        return {
          user_id: p.id,
          id: p.id,
          name: p.name,
          amountPaise: Math.max(0, pPaise),
          split_type: 'percentage',
          share_amount: paiseToRupees(pPaise),
          percentage: pct,
        };
      });
      break;
    }

    case 'shares': {
      let totalShares = 0;
      participants.forEach(p => totalShares += (parseInt(p.val, 10) || 0));

      if (totalShares <= 0) {
        isValid = false;
        errorMsg = 'Total shares must be greater than 0';
      }

      let allocatedPaise = 0;
      splits = participants.map((p, idx) => {
        const shares = parseInt(p.val, 10) || 0;
        let pPaise = totalShares > 0 ? Math.round((totalPaise * shares) / totalShares) : 0;
        if (idx === count - 1 && isValid) {
          pPaise = totalPaise - allocatedPaise;
        }
        allocatedPaise += pPaise;
        return {
          user_id: p.id,
          id: p.id,
          name: p.name,
          amountPaise: Math.max(0, pPaise),
          split_type: 'shares',
          share_amount: paiseToRupees(pPaise),
          share_count: shares,
        };
      });
      break;
    }

    default:
      isValid = false;
      errorMsg = 'Unknown split mode';
  }

  return { splits, isValid, errorMsg };
}

/**
 * Recompute friend balances based on expenses
 */
export function computeFriendBalances(friends, expenses, currentUserId) {
  const balances = {};
  friends.forEach(f => {
    balances[f.id] = 0;
  });

  expenses.forEach(exp => {
    const payerId = exp.payer_id;
    const splits = exp.splits || [];

    splits.forEach(s => {
      const participantId = s.user_id || s.id;
      const sharePaise = s.amountPaise !== undefined ? s.amountPaise : rupeesToPaise(s.share_amount || 0);

      // Current user paid for someone else
      if (payerId === currentUserId && participantId !== currentUserId) {
        if (balances[participantId] !== undefined) {
          balances[participantId] += sharePaise;
        }
      }

      // Someone else paid for current user
      if (payerId !== currentUserId && participantId === currentUserId) {
        if (balances[payerId] !== undefined) {
          balances[payerId] -= sharePaise;
        }
      }
    });
  });

  return friends.map(f => ({
    ...f,
    balancePaise: balances[f.id] !== undefined ? balances[f.id] : f.balancePaise
  }));
}
