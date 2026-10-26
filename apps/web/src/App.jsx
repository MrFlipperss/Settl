import { useEffect, useMemo, useState } from 'react'
import { createClient } from '@supabase/supabase-js'
import {
  Activity, ArrowDownLeft, ArrowDownRight, ArrowRight, ArrowUpRight,
  Bell, Check, ChevronDown, Clock3, Command, CreditCard,
  Filter, FolderPlus, Home, LayoutGrid, LogOut, Moon, MoreHorizontal, Pencil,
  Plus, ReceiptText, Search, Settings, ShieldCheck, Sparkles, Sun, Users, Wallet,
  X, Zap,
} from 'lucide-react'

const API_URL = (import.meta.env.VITE_API_URL || 'https://settl-kru1.onrender.com').replace(/\/$/, '')
const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL
const SUPABASE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY
const supabase = SUPABASE_URL && SUPABASE_KEY ? createClient(SUPABASE_URL, SUPABASE_KEY) : null
const currency = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 2 })
const amount = (paise = 0) => currency.format(Number(paise || 0) / 100)
const initials = (name = '') => name.split(/\s+/).map((part) => part[0]).join('').slice(0, 2).toUpperCase() || '•'
const uid = () => crypto.randomUUID()

async function request(path, token, options = {}) {
  const headers = { Accept: 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}), ...(options.body ? { 'Content-Type': 'application/json' } : {}), ...options.headers }
  const response = await fetch(`${API_URL}${path}`, { ...options, headers })
  if (response.status === 204) return null
  const payload = await response.json().catch(() => ({}))
  if (!response.ok) throw new Error(payload.error || `Request failed (${response.status})`)
  return payload
}

function Avatar({ name, tone = 'lavender', size = '' }) { return <span className={`avatar avatar-${tone} ${size}`}>{initials(name)}</span> }
function Empty({ icon: Icon = ReceiptText, title, copy, action }) { return <div className="empty-state"><span className="empty-icon"><Icon size={21} /></span><strong>{title}</strong><p>{copy}</p>{action}</div> }
function Notice({ children, onClose, kind = 'error' }) { if (!children) return null; return <div className={`notice notice-${kind}`} role="status"><span>{children}</span>{onClose && <button onClick={onClose} aria-label="Dismiss"><X size={15} /></button>}</div> }

const navItems = [
  { id: 'home', label: 'Overview', icon: Home, section: 'Workspace' },
  { id: 'activity', label: 'Activity', icon: Activity },
  { id: 'balances', label: 'Balances', icon: ArrowDownRight },
  { id: 'people', label: 'People', icon: Users, section: 'Manage' },
  { id: 'collections', label: 'Collections', icon: LayoutGrid },
]

