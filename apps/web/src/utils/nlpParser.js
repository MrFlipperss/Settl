/**
 * Rule-based Natural Language Interpreter for Settl Spotlight
 * Converts text like "₹100 dinner with sarah" into structured actions with preview chips.
 */

const CATEGORY_KEYWORDS = {
  Food: ['dinner', 'lunch', 'breakfast', 'chai', 'coffee', 'swiggy', 'zomato', 'food', 'restaurant', 'pizza', 'biryani', 'drinks', 'cafe'],
  Transport: ['uber', 'ola', 'cab', 'auto', 'metro', 'fuel', 'petrol', 'flight', 'train', 'bus', 'ticket', 'toll'],
  Rent: ['rent', 'maintenance', 'electricity', 'water', 'wifi', 'maid', 'cook'],
  Entertainment: ['movie', 'cinema', 'pvr', 'concert', 'game', 'bowling', 'netflix', 'spotify'],
  Shopping: ['amazon', 'flipkart', 'myntra', 'groceries', 'supermarket', 'clothes', 'mall']
};

export function parseSpotlightQuery(queryText, availableUsers = [], availableGroups = []) {
  if (!queryText || !queryText.trim()) return null;

  const raw = queryText.trim();
  const lower = raw.toLowerCase();

  // Pattern 1: Budget updates ("set food budget 6000", "budget food 5000")
  const budgetMatch = lower.match(/(?:set|update)?\s*([a-z\s]+)?\s*budget\s*(?:for\s*([a-z\s]+))?\s*(?:to|is|=)?\s*₹?\s*(\d+)/i) ||
                      lower.match(/set\s+([a-z]+)\s+budget\s+(\d+)/i);
  if (budgetMatch) {
    const amount = parseInt(budgetMatch[3] || budgetMatch[2], 10);
    const categoryRaw = (budgetMatch[1] || budgetMatch[2] || 'General').trim();
    const category = categoryRaw.charAt(0).toUpperCase() + categoryRaw.slice(1);
    
    return {
      type: 'SET_BUDGET',
      actionTitle: `Set ${category} Budget`,
      amount,
      category,
      previewChip: {
        badge: 'BUDGET UPDATE',
        badgeColor: 'gold',
        details: `Set monthly target for ${category} to ₹${amount.toLocaleString('en-IN')}`,
        payload: { category, amount }
      }
    };
  }

  // Pattern 2: UPI Money Requests ("request 500 from rahul", "ask sarah for 1200")
  const requestMatch = lower.match(/(?:request|ask|collect|upi)\s*₹?\s*(\d+)\s*(?:from|of)\s*([a-z\s]+)/i) ||
                       lower.match(/(?:request|ask)\s*([a-z\s]+)\s*(?:for)?\s*₹?\s*(\d+)/i);
  if (requestMatch) {
    let amount = parseInt(requestMatch[1], 10);
    let personName = requestMatch[2];
    if (isNaN(amount)) {
      amount = parseInt(requestMatch[2], 10);
      personName = requestMatch[1];
    }
    personName = personName ? personName.trim() : 'Friend';

    return {
      type: 'REQUEST_MONEY',
      actionTitle: `Generate UPI QR for ${personName}`,
      amount,
      personName,
      previewChip: {
        badge: 'UPI REQUEST',
        badgeColor: 'blue',
        details: `Generate UPI QR code to receive ₹${amount.toLocaleString('en-IN')} from ${personName}`,
        payload: { personName, amount }
      }
    };
  }

  // Pattern 3: Subscriptions ("add netflix 499 monthly", "subscription spotify 119")
  const subMatch = lower.match(/(?:add|new|create)?\s*(?:subscription|sub)\s*([a-z0-9\s]+)\s*₹?\s*(\d+)\s*(monthly|yearly|annual)?/i) ||
                   lower.match(/add\s+([a-z0-9\s]+)\s+₹?\s*(\d+)\s*(monthly|yearly|annual)?/i);
  if (subMatch && (lower.includes('monthly') || lower.includes('yearly') || lower.includes('sub') || lower.includes('netflix') || lower.includes('spotify'))) {
    const name = subMatch[1].trim();
    const amount = parseInt(subMatch[2], 10);
    const cycle = (subMatch[3] || 'monthly').toLowerCase().includes('year') ? 'Yearly' : 'Monthly';

    return {
      type: 'ADD_SUBSCRIPTION',
      actionTitle: `Add ${cycle} Subscription`,
      name,
      amount,
      cycle,
      previewChip: {
        badge: 'RECURRING SUB',
        badgeColor: 'purple',
        details: `Track ${name} (₹${amount}/${cycle === 'Monthly' ? 'mo' : 'yr'})`,
        payload: { name, amount, cycle }
      }
    };
  }

  // Pattern 4: Expense Logging ("₹100 dinner with sarah", "250 swiggy flatmates", "paid 600 taxi")
  // Extract amount
  const amountMatch = raw.match(/(?:₹|rs\.?|inr)?\s*(\d+(?:\.\d{1,2})?)/i);
  if (amountMatch) {
    const amount = parseFloat(amountMatch[1]);
    
    // Extract person/group
    let matchedPerson = null;
    let matchedGroup = null;

    availableUsers.forEach(u => {
      if (lower.includes(u.name.toLowerCase())) matchedPerson = u;
    });

    availableGroups.forEach(g => {
      if (lower.includes(g.name.toLowerCase()) || lower.includes(g.account_number.toLowerCase())) matchedGroup = g;
    });

    // Detect category from keywords
    let detectedCategory = 'General';
    for (const [cat, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
      if (keywords.some(kw => lower.includes(kw))) {
        detectedCategory = cat;
        break;
      }
    }

    // Clean note description
    let note = raw
      .replace(/(?:₹|rs\.?|inr)?\s*\d+(?:\.\d{1,2})?/gi, '')
      .replace(/with|and|for|paid|spent|in|on/gi, '')
      .trim();

    if (!note) note = `${detectedCategory} expense`;

    const targetLabel = matchedGroup ? matchedGroup.name : (matchedPerson ? matchedPerson.name : 'Personal');

    return {
      type: 'CREATE_EXPENSE',
      actionTitle: `Log ₹${amount} Expense`,
      amount,
      category: detectedCategory,
      note,
      targetPerson: matchedPerson,
      targetGroup: matchedGroup,
      previewChip: {
        badge: 'EXPENSE DRAFT',
        badgeColor: 'green',
        details: `₹${amount} • ${detectedCategory} • Split with ${targetLabel} (${note})`,
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

  return {
    type: 'UNKNOWN',
    actionTitle: 'Custom Action',
    previewChip: {
      badge: 'SEARCH / ADD',
      badgeColor: 'gray',
      details: `Search ledger or parse "${queryText}"`,
      payload: { query: queryText }
    }
  };
}
