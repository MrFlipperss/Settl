// Intelligent Spotlight NLP Parser for Settl expenses

function escapeRegex(str) {
  return (str || '').replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

export async function parseSpotlightExpense(text, { people = [], groups = [], currentUserId = '', searchContacts = null }) {
  const normalizedText = (text || '').replace(/\s+/g, ' ').trim()
  if (!normalizedText) {
    return {
      amount: '',
      note: 'Expense',
      category: 'Other',
      groupId: '',
      groupName: '',
      matchedGroup: null,
      participantIDs: currentUserId ? [currentUserId] : [],
      matchedPeople: [],
    }
  }

  // 1. Extract Amount
  const amountRegex = /(?:₹|rs\.?|inr)\s*([\d,]+(?:\.\d{1,2})?)/i
  const standaloneNumberRegex = /(?:^|\s)([\d,]+(?:\.\d{1,2})?)(?=\s|$)/
  let rawAmount = ''
  let amountToken = ''
  const cashMatch = normalizedText.match(amountRegex) || normalizedText.match(standaloneNumberRegex)
  if (cashMatch) {
    amountToken = cashMatch[0]
    rawAmount = cashMatch[1].replace(/,/g, '')
  }

  let remainder = amountToken ? normalizedText.replace(amountToken, ' ') : normalizedText

  // 2. Detect & Match Collection (Group)
  let matchedGroup = null
  const sortedGroups = [...(groups || [])].sort((a, b) => (b.name?.length || 0) - (a.name?.length || 0))

  for (const group of sortedGroups) {
    if (!group?.name || group.name.trim().length < 2) continue
    const gName = group.name.trim()
    const prepRegex = new RegExp(`\\b(?:in|for|at|under|to|collection|group)\\s+${escapeRegex(gName)}\\b`, 'i')
    const directRegex = new RegExp(`\\b${escapeRegex(gName)}\\b`, 'i')

    if (prepRegex.test(remainder)) {
      matchedGroup = group
      remainder = remainder.replace(prepRegex, ' ')
      break
    } else if (directRegex.test(remainder)) {
      matchedGroup = group
      remainder = remainder.replace(directRegex, ' ')
      break
    }
  }

  // Fallback: check if user wrote e.g. "in Goa" where group name is "Goa Trip"
  if (!matchedGroup) {
    const prepPhrase = remainder.match(/\b(?:in|at|under)\s+([a-zA-Z0-9\s]+?)(?=\s+(?:with|for|among|from|₹|rs|\d)|$)/i)
    if (prepPhrase && prepPhrase[1].trim().length >= 3) {
      const phrase = prepPhrase[1].trim().toLowerCase()
      const partialMatch = sortedGroups.find((g) => {
        const gn = (g.name || '').toLowerCase()
        return gn.includes(phrase) || phrase.includes(gn)
      })
      if (partialMatch) {
        matchedGroup = partialMatch
        remainder = remainder.replace(prepPhrase[0], ' ')
      }
    }
  }

  // 3. Detect & Match People
  const matchedPeople = new Map()
  const matchedNamesToStrip = new Set()

  // First check preposition phrase: "with Sarah and Alex"
  const withPhraseMatch = remainder.match(/\b(?:with|among|from)\s+([^0-9]+?)(?=\s+(?:in|for|at|under|collection|group)|$)/i)
  let candidateNames = []
  if (withPhraseMatch) {
    const rawNames = withPhraseMatch[1].trim()
    candidateNames = rawNames.split(/\s*(?:,|&|\band\b)\s*/i).map((s) => s.trim()).filter((s) => s.length >= 2)
    remainder = remainder.replace(withPhraseMatch[0], ' ')
  }

  const sortedPeople = [...(people || [])]
    .filter((p) => p.kind !== 'self' && p.participant_id !== currentUserId && p.display_name && p.display_name !== 'Settl person')
    .sort((a, b) => (b.display_name?.length || 0) - (a.display_name?.length || 0))

  // Match existing known contacts in text (even if "with" wasn't used)
  for (const p of sortedPeople) {
    const fullName = p.display_name.trim()
    const firstName = fullName.split(/\s+/)[0]
    const fullRegex = new RegExp(`\\b${escapeRegex(fullName)}\\b`, 'i')
    const firstRegex = firstName.length >= 3 ? new RegExp(`\\b${escapeRegex(firstName)}\\b`, 'i') : null

    if (fullRegex.test(remainder)) {
      matchedPeople.set(p.participant_id, p)
      matchedNamesToStrip.add(fullName)
      remainder = remainder.replace(fullRegex, ' ')
    } else if (firstRegex && firstRegex.test(remainder)) {
      matchedPeople.set(p.participant_id, p)
      matchedNamesToStrip.add(firstName)
      remainder = remainder.replace(firstRegex, ' ')
    }
  }

  // Also check candidates from "with..."
  for (const name of candidateNames) {
    matchedNamesToStrip.add(name)
    const found = sortedPeople.find((p) => {
      const fn = (p.display_name || '').toLowerCase()
      return fn === name.toLowerCase() || fn.startsWith(name.toLowerCase() + ' ')
    })
    if (found) {
      matchedPeople.set(found.participant_id, found)
    } else if (typeof searchContacts === 'function') {
      try {
        const results = await searchContacts(name)
        if (results && results.length > 0) {
          const match = results[0]
          matchedPeople.set(match.participant_id, match)
        }
      } catch {
        // Ignore search failure
      }
    }
  }

  // Remove any remaining person names from description
  for (const name of matchedNamesToStrip) {
    if (name.length >= 2) {
      remainder = remainder.replace(new RegExp(`\\b${escapeRegex(name)}\\b`, 'gi'), ' ')
    }
  }

  // Also remove group name if any fragments remain
  if (matchedGroup?.name) {
    remainder = remainder.replace(new RegExp(`\\b${escapeRegex(matchedGroup.name)}\\b`, 'gi'), ' ')
  }

  // 4. Categorize based on keywords
  const checkText = `${normalizedText} ${remainder}`.toLowerCase()
  let category = 'Other'
  if (/food|dinner|lunch|breakfast|brunch|coffee|chai|tea|grocer|restaurant|snack|meal|pizza|biryani|swiggy|zomato|cafe|burger|drinks|bar|dessert|bakery/i.test(checkText)) {
    category = 'Food'
  } else if (/cab|auto|uber|ola|metro|bus|train|fuel|petrol|diesel|taxi|rickshaw|toll|parking|flight|railway/i.test(checkText)) {
    category = 'Transport'
  } else if (/trip|hotel|travel|stay|resort|airbnb|vacation|tour/i.test(checkText)) {
    category = 'Travel'
  } else if (/rent|electricity|water|internet|wifi|utility|bill|maintenance|maid|cook|gas/i.test(checkText)) {
    category = 'Home'
  } else if (/shopping|clothes|purchase|market|amazon|flipkart|myntra|store|mall|shoes/i.test(checkText)) {
    category = 'Shopping'
  } else if (/movie|cinema|concert|game|netflix|spotify|pvr|show|theatre/i.test(checkText)) {
    category = 'Entertainment'
  }

  // 5. Clean Description (Note)
  let cleanNote = remainder
    .replace(/\b(?:with|and|for|paid|spent|in|on|at|under|trip|group|collection)\b/gi, ' ')
    .replace(/[^a-zA-Z0-9\s\u0080-\uFFFF-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()

  if (!cleanNote) {
    cleanNote = category !== 'Other' ? category : 'Expense'
  } else {
    cleanNote = cleanNote.charAt(0).toUpperCase() + cleanNote.slice(1)
  }

  const participantIDs = [
    ...(currentUserId ? [currentUserId] : []),
    ...matchedPeople.keys(),
  ]

  return {
    amount: rawAmount,
    note: cleanNote,
    category,
    groupId: matchedGroup?.id || '',
    groupName: matchedGroup?.name || '',
    matchedGroup,
    participantIDs: [...new Set(participantIDs)],
    matchedPeople: [...matchedPeople.values()],
  }
}