export default function App() {
  const [session, setSession] = useState(null)
  const [profile, setProfile] = useState(null)
  const [authLoading, setAuthLoading] = useState(Boolean(supabase))
  const [screen, setScreen] = useState('home')
  const [data, setData] = useState({ expenses: [], groups: [], contacts: [], balances: null })
  const [knownPeople, setKnownPeople] = useState([])
  const [loading, setLoading] = useState(false)
  const [notice, setNotice] = useState(null)
  const [modal, setModal] = useState(null)
  const [query, setQuery] = useState('')
  const [dark, setDark] = useState(localStorage.getItem('settl-theme') === 'dark')
  const [busy, setBusy] = useState(false)
  const [notifications, setNotifications] = useState([])
  const [settlements, setSettlements] = useState([])
  const [unreadNotifications, setUnreadNotifications] = useState(0)
  const [notificationsOpen, setNotificationsOpen] = useState(false)
  const [notificationsLoading, setNotificationsLoading] = useState(false)

  useEffect(() => {
    document.documentElement.dataset.theme = dark ? 'dark' : 'light'
    localStorage.setItem('settl-theme', dark ? 'dark' : 'light')
  }, [dark])

  useEffect(() => {
    if (!supabase) { setAuthLoading(false); return }
    supabase.auth.getSession().then(({ data: result }) => { setSession(result.session); setAuthLoading(false) })
    const { data: listener } = supabase.auth.onAuthStateChange((_event, current) => setSession(current))
    return () => listener.subscription.unsubscribe()
  }, [])

  useEffect(() => {
    let alive = true
    async function load() {
      if (!session?.access_token) { setProfile(null); setData({ expenses: [], groups: [], contacts: [], balances: null }); setKnownPeople([]); setSettlements([]); return }
      setLoading(true); setNotice(null)
      try {
        const saved = JSON.parse(sessionStorage.getItem(`settl-profile:${session.user.id}`) || 'null')
        let currentProfile = saved
        if (!currentProfile) {
          const { data: authProfile } = await supabase.auth.getUser()
          currentProfile = authProfile.user?.user_metadata?.settl_profile || null
        }
        if (!currentProfile) { if (alive) setProfile(null); return }
        if (alive) setProfile(currentProfile)
        const [expenses, groups, balances, contacts, savedSettlements] = await Promise.all([
          request('/api/v1/expenses/', session.access_token),
          request('/api/v1/groups/', session.access_token),
          request('/api/v1/balances', session.access_token),
          request('/api/v1/contacts', session.access_token),
          request('/api/v1/settlements/', session.access_token),
        ])
        if (alive) {
          setData((prev) => ({ ...prev, expenses: Array.isArray(expenses) ? expenses : [], groups: Array.isArray(groups) ? groups : [], contacts: Array.isArray(contacts) ? contacts : [], balances }))
          setSettlements(Array.isArray(savedSettlements) ? savedSettlements : [])
        }
      } catch (error) { if (alive) setNotice(error.message) }
      finally { if (alive) setLoading(false) }
    }
    load()
    return () => { alive = false }
  }, [session])

  useEffect(() => {
    if (!profile?.participant_id || !session?.access_token) {
      setNotifications([])
      setUnreadNotifications(0)
      return
    }
    let alive = true
    const refresh = async () => {
      try {
        const [response, currentSettlements] = await Promise.all([
          request('/api/v1/notifications', session.access_token),
          request('/api/v1/settlements/', session.access_token),
        ])
        if (!alive) return
        setNotifications(Array.isArray(response.notifications) ? response.notifications : [])
        setUnreadNotifications(Number(response.unread_count || 0))
        setSettlements(Array.isArray(currentSettlements) ? currentSettlements : [])
      } catch { /* Show fresh updates the next time the user opens the app. */ }
    }
    refresh()
    const interval = setInterval(refresh, 30_000)
    return () => { alive = false; clearInterval(interval) }
  }, [profile?.participant_id, session?.access_token])

  const people = useMemo(() => {
    const all = new Map()
    if (profile?.participant_id) all.set(profile.participant_id, { participant_id: profile.participant_id, display_name: profile.display_name, kind: 'self' })
    data.contacts.forEach((person) => all.set(person.participant_id, person))
    knownPeople.forEach((person) => { if (!all.has(person.participant_id)) all.set(person.participant_id, person) })
    data.balances?.breakdown?.forEach((person) => {
      if (person.user_id && !all.has(person.user_id)) all.set(person.user_id, { participant_id: person.user_id, display_name: person.user_name || 'Settl person', kind: 'balance' })
    })
    return [...all.values()]
  }, [profile, data, knownPeople])

  async function refresh() {
    if (!session?.access_token) return
    setLoading(true)
    try {
      const [expenses, groups, balances, contacts, savedSettlements] = await Promise.all([
        request('/api/v1/expenses/', session.access_token), request('/api/v1/groups/', session.access_token), request('/api/v1/balances', session.access_token), request('/api/v1/contacts', session.access_token), request('/api/v1/settlements/', session.access_token),
      ])
      setData((prev) => ({ ...prev, expenses: Array.isArray(expenses) ? expenses : [], groups: Array.isArray(groups) ? groups : [], contacts: Array.isArray(contacts) ? contacts : [], balances }))
      setSettlements(Array.isArray(savedSettlements) ? savedSettlements : [])
    } catch (error) { setNotice(error.message) } finally { setLoading(false) }
  }

  async function loadNotifications(silent = false) {
    if (!session?.access_token) return
    if (!silent) setNotificationsLoading(true)
    try {
      const response = await request('/api/v1/notifications', session.access_token)
      setNotifications(Array.isArray(response.notifications) ? response.notifications : [])
      setUnreadNotifications(Number(response.unread_count || 0))
    } catch (error) {
      if (!silent) setNotice(error.message)
    } finally {
      if (!silent) setNotificationsLoading(false)
    }
  }

  async function markNotificationRead(notification) {
    if (notification.read_at) return
    try {
      await request(`/api/v1/notifications/${notification.id}/read`, session.access_token, { method: 'PATCH' })
      setNotifications((items) => items.map((item) => item.id === notification.id ? { ...item, read_at: new Date().toISOString() } : item))
      setUnreadNotifications((count) => Math.max(0, count - 1))
    } catch (error) { setNotice(error.message) }
  }

  async function markAllNotificationsRead() {
    try {
      await request('/api/v1/notifications/read-all', session.access_token, { method: 'PATCH' })
      const now = new Date().toISOString()
      setNotifications((items) => items.map((item) => ({ ...item, read_at: item.read_at || now })))
      setUnreadNotifications(0)
    } catch (error) { setNotice(error.message) }
  }

  function cacheGroupMembers(members = []) {
    const known = members.filter((member) => member.display_name && member.participant_id !== profile.participant_id)
      .map((member) => ({ participant_id: member.participant_id, display_name: member.display_name, kind: 'group' }))
    setKnownPeople((prev) => [...new Map([...prev, ...known].map((person) => [person.participant_id, person])).values()])
  }

  async function loadGroupMembers(groupID) {
    const response = await request(`/api/v1/groups/${groupID}/members`, session.access_token)
    const members = (Array.isArray(response) ? response : []).map((member) => ({
      ...member,
      display_name: member.display_name || `Member ${member.participant_id?.slice(0, 8) || ''}`.trim(),
    }))
    cacheGroupMembers(members)
    return members
  }

  async function openCollection(group) {
    setBusy(true)
    try {
      const [detail, members] = await Promise.all([
        request(`/api/v1/groups/${group.id}`, session.access_token),
        loadGroupMembers(group.id),
      ])
      setModal({ type: 'collectionDetail', group: detail || group, members: Array.isArray(members) ? members : [] })
    } catch (error) { setNotice(error.message) }
    finally { setBusy(false) }
  }

  async function addCollectionMember(groupID, participantID) {
    setBusy(true)
    try {
      await request(`/api/v1/groups/${groupID}/members`, session.access_token, { method: 'POST', body: JSON.stringify({ user_id: participantID }) })
      const members = await loadGroupMembers(groupID)
      setModal((current) => current?.group?.id === groupID ? { ...current, members } : current)
      await refresh()
    } finally { setBusy(false) }
  }

  async function removeCollectionMember(groupID, participantID) {
    setBusy(true)
    try {
      await request(`/api/v1/groups/${groupID}/members/${participantID}`, session.access_token, { method: 'DELETE' })
      const members = await loadGroupMembers(groupID)
      setModal((current) => current?.group?.id === groupID ? { ...current, members } : current)
      await refresh()
    } finally { setBusy(false) }
  }

  function startCollectionExpense(group, members) {
    setModal({
      type: 'expense',
      prefill: { groupId: group.id, participantIDs: members.map((member) => member.participant_id) },
    })
  }

  async function saveExpense(input, idempotencyKey) {
    setBusy(true); setNotice(null)
    try {
      await request('/api/v1/expenses/', session.access_token, { method: 'POST', headers: { 'Idempotency-Key': idempotencyKey }, body: JSON.stringify(input) })
      setModal(null); await refresh(); await loadNotifications(true); setNotice('Expense saved and added to your ledger.');
    } catch (error) { setNotice(error.message); throw error }
    finally { setBusy(false) }
  }

  async function openExpenseForEditing(expense) {
    setBusy(true)
    try {
      const detail = await request(`/api/v1/expenses/${expense.id}`, session.access_token)
      const splitPeople = (detail?.splits || []).filter((split) => !people.some((person) => person.participant_id === split.user_id))
      if (splitPeople.length) setKnownPeople((prev) => [...new Map([...prev, ...splitPeople.map((split) => ({ participant_id: split.user_id, display_name: `Person ${split.user_id.slice(0, 8)}`, kind: 'expense' }))].map((person) => [person.participant_id, person])).values()])
      setModal({ type: 'editExpense', expense: detail || expense })
    } catch (error) { setNotice(error.message) }
    finally { setBusy(false) }
  }

  async function updateExpense(expenseID, input) {
    setBusy(true); setNotice(null)
    try {
      await request(`/api/v1/expenses/${expenseID}`, session.access_token, { method: 'PUT', body: JSON.stringify(input) })
      setModal(null); await refresh(); await loadNotifications(true); setNotice('Expense updated.')
    } catch (error) { setNotice(error.message); throw error }
    finally { setBusy(false) }
  }

  async function recordSettlement(input) {
    setBusy(true); setNotice(null)
    try {
      const settlement = await request('/api/v1/settlements/', session.access_token, { method: 'POST', body: JSON.stringify(input) })
      setModal(null); await refresh()
      setNotice(settlement.status === 'confirmed' ? 'Payment recorded and balance updated.' : 'Payment recorded. The other person needs to confirm it before the balance changes.')
    } catch (error) { setNotice(error.message); throw error }
    finally { setBusy(false) }
  }

  async function respondToSettlement(settlementID, status) {
    setBusy(true)
    try {
      await request(`/api/v1/settlements/${settlementID}`, session.access_token, { method: 'PATCH', body: JSON.stringify({ status }) })
      await refresh()
      setNotice(status === 'confirmed' ? 'Payment confirmed and balance updated.' : 'Payment request declined.')
    } catch (error) { setNotice(error.message) }
    finally { setBusy(false) }
  }

  async function updateUPI(upiID) {
    setBusy(true)
    try {
      const updated = await request('/api/v1/profile', session.access_token, { method: 'POST', body: JSON.stringify({ display_name: profile.display_name, phone_number: profile.phone_number, upi_id: upiID.trim() }) })
      setProfile(updated)
      sessionStorage.setItem(`settl-profile:${session.user.id}`, JSON.stringify(updated))
      void supabase.auth.updateUser({ data: { settl_profile: updated } })
      setModal(null); await refresh(); setNotice('UPI details updated.')
    } catch (error) { setNotice(error.message); throw error }
    finally { setBusy(false) }
  }

  async function createCollection(name, participantIDs = []) {
    setBusy(true)
    let groupCreated = false
    try {
      const group = await request('/api/v1/groups/', session.access_token, { method: 'POST', body: JSON.stringify({ name }) })
      groupCreated = true
      await refresh()
      for (const user_id of participantIDs) await request(`/api/v1/groups/${group.id}/members`, session.access_token, { method: 'POST', body: JSON.stringify({ user_id }) })
      setModal(null); await refresh(); setNotice('Collection created.')
    } catch (error) {
      if (groupCreated) { setModal(null); await refresh(); setNotice(`Collection created, but a person could not be added: ${error.message}`) }
      else setNotice(error.message)
    } finally { setBusy(false) }
  }

  async function addPerson(display_name, phone_number) {
    setBusy(true)
    try {
      const person = await request('/api/v1/contacts', session.access_token, { method: 'POST', body: JSON.stringify({ display_name, phone_number }) })
      setData((prev) => ({ ...prev, contacts: [...prev.contacts.filter((item) => item.participant_id !== person.participant_id), person] }))
      if (person.is_registered) {
        setModal(null)
        setNotice(`${person.display_name} already has Settl; we notified them.`)
      } else {
        setModal({ type: 'invite', person })
      }
    } catch (error) { setNotice(error.message) } finally { setBusy(false) }
  }

  async function startFromSpotlight(text) {
    const normalizedText = text.replace(/\s+/g, ' ').trim()
    const cash = normalizedText.match(/(?:₹|rs\.?|inr)\s*([\d,]+(?:\.\d{1,2})?)/i)
      || normalizedText.match(/(?:^|\s)([\d,]+(?:\.\d{1,2})?)(?=\s|$)/)
    const rawAmount = cash?.[1]?.replace(/,/g, '') || ''
    const note = (cash ? normalizedText.replace(cash[0], ' ').replace(/\s+/g, ' ').trim() : normalizedText)
      .replace(/\s*\b(?:with|for|among)\s+.+$/i, '').trim()
    const category = /food|dinner|lunch|breakfast|coffee|chai|grocer|restaurant|snack|meal/i.test(note) ? 'Food'
      : /cab|auto|uber|metro|bus|train|fuel|taxi|rickshaw/i.test(note) ? 'Transport'
        : /trip|flight|hotel|travel|stay/i.test(note) ? 'Travel'
          : /rent|electricity|water|internet|utility|bill/i.test(note) ? 'Home'
            : /shopping|clothes|purchase|market/i.test(note) ? 'Shopping'
              : /movie|cinema|concert|game|netflix/i.test(note) ? 'Entertainment' : 'Other'
    const normalizedNote = (value) => value.normalize('NFKD').replace(/[\u0300-\u036f]/g, '').toLocaleLowerCase().replace(/[^\p{L}\p{N}]+/gu, ' ').trim()
    const noteWords = ` ${normalizedNote(note)} `
    const mentionedPeople = [...people]
    const namePhrase = note.match(/\b(?:with|for|among)\s+(.+)$/i)?.[1]
    if (namePhrase) {
      const names = namePhrase.split(/\s*(?:,|&|\band\b)\s*/i).map((name) => name.trim()).filter((name) => name.length >= 2)
      const searches = await Promise.allSettled(names.map((name) => request(`/api/v1/contacts/search?q=${encodeURIComponent(name)}`, session.access_token)))
      searches.forEach((result) => {
        if (result.status === 'fulfilled' && Array.isArray(result.value)) mentionedPeople.push(...result.value)
      })
      const unique = new Map(mentionedPeople.map((person) => [person.participant_id, person]))
      setKnownPeople((prev) => [...new Map([...prev, ...mentionedPeople.filter((person) => person.kind !== 'self')].map((person) => [person.participant_id, person])).values()])
      mentionedPeople.splice(0, mentionedPeople.length, ...unique.values())
    }
    const peopleDraft = mentionedPeople.filter((person) => {
      if (person.kind === 'self' || !person.display_name || person.display_name === 'Settl person') return false
      const aliases = normalizedNote(person.display_name).split(' ')
      return aliases.some((alias) => alias.length >= 3 && noteWords.includes(` ${alias} `))
    }).map((person) => person.participant_id)
    setModal({ type: 'expense', prefill: { amount: rawAmount, note, category, participantIDs: [profile.participant_id, ...peopleDraft] } })
  }

  async function logout() { if (session?.user?.id) sessionStorage.removeItem(`settl-profile:${session.user.id}`); if (supabase) await supabase.auth.signOut(); setProfile(null) }

  if (authLoading) return <div className="loading-screen"><div className="brand-mark">s</div><span>Opening your Settl…</span></div>
  if (!supabase) return <SetupScreen />
  if (!session) return <AuthScreen onNotice={setNotice} notice={notice} />
  if (!profile) return <ProfileScreen session={session} onComplete={(value) => { sessionStorage.setItem(`settl-profile:${session.user.id}`, JSON.stringify(value)); supabase.auth.updateUser({ data: { settl_profile: value } }); setProfile(value); }} onLogout={logout} />

  return <div className="app-shell">
    <a className="skip-link" href="#main-content">Skip to content</a>
    <aside className="sidebar">
      <div className="brand"><span className="brand-mark">s</span><span className="brand-name">settl<span className="brand-period">.</span></span></div>
      <button className="workspace-switch"><span className="workspace-badge">{initials(profile.display_name)}</span><span className="workspace-copy"><b>{profile.display_name}</b><small>Personal space</small></span><ChevronDown size={15} /></button>
      <nav className="nav-list" aria-label="Main navigation">
        {navItems.map((item) => <div key={item.id}>{item.section && <div className="nav-section">{item.section}</div>}<button className={`nav-item ${screen === item.id ? 'active' : ''}`} onClick={() => setScreen(item.id)}><item.icon size={17} strokeWidth={1.8} /><span>{item.label}</span>{item.id === 'activity' && data.expenses.length > 0 && <span className="nav-count">{data.expenses.length}</span>}{item.id === 'balances' && settlements.some((settlement) => settlement.payee_id === profile.participant_id && settlement.status === 'pending') && <span className="nav-count">{settlements.filter((settlement) => settlement.payee_id === profile.participant_id && settlement.status === 'pending').length}</span>}</button></div>)}
      </nav>
      <div className="sidebar-bottom">
        <div className="upgrade-card"><div className="upgrade-icon"><Sparkles size={16} /></div><b>Money, made lighter.</b><p>Keep shared spending clear, calm, and together.</p><button onClick={() => setModal({ type: 'about' })}>How Settl works <ArrowRight size={14} /></button></div>
        <button className="nav-item" onClick={() => setModal({ type: 'settings' })}><Settings size={17} /><span>Settings</span></button>
        <div className="account-row"><Avatar name={profile.display_name} tone="mint" /><span className="account-name"><b>{profile.display_name}</b><small>{profile.phone_number}</small></span><button className="icon-button" aria-label="Sign out" onClick={logout}><LogOut size={16} /></button></div>
      </div>
    </aside>

    <main id="main-content" className="main-area" tabIndex="-1">
      <header className="topbar"><div className="breadcrumb"><span>Workspace</span><span className="crumb-slash">/</span><b>{navItems.find((item) => item.id === screen)?.label || 'Overview'}</b></div><div className="topbar-actions"><button className="search-trigger" onClick={() => { setScreen('home'); setTimeout(() => document.querySelector('#global-search')?.focus(), 0) }}><Search size={15} /><span>Search people, expenses...</span><kbd>⌘ K</kbd></button><div className="notifications-anchor"><button className="icon-button notification-button" aria-label="Notifications" aria-expanded={notificationsOpen} onClick={() => { const open = !notificationsOpen; setNotificationsOpen(open); if (open) loadNotifications(false) }}><Bell size={17} />{unreadNotifications > 0 && <span className="notification-count">{unreadNotifications > 9 ? '9+' : unreadNotifications}</span>}</button>{notificationsOpen && <NotificationsPopover items={notifications} unreadCount={unreadNotifications} loading={notificationsLoading} onClose={() => setNotificationsOpen(false)} onReadAll={markAllNotificationsRead} onSelect={async (item) => { await markNotificationRead(item); setNotificationsOpen(false); setScreen('activity'); await refresh() }}/>}</div><button className="icon-button theme-toggle" aria-label="Toggle color theme" onClick={() => setDark(!dark)}>{dark ? <Sun size={17} /> : <Moon size={17} />}</button></div></header>
      <div className="page-wrap"><Notice kind={notice?.includes('saved') || notice?.includes('created') || notice?.includes('added') || notice?.includes('updated') ? 'success' : 'error'} onClose={() => setNotice(null)}>{notice}</Notice>
        {screen === 'home' && <Overview profile={profile} data={data} people={people} loading={loading} onExpense={() => setModal({ type: 'expense' })} onNavigate={setScreen} onSearch={startFromSpotlight} />}
        {screen === 'activity' && <ActivityPage data={data} people={people} profile={profile} loading={loading} query={query} onQuery={setQuery} onExpense={() => setModal({ type: 'expense' })} onEditExpense={openExpenseForEditing} />}
        {screen === 'balances' && <BalancesPage balances={data.balances} settlements={settlements} profile={profile} loading={loading} busy={busy} people={people} onNavigate={setScreen} onSettle={(entry) => setModal({ type: 'settlement', entry })} onSettlementResponse={respondToSettlement} />}
        {screen === 'people' && <PeoplePage data={data} query={query} onQuery={setQuery} onAdd={() => setModal({ type: 'person' })} />}
        {screen === 'collections' && <CollectionsPage data={data} loading={loading} onCreate={() => setModal({ type: 'collection' })} onOpen={openCollection} />}
      </div>
    </main>
    <button className="mobile-add" aria-label="Add expense" onClick={() => setModal({ type: 'expense' })}><Plus size={24} /></button>
    {modal && <ModalHost modal={modal} close={() => setModal(null)} profile={profile} people={people} groups={data.groups} expenses={data.expenses} busy={busy} onExpense={saveExpense} onUpdateExpense={updateExpense} onSettlement={recordSettlement} onUpdateUPI={updateUPI} onEditUPI={() => setModal({ type: 'upi' })} onCollection={createCollection} onPerson={addPerson} onOpenPerson={() => setModal({ type: 'person' })} onLoadGroupMembers={loadGroupMembers} onAddMember={addCollectionMember} onRemoveMember={removeCollectionMember} onAddCollectionExpense={startCollectionExpense} onTheme={() => setDark(!dark)} dark={dark} />}
  </div>
}

