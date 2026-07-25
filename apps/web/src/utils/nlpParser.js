/**
 * Fixed & Enhanced Spotlight NLP Parser for Settl
 * Bug Fix: Uses word boundaries \b to prevent sub-string stripping (e.g. "dinner" -> "dner")
 */

const CATEGORY_KEYWORDS = {
  Food: ['dinner', 'lunch', 'breakfast', 'chai', 'coffee', 'swiggy', 'zomato', 'food', 'restaurant', 'pizza', 'biryani', 'drinks', 'cafe', 'bar', 'burger'],
  Transport: ['uber', 'ola', 'cab', 'auto', 'metro', 'fuel', 'petrol', 'flight', 'train', 'bus', 'ticket', 'toll', 'parking'],
  Rent: ['rent', 'maintenance', 'electricity', 'water', 'wifi', 'maid', 'cook', 'house'],
  Entertainment: ['movie', 'cinema', 'pvr', 'concert', 'game', 'bowling', 'netflix', 'spotify', 'show'],
  Shopping: ['amazon', 'flipkart', 'myntra', 'groceries', 'supermarket', 'clothes', 'mall', 'mart']
};

export function parseSpotlightQuery(queryText, availableUsers = [], availableGroups = [], availableExpenses = []) {
  if (!queryText || !queryText.trim()) return null;

  const raw = queryText.trim();
  const lower = raw.toLowerCase();

  // Pattern 1: Budget commands ("set food budget 8000", "update rent budget 25000")
  const budgetMatch = lower.match(/(?:set|update)?\s*([a-z\s]+)?\s*budget\s*(?:for\s*([a-z\s]+))?\s*(?:to|is|=)?\s*₹?\s*(\d+)/i) ||
                      lower.match(/set\s+([a-z]+)\s+budget\s+(\d+)/i);
  if (budgetMatch) {
    const amount = parseInt(budgetMatch[3] || budgetMatch[2], 10);
    const categoryRaw = (budgetMatch[1] || budgetMatch[2] || 'General').trim();
    const category = categoryRaw.charAt(0).toUpperCase() + categoryRaw.slice(1);
    
    return {
      type: 'SET_BUDGET',
      actionTitle: `Set ${category} Budget to ₹${amount.toLocaleString('en-IN')}`,
      category,
      amount,
      previewChip: {
        badge: 'BUDGET COMMAND',
        badgeColor: 'gold',
        title: `Set ${category} Budget`,
        details: `Monthly limit: ₹${amount.toLocaleString('en-IN')}`,
        payload: { category, amount }
      }
    };
  }

  // Pattern 2: UPI Requests / Payments ("request 500 from rahul", "pay 1200 to sarah")
  const upiMatch = lower.match(/(?:request|ask|collect|pay|send)\s*₹?\s*(\d+)\s*(?:from|to|of)?\s*([a-z\s]+)?/i);
  if (upiMatch && (lower.includes('request') || lower.includes('pay') || lower.includes('ask') || lower.includes('send'))) {
    const isPay = lower.includes('pay') || lower.includes('send');
    const amount = parseInt(upiMatch[1], 10);
    let personName = (upiMatch[2] || 'Friend').trim();

    const matchedPerson = availableUsers.find(u => u.name.toLowerCase().includes(personName.toLowerCase())) || { name: personName, upi_vpa: `${personName.toLowerCase()}@upi` };

    return {
      type: 'UPI_ACTION',
      actionTitle: isPay ? `Pay ₹${amount} via UPI to ${matchedPerson.name}` : `Request ₹${amount} via UPI from ${matchedPerson.name}`,
      isPay,
      amount,
      person: matchedPerson,
      previewChip: {
        badge: isPay ? 'PAY UPI' : 'REQUEST UPI',
        badgeColor: isPay ? 'green' : 'blue',
        title: isPay ? `Pay ${matchedPerson.name}` : `Request from ${matchedPerson.name}`,
        details: `Generate UPI QR for ₹${amount.toLocaleString('en-IN')}`,
        payload: { person: matchedPerson, amount, isPay }
      }
    };
  }

  // Pattern 3: Subscriptions ("add netflix 499 monthly")
  const subMatch = lower.match(/(?:add|new|create)?\s*(?:subscription|sub)\s*([a-z0-9\s]+)\s*₹?\s*(\d+)\s*(monthly|yearly|annual)?/i);
  if (subMatch && (lower.includes('monthly') || lower.includes('yearly') || lower.includes('sub') || lower.includes('netflix') || lower.includes('spotify'))) {
    const name = subMatch[1].trim();
    const amount = parseInt(subMatch[2], 10);
    const cycle = (subMatch[3] || 'monthly').toLowerCase().includes('year') ? 'Yearly' : 'Monthly';

    return {
      type: 'ADD_SUBSCRIPTION',
      actionTitle: `Track ${name} Subscription (₹${amount}/${cycle === 'Monthly' ? 'mo' : 'yr'})`,
      name,
      amount,
      cycle,
      previewChip: {
        badge: 'SUBSCRIPTION',
        badgeColor: 'purple',
        title: `Recurring ${name}`,
        details: `₹${amount}/${cycle === 'Monthly' ? 'mo' : 'yr'} renewal alert`,
        payload: { name, amount, cycle }
      }
    };
  }

  // Pattern 4: Natural Language Expense Logging ("₹100 dinner with Sarah")
  const amountMatch = raw.match(/(?:₹|rs\.?|inr)?\s*(\d+(?:\.\d{1,2})?)/i);
  if (amountMatch) {
    const amount = parseFloat(amountMatch[1]);
    
    let matchedPerson = null;
    let matchedGroup = null;

    availableUsers.forEach(u => {
      if (lower.includes(u.name.toLowerCase())) matchedPerson = u;
    });

    availableGroups.forEach(g => {
      if (lower.includes(g.name.toLowerCase()) || lower.includes(g.account_number.toLowerCase())) matchedGroup = g;
    });

    // Detect category
    let detectedCategory = 'Food';
    for (const [cat, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
      if (keywords.some(kw => lower.includes(kw))) {
        detectedCategory = cat;
        break;
      }
    }

    // BUG FIX: Use \b word boundaries so "dinner" does NOT get stripped to "dner"!
    let note = raw
      .replace(/(?:₹|rs\.?|inr)?\s*\d+(?:\.\d{1,2})?/gi, '')
      .replace(/\b(?:with|and|for|paid|spent|in|on|trip)\b/gi, '')
      .trim();

    // Capitalize first letter of note cleanly
    if (!note) {
      note = `${detectedCategory} expense`;
    } else {
      note = note.charAt(0).toUpperCase() + note.slice(1);
    }

    const splitSummary = matchedGroup ? `Group split (${matchedGroup.name})` : (matchedPerson ? `50/50 split with ${matchedPerson.name}` : '100% Personal');

    return {
      type: 'CREATE_EXPENSE',
      actionTitle: `Log ₹${amount} ${note}`,
      amount,
      category: detectedCategory,
      note,
      targetPerson: matchedPerson,
      targetGroup: matchedGroup,
      previewChip: {
        badge: 'EXPENSE DRAFT',
        badgeColor: 'gold',
        title: `₹${amount} • ${note}`,
        details: `${detectedCategory} • ${splitSummary}`,
        payload: {
          amount,
          category: detectedCategory,
          note,
          group_id: matchedGroup ? matchedGroup.id : null,
          person_id: matchedPerson ? matchedPerson.id : null
        }
      }
    };
  }

  // Search Fallback
  const matchingFriends = availableUsers.filter(u => u.name.toLowerCase().includes(lower));
  const matchingGroups = availableGroups.filter(g => g.name.toLowerCase().includes(lower) || g.account_number.toLowerCase().includes(lower));
  const matchingExpenses = availableExpenses.filter(e => e.note.toLowerCase().includes(lower) || e.category.toLowerCase().includes(lower));

  return {
    type: 'SEARCH',
    actionTitle: `Search ledger for "${queryText}"`,
    searchResults: { friends: matchingFriends, groups: matchingGroups, expenses: matchingExpenses },
    previewChip: {
      badge: 'SEARCH',
      badgeColor: 'cyan',
      title: `Search "${queryText}"`,
      details: `Found ${matchingFriends.length} contacts, ${matchingGroups.length} groups, ${matchingExpenses.length} entries`,
      payload: { query: queryText }
    }
  };
}