function SetupScreen() {
  return <div className="setup-screen"><div className="setup-card"><div className="brand"><span className="brand-mark">s</span><span className="brand-name">settl<span className="brand-period">.</span></span></div><div className="eyebrow">A calmer way to split costs</div><h1>Your shared money,<br /><em>all settled.</em></h1><p>Settl brings your people, expenses, and balances into one clear space. To connect this web app, add your Supabase project URL and anonymous key to the web environment.</p><div className="setup-steps"><div><span>01</span><b>Connect Supabase Auth</b><small>Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.</small></div><div><span>02</span><b>Connect the Settl API</b><small>Set VITE_API_URL if you use a different backend.</small></div></div><div className="setup-note"><ShieldCheck size={17} /><span>Credentials stay in your local environment. This build never falls back to sample financial data.</span></div></div><div className="setup-aside"><div className="abstract-orbit orbit-one"/><div className="abstract-orbit orbit-two"/><div className="floating-card balance-float"><span>THIS MONTH</span><strong>₹ 8,240<span>.00</span></strong><small><i/> Everyone’s in sync</small></div><div className="floating-card people-float"><div className="stacked-avatars"><Avatar name="A" tone="peach"/><Avatar name="M" tone="blue"/><Avatar name="R" tone="mint"/></div><span>Good company.<br />Clear numbers.</span></div><div className="floating-caption">Shared costs, without the awkward math.</div></div></div>
}

function AuthScreen({ onNotice, notice }) {
  const [mode, setMode] = useState('signin'); const [email, setEmail] = useState(''); const [password, setPassword] = useState(''); const [busy, setBusy] = useState(false)
  async function submit(event) {
    event.preventDefault(); if (!email || password.length < 6) return onNotice('Enter a valid email and a password with at least 6 characters.')
    setBusy(true); onNotice(null)
    try {
      const result = mode === 'signin'
        ? await supabase.auth.signInWithPassword({ email, password })
        : await supabase.auth.signUp({ email, password, options: { emailRedirectTo: window.location.origin } })
      if (result.error) {
        const msg = result.error.message || ''
        if (/rate limit/i.test(msg) || /over_email_send_rate_limit/i.test(result.error.code || ''))
          onNotice('Too many sign-up attempts — Supabase limits confirmation emails to a few per hour. Please wait a few minutes and try again, or use an email address you haven\'t signed up with recently.')
        else if (/already registered/i.test(msg) || /user already registered/i.test(msg))
          onNotice('An account already exists for this email. Switch to sign in instead.')
        else if (/email not confirmed/i.test(msg))
          onNotice('Please confirm your email before signing in. Check your inbox for the confirmation link.')
        else
          onNotice(msg || 'Something went wrong. Please try again.')
      }
      else if (mode === 'signup' && result.data.session) { /* email confirmation disabled — session granted immediately, onAuthStateChange handles the rest */ }
      else if (mode === 'signup' && !result.data.session && result.data.user?.identities?.length === 0) onNotice('An account may already exist for this email. Switch to sign in.')
      else if (mode === 'signup' && !result.data.session) onNotice('Account created. Check your email for the confirmation link, then return here to finish setup.')
    } catch (error) { onNotice(error.message || 'Could not reach the authentication service. Check your connection and try again.') }
    finally { setBusy(false) }
  }
  return <div className="auth-screen"><div className="auth-brand"><span className="brand-mark">s</span><span className="brand-name">settl<span className="brand-period">.</span></span></div><div className="auth-card"><div className="eyebrow">Welcome to Settl</div><h1>{mode === 'signin' ? 'Good to see you.' : 'Let’s get you started.'}</h1><p>{mode === 'signin' ? 'Sign in to pick up right where you left off.' : 'Create an account to start sharing the load.'}</p>{notice && <Notice kind={notice.startsWith('Account created.') ? 'success' : 'error'}>{notice}</Notice>}<form onSubmit={submit}><label>Email address<input type="email" autoComplete="email" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="you@example.com" required /></label><label>Password<input type="password" autoComplete={mode === 'signin' ? 'current-password' : 'new-password'} value={password} onChange={(event) => setPassword(event.target.value)} placeholder="At least 6 characters" required minLength={6} /></label><button className="button button-primary full-button" disabled={busy}>{busy ? 'One moment…' : mode === 'signin' ? 'Sign in' : 'Create account'}<ArrowRight size={16}/></button></form><div className="auth-divider"><span/>or<span/></div><button className="button button-secondary full-button" onClick={() => { setMode(mode === 'signin' ? 'signup' : 'signin'); onNotice(null) }}>{mode === 'signin' ? 'Create a new account' : 'I already have an account'}</button><small className="auth-footnote"><ShieldCheck size={14}/> Your account is protected by Supabase authentication.</small></div><p className="auth-legal">By continuing, you agree to use Settl to keep shared expenses transparent and fair.</p></div>
}

function ProfileScreen({ session, onComplete, onLogout }) {
  const [name, setName] = useState(session.user.user_metadata?.full_name || ''); const [phone, setPhone] = useState(''); const [upi, setUpi] = useState(''); const [busy, setBusy] = useState(false); const [error, setError] = useState('')
  async function submit(event) {
    event.preventDefault(); if (!name.trim() || phone.replace(/\D/g, '').length < 10) return setError('Add your name and a valid phone number to continue.')
    setBusy(true); setError('')
    try { const profile = await request('/api/v1/profile', session.access_token, { method: 'POST', body: JSON.stringify({ display_name: name.trim(), phone_number: phone.trim(), upi_id: upi.trim() || undefined }) }); onComplete(profile) }
    catch (issue) { setError(issue.message) } finally { setBusy(false) }
  }
  return <div className="auth-screen"><div className="auth-brand"><span className="brand-mark">s</span><span className="brand-name">settl<span className="brand-period">.</span></span></div><div className="auth-card"><div className="eyebrow">A little introduction</div><h1>Make it yours.</h1><p>Your name and phone help friends find you and keep shared expenses connected.</p>{error && <Notice>{error}</Notice>}<form onSubmit={submit}><label>Your name<input value={name} onChange={(event) => setName(event.target.value)} autoComplete="name" placeholder="e.g. Aanya Mehta" required /></label><label>Phone number<input value={phone} onChange={(event) => setPhone(event.target.value)} autoComplete="tel" placeholder="+91 98765 43210" required /></label><label>UPI ID <span className="optional">Optional</span><input value={upi} onChange={(event) => setUpi(event.target.value)} placeholder="name@bank" /></label><button className="button button-primary full-button" disabled={busy}>{busy ? 'Setting up…' : 'Continue'}<ArrowRight size={16}/></button></form><button className="text-button logout-link" onClick={onLogout}>Sign out</button></div></div>
}

function Overview({ profile, data, people, loading, onExpense, onNavigate, onSearch }) {
  const [spotlightText, setSpotlightText] = useState('')
  const [spotlightLoading, setSpotlightLoading] = useState(false)
  const expenses = [...data.expenses].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
  const month = new Date().toISOString().slice(0, 7)
  const monthSpend = data.expenses.filter((item) => String(item.timestamp || '').slice(0, 7) === month && item.payer_id === profile.participant_id).reduce((sum, item) => sum + Number(item.amount_paise || 0), 0)
  const owed = Number(data.balances?.total_owed_paise || 0); const owing = Number(data.balances?.total_owing_paise || 0)
  async function submitSpotlight(event) {
    event.preventDefault()
    if (!spotlightText.trim() || spotlightLoading) return
    setSpotlightLoading(true)
    try { await onSearch(spotlightText); setSpotlightText('') }
    finally { setSpotlightLoading(false) }
  }
  return <>
    <section className="welcome-row"><div><div className="eyebrow">{new Intl.DateTimeFormat('en-IN', { weekday: 'long', month: 'long', day: 'numeric' }).format(new Date())}</div><h1>Good afternoon, {profile.display_name.split(' ')[0]}<span className="welcome-dot">.</span></h1><p>Shared spending, made a little more straightforward.</p></div><button className="button button-primary new-expense" onClick={onExpense}><Plus size={17}/> Add an expense</button></section>
    <section className="spotlight-panel"><div className="spotlight-copy"><span className="spotlight-spark"><Sparkles size={15}/></span><div><b>Quick expense</b><span>Describe the cost, then review and edit its draft before saving.</span></div></div><form className="spotlight-entry" onSubmit={submitSpotlight}><label className="spotlight-input" htmlFor="global-search"><Search size={18}/><input id="global-search" value={spotlightText} onChange={(event) => setSpotlightText(event.target.value)} placeholder="₹420 dinner with Aanya" /><kbd>↵</kbd></label><button className="button button-primary spotlight-submit" type="submit" disabled={!spotlightText.trim() || spotlightLoading}>{spotlightLoading ? 'Finding people…' : 'Draft expense'}{!spotlightLoading && <ArrowRight size={14}/>}</button></form><div className="spotlight-shortcuts"><span><Zap size={13}/> Example: amount + what it was for + person</span><button type="button" onClick={onExpense}>Open the full form <ArrowRight size={13}/></button></div></section>
    <div className="section-heading"><div><h2>Your overview</h2><p>A clear picture of what’s happening together.</p></div><span className="live-label"><span/> LIVE LEDGER</span></div>
    <section className="metric-grid">
      <article className="metric-card metric-primary"><div className="metric-label">You’re owed <span className="metric-icon"><ArrowDownLeft size={16}/></span></div><div className="metric-number">{amount(owed)}</div><div className="metric-foot"><span className="metric-dot green"/>Across everyone</div><button className="metric-link" onClick={() => onNavigate('balances')}>View balances <ArrowRight size={13}/></button></article>
      <article className="metric-card"><div className="metric-label">You owe <span className="metric-icon pale"><ArrowUpRight size={16}/></span></div><div className="metric-number">{amount(owing)}</div><div className="metric-foot"><span className="metric-dot orange"/>Ready when you are</div><button className="metric-link" onClick={() => onNavigate('balances')}>Settle up <ArrowRight size={13}/></button></article>
      <article className="metric-card"><div className="metric-label">You paid this month <span className="metric-icon pale"><ReceiptText size={16}/></span></div><div className="metric-number">{amount(monthSpend)}</div><div className="metric-foot">Your payments in the ledger</div><button className="metric-link" onClick={() => onNavigate('activity')}>See activity <ArrowRight size={13}/></button></article>
    </section>
    <div className="content-grid"><section className="content-card recent-card"><div className="card-heading"><div><h3>Recent activity</h3><p>The latest from your shared ledger</p></div><button className="subtle-link" onClick={() => onNavigate('activity')}>See all <ArrowRight size={14}/></button></div>{loading ? <div className="skeleton-list">{[0, 1, 2].map((x) => <div className="skeleton-row" key={x}/>)}</div> : expenses.length ? <div className="activity-list">{expenses.slice(0, 5).map((expense) => <ExpenseRow key={expense.id} expense={expense} people={people}/>)}</div> : <Empty icon={ReceiptText} title="A fresh start" copy="Your expense ledger is empty. Add a shared cost and Settl will keep the split clear." action={<button className="button button-secondary" onClick={onExpense}><Plus size={15}/> Add your first expense</button>}/>}</section>
      <section className="content-card side-card"><div className="card-heading"><div><h3>Your circles</h3><p>Collections keep everyone together</p></div><button className="round-add" aria-label="Add collection" onClick={() => onNavigate('collections')}><ArrowRight size={15}/></button></div>{data.groups.length ? <div className="mini-collection-list">{data.groups.slice(0, 4).map((group, index) => <button key={group.id} onClick={() => onNavigate('collections')} className="mini-collection"><span className={`collection-avatar collection-${index % 4}`}><Users size={16}/></span><span><b>{group.name}</b><small>{group.member_count || 1} members · {group.account_number || 'Collection'}</small></span><ChevronDown className="collection-arrow" size={15}/></button>)}</div> : <Empty icon={Users} title="Bring a group together" copy="Create a collection for your flat, trip, or regular plans." action={<button className="button button-secondary" onClick={() => onNavigate('collections')}><FolderPlus size={15}/> Create a collection</button>}/>}<div className="side-divider"/><button className="side-foot-link" onClick={() => onNavigate('people')}><span className="stacked-avatars"><Avatar name={profile.display_name} tone="mint"/><Avatar name="+" tone="lavender"/></span><span><b>Your people</b><small>{data.contacts.length} saved {data.contacts.length === 1 ? 'contact' : 'contacts'}</small></span><ArrowRight size={14}/></button></section></div>
    <section className="bottom-prompt"><span className="prompt-icon"><Command size={19}/></span><div><b>Think of Settl like a shared notebook.</b><p>Log the cost, choose who was there, and let the numbers take care of themselves.</p></div><button onClick={onExpense}>Log an expense <ArrowRight size={14}/></button></section>
  </>
}

function ExpenseRow({ expense, people, onEdit }) {
  const payer = people.find((item) => item.participant_id === expense.payer_id)
  const date = expense.timestamp ? new Date(expense.timestamp) : new Date()
  const colors = { Food: 'peach', Travel: 'blue', Transport: 'mint', Shopping: 'lavender', Entertainment: 'sun', Uncategorized: 'stone' }
  return <div className="expense-row"><span className={`expense-category category-${(colors[expense.category] || 'stone')}`}><ReceiptText size={17}/></span><div className="expense-info"><b>{expense.note || expense.category || 'Shared expense'}</b><small>{payer?.display_name || 'A participant'} paid · {date.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}</small></div><div className="expense-amount"><b>{amount(expense.amount_paise)}</b><small>{expense.category || 'Expense'}</small></div>{onEdit && <button className="expense-edit" onClick={() => onEdit(expense)} aria-label={`Edit ${expense.note || expense.category || 'expense'}`} title="Edit expense"><Pencil size={14}/></button>}</div>
}

function ActivityPage({ data, people, profile, loading, query, onQuery, onExpense, onEditExpense }) {
  const [filter, setFilter] = useState('All activity')
  const expenses = [...data.expenses].filter((expense) => filter === 'All activity' || Boolean(expense.group_id)).filter((expense) => `${expense.note || ''} ${expense.category || ''}`.toLowerCase().includes(query.toLowerCase())).sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
  return <><PageHeader eyebrow="Your ledger" title="Activity" copy="Every shared cost, in one place." action={<button className="button button-primary" onClick={onExpense}><Plus size={16}/> Add an expense</button>}/><section className="content-card page-card"><div className="toolbar"><label className="inline-search"><Search size={16}/><input value={query} onChange={(event) => onQuery(event.target.value)} placeholder="Search expenses"/></label><label className="select-filter"><Filter size={15}/><select value={filter} onChange={(event) => setFilter(event.target.value)}><option>All activity</option><option>Collections</option></select><ChevronDown size={14}/></label></div>{loading ? <div className="skeleton-list">{[0, 1, 2, 3].map((x) => <div className="skeleton-row" key={x}/>)}</div> : expenses.length ? <><div className="table-meta">{expenses.length} {expenses.length === 1 ? 'expense' : 'expenses'} in your ledger</div><div className="activity-list full-activity">{expenses.map((expense) => <ExpenseRow key={expense.id} expense={expense} people={people} onEdit={expense.payer_id === profile.participant_id ? onEditExpense : undefined}/>)}</div></> : <Empty title={query ? 'No matches' : 'Nothing here yet'} copy={query ? 'Try another search term.' : 'Once you log a shared cost, it will show up here.'} action={!query && <button className="button button-secondary" onClick={onExpense}><Plus size={15}/> Add an expense</button>}/>}</section></>
}

function BalancesPage({ balances, settlements, profile, loading, busy, people, onNavigate, onSettle, onSettlementResponse }) {
  const list = balances?.breakdown || []
  const incoming = settlements.filter((item) => item.payee_id === profile.participant_id && item.status === 'pending')
  const outgoing = settlements.filter((item) => item.payer_id === profile.participant_id && item.status === 'pending')
  const pendingPayees = new Set(outgoing.map((item) => item.payee_id))
  return <><PageHeader eyebrow="Keep things even" title="Balances" copy="See where you stand with everyone."/><div className="balance-summary"><div className="balance-total-card positive"><span>People owe you</span><b>{amount(balances?.total_owed_paise)}</b><small><ArrowDownLeft size={13}/> Incoming</small></div><div className="balance-total-card negative"><span>You owe</span><b>{amount(balances?.total_owing_paise)}</b><small><ArrowUpRight size={13}/> Outgoing</small></div><div className="balance-total-card net"><span>Your net balance</span><b>{amount(balances?.net_paise)}</b><small><Activity size={13}/> Across all connections</small></div></div>{(incoming.length > 0 || outgoing.length > 0) && <section className="content-card settlement-requests"><div className="card-heading"><div><h3>Payment confirmations</h3><p>Payments only affect balances once confirmed.</p></div></div>{incoming.map((item) => <div className="settlement-request" key={item.id}><div><b>{item.payer_name} says they paid {amount(item.amount_paise)}</b><small>Confirm only after the payment reaches you.</small></div><button className="button button-secondary button-small" onClick={() => onSettlementResponse(item.id, 'declined')} disabled={busy}>Decline</button><button className="button button-primary button-small" onClick={() => onSettlementResponse(item.id, 'confirmed')} disabled={busy}>Confirm received</button></div>)}{outgoing.map((item) => <div className="settlement-request" key={item.id}><div><b>{amount(item.amount_paise)} sent to {item.payee_name}</b><small>Waiting for them to confirm receipt.</small></div><span className="settlement-pending">Pending</span></div>)}</section>}<section className="content-card page-card"><div className="card-heading"><div><h3>Between you and them</h3><p>Choose “Settle up” to pay and record a confirmation request.</p></div></div>{loading ? <div className="skeleton-list"><div className="skeleton-row"/><div className="skeleton-row"/></div> : list.length ? <div className="balance-list">{list.map((entry) => <BalanceRow key={entry.user_id} entry={entry} owesYou={entry.direction === 'owed_to_me' ? true : entry.direction === 'i_owe' ? false : null} people={people} pending={pendingPayees.has(entry.user_id)} onSettle={onSettle}/> )}</div> : <Empty icon={Wallet} title="You’re all square" copy="Nothing outstanding between you and your people. Shared expenses will settle in here." action={<button className="button button-secondary" onClick={() => onNavigate('activity')}><ReceiptText size={15}/> View activity</button>}/>}</section><div className="info-note"><ShieldCheck size={17}/><span>UPI opens your payment app. Settl never marks a transfer paid automatically; the recipient confirms in-app so both balances stay accurate.</span></div></>
}

function BalanceRow({ entry, owesYou, people, pending, onSettle }) {
  const person = people.find((item) => item.participant_id === entry.user_id); const display = entry.user_name || person?.display_name || 'Settl person'
  return <div className="balance-row"><Avatar name={display} tone="blue"/><div className="balance-person"><b>{display}</b><small>{owesYou === null ? 'Direction unavailable' : owesYou ? 'Owes you' : 'You owe'}</small></div><span className={`balance-indicator ${owesYou === null ? 'neutral' : owesYou ? 'incoming' : 'outgoing'}`}>{owesYou === null ? <Activity size={14}/> : owesYou ? <ArrowDownLeft size={14}/> : <ArrowUpRight size={14}/>}</span><div className={`balance-value ${owesYou === null ? 'is-neutral' : owesYou ? 'is-incoming' : 'is-outgoing'}`}><b>{amount(entry.amount_paise)}</b><small>{owesYou === null ? 'per API response' : owesYou ? 'to receive' : 'to settle'}</small></div>{owesYou === false && (pending ? <span className="settlement-pending">Payment pending</span> : <button className="button button-secondary button-small settle-up-button" onClick={() => onSettle(entry)}>Settle up</button>)}</div>
}

function SettlementForm({ entry, busy, onSave, close }) {
  const [value, setValue] = useState((Number(entry.amount_paise || 0) / 100).toFixed(2))
  const [error, setError] = useState('')
  const maxAmount = Number(entry.amount_paise || 0) / 100
  const payableAmount = Number(value)
  const valid = Number.isFinite(payableAmount) && payableAmount > 0 && payableAmount <= maxAmount
  const upiLink = entry.upi_id && valid
    ? `upi://pay?${new URLSearchParams({ pa: entry.upi_id, pn: entry.user_name || 'Settl person', am: payableAmount.toFixed(2), cu: 'INR', tn: 'Settl balance settlement' })}`
    : ''
  function submit(event) {
    event.preventDefault()
    if (!valid) return setError(`Enter an amount up to ${amount(entry.amount_paise)}.`)
    setError('')
    onSave({ payee_id: entry.user_id, amount: payableAmount }).catch((issue) => setError(issue.message))
  }
  return <form className="modal-content settlement-form" onSubmit={submit}><p className="modal-description">You owe <b>{entry.user_name}</b> {amount(entry.amount_paise)}. Pay them, then record the payment here.</p><label>Amount to pay<input type="number" min="0.01" max={maxAmount} step="0.01" inputMode="decimal" value={value} onChange={(event) => setValue(event.target.value)} required/></label>{entry.upi_id ? <div className="upi-pay-details"><span>UPI ID</span><b>{entry.upi_id}</b><a className="button button-secondary" href={upiLink}>Pay {amount(Math.round(payableAmount * 100))} via UPI<ArrowUpRight size={15}/></a></div> : <div className="settlement-no-upi">{entry.user_name} hasn’t added a UPI ID. Arrange payment with them, then record it for confirmation.</div>}{error && <Notice>{error}</Notice>}<p className="settlement-confirm-hint">After you pay, choose “I’ve paid”. The other person must confirm before Settl reduces the balance.</p><div className="modal-footer"><button type="button" className="text-button" onClick={close}>Cancel</button><button className="button button-primary" disabled={!valid || busy}>{busy ? 'Recording…' : 'I’ve paid this amount'}<ArrowRight size={15}/></button></div></form>
}

function UPIForm({ profile, busy, onSave, close }) {
  const [value, setValue] = useState(profile.upi_id || '')
  const [error, setError] = useState('')
  function submit(event) {
    event.preventDefault()
    if (value.trim() && !/^[^@\s]+@[^@\s]+$/.test(value.trim())) return setError('Enter a valid UPI ID, such as name@bank.')
    setError('')
    onSave(value).catch((issue) => setError(issue.message))
  }
  return <form className="modal-content" onSubmit={submit}><p className="modal-description">Add your UPI ID so people who owe you can pay you from their UPI app. Settl never stores bank credentials.</p><label>UPI ID<input value={value} onChange={(event) => setValue(event.target.value)} placeholder="name@bank" autoComplete="off" autoFocus/></label>{error && <Notice>{error}</Notice>}<div className="modal-footer"><button type="button" className="text-button" onClick={close}>Cancel</button><button className="button button-primary" disabled={busy}>{busy ? 'Saving…' : 'Save UPI ID'}<ArrowRight size={15}/></button></div></form>
}

function PeoplePage({ data, query, onQuery, onAdd }) {
  const normalizedQuery = query.trim().toLocaleLowerCase()
  const people = (data.contacts || []).filter((person) => !normalizedQuery || `${person.display_name || ''} ${person.phone_number || ''}`.toLocaleLowerCase().includes(normalizedQuery))
  return <><PageHeader eyebrow="Good company" title="People" copy="Keep track of who you share things with." action={<button className="button button-primary" onClick={onAdd}><Plus size={16}/> Add a person</button>}/><section className="content-card page-card"><div className="toolbar"><label className="inline-search"><Search size={16}/><input value={query} onChange={(event) => onQuery(event.target.value)} placeholder="Search by name or phone"/></label><span className="toolbar-hint"><Users size={15}/>{people.length} {people.length === 1 ? 'person' : 'people'}</span></div>{people.length ? <div className="people-grid">{people.map((person, index) => <article className="person-card" key={person.participant_id}><Avatar name={person.display_name} tone={['lavender', 'mint', 'peach', 'blue'][index % 4]} size="large"/><div className="person-detail"><b>{person.display_name}</b><span>{person.phone_number || 'Settl contact'}</span></div><MoreHorizontal size={17} className="person-more"/></article>)}</div> : <Empty icon={Users} title="Your circle starts here" copy="Add people by name and phone. Settl uses real contacts from your account, never sample identities." action={<button className="button button-secondary" onClick={onAdd}><Plus size={15}/> Add a person</button>}/>}</section><div className="privacy-note"><ShieldCheck size={16}/> Phone numbers are used to match people who join Settl.</div></>
}

function CollectionsPage({ data, loading, onCreate, onOpen }) {
  return <><PageHeader eyebrow="Your circles" title="Collections" copy="Bring recurring groups together, without the admin." action={<button className="button button-primary" onClick={onCreate}><Plus size={16}/> New collection</button>}/><div className="collection-grid">{data.groups.map((group, index) => <article className="collection-card" key={group.id}><div className={`collection-hero collection-${index % 4}`}><div className="collection-orbit"/><div className="collection-icon"><Users size={20}/></div><span>{group.account_number || 'SETTL COLLECTION'}</span><MoreHorizontal className="collection-more" size={18}/></div><div className="collection-body"><h3>{group.name}</h3><p>{group.member_count || 1} members · Created {new Date(group.created_at).toLocaleDateString('en-IN', { month: 'short', year: 'numeric' })}</p><button className="collection-open" onClick={() => onOpen(group)}>Open collection <ArrowRight size={14}/></button></div></article>)}{!data.groups.length && !loading && <div className="collection-empty"><Empty icon={LayoutGrid} title="Make room for your regulars" copy="A collection can be your flatmates, family, or the people you travel with." action={<button className="button button-secondary" onClick={onCreate}><FolderPlus size={15}/> Create a collection</button>}/></div>}{loading && <div className="skeleton-row"/>}</div></>
}

function PageHeader({ eyebrow, title, copy, action }) { return <section className="page-header"><div><div className="eyebrow">{eyebrow}</div><h1>{title}</h1><p>{copy}</p></div>{action}</section> }

function NotificationsPopover({ items, unreadCount, loading, onClose, onReadAll, onSelect }) {
  return <section className="notifications-popover" role="dialog" aria-label="Notifications"><header><div><b>Notifications</b><small>{unreadCount ? `${unreadCount} unread` : 'You’re up to date'}</small></div><div className="notification-actions">{unreadCount > 0 && <button onClick={onReadAll}>Mark all read</button>}<button className="icon-button" aria-label="Close notifications" onClick={onClose}><X size={15}/></button></div></header>{loading ? <div className="notification-empty">Loading your notifications…</div> : items.length ? <div className="notification-list">{items.map((item) => <button key={item.id} className={`notification-item ${item.read_at ? 'read' : 'unread'}`} onClick={() => onSelect(item)}><span className="notification-avatar"><ReceiptText size={15}/></span><span className="notification-copy"><b>{item.title}</b><span>{item.actor_display_name} · {item.body}</span><small>{new Date(item.created_at).toLocaleString('en-IN', { day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit' })}</small></span>{!item.read_at && <i aria-label="Unread"/>}</button>)}</div> : <div className="notification-empty"><span className="empty-icon"><Bell size={17}/></span><b>No notifications yet</b><p>When someone adds you to a shared expense, it’ll show up here.</p></div>}<footer><span>Notifications are in-app. Unregistered contacts can see them after they join Settl.</span></footer></section>
}

function ModalHost({ modal, close, profile, people, groups, expenses, busy, onExpense, onUpdateExpense, onSettlement, onUpdateUPI, onEditUPI, onCollection, onPerson, onOpenPerson, onLoadGroupMembers, onAddMember, onRemoveMember, onAddCollectionExpense, dark, onTheme }) {
  const titles = { expense: 'Add an expense', editExpense: 'Edit expense', settlement: 'Settle up', upi: 'Payment details', collection: 'New collection', person: 'Add a person', invite: 'Invite to Settl', settings: 'Settings', about: 'A little more about Settl' }
  const isDetail = modal.type === 'collectionDetail'
  const editingExpense = modal.type === 'editExpense' ? modal.expense : null
  const savedSplits = editingExpense?.splits || []
  const expensePrefill = editingExpense ? {
    amount: (Number(editingExpense.amount_paise || 0) / 100).toFixed(2),
    note: editingExpense.note || '',
    category: editingExpense.category || 'Food',
    groupId: editingExpense.group_id || '',
    splitType: 'exact',
    participantIDs: savedSplits.map((split) => split.user_id),
    raw: Object.fromEntries(savedSplits.map((split) => [split.user_id, (Number(split.share_amount_paise || 0) / 100).toFixed(2)])),
  } : undefined
  const heading = isDetail ? modal.group.name : titles[modal.type]
  return <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) close() }}><section className={`modal ${modal.type === 'expense' || modal.type === 'editExpense' || isDetail ? 'modal-wide' : ''}`} role="dialog" aria-modal="true" aria-labelledby="modal-title"><header className="modal-header"><div><div className="eyebrow">{isDetail ? `Collection · ${modal.group.account_number || 'Shared space'}` : modal.type === 'expense' || modal.type === 'editExpense' ? 'Shared spending' : 'Your Settl space'}</div><h2 id="modal-title">{heading}</h2></div><button className="icon-button modal-close" aria-label="Close dialog" onClick={close}><X size={18}/></button></header>{(modal.type === 'expense' || editingExpense) && <ExpenseForm profile={profile} people={people} groups={groups} busy={busy} prefill={editingExpense ? expensePrefill : modal.prefill} editingExpense={editingExpense} onLoadGroupMembers={onLoadGroupMembers} onSave={onExpense} onUpdateExpense={onUpdateExpense} close={close}/ >}{modal.type === 'settlement' && <SettlementForm entry={modal.entry} busy={busy} onSave={onSettlement} close={close}/ >}{modal.type === 'upi' && <UPIForm profile={profile} busy={busy} onSave={onUpdateUPI} close={close}/ >}{isDetail && <CollectionDetail group={modal.group} members={modal.members} expenses={expenses} people={people} profile={profile} busy={busy} onAddMember={onAddMember} onRemoveMember={onRemoveMember} onAddExpense={onAddCollectionExpense} onOpenPerson={onOpenPerson}/ >}{modal.type === 'person' && <PersonForm busy={busy} onSave={onPerson} close={close}/ >}{modal.type === 'invite' && <InvitePerson person={modal.person} close={close}/ >}{modal.type === 'collection' && <CollectionForm people={people} busy={busy} onSave={onCollection} close={close}/ >}{modal.type === 'settings' && <div className="modal-content"><div className="setting-row"><span className="setting-icon"><Moon size={17}/></span><div><b>Appearance</b><small>Choose a comfortable theme</small></div><button className="button button-small button-secondary" onClick={onTheme}>{dark ? 'Dark' : 'Light'}<ChevronDown size={13}/></button></div><div className="setting-row"><span className="setting-icon"><ShieldCheck size={17}/></span><div><b>Account</b><small>{profile.display_name} · {profile.phone_number}</small></div></div><div className="setting-row"><span className="setting-icon"><CreditCard size={17}/></span><div><b>Payments</b><small>{profile.upi_id || 'UPI details not added'}</small></div><button className="button button-small button-secondary" onClick={onEditUPI}>{profile.upi_id ? 'Update' : 'Add UPI'}</button></div><div className="setup-note"><ShieldCheck size={16}/><span>Ledger data comes from your Settl account. This browser stores only your theme preference and the active auth session.</span></div></div>}{modal.type === 'about' && <div className="modal-content about-copy"><p>Settl helps people keep shared expenses clear. Log what happened, pick the people involved, and review the split before saving.</p><div className="about-feature"><span><Zap size={16}/></span><div><b>Fast capture</b><small>One expense, the right people, a clear split.</small></div></div><div className="about-feature"><span><Users size={16}/></span><div><b>People first</b><small>Collections make recurring groups easier, but they’re optional.</small></div></div><div className="about-feature"><span><ShieldCheck size={16}/></span><div><b>Honest money</b><small>Only confirmed backend responses appear in your ledger.</small></div></div><div className="future-note"><Sparkles size={15}/> Budgets, recurring payments, ticket storage, and receipt scanning are not connected yet.</div></div>}</section></div>
}

function InvitePerson({ person, close }) {
  const [copied, setCopied] = useState(false)
  const [error, setError] = useState('')
  const invite = `Hi ${person.display_name}, join me on Settl so we can keep shared expenses clear: ${window.location.origin}`
  async function copyInvite() {
    setError('')
    try {
      await navigator.clipboard.writeText(invite)
      setCopied(true)
    } catch {
      setError('Copy is unavailable in this browser. Select the invite text below and copy it.')
    }
  }
  async function shareInvite() {
    setError('')
    if (!navigator.share) return copyInvite()
    try { await navigator.share({ title: 'Join me on Settl', text: invite }) }
    catch (issue) { if (issue.name !== 'AbortError') setError('Could not open the share sheet. You can copy the invite text below.') }
  }
  return <div className="modal-content"><p className="modal-description"><b>{person.display_name}</b> doesn’t have a Settl account yet. We’ve saved them as a contact. Share an invite so they can join; their pending notification will be waiting when they sign up.</p><label>Invite message<textarea value={invite} readOnly rows="3" onFocus={(event) => event.target.select()}/></label>{error && <Notice>{error}</Notice>}{copied && <Notice kind="success">Invite copied. Send it to {person.display_name} when you’re ready.</Notice>}<div className="modal-footer"><button type="button" className="text-button" onClick={close}>Done</button><button type="button" className="button button-secondary" onClick={copyInvite}>Copy invite</button><button type="button" className="button button-primary" onClick={shareInvite}>Share invite<ArrowRight size={15}/></button></div></div>
}

function CollectionDetail({ group, members, expenses, people, profile, busy, onAddMember, onRemoveMember, onAddExpense, onOpenPerson }) {
  const [participantID, setParticipantID] = useState('')
  const [error, setError] = useState('')
  const memberIDs = new Set(members.map((member) => member.participant_id))
  const candidates = people.filter((person) => person.kind !== 'self' && person.display_name !== 'Settl person' && !memberIDs.has(person.participant_id))
  const groupExpenses = expenses.filter((expense) => expense.group_id === group.id).sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
  const totalPaise = groupExpenses.reduce((sum, expense) => sum + Number(expense.amount_paise || 0), 0)
  async function addSelected() {
    if (!participantID) return
    setError('')
    try { await onAddMember(group.id, participantID); setParticipantID('') }
    catch (issue) { setError(issue.message) }
  }
  async function remove(member) {
    if (member.participant_id === profile.participant_id) return
    if (!window.confirm(`Remove ${member.display_name} from ${group.name}?`)) return
    setError('')
    try { await onRemoveMember(group.id, member.participant_id) }
    catch (issue) { setError(issue.message) }
  }
  return <div className="modal-content collection-detail"><div className="collection-stats"><div><span>People</span><b>{members.length}</b></div><div><span>Expenses</span><b>{groupExpenses.length}</b></div><div><span>Total logged</span><b>{amount(totalPaise)}</b></div></div><section className="detail-section"><div className="detail-section-heading"><div><h3>Members</h3><p>People in this shared space</p></div><button className="text-link" onClick={onOpenPerson}><Plus size={14}/> Add a person</button></div><div className="member-list">{members.map((member, index) => <div className="member-row" key={member.participant_id}><Avatar name={member.display_name} tone={['mint', 'lavender', 'peach', 'blue'][index % 4]}/><div><b>{member.display_name}{member.participant_id === profile.participant_id ? ' (you)' : ''}</b><small>{member.participant_id === profile.participant_id ? 'Collection creator' : 'Collection member'}</small></div>{member.participant_id !== profile.participant_id && <button className="member-remove" onClick={() => remove(member)} disabled={busy}>Remove</button>}</div>)}</div>{candidates.length ? <div className="member-add-row"><select value={participantID} onChange={(event) => setParticipantID(event.target.value)} aria-label="Choose a person to add"><option value="">Choose a person…</option>{candidates.map((person) => <option key={person.participant_id} value={person.participant_id}>{person.display_name}</option>)}</select><button className="button button-secondary button-small" onClick={addSelected} disabled={!participantID || busy}>{busy ? 'Adding…' : 'Add member'}</button></div> : <div className="member-empty">No other saved people to add yet. Add someone by name and phone, then return here.</div>}{error && <Notice>{error}</Notice>}</section><section className="detail-section detail-activity"><div className="detail-section-heading"><div><h3>Recent expenses</h3><p>Expenses tagged to this collection</p></div></div>{groupExpenses.length ? <div className="activity-list">{groupExpenses.slice(0, 3).map((expense) => <ExpenseRow key={expense.id} expense={expense} people={people}/>)}</div> : <p className="detail-empty-copy">No expenses in this collection yet.</p>}</section><div className="modal-footer collection-footer"><button className="text-button" onClick={() => onAddExpense(group, members)}><Plus size={14}/> Add expense to collection</button><span className="modal-footer-spacer"/><span className="collection-created">Created {new Date(group.created_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}</span></div></div>
}

function ExpenseForm({ profile, people, groups, busy, prefill = {}, editingExpense, onLoadGroupMembers, onSave, onUpdateExpense, close }) {
  const [value, setValue] = useState(prefill.amount || ''); const [note, setNote] = useState(prefill.note || ''); const [category, setCategory] = useState(prefill.category || 'Food'); const [groupId, setGroupId] = useState(prefill.groupId || ''); const [membersLoading, setMembersLoading] = useState(false); const [splitType, setSplitType] = useState(prefill.splitType || 'equal'); const [selected, setSelected] = useState(prefill.participantIDs?.length ? prefill.participantIDs : [profile.participant_id]); const [raw, setRaw] = useState(prefill.raw || {}); const [error, setError] = useState(''); const [retryKey] = useState(uid())
  const amountPaise = Math.round(Number(value) * 100)
  const participants = people.filter((person) => selected.includes(person.participant_id))
  const exactTotal = participants.reduce((sum, person) => sum + Math.round(Number(raw[person.participant_id] || 0) * 100), 0)
  const percentageTotal = participants.reduce((sum, person) => sum + Number(raw[person.participant_id] || 0), 0)
  const shareTotal = participants.reduce((sum, person) => sum + Math.max(0, Number(raw[person.participant_id] || 1)), 0)
  const valid = amountPaise > 0 && Math.abs(Number(value) * 100 - amountPaise) < 0.000001 && participants.length > 0 && (splitType !== 'exact' || (participants.every((person) => Number(raw[person.participant_id] || 0) >= 0) && exactTotal === amountPaise)) && (splitType !== 'percentage' || (participants.every((person) => Number(raw[person.participant_id] || 0) >= 0) && Math.round(percentageTotal * 100) === 10000)) && (splitType !== 'shares' || participants.every((person) => Number.isInteger(Number(raw[person.participant_id] || 0)) && Number(raw[person.participant_id] || 0) > 0))
  function previewShare(person, index) {
    if (splitType === 'exact') return Math.round(Number(raw[person.participant_id] || 0) * 100)
    if (splitType === 'equal') return Math.floor(amountPaise / participants.length) + (index === 0 ? amountPaise % participants.length : 0)
    if (splitType === 'percentage') {
      if (index === participants.length - 1) return amountPaise - participants.slice(0, -1).reduce((sum, participant) => sum + Math.floor(amountPaise * Math.round(Number(raw[participant.participant_id] || 0) * 100) / 10000), 0)
      return Math.floor(amountPaise * Math.round(Number(raw[person.participant_id] || 0) * 100) / 10000)
    }
    if (index === participants.length - 1) return amountPaise - participants.slice(0, -1).reduce((sum, participant) => sum + Math.floor(amountPaise * Number(raw[participant.participant_id] || 1) / shareTotal), 0)
    return Math.floor(amountPaise * Number(raw[person.participant_id] || 1) / shareTotal)
  }
  function togglePerson(id) { setSelected((prev) => prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]) }
  async function changeGroup(id) {
    setGroupId(id)
    setError('')
    if (!id) { setSelected([profile.participant_id]); return }
    setMembersLoading(true)
    try {
      const members = await onLoadGroupMembers(id)
      setSelected(members.map((member) => member.participant_id))
    } catch (issue) { setError(issue.message) }
    finally { setMembersLoading(false) }
  }
  function setSplit(mode) { setSplitType(mode); if (mode === 'shares') setRaw(Object.fromEntries(selected.map((id) => [id, 1]))); if (mode === 'percentage') { const n = Math.max(1, selected.length); setRaw(Object.fromEntries(selected.map((id, index) => [id, index === n - 1 ? 100 - Math.floor(100 / n) * (n - 1) : Math.floor(100 / n)]))) } }
  function makeSplits() {
    if (splitType === 'equal') return participants.map((person) => ({ user_id: person.participant_id }))
    if (splitType === 'exact') return participants.map((person) => ({ user_id: person.participant_id, exact_amount: Number(raw[person.participant_id] || 0) }))
    if (splitType === 'percentage') return participants.map((person) => ({ user_id: person.participant_id, percentage: Number(raw[person.participant_id] || 0) }))
    return participants.map((person) => ({ user_id: person.participant_id, share_count: Number(raw[person.participant_id] || 1) }))
  }
  async function submit(event) {
    event.preventDefault(); if (!valid) return setError('Check the amount and make sure every participant has a valid share.')
    setError('')
    try {
      const input = { group_id: groupId || null, amount: Number(value), split_type: splitType, category, note: note.trim() || undefined, splits: makeSplits() }
      if (editingExpense) await onUpdateExpense(editingExpense.id, input)
      else await onSave(input, retryKey)
    }
    catch { /* A retry uses the same key for this exact draft. */ }
  }
  return <form className="modal-content expense-form" onSubmit={submit}><div className="amount-entry"><label htmlFor="expense-amount">How much was it?</label><div className="amount-input-wrap"><span>₹</span><input id="expense-amount" type="number" min="0.01" step="0.01" inputMode="decimal" placeholder="0.00" value={value} onChange={(event) => setValue(event.target.value)} autoFocus required/><span className="amount-suffix">INR</span></div></div><div className="form-two-col"><label>What was it for?<input value={note} onChange={(event) => setNote(event.target.value)} placeholder="Dinner, cab, groceries…"/></label><label>Category<select value={category} onChange={(event) => setCategory(event.target.value)}>{['Food', 'Transport', 'Travel', 'Shopping', 'Entertainment', 'Home', 'Other', 'Uncategorized'].map((item) => <option key={item}>{item}</option>)}</select></label></div><div className="form-two-col"><label>Collection <span className="optional">Optional</span><select value={groupId} disabled={Boolean(editingExpense)} onChange={(event) => changeGroup(event.target.value)}><option value="">No collection</option>{groups.map((group) => <option key={group.id} value={group.id}>{group.name}</option>)}</select></label><div className="form-note"><Clock3 size={14}/>{editingExpense ? 'Collection stays the same when editing' : membersLoading ? 'Loading collection members…' : groupId ? 'Collection members selected' : 'Saved with today’s date'}</div></div><div className="form-field-label">Who was part of this? <small>Choose everyone sharing the cost.</small></div><div className="participant-picker">{people.map((person, index) => <button type="button" key={person.participant_id} className={`participant-chip ${selected.includes(person.participant_id) ? 'selected' : ''}`} onClick={() => togglePerson(person.participant_id)}><Avatar name={person.display_name} tone={['mint', 'lavender', 'peach', 'blue'][index % 4]}/><span>{person.display_name}{person.kind === 'self' ? ' (you)' : ''}</span>{selected.includes(person.participant_id) && <Check size={14}/>}</button>)}</div>{people.length <= 1 && <div className="inline-hint">Add people in <b>People</b> before splitting this expense.</div>}<div className="split-title"><div className="form-field-label">Split it <small>Review each share before saving.</small></div><div className="split-segment">{[['equal', 'Equal'], ['exact', 'Exact'], ['percentage', '%'], ['shares', 'Shares']].map(([id, label]) => <button type="button" key={id} onClick={() => setSplit(id)} className={splitType === id ? 'chosen' : ''}>{label}</button>)}</div></div>{splitType !== 'equal' && <div className="split-input-list">{participants.map((person) => <label key={person.participant_id}><span>{person.display_name}</span><div><input type="number" min="0" step={splitType === 'shares' ? '1' : '0.01'} value={raw[person.participant_id] ?? (splitType === 'shares' ? 1 : '')} onChange={(event) => setRaw((prev) => ({ ...prev, [person.participant_id]: event.target.value }))}/><small>{splitType === 'exact' ? '₹' : splitType === 'percentage' ? '%' : 'shares'}</small></div></label>)}</div>}<div className={`split-preview ${valid ? '' : 'preview-invalid'}`}><span>Split preview <small>{participants.length} people · {splitType}</small></span><b>{amount(amountPaise)}</b>{participants.length > 0 && <div className="preview-shares">{participants.map((person, index) => <span key={person.participant_id}>{person.display_name}: <b>{amount(previewShare(person, index))}</b></span>)}</div>}{splitType === 'exact' && <small className="validation-hint">Assigned {amount(exactTotal)} of {amount(amountPaise)}</small>}{splitType === 'percentage' && <small className="validation-hint">Total {percentageTotal.toFixed(2)}% (must equal 100%)</small>}</div>{error && <Notice>{error}</Notice>}<footer className="modal-footer"><button type="button" className="text-button" onClick={close}>Cancel</button><button className="button button-primary" disabled={!valid || busy || membersLoading}>{busy ? 'Saving…' : editingExpense ? 'Save changes' : 'Save expense'}<ArrowRight size={15}/></button></footer></form>
}

function PersonForm({ busy, onSave, close }) {
  const [name, setName] = useState(''); const [phone, setPhone] = useState(''); const [error, setError] = useState('')
  function submit(event) { event.preventDefault(); if (phone.replace(/\D/g, '').length < 10) return setError('Enter a valid phone number.'); onSave(name.trim(), phone.trim()) }
  return <form className="modal-content" onSubmit={submit}><p className="modal-description">Add someone you share expenses with. Their phone number helps match them if they join Settl later.</p><label>Name<input value={name} onChange={(event) => setName(event.target.value)} placeholder="e.g. Aanya Mehta" required autoFocus/></label><label>Phone number<input value={phone} onChange={(event) => setPhone(event.target.value)} placeholder="+91 98765 43210" required/></label>{error && <Notice>{error}</Notice>}<div className="modal-footer"><button type="button" className="text-button" onClick={close}>Cancel</button><button className="button button-primary" disabled={busy || !name.trim()}>{busy ? 'Adding…' : 'Add person'}<ArrowRight size={15}/></button></div></form>
}

function CollectionForm({ people, busy, onSave, close }) {
  const [name, setName] = useState(''); const [selected, setSelected] = useState([])
  return <form className="modal-content" onSubmit={(event) => { event.preventDefault(); onSave(name.trim(), selected) }}><p className="modal-description">A shared space for your flatmates, family, or the next trip. You can add people now or later.</p><label>Collection name<input value={name} onChange={(event) => setName(event.target.value)} placeholder="e.g. Goa weekend" required autoFocus/></label>{people.filter((person) => person.kind !== 'self').length > 0 && <div><div className="form-field-label">Add people <small>Optional</small></div><div className="participant-picker">{people.filter((person) => person.kind !== 'self').map((person) => <button type="button" key={person.participant_id} className={`participant-chip ${selected.includes(person.participant_id) ? 'selected' : ''}`} onClick={() => setSelected((prev) => prev.includes(person.participant_id) ? prev.filter((id) => id !== person.participant_id) : [...prev, person.participant_id])}><Avatar name={person.display_name} tone="lavender"/><span>{person.display_name}</span>{selected.includes(person.participant_id) && <Check size={14}/>}</button>)}</div></div>}<div className="modal-footer"><button type="button" className="text-button" onClick={close}>Cancel</button><button className="button button-primary" disabled={busy || !name.trim()}>{busy ? 'Creating…' : 'Create collection'}<ArrowRight size={15}/></button></div></form>
}
