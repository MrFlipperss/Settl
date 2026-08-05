import { useState, useRef, type CSSProperties } from "react"

type Mode = "light" | "dark"
type NavTab = "activity" | "home" | "profile"
type ProfileTab = "overview" | "groups" | "receipts" | "tickets"
type ActivityTab = "transactions" | "budgets"

interface AccentPreset {
  name: string
  hex: string // display swatch
  light: { primary: string; container: string; onContainer: string }
  dark:  { primary: string; container: string; onContainer: string }
}

// 6 accent options — all perceptually muted, pleasant
const ACCENT_PRESETS: AccentPreset[] = [
  { name: "Violet",  hex: "#8B5CF6", light: { primary: "#7B5EA7", container: "#EDE9FE", onContainer: "#2E1065" }, dark:  { primary: "#C4B5FD", container: "#3D2570", onContainer: "#EDE9FE" } },
  { name: "Blue",    hex: "#60A5FA", light: { primary: "#4A7AB5", container: "#DBEAFE", onContainer: "#1E3A5F" }, dark:  { primary: "#93C5FD", container: "#1A3A6E", onContainer: "#DBEAFE" } },
  { name: "Teal",    hex: "#2DD4BF", light: { primary: "#3A8E8A", container: "#CCFBF1", onContainer: "#134E4A" }, dark:  { primary: "#5EEAD4", container: "#0E4A48", onContainer: "#CCFBF1" } },
  { name: "Emerald", hex: "#34D399", light: { primary: "#3A8C65", container: "#D1FAE5", onContainer: "#064E3B" }, dark:  { primary: "#6EE7B7", container: "#0A4A30", onContainer: "#D1FAE5" } },
  { name: "Indigo",  hex: "#818CF8", light: { primary: "#5B68C0", container: "#E0E7FF", onContainer: "#1E1B4B" }, dark:  { primary: "#C7D2FE", container: "#252D75", onContainer: "#E0E7FF" } },
  { name: "Orange",  hex: "#F97316", light: { primary: "#C4673A", container: "#FFEDD5", onContainer: "#431407" }, dark:  { primary: "#FCA87A", container: "#5C2510", onContainer: "#FFEDD5" } },
  { name: "Rose",    hex: "#FB7185", light: { primary: "#A8455E", container: "#FFDAD6", onContainer: "#410001" }, dark:  { primary: "#FCA5A5", container: "#5C1828", onContainer: "#FFE4E6" } },
]

interface Person { name: string; amount: number; upi: string; initials: string; color: string }

const PEOPLE: Person[] = [
  { name: "Arjun", amount: -450,  upi: "arjun@oksbi",  initials: "AR", color: "#9B7EBD" },
  { name: "Priya", amount: 1200,  upi: "priya@upi",    initials: "PR", color: "#7C9BBF" },
  { name: "Rahul", amount: -800,  upi: "rahul@okaxis", initials: "RK", color: "#5BA8A0" },
  { name: "Sneha", amount: 350,   upi: "sneha@ybl",    initials: "SM", color: "#B07DA0" },
  { name: "Dev",   amount: -200,  upi: "dev@paytm",    initials: "DV", color: "#6B9E8A" },
  { name: "Meera", amount: 650,   upi: "meera@upi",    initials: "MK", color: "#8E7BB5" },
]

const CATEGORIES = [
  { name: "Food",    spent: 3840, budget: 5000, color: "#E08060", icon: "food"    },
  { name: "Travel",  spent: 2100, budget: 3000, color: "#60A8C8", icon: "travel"  },
  { name: "Grocery", spent: 4200, budget: 4000, color: "#70B870", icon: "grocery" },
  { name: "Bills",   spent: 2800, budget: 3500, color: "#9880CC", icon: "bills"   },
  { name: "Fun",     spent: 1340, budget: 2000, color: "#CC8080", icon: "fun"     },
]

const TRANSACTIONS = [
  { merchant: "Swiggy",     amount: -480,  date: "Today",     category: "Food",    icon: "food"    },
  { merchant: "Ola Cabs",   amount: -220,  date: "Today",     category: "Travel",  icon: "travel"  },
  { merchant: "Salary",     amount: 52000, date: "Yesterday", category: "Income",  icon: "income"  },
  { merchant: "BigBasket",  amount: -1340, date: "Yesterday", category: "Grocery", icon: "grocery" },
  { merchant: "BookMyShow", amount: -660,  date: "Jul 22",    category: "Fun",     icon: "fun"     },
  { merchant: "Zepto",      amount: -195,  date: "Jul 20",    category: "Grocery", icon: "grocery" },
]

const GROUPS = [
  { name: "Goa Trip 2024", members: 5,  balance: 1200, icon: "beach"  },
  { name: "Flat Expenses", members: 3,  balance: -340, icon: "home"   },
  { name: "Office Lunch",  members: 8,  balance: 560,  icon: "food"   },
  { name: "Wedding Pool",  members: 12, balance: 0,    icon: "people" },
]

const RECEIPTS = [
  { merchant: "Swiggy",     amount: 480,  date: "Jul 30", category: "Food"          },
  { merchant: "Ola Cabs",   amount: 220,  date: "Jul 28", category: "Travel"        },
  { merchant: "BigBasket",  amount: 1340, date: "Jul 26", category: "Groceries"     },
  { merchant: "BookMyShow", amount: 660,  date: "Jul 22", category: "Entertainment" },
  { merchant: "Zepto",      amount: 195,  date: "Jul 20", category: "Groceries"     },
]

const TICKETS = [
  { event: "Coldplay Mumbai",    date: "Jan 18, 2025", venue: "DY Patil Stadium",      status: "confirmed" },
  { event: "IPL Final",          date: "May 25, 2025", venue: "Narendra Modi Stadium", status: "pending"   },
  { event: "Lollapalooza India", date: "Mar 8, 2025",  venue: "Mahalaxmi Racecourse",  status: "confirmed" },
]

const QR_CELLS = [
  [1,1,1,1,1,1,1,0,1,0,1,1,0,0,1,1,1,1,1,1,1],[1,0,0,0,0,0,1,0,0,1,0,0,1,0,1,0,0,0,0,0,1],
  [1,0,1,1,1,0,1,0,1,0,0,1,0,0,1,0,1,1,1,0,1],[1,0,1,1,1,0,1,0,0,1,1,0,0,0,1,0,1,1,1,0,1],
  [1,0,1,1,1,0,1,0,1,1,0,0,1,0,1,0,1,1,1,0,1],[1,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,1],
  [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],[0,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0,0,0],
  [1,0,1,1,0,1,1,1,0,1,1,0,1,1,0,1,0,1,1,0,1],[0,1,0,0,1,0,0,0,1,0,0,1,0,0,1,0,1,0,0,1,0],
  [1,0,0,1,0,1,0,1,0,1,1,0,1,0,0,1,0,0,1,0,1],[0,1,1,0,0,0,1,0,1,1,0,0,1,0,1,1,0,1,0,0,0],
  [1,1,0,0,1,1,0,0,0,1,0,1,0,0,0,0,1,0,0,1,1],[0,0,0,0,0,0,0,0,1,0,1,1,0,0,1,0,0,1,0,0,0],
  [1,1,1,1,1,1,1,0,0,1,1,0,0,0,1,0,1,0,1,1,0],[1,0,0,0,0,0,1,0,1,0,0,1,0,0,0,1,0,0,1,0,1],
  [1,0,1,1,1,0,1,0,0,1,1,0,1,0,1,0,1,0,0,1,0],[1,0,1,1,1,0,1,0,1,0,0,1,0,1,0,1,0,1,1,0,0],
  [1,0,1,1,1,0,1,0,0,1,1,0,1,0,1,0,0,0,1,0,1],[1,0,0,0,0,0,1,0,1,1,0,1,0,0,0,1,0,1,0,0,0],
  [1,1,1,1,1,1,1,0,0,0,1,0,1,0,1,0,1,0,1,1,1],
]

// ── SVG icon set ──────────────────────────────────────────────────────────────
function Icon({ id, size = 18, color = "currentColor" }: { id: string; size?: number; color?: string }) {
  const s = { width: size, height: size, fill: "none", stroke: color, strokeWidth: 1.8, strokeLinecap: "round" as const, strokeLinejoin: "round" as const }
  switch (id) {
    case "food":    return <svg {...s} viewBox="0 0 24 24"><path d="M18 8h1a4 4 0 0 1 0 8h-1"/><path d="M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"/><line x1="6" y1="1" x2="6" y2="4"/><line x1="10" y1="1" x2="10" y2="4"/><line x1="14" y1="1" x2="14" y2="4"/></svg>
    case "travel":  return <svg {...s} viewBox="0 0 24 24"><rect x="1" y="3" width="15" height="13" rx="2"/><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>
    case "grocery": return <svg {...s} viewBox="0 0 24 24"><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"/></svg>
    case "bills":   return <svg {...s} viewBox="0 0 24 24"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
    case "fun":     return <svg {...s} viewBox="0 0 24 24"><rect x="2" y="2" width="20" height="20" rx="2.18" ry="2.18"/><line x1="7" y1="2" x2="7" y2="22"/><line x1="17" y1="2" x2="17" y2="22"/><line x1="2" y1="12" x2="22" y2="12"/><line x1="2" y1="7" x2="7" y2="7"/><line x1="2" y1="17" x2="7" y2="17"/><line x1="17" y1="17" x2="22" y2="17"/><line x1="17" y1="7" x2="22" y2="7"/></svg>
    case "income":  return <svg {...s} viewBox="0 0 24 24"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
    case "home":    return <svg {...s} viewBox="0 0 24 24"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
    case "beach":   return <svg {...s} viewBox="0 0 24 24"><path d="M17.5 8a5.5 5.5 0 1 0-11 0"/><path d="M3 19l4-9 5 4 4-7 5 12H3z"/></svg>
    case "people":  return <svg {...s} viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
    case "activity":return <svg {...s} viewBox="0 0 24 24"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>
    case "profile": return <svg {...s} viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
    case "settings":return <svg {...s} viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
    case "logout":  return <svg {...s} viewBox="0 0 24 24"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
    case "receipt": return <svg {...s} viewBox="0 0 24 24"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
    case "ticket":  return <svg {...s} viewBox="0 0 24 24"><path d="M15 5v2m0 4v2m0 4v2M5 5h14a2 2 0 0 1 2 2v3a2 2 0 0 0 0 4v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-3a2 2 0 0 0 0-4V7a2 2 0 0 1 2-2z"/></svg>
    case "close":   return <svg {...s} viewBox="0 0 24 24"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
    case "chevron": return <svg {...s} viewBox="0 0 24 24"><polyline points="9 18 15 12 9 6"/></svg>
    case "plus":    return <svg {...s} viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
    case "qr":      return <svg {...s} viewBox="0 0 24 24"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg>
    case "share":   return <svg {...s} viewBox="0 0 24 24"><circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/><line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>
    case "check":   return <svg {...s} viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
    default:        return <svg {...s} viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>
  }
}

function QRCode({ fg, bg }: { fg: string; bg: string }) {
  return (
    <div style={{ background: bg, padding: 12, borderRadius: 8, display: "inline-block" }}>
      {QR_CELLS.map((row, i) => (
        <div key={i} style={{ display: "flex" }}>
          {row.map((cell, j) => (
            <div key={j} style={{ width: 7, height: 7, background: cell ? fg : "transparent", borderRadius: cell ? 1 : 0 }} />
          ))}
        </div>
      ))}
    </div>
  )
}

interface Tokens {
  bg: string; cardBg: string; surfaceVariant: string
  onSurface: string; onSurfaceVar: string
  primary: string; container: string; onContainer: string
  border: string; navBg: string; navBorder: string; shadow: string
  glassInner: string; headerBg: string
}

function getTokens(accent: AccentPreset, mode: Mode): Tokens {
  const dark = mode === "dark"
  const a = dark ? accent.dark : accent.light
  // muted header bg — a desaturated tint of primary
  const headerBg = dark ? a.container : a.primary
  return dark ? {
    bg: "#0f0f13", cardBg: "#1c1b20", surfaceVariant: "#25232c",
    onSurface: "#e2dde8", onSurfaceVar: "#8a8494",
    primary: a.primary, container: a.container, onContainer: a.onContainer,
    border: "#2a2832",
    navBg: "rgba(20,19,26,0.78)",
    navBorder: "rgba(255,255,255,0.09)",
    shadow: "rgba(0,0,0,0.5)",
    glassInner: "rgba(255,255,255,0.05)",
    headerBg,
  } : {
    bg: "#f0eef6", cardBg: "#ffffff", surfaceVariant: "#e8e4f0",
    onSurface: "#1c1a24", onSurfaceVar: "#7a7488",
    primary: a.primary, container: a.container, onContainer: a.onContainer,
    border: "#e2ddf0",
    navBg: "rgba(252,250,255,0.68)",
    navBorder: "rgba(255,255,255,0.6)",
    shadow: "rgba(80,60,140,0.12)",
    glassInner: "rgba(255,255,255,0.55)",
    headerBg,
  }
}

function SpendingRing({ spent, budget }: { spent: number; budget: number }) {
  const pct = Math.min(spent / budget, 1)
  const r = 34, cx = 40, cy = 40, stroke = 6, circ = 2 * Math.PI * r
  return (
    <svg width={80} height={80} style={{ transform: "rotate(-90deg)" }}>
      <circle cx={cx} cy={cy} r={r} fill="none" stroke="rgba(255,255,255,0.15)" strokeWidth={stroke} />
      <circle cx={cx} cy={cy} r={r} fill="none" stroke="rgba(255,255,255,0.85)"
        strokeWidth={stroke} strokeLinecap="round"
        strokeDasharray={`${pct * circ} ${circ}`}
        style={{ transition: "stroke-dasharray 0.6s ease" }}
      />
    </svg>
  )
}

// ── Calculator ────────────────────────────────────────────────────────────────
const CALC_ROWS = [["C","±","%","÷"],["7","8","9","×"],["4","5","6","−"],["1","2","3","+"],[" 0",".","⌫","="]]

function Calculator({ t }: { t: Tokens }) {
  const [display, setDisplay] = useState("0")
  const [prev, setPrev]       = useState<number | null>(null)
  const [op, setOp]           = useState<string | null>(null)
  const [fresh, setFresh]     = useState(false)

  const press = (key: string) => {
    const k = key.trim()
    if (k === "C")  { setDisplay("0"); setPrev(null); setOp(null); setFresh(false); return }
    if (k === "⌫")  { setDisplay(d => d.length > 1 ? d.slice(0,-1) : "0"); return }
    if (k === "±")  { setDisplay(d => d.startsWith("-") ? d.slice(1) : "-" + d); return }
    if (k === "%")  { setDisplay(d => String(parseFloat(d) / 100)); return }
    if (["÷","×","−","+"].includes(k)) { setPrev(parseFloat(display)); setOp(k); setFresh(true); return }
    if (k === "=") {
      if (prev === null || !op) return
      const cur = parseFloat(display)
      const res = op === "÷" ? prev/cur : op === "×" ? prev*cur : op === "−" ? prev-cur : prev+cur
      setDisplay(String(parseFloat(res.toFixed(8)))); setPrev(null); setOp(null); setFresh(false); return
    }
    if (k === ".") { if (display.includes(".") && !fresh) return; setDisplay(fresh ? "0." : display+"."); setFresh(false); return }
    setDisplay(fresh ? k : display === "0" ? k : display+k); setFresh(false)
  }

  const isOp = (k: string) => ["÷","×","−","+"].includes(k.trim())
  const btn = (key: string) => {
    const k = key.trim(); const op2 = isOp(k); const eq = k === "="; const cl = ["C","±","%","⌫"].includes(k)
    return (
      <button key={key} onClick={() => press(key)} style={{
        background: eq || op2 ? t.container : t.surfaceVariant,
        color: eq || op2 ? t.onContainer : cl ? t.onSurfaceVar : t.onSurface,
        border: "none", borderRadius: 16, padding: "10px 0", fontSize: 15,
        fontWeight: eq || op2 ? 600 : 400, cursor: "pointer",
        fontFamily: "'Roboto', sans-serif", transition: "filter 0.1s",
      }}
        onMouseDown={e => (e.currentTarget.style.filter = "brightness(0.88)")}
        onMouseUp={e => (e.currentTarget.style.filter = "none")}
        onMouseLeave={e => (e.currentTarget.style.filter = "none")}
      >{k}</button>
    )
  }
  return (
    <div style={{ background: t.cardBg, borderRadius: 20, padding: 12, marginBottom: 16, border: `1px solid ${t.border}`, animation: "expandDown 0.22s cubic-bezier(.4,0,.2,1)" }}>
      <div style={{ textAlign: "right", fontSize: 30, fontWeight: 300, color: t.onSurface, padding: "4px 8px 10px", fontFamily: "'Roboto', sans-serif", letterSpacing: -1 }}>{display}</div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 6, marginBottom: 6 }}>{CALC_ROWS.slice(0,4).flat().map(k => btn(k))}</div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 6 }}>{CALC_ROWS[4].map(k => btn(k))}</div>
    </div>
  )
}

// ── Settings sheet ────────────────────────────────────────────────────────────
function SettingsSheet({ t, mode, setMode, accentIdx, setAccentIdx, onClose }: {
  t: Tokens; mode: Mode; setMode: (m: Mode) => void
  accentIdx: number; setAccentIdx: (i: number) => void; onClose: () => void
}) {
  const [emailNotif, setEmailNotif] = useState(true)
  const [pushNotif,  setPushNotif]  = useState(true)

  const Toggle = ({ on, toggle }: { on: boolean; toggle: () => void }) => (
    <button onClick={toggle} style={{ width: 50, height: 30, borderRadius: 100, border: "none", cursor: "pointer", background: on ? t.primary : t.surfaceVariant, position: "relative", transition: "background 0.2s", flexShrink: 0 }}>
      <div style={{ position: "absolute", top: 4, left: on ? 24 : 4, width: 22, height: 22, borderRadius: "50%", background: on ? "#fff" : t.onSurfaceVar, transition: "left 0.2s cubic-bezier(.4,0,.2,1)" }} />
    </button>
  )

  const Row = ({ iconId, label, sub, right }: { iconId: string; label: string; sub?: string; right?: React.ReactNode }) => (
    <div style={{ display: "flex", alignItems: "center", gap: 14, padding: "13px 16px", background: t.cardBg, borderRadius: 18, marginBottom: 8, border: `1px solid ${t.border}` }}>
      <div style={{ width: 36, height: 36, borderRadius: 12, background: t.surfaceVariant, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
        <Icon id={iconId} size={18} color={t.onSurfaceVar} />
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 14, color: t.onSurface, fontWeight: 500, fontFamily: "'Roboto', sans-serif" }}>{label}</div>
        {sub && <div style={{ fontSize: 12, color: t.onSurfaceVar, marginTop: 1, fontFamily: "'Roboto', sans-serif" }}>{sub}</div>}
      </div>
      {right ?? <Icon id="chevron" size={16} color={t.onSurfaceVar} />}
    </div>
  )

  const SecLabel = ({ label }: { label: string }) => (
    <div style={{ fontSize: 11, fontWeight: 700, color: t.primary, letterSpacing: 1, textTransform: "uppercase", marginTop: 20, marginBottom: 8, paddingLeft: 4, fontFamily: "'Roboto', sans-serif" }}>{label}</div>
  )

  return (
    <div style={{ position: "fixed", inset: 0, zIndex: 600, display: "flex", alignItems: "flex-end", justifyContent: "center" }} onClick={onClose}>
      <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.48)", backdropFilter: "blur(4px)", animation: "fadeIn 0.2s ease" }} />
      <div style={{ position: "relative", background: t.bg, borderRadius: "28px 28px 0 0", width: "100%", maxWidth: 430, maxHeight: "88dvh", overflowY: "auto", boxShadow: "0 -8px 40px rgba(0,0,0,0.22)", animation: "slideUp 0.3s cubic-bezier(.4,0,.2,1)", padding: "0 16px 48px" }}
        onClick={e => e.stopPropagation()}>
        <div style={{ width: 36, height: 4, borderRadius: 2, background: t.border, margin: "12px auto 4px" }} />
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "14px 0 18px" }}>
          <span style={{ fontSize: 20, fontWeight: 600, color: t.onSurface, fontFamily: "'Roboto', sans-serif" }}>Settings</span>
          <button onClick={onClose} style={{ background: t.surfaceVariant, border: "none", borderRadius: "50%", width: 32, height: 32, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", color: t.onSurfaceVar }}>
            <Icon id="close" size={16} color={t.onSurfaceVar} />
          </button>
        </div>

        <SecLabel label="Appearance" />
        <div style={{ background: t.cardBg, borderRadius: 18, padding: "14px 16px", marginBottom: 8, border: `1px solid ${t.border}` }}>
          <div style={{ fontSize: 14, color: t.onSurface, fontWeight: 500, marginBottom: 12, fontFamily: "'Roboto', sans-serif" }}>Theme</div>
          <div style={{ display: "flex", gap: 8 }}>
            {(["light","dark"] as Mode[]).map(m => {
              const active = mode === m
              return (
                <button key={m} onClick={() => setMode(m)} style={{ flex: 1, padding: "10px", borderRadius: 14, border: `2px solid ${active ? t.primary : t.border}`, background: active ? t.container : "transparent", color: active ? t.onContainer : t.onSurfaceVar, cursor: "pointer", fontFamily: "'Roboto', sans-serif", fontSize: 13, fontWeight: 500, transition: "all 0.18s", display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
                  <Icon id={m === "light" ? "bills" : "fun"} size={20} color={active ? t.onContainer : t.onSurfaceVar} />
                  <span>{m === "light" ? "Light" : "Dark"}</span>
                </button>
              )
            })}
          </div>
        </div>
        <div style={{ background: t.cardBg, borderRadius: 18, padding: "14px 16px", marginBottom: 8, border: `1px solid ${t.border}` }}>
          <div style={{ fontSize: 14, color: t.onSurface, fontWeight: 500, marginBottom: 12, fontFamily: "'Roboto', sans-serif" }}>Accent colour</div>
          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
            {ACCENT_PRESETS.map((preset, i) => {
              const active = accentIdx === i
              return (
                <button key={preset.name} onClick={() => setAccentIdx(i)} title={preset.name} style={{ width: 38, height: 38, borderRadius: "50%", background: preset.hex, border: active ? `3px solid ${t.onSurface}` : "3px solid transparent", outline: active ? `2px solid ${preset.hex}` : "none", outlineOffset: 2, cursor: "pointer", transition: "all 0.15s" }} />
              )
            })}
          </div>
          <div style={{ marginTop: 10, fontSize: 12, color: t.onSurfaceVar, fontFamily: "'Roboto', sans-serif" }}>{ACCENT_PRESETS[accentIdx].name}</div>
        </div>

        <SecLabel label="Notifications" />
        <Row iconId="receipt" label="Email notifications" sub="Reminders and due alerts" right={<Toggle on={emailNotif} toggle={() => setEmailNotif(!emailNotif)} />} />
        <Row iconId="activity" label="Push notifications" sub="Real-time payment updates" right={<Toggle on={pushNotif} toggle={() => setPushNotif(!pushNotif)} />} />

        <SecLabel label="Account" />
        <Row iconId="receipt" label="Email" sub="rahul.sharma@gmail.com" />
        <Row iconId="people" label="Phone" sub="+91 98765 43210" />
        <Row iconId="settings" label="Privacy & data" />

        <SecLabel label="Session" />
        <button style={{ width: "100%", marginTop: 4, padding: "14px 16px", borderRadius: 18, border: "none", background: "#ef444416", color: "#d85050", cursor: "pointer", fontFamily: "'Roboto', sans-serif", fontSize: 14, fontWeight: 600, display: "flex", alignItems: "center", justifyContent: "center", gap: 10, transition: "background 0.15s" }}
          onMouseEnter={e => (e.currentTarget.style.background = "#ef444428")}
          onMouseLeave={e => (e.currentTarget.style.background = "#ef444416")}
        >
          <Icon id="logout" size={17} color="#d85050" />
          Log out
        </button>
        <div style={{ marginTop: 28, textAlign: "center", fontSize: 11, color: t.onSurfaceVar, fontFamily: "'Roboto', sans-serif" }}>SplitKaro v2.4.1 · Made with ♥</div>
      </div>
    </div>
  )
}

// ── Profile page ──────────────────────────────────────────────────────────────
function ProfilePage({ t, onOpenSettings }: { t: Tokens; onOpenSettings: () => void }) {
  const [tab, setTab] = useState<ProfileTab>("overview")
  const TABS: { id: ProfileTab; label: string; icon: string }[] = [
    { id: "overview", label: "Overview", icon: "home"    },
    { id: "groups",   label: "Groups",   icon: "people"  },
    { id: "receipts", label: "Receipts", icon: "receipt" },
    { id: "tickets",  label: "Tickets",  icon: "ticket"  },
  ]

  return (
    <div style={{ position: "relative" }}>
      {/* Header */}
      <div style={{ background: t.headerBg, padding: "52px 20px 72px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "absolute", top: -50, right: -40, width: 200, height: 200, borderRadius: "50%", background: "rgba(255,255,255,0.05)" }} />
        <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
          <div style={{ width: 56, height: 56, borderRadius: "50%", background: "rgba(255,255,255,0.2)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20, fontWeight: 700, color: "#fff", fontFamily: "'Roboto', sans-serif", flexShrink: 0 }}>RS</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 19, fontWeight: 600, color: "#fff", fontFamily: "'Roboto', sans-serif" }}>Rahul Sharma</div>
            <div style={{ fontSize: 12, color: "rgba(255,255,255,0.65)", marginTop: 2, fontFamily: "'Roboto', sans-serif" }}>rahul@okaxis · UPI active</div>
          </div>
          <div style={{ textAlign: "right" }}>
            <div style={{ fontSize: 11, color: "rgba(255,255,255,0.55)", fontFamily: "'Roboto', sans-serif" }}>Net balance</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: "#fff", fontFamily: "'Roboto', sans-serif" }}>+₹1,950</div>
          </div>
        </div>
      </div>
      {/* Gear button — above the foreground card via zIndex */}
      <button onClick={onOpenSettings} style={{ position: "absolute", top: 14, right: 14, zIndex: 10, width: 34, height: 34, borderRadius: "50%", background: "rgba(255,255,255,0.18)", border: "none", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", transition: "background 0.15s" }}
        onMouseEnter={e => (e.currentTarget.style.background = "rgba(255,255,255,0.28)")}
        onMouseLeave={e => (e.currentTarget.style.background = "rgba(255,255,255,0.18)")}
      >
        <Icon id="settings" size={16} color="#fff" />
      </button>

      {/* Foreground card — rounded TOP corners overlap header */}
      <div style={{ background: t.cardBg, borderRadius: "28px 28px 0 0", marginTop: -28, padding: "20px 16px 0", position: "relative", zIndex: 1, minHeight: "100dvh" }}>
        {/* Tab bar */}
        <div style={{ display: "flex", gap: 6, marginBottom: 20, overflowX: "auto", paddingBottom: 2 }}>
          {TABS.map(tb => (
            <button key={tb.id} onClick={() => setTab(tb.id)} style={{ flexShrink: 0, display: "flex", alignItems: "center", gap: 6, padding: "8px 16px", borderRadius: 100, border: "none", background: tab === tb.id ? t.container : t.surfaceVariant, color: tab === tb.id ? t.onContainer : t.onSurfaceVar, cursor: "pointer", fontFamily: "'Roboto', sans-serif", fontSize: 13, fontWeight: tab === tb.id ? 600 : 400, transition: "all 0.18s" }}>
              <Icon id={tb.icon} size={14} color={tab === tb.id ? t.onContainer : t.onSurfaceVar} />
              {tb.label}
            </button>
          ))}
        </div>

        {tab === "overview" && (
          <div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 18 }}>
              {[
                { label: "You owe",      value: "₹1,450", color: "#c0504a" },
                { label: "Owed to you",  value: "₹3,400", color: "#4a9060" },
                { label: "Groups",       value: "4",       color: t.primary },
                { label: "Transactions", value: "38",      color: t.primary },
              ].map(stat => (
                <div key={stat.label} style={{ background: t.cardBg, borderRadius: 18, padding: "14px 16px", border: `1px solid ${t.border}` }}>
                  <div style={{ fontSize: 11, color: t.onSurfaceVar, fontFamily: "'Roboto', sans-serif", marginBottom: 6 }}>{stat.label}</div>
                  <div style={{ fontSize: 22, fontWeight: 700, color: stat.color, fontFamily: "'Roboto', sans-serif" }}>{stat.value}</div>
                </div>
              ))}
            </div>
            <div style={{ fontSize: 11, fontWeight: 700, color: t.primary, letterSpacing: 1, textTransform: "uppercase", marginBottom: 10, paddingLeft: 2, fontFamily: "'Roboto', sans-serif" }}>Recent activity</div>
            {PEOPLE.slice(0,4).map(p => (
              <div key={p.name} style={{ display: "flex", alignItems: "center", gap: 12, padding: "11px 14px", background: t.cardBg, borderRadius: 16, marginBottom: 6, border: `1px solid ${t.border}` }}>
                <div style={{ width: 36, height: 36, borderRadius: "50%", background: p.color, color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, fontWeight: 700, flexShrink: 0 }}>{p.initials}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 500, color: t.onSurface, fontFamily: "'Roboto', sans-serif" }}>{p.name}</div>
                  <div style={{ fontSize: 11, color: t.onSurfaceVar, fontFamily: "'Roboto', sans-serif" }}>{p.upi}</div>
                </div>
                <span style={{ fontSize: 14, fontWeight: 700, color: p.amount > 0 ? "#4a9060" : "#c0504a", fontFamily: "'Roboto', sans-serif" }}>
                  {p.amount > 0 ? "+" : ""}₹{Math.abs(p.amount).toLocaleString("en-IN")}
                </span>
              </div>
            ))}
          </div>
        )}

        {tab === "groups" && (
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            {GROUPS.map(g => (
              <div key={g.name} style={{ background: t.cardBg, borderRadius: 18, padding: "14px 16px", display: "flex", alignItems: "center", gap: 12, border: `1px solid ${t.border}` }}>
                <div style={{ width: 42, height: 42, borderRadius: 14, background: t.container, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <Icon id={g.icon} size={20} color={t.onContainer} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 500, color: t.onSurface, fontFamily: "'Roboto', sans-serif" }}>{g.name}</div>
                  <div style={{ fontSize: 11, color: t.onSurfaceVar, marginTop: 2, fontFamily: "'Roboto', sans-serif" }}>{g.members} members</div>
                </div>
                <div style={{ fontSize: 14, fontWeight: 700, color: g.balance > 0 ? "#4a9060" : g.balance < 0 ? "#c0504a" : t.onSurfaceVar, fontFamily: "'Roboto', sans-serif" }}>
                  {g.balance === 0 ? "Settled" : `${g.balance > 0 ? "+" : ""}₹${Math.abs(g.balance).toLocaleString("en-IN")}`}
                </div>
              </div>
            ))}
          </div>
        )}

        {tab === "receipts" && (
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            {RECEIPTS.map((r, i) => (
              <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 16px", background: t.cardBg, borderRadius: 16, border: `1px solid ${t.border}` }}>
                <div style={{ width: 38, height: 38, borderRadius: 12, background: t.container, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                  <Icon id="receipt" size={16} color={t.onContainer} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 500, color: t.onSurface, fontFamily: "'Roboto', sans-serif" }}>{r.merchant}</div>
                  <div style={{ fontSize: 11, color: t.onSurfaceVar, marginTop: 2, fontFamily: "'Roboto', sans-serif" }}>{r.category} · {r.date}</div>
                </div>
                <div style={{ fontSize: 14, fontWeight: 700, color: t.onSurface, fontFamily: "'Roboto', sans-serif" }}>₹{r.amount}</div>
              </div>
            ))}
          </div>
        )}

        {tab === "tickets" && (
          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {TICKETS.map((tk, i) => (
              <div key={i} style={{ background: t.cardBg, borderRadius: 20, overflow: "hidden", border: `1px solid ${t.border}` }}>
                <div style={{ padding: "14px 16px", background: t.headerBg }}>
                  <div style={{ fontSize: 15, fontWeight: 600, color: "#fff", fontFamily: "'Roboto', sans-serif" }}>{tk.event}</div>
                  <div style={{ fontSize: 11, color: "rgba(255,255,255,0.6)", marginTop: 3, fontFamily: "'Roboto', sans-serif" }}>{tk.venue}</div>
                </div>
                <div style={{ padding: "10px 16px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <div style={{ fontSize: 13, color: t.onSurface, fontFamily: "'Roboto', sans-serif" }}>{tk.date}</div>
                  <div style={{ fontSize: 11, fontWeight: 600, padding: "3px 12px", borderRadius: 100, background: tk.status === "confirmed" ? "#4a906018" : "#b0882018", color: tk.status === "confirmed" ? "#4a9060" : "#b08820", fontFamily: "'Roboto', sans-serif" }}>
                    {tk.status === "confirmed" ? "Confirmed" : "Pending"}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

// ── Add Expense Sheet ─────────────────────────────────────────────────────────
function AddExpenseSheet({ t, onClose }: { t: Tokens; onClose: () => void }) {
  const [amount, setAmount]       = useState("")
  const [description, setDescription] = useState("")
  const [category, setCategory]   = useState(CATEGORIES[0].name)
  const [date, setDate]           = useState(new Date().toISOString().split("T")[0])
  const [splitWith, setSplitWith] = useState<string[]>([])
  const [step, setStep]           = useState<"amount" | "details">("amount")

  const togglePerson = (name: string) =>
    setSplitWith(p => p.includes(name) ? p.filter(n => n !== name) : [...p, name])

  const displayAmount = amount === "" ? "0" : amount

  const handleDigit = (d: string) => {
    if (d === "." && amount.includes(".")) return
    if (d === "." && amount === "") { setAmount("0."); return }
    setAmount(a => a === "0" ? d : a + d)
  }
  const handleDel = () => setAmount(a => a.length <= 1 ? "" : a.slice(0, -1))

  const DIGITS = ["1","2","3","4","5","6","7","8","9",".","0","⌫"]

  return (
    <div style={{ position: "fixed", inset: 0, zIndex: 600, display: "flex", alignItems: "flex-end", justifyContent: "center" }} onClick={onClose}>
      <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.48)", backdropFilter: "blur(4px)", animation: "fadeIn 0.2s ease" }} />
      <div
        style={{ position: "relative", background: t.cardBg, borderRadius: "28px 28px 0 0", width: "100%", maxWidth: 430, maxHeight: "92dvh", overflowY: "auto", boxShadow: "0 -8px 40px rgba(0,0,0,0.22)", animation: "slideUp 0.3s cubic-bezier(.4,0,.2,1)", paddingBottom: 40 }}
        onClick={e => e.stopPropagation()}
      >
        {/* Handle + header */}
        <div style={{ width: 36, height: 4, borderRadius: 2, background: t.border, margin: "12px auto 0" }} />
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "14px 20px 0" }}>
          <span style={{ fontSize: 18, fontWeight: 600, color: t.onSurface, fontFamily: "'Roboto', sans-serif" }}>Add Expense</span>
          <button onClick={onClose} style={{ background: t.surfaceVariant, border: "none", borderRadius: "50%", width: 32, height: 32, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
            <Icon id="close" size={15} color={t.onSurfaceVar} />
          </button>
        </div>

        {step === "amount" && (
          <div>
            {/* Big amount display */}
            <div style={{ textAlign: "center", padding: "28px 24px 16px" }}>
              <div style={{ fontSize: 11, fontWeight: 600, color: t.onSurfaceVar, letterSpacing: 1, textTransform: "uppercase", marginBottom: 8, fontFamily: "'Roboto', sans-serif" }}>Amount</div>
              <div style={{ fontSize: 56, fontWeight: 300, color: t.onSurface, letterSpacing: -2, fontFamily: "'Roboto', sans-serif", lineHeight: 1 }}>
                <span style={{ fontSize: 28, fontWeight: 400, verticalAlign: "super", marginRight: 2, color: t.onSurfaceVar }}>₹</span>
                {displayAmount}
              </div>
            </div>

            {/* Numpad */}
            <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 8, padding: "0 20px 20px" }}>
              {DIGITS.map(d => (
                <button key={d} onClick={() => d === "⌫" ? handleDel() : handleDigit(d)}
                  style={{ height: 60, borderRadius: 18, border: "none", background: d === "⌫" ? t.surfaceVariant : t.surfaceVariant, color: d === "⌫" ? t.onSurfaceVar : t.onSurface, fontSize: d === "⌫" ? 20 : 22, fontWeight: 400, cursor: "pointer", fontFamily: "'Roboto', sans-serif", transition: "filter 0.1s", display: "flex", alignItems: "center", justifyContent: "center" }}
                  onMouseDown={e => (e.currentTarget.style.filter = "brightness(0.9)")}
                  onMouseUp={e => (e.currentTarget.style.filter = "none")}
                  onMouseLeave={e => (e.currentTarget.style.filter = "none")}
                >{d}</button>
              ))}
            </div>

            <div style={{ padding: "0 20px" }}>
              <button
                onClick={() => amount && setStep("details")}
                style={{ width: "100%", padding: "16px", borderRadius: 20, border: "none", background: amount ? t.primary : t.surfaceVariant, color: amount ? "#fff" : t.onSurfaceVar, fontSize: 16, fontWeight: 600, cursor: amount ? "pointer" : "default", fontFamily: "'Roboto', sans-serif", transition: "all 0.18s" }}
              >
                Continue
              </button>
            </div>
          </div>
        )}

        {step === "details" && (
          <div style={{ padding: "16px 20px 0" }}>
            {/* Amount summary pill */}
            <button onClick={() => setStep("amount")} style={{ display: "flex", alignItems: "center", gap: 8, background: t.container, border: "none", borderRadius: 100, padding: "8px 16px", cursor: "pointer", marginBottom: 20 }}>
              <span style={{ fontSize: 22, fontWeight: 600, color: t.onContainer, fontFamily: "'Roboto', sans-serif" }}>₹{parseFloat(amount || "0").toLocaleString("en-IN")}</span>
              <Icon id="chevron" size={14} color={t.onContainer} />
            </button>

            {/* Description */}
            <div style={{ marginBottom: 14 }}>
              <div style={{ fontSize: 11, fontWeight: 600, color: t.onSurfaceVar, letterSpacing: 1, textTransform: "uppercase", marginBottom: 8, fontFamily: "'Roboto', sans-serif" }}>Description</div>
              <input
                value={description}
                onChange={e => setDescription(e.target.value)}
                placeholder="e.g. Dinner at Smoke House"
                style={{ width: "100%", padding: "13px 16px", borderRadius: 16, border: `1.5px solid ${t.border}`, background: t.surfaceVariant, color: t.onSurface, fontSize: 14, fontFamily: "'Roboto', sans-serif", outline: "none", boxSizing: "border-box" }}
                onFocus={e => (e.target.style.borderColor = t.primary)}
                onBlur={e => (e.target.style.borderColor = t.border)}
              />
            </div>

            {/* Category */}
            <div style={{ marginBottom: 14 }}>
              <div style={{ fontSize: 11, fontWeight: 600, color: t.onSurfaceVar, letterSpacing: 1, textTransform: "uppercase", marginBottom: 8, fontFamily: "'Roboto', sans-serif" }}>Category</div>
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                {CATEGORIES.map(cat => (
                  <button key={cat.name} onClick={() => setCategory(cat.name)}
                    style={{ display: "flex", alignItems: "center", gap: 6, padding: "8px 14px", borderRadius: 100, border: "none", background: category === cat.name ? t.container : t.surfaceVariant, color: category === cat.name ? t.onContainer : t.onSurfaceVar, cursor: "pointer", fontFamily: "'Roboto', sans-serif", fontSize: 13, fontWeight: category === cat.name ? 600 : 400, transition: "all 0.15s" }}>
                    <Icon id={cat.icon} size={13} color={category === cat.name ? t.onContainer : t.onSurfaceVar} />
                    {cat.name}
                  </button>
                ))}
              </div>
            </div>

            {/* Date */}
            <div style={{ marginBottom: 14 }}>
              <div style={{ fontSize: 11, fontWeight: 600, color: t.onSurfaceVar, letterSpacing: 1, textTransform: "uppercase", marginBottom: 8, fontFamily: "'Roboto', sans-serif" }}>Date</div>
              <input type="date" value={date} onChange={e => setDate(e.target.value)}
                style={{ width: "100%", padding: "13px 16px", borderRadius: 16, border: `1.5px solid ${t.border}`, background: t.surfaceVariant, color: t.onSurface, fontSize: 14, fontFamily: "'Roboto', sans-serif", outline: "none", boxSizing: "border-box" }}
                onFocus={e => (e.target.style.borderColor = t.primary)}
                onBlur={e => (e.target.style.borderColor = t.border)}
              />
            </div>

            {/* Split with */}
            <div style={{ marginBottom: 24 }}>
              <div style={{ fontSize: 11, fontWeight: 600, color: t.onSurfaceVar, letterSpacing: 1, textTransform: "uppercase", marginBottom: 8, fontFamily: "'Roboto', sans-serif" }}>Split with</div>
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                {PEOPLE.map(p => {
                  const on = splitWith.includes(p.name)
                  return (
                    <button key={p.name} onClick={() => togglePerson(p.name)}
                      style={{ display: "flex", alignItems: "center", gap: 7, padding: "7px 14px 7px 8px", borderRadius: 100, border: `2px solid ${on ? t.primary : "transparent"}`, background: on ? t.container : t.surfaceVariant, cursor: "pointer", transition: "all 0.15s", fontFamily: "'Roboto', sans-serif", fontSize: 13, fontWeight: on ? 600 : 400, color: on ? t.onContainer : t.onSurfaceVar }}>
                      <div style={{ width: 24, height: 24, borderRadius: "50%", background: p.color, color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 9, fontWeight: 700 }}>{p.initials}</div>
                      {p.name}
                    </button>
                  )
                })}
              </div>
            </div>

            {/* Save */}
            <button onClick={onClose}
              style={{ width: "100%", padding: "16px", borderRadius: 20, border: "none", background: t.primary, color: "#fff", fontSize: 16, fontWeight: 600, cursor: "pointer", fontFamily: "'Roboto', sans-serif", boxShadow: `0 4px 16px ${t.shadow}` }}>
              Save Expense
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

// ── Main App ──────────────────────────────────────────────────────────────────
const NAV_TABS: NavTab[] = ["activity", "home", "profile"]

export default function App() {
  const [mode, setMode]           = useState<Mode>("light")
  const [accentIdx, setAccentIdx] = useState(0)
  const [activeTab, setActiveTab] = useState<NavTab>("home")
  const [activityTab, setActivityTab] = useState<ActivityTab>("transactions")
  const [showSettings, setShowSettings] = useState(false)
  const [showAddExpense, setShowAddExpense] = useState(false)
  const [selectedPerson, setSelectedPerson] = useState<Person | null>(null)
  const [showUPI, setShowUPI]     = useState(false)
  const [showCalc, setShowCalc]   = useState(false)

  const accent = ACCENT_PRESETS[accentIdx]
  const t      = getTokens(accent, mode)
  const isDark = mode === "dark"
  const SPENT  = 14280, BUDGET = 20000

  // ── Drag-to-switch on nav ─────────────────────────────────────────────────
  const dragRef = useRef({ startX: 0, active: false, moved: false })
  const onNavPD = (e: React.PointerEvent) => { dragRef.current = { startX: e.clientX, active: true, moved: false } }
  const onNavPM = (e: React.PointerEvent) => {
    if (!dragRef.current.active) return
    const delta = e.clientX - dragRef.current.startX
    if (Math.abs(delta) > 52) {
      dragRef.current.active = false; dragRef.current.moved = true
      const idx = NAV_TABS.indexOf(activeTab)
      if (delta < 0 && idx < NAV_TABS.length - 1) setActiveTab(NAV_TABS[idx + 1])
      if (delta > 0 && idx > 0)                   setActiveTab(NAV_TABS[idx - 1])
    }
  }
  const onNavPU = () => { dragRef.current.active = false }

  const txGroups = TRANSACTIONS.reduce<Record<string, typeof TRANSACTIONS>>((acc, tx) => {
    ;(acc[tx.date] ||= []).push(tx); return acc
  }, {})

  const NavBtn = ({ tab, iconId, label }: { tab: NavTab; iconId: string; label: string }) => {
    const active = activeTab === tab
    return (
      <button
        onClick={() => { if (!dragRef.current.moved) setActiveTab(tab); dragRef.current.moved = false }}
        style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 3, padding: "10px 4px 8px", border: "none", background: "none", cursor: "pointer", color: active ? t.primary : t.onSurfaceVar, transition: "color 0.18s", WebkitTapHighlightColor: "transparent" }}
      >
        <div style={{ padding: "4px 14px", borderRadius: 100, background: active ? t.container : "transparent", transition: "background 0.18s" }}>
          <Icon id={iconId} size={22} color={active ? t.primary : t.onSurfaceVar} />
        </div>
        <span style={{ fontSize: 10, fontWeight: active ? 600 : 400, fontFamily: "'Roboto', sans-serif" }}>{label}</span>
      </button>
    )
  }

  return (
    <div style={{ background: t.bg, color: t.onSurface, minHeight: "100dvh", fontFamily: "'Roboto', sans-serif", position: "relative", overflowX: "hidden" }}>
      <div style={{ maxWidth: 430, margin: "0 auto", paddingBottom: 110 }}>

        {/* ── Home ── */}
        {activeTab === "home" && (
          <div>
            {/* Colored header — square at bottom */}
            <div style={{ background: t.headerBg, padding: "52px 22px 72px", position: "relative", overflow: "hidden" }}>
              <div style={{ position: "absolute", top: -40, right: -40, width: 180, height: 180, borderRadius: "50%", background: "rgba(255,255,255,0.06)" }} />
              <div style={{ position: "absolute", bottom: 20, left: -20, width: 120, height: 120, borderRadius: "50%", background: "rgba(255,255,255,0.04)" }} />
              <div style={{ position: "relative", display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                <div>
                  <div style={{ fontSize: 13, color: "rgba(255,255,255,0.65)", fontWeight: 500, marginBottom: 6 }}>August 2024</div>
                  <div style={{ fontSize: 38, fontWeight: 700, color: "#fff", letterSpacing: -1.5, lineHeight: 1 }}>₹{SPENT.toLocaleString("en-IN")}</div>
                  <div style={{ fontSize: 13, color: "rgba(255,255,255,0.55)", marginTop: 6 }}>of ₹{BUDGET.toLocaleString("en-IN")} budget</div>
                  <div style={{ marginTop: 14, height: 4, width: 180, borderRadius: 100, background: "rgba(255,255,255,0.18)" }}>
                    <div style={{ height: "100%", width: `${(SPENT/BUDGET)*100}%`, borderRadius: 100, background: "rgba(255,255,255,0.7)" }} />
                  </div>
                  <div style={{ marginTop: 6, fontSize: 12, color: "rgba(255,255,255,0.5)" }}>₹{(BUDGET-SPENT).toLocaleString("en-IN")} remaining</div>
                </div>
                <SpendingRing spent={SPENT} budget={BUDGET} />
              </div>
            </div>

            {/* Foreground card — rounded TOP corners overlap header */}
            <div style={{ background: t.cardBg, borderRadius: "28px 28px 0 0", marginTop: -28, padding: "20px 16px 0", position: "relative", zIndex: 1, minHeight: "100dvh" }}>
              {/* Categories */}
              <div style={{ background: t.cardBg, borderRadius: 20, padding: 16, marginBottom: 14, border: `1px solid ${t.border}` }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
                  <span style={{ fontSize: 14, fontWeight: 600, color: t.onSurface }}>Spending by category</span>
                  <span style={{ fontSize: 12, color: t.primary, fontWeight: 500, cursor: "pointer" }}>See all</span>
                </div>
                {CATEGORIES.map(cat => {
                  const pct = Math.min(cat.spent / cat.budget, 1), over = cat.spent > cat.budget
                  return (
                    <div key={cat.name} style={{ marginBottom: 12 }}>
                      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 5 }}>
                        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                          <div style={{ width: 28, height: 28, borderRadius: 9, background: cat.color + "22", display: "flex", alignItems: "center", justifyContent: "center" }}>
                            <Icon id={cat.icon} size={14} color={cat.color} />
                          </div>
                          <span style={{ fontSize: 13, fontWeight: 500, color: t.onSurface }}>{cat.name}</span>
                        </div>
                        <span style={{ fontSize: 13, fontWeight: 600, color: over ? "#c0504a" : t.onSurface }}>
                          ₹{cat.spent.toLocaleString("en-IN")}<span style={{ fontWeight: 400, color: t.onSurfaceVar }}> / ₹{cat.budget.toLocaleString("en-IN")}</span>
                        </span>
                      </div>
                      <div style={{ height: 5, borderRadius: 100, background: t.surfaceVariant, overflow: "hidden" }}>
                        <div style={{ height: "100%", width: `${pct*100}%`, borderRadius: 100, background: over ? "#c0504a" : cat.color }} />
                      </div>
                    </div>
                  )
                })}
              </div>

              {/* Search + calc */}
              <div style={{ background: t.cardBg, borderRadius: 20, padding: "12px 14px", marginBottom: 14, border: `1px solid ${t.border}` }}>
                <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: showCalc ? 12 : 0 }}>
                  <Icon id="grocery" size={16} color={t.onSurfaceVar} />
                  <span style={{ flex: 1, color: t.onSurfaceVar, fontSize: 14 }}>Search expenses…</span>
                  <button onClick={() => setShowCalc(c => !c)} style={{ background: showCalc ? t.container : t.surfaceVariant, border: "none", cursor: "pointer", padding: "6px 8px", display: "flex", alignItems: "center", color: showCalc ? t.onContainer : t.onSurfaceVar, borderRadius: 10 }}>
                    <Icon id="bills" size={16} color={showCalc ? t.onContainer : t.onSurfaceVar} />
                  </button>
                </div>
                {showCalc && <Calculator t={t} />}
              </div>

              {/* Dues */}
              <div style={{ background: t.cardBg, borderRadius: 20, padding: 16, marginBottom: 14, border: `1px solid ${t.border}` }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
                  <span style={{ fontSize: 14, fontWeight: 600, color: t.onSurface }}>Dues</span>
                  <span style={{ fontSize: 12, color: t.primary, fontWeight: 500, cursor: "pointer" }}>See all</span>
                </div>
                <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
                  {PEOPLE.map(person => {
                    const owesMe = person.amount > 0, amt = Math.abs(person.amount)
                    return (
                      <button key={person.name}
                        onClick={() => { setSelectedPerson(person); setShowUPI(false) }}
                        style={{ display: "flex", alignItems: "center", gap: 10, width: "100%", background: t.surfaceVariant, borderRadius: 16, padding: "10px 12px", border: "none", cursor: "pointer", textAlign: "left", transition: "filter 0.12s" }}
                        onMouseEnter={e => (e.currentTarget.style.filter = "brightness(0.96)")}
                        onMouseLeave={e => (e.currentTarget.style.filter = "none")}
                      >
                        <div style={{ width: 36, height: 36, borderRadius: "50%", background: person.color, color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 11, fontWeight: 700, flexShrink: 0 }}>{person.initials}</div>
                        <div style={{ flex: 1 }}>
                          <div style={{ fontSize: 13, fontWeight: 500, color: t.onSurface }}>{person.name}</div>
                          <div style={{ fontSize: 11, color: t.onSurfaceVar, marginTop: 1 }}>{person.upi}</div>
                        </div>
                        <span style={{ fontSize: 13, fontWeight: 700, color: owesMe ? "#4a9060" : "#c0504a" }}>{owesMe ? "+" : "−"}₹{amt.toLocaleString("en-IN")}</span>
                      </button>
                    )
                  })}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ── Activity (Transactions + Budgets) ── */}
        {activeTab === "activity" && (
          <div>
            <div style={{ background: t.headerBg, padding: "52px 20px 72px", position: "relative", overflow: "hidden" }}>
              <div style={{ position: "absolute", top: -40, right: -40, width: 160, height: 160, borderRadius: "50%", background: "rgba(255,255,255,0.05)" }} />
              <div style={{ fontSize: 13, color: "rgba(255,255,255,0.55)", marginBottom: 6 }}>August 2024</div>
              <div style={{ fontSize: 32, fontWeight: 700, color: "#fff", letterSpacing: -1 }}>Activity</div>
            </div>

            <div style={{ background: t.cardBg, borderRadius: "28px 28px 0 0", marginTop: -28, padding: "20px 16px 0", position: "relative", zIndex: 1, minHeight: "100dvh" }}>
              {/* Sub-tab toggle */}
              <div style={{ display: "flex", gap: 6, marginBottom: 20 }}>
                {(["transactions","budgets"] as ActivityTab[]).map(at => (
                  <button key={at} onClick={() => setActivityTab(at)} style={{ flex: 1, padding: "9px 0", borderRadius: 100, border: "none", background: activityTab === at ? t.container : t.surfaceVariant, color: activityTab === at ? t.onContainer : t.onSurfaceVar, cursor: "pointer", fontFamily: "'Roboto', sans-serif", fontSize: 13, fontWeight: activityTab === at ? 600 : 400, transition: "all 0.18s", display: "flex", alignItems: "center", justifyContent: "center", gap: 6 }}>
                    <Icon id={at === "transactions" ? "activity" : "income"} size={14} color={activityTab === at ? t.onContainer : t.onSurfaceVar} />
                    {at === "transactions" ? "Transactions" : "Budgets"}
                  </button>
                ))}
              </div>

              {activityTab === "transactions" && (
                Object.entries(txGroups).map(([date, txs]) => (
                  <div key={date} style={{ marginBottom: 16 }}>
                    <div style={{ fontSize: 11, fontWeight: 600, color: t.onSurfaceVar, letterSpacing: 0.5, textTransform: "uppercase", marginBottom: 8, paddingLeft: 4 }}>{date}</div>
                    <div style={{ background: t.cardBg, borderRadius: 20, overflow: "hidden", border: `1px solid ${t.border}` }}>
                      {txs.map((tx, i) => (
                        <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 16px", borderBottom: i < txs.length-1 ? `1px solid ${t.border}` : "none" }}>
                          <div style={{ width: 40, height: 40, borderRadius: 13, background: t.container, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                            <Icon id={tx.icon} size={18} color={t.onContainer} />
                          </div>
                          <div style={{ flex: 1 }}>
                            <div style={{ fontSize: 14, fontWeight: 500, color: t.onSurface }}>{tx.merchant}</div>
                            <div style={{ fontSize: 11, color: t.onSurfaceVar, marginTop: 2 }}>{tx.category}</div>
                          </div>
                          <span style={{ fontSize: 14, fontWeight: 700, color: tx.amount > 0 ? "#4a9060" : t.onSurface }}>
                            {tx.amount > 0 ? "+" : "−"}₹{Math.abs(tx.amount).toLocaleString("en-IN")}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                ))
              )}

              {activityTab === "budgets" && (
                <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                  {CATEGORIES.map(cat => {
                    const pct = Math.min(cat.spent / cat.budget, 1), over = cat.spent > cat.budget
                    return (
                      <div key={cat.name} style={{ background: t.cardBg, borderRadius: 20, padding: 16, border: `1px solid ${t.border}` }}>
                        <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 12 }}>
                          <div style={{ width: 44, height: 44, borderRadius: 15, background: cat.color + "1a", display: "flex", alignItems: "center", justifyContent: "center" }}>
                            <Icon id={cat.icon} size={20} color={cat.color} />
                          </div>
                          <div style={{ flex: 1 }}>
                            <div style={{ fontSize: 15, fontWeight: 600, color: t.onSurface }}>{cat.name}</div>
                            <div style={{ fontSize: 12, color: t.onSurfaceVar, marginTop: 1 }}>₹{cat.spent.toLocaleString("en-IN")} of ₹{cat.budget.toLocaleString("en-IN")}</div>
                          </div>
                          <div style={{ fontSize: 15, fontWeight: 700, color: over ? "#c0504a" : "#4a9060" }}>{over ? "Over" : `${Math.round((1-pct)*100)}% left`}</div>
                        </div>
                        <div style={{ height: 7, borderRadius: 100, background: t.surfaceVariant, overflow: "hidden" }}>
                          <div style={{ height: "100%", width: `${pct*100}%`, borderRadius: 100, background: over ? "#c0504a" : cat.color }} />
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}
            </div>
          </div>
        )}

        {/* ── Profile ── */}
        {activeTab === "profile" && <ProfilePage t={t} onOpenSettings={() => setShowSettings(true)} />}
      </div>

      {/* ── FAB ── */}
      {(activeTab === "home" || activeTab === "activity") && (
        <button onClick={() => setShowAddExpense(true)} style={{ position: "fixed", bottom: 96, right: "max(16px, calc(50% - 215px + 16px))", width: 54, height: 54, borderRadius: 18, background: t.primary, color: "#fff", border: "none", cursor: "pointer", zIndex: 100, display: "flex", alignItems: "center", justifyContent: "center", boxShadow: `0 4px 18px ${t.shadow}`, transition: "transform 0.15s" }}
          onMouseEnter={e => (e.currentTarget.style.transform = "scale(1.07)")}
          onMouseLeave={e => (e.currentTarget.style.transform = "scale(1)")}
        >
          <Icon id="plus" size={24} color="#fff" />
        </button>
      )}

      {/* ── Floating liquid-glass nav — order: Activity | Home | Profile ── */}
      <div
        onPointerDown={onNavPD} onPointerMove={onNavPM}
        onPointerUp={onNavPU} onPointerLeave={onNavPU}
        style={{ position: "fixed", bottom: 20, left: "50%", transform: "translateX(-50%)", width: "calc(100% - 80px)", maxWidth: 280, borderRadius: 40, background: t.navBg, backdropFilter: "blur(28px) saturate(180%)", WebkitBackdropFilter: "blur(28px) saturate(180%)", border: `1px solid ${t.navBorder}`, boxShadow: `0 8px 32px ${t.shadow}, inset 0 1px 0 ${t.glassInner}`, display: "flex", zIndex: 200, userSelect: "none", touchAction: "pan-x", cursor: "grab", overflow: "hidden" } as CSSProperties}
      >
        <div style={{ position: "absolute", top: 0, left: "10%", right: "10%", height: 1, background: t.glassInner, borderRadius: 1 }} />
        <NavBtn tab="activity" iconId="activity" label="Activity" />
        <NavBtn tab="home"     iconId="home"     label="Home"     />
        <NavBtn tab="profile"  iconId="profile"  label="Profile"  />
      </div>

      {/* ── Person detail sheet ── */}
      {selectedPerson && (
        <div style={{ position: "fixed", inset: 0, zIndex: 400, display: "flex", alignItems: "flex-end", justifyContent: "center" }}
          onClick={() => { setSelectedPerson(null); setShowUPI(false) }}>
          <div style={{ position: "absolute", inset: 0, background: "rgba(0,0,0,0.48)", backdropFilter: "blur(4px)", animation: "fadeIn 0.2s ease" }} />
          <div style={{ position: "relative", background: t.cardBg, borderRadius: "28px 28px 0 0", width: "100%", maxWidth: 430, padding: "0 0 44px", boxShadow: "0 -8px 40px rgba(0,0,0,0.18)", animation: "slideUp 0.28s cubic-bezier(.4,0,.2,1)" }}
            onClick={e => e.stopPropagation()}>
            <div style={{ width: 36, height: 4, borderRadius: 2, background: t.border, margin: "12px auto 20px" }} />
            <div style={{ background: selectedPerson.color, padding: "20px 24px 24px" }}>
              <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
                <div style={{ width: 52, height: 52, borderRadius: "50%", background: "rgba(255,255,255,0.22)", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18, fontWeight: 700 }}>{selectedPerson.initials}</div>
                <div>
                  <div style={{ fontSize: 18, fontWeight: 600, color: "#fff" }}>{selectedPerson.name}</div>
                  <div style={{ fontSize: 12, color: "rgba(255,255,255,0.7)", marginTop: 2 }}>{selectedPerson.upi}</div>
                </div>
              </div>
              <div style={{ marginTop: 16, textAlign: "center" }}>
                <div style={{ fontSize: 12, color: "rgba(255,255,255,0.65)", marginBottom: 4 }}>
                  {selectedPerson.amount < 0 ? `You owe ${selectedPerson.name}` : `${selectedPerson.name} owes you`}
                </div>
                <div style={{ fontSize: 34, fontWeight: 700, color: "#fff", letterSpacing: -1 }}>₹{Math.abs(selectedPerson.amount).toLocaleString("en-IN")}</div>
              </div>
            </div>

            {selectedPerson.amount > 0 && showUPI && (
              <div style={{ margin: "16px 24px", background: t.surfaceVariant, borderRadius: 20, padding: 18, display: "flex", flexDirection: "column", alignItems: "center", gap: 12, animation: "fadeIn 0.2s ease" }}>
                <div style={{ fontSize: 12, fontWeight: 600, color: t.onSurface }}>UPI Request · ₹{selectedPerson.amount.toLocaleString("en-IN")}</div>
                <QRCode fg={isDark ? "#ffffff" : "#000000"} bg={isDark ? "#2a2830" : "#ffffff"} />
                <div style={{ background: t.cardBg, borderRadius: 12, padding: "9px 12px", width: "100%", border: `1px solid ${t.border}` }}>
                  <div style={{ fontSize: 10, color: t.onSurfaceVar, marginBottom: 2, fontWeight: 600, letterSpacing: 0.5, textTransform: "uppercase" }}>Note</div>
                  <div style={{ fontSize: 13, color: t.onSurface, lineHeight: 1.4 }}>"{selectedPerson.name} owes ₹{selectedPerson.amount} — settling via UPI"</div>
                </div>
              </div>
            )}

            <div style={{ padding: "16px 24px 0", display: "flex", flexDirection: "column", gap: 10 }}>
              {selectedPerson.amount > 0 && !showUPI && (
                <button onClick={() => setShowUPI(true)} style={{ width: "100%", padding: "14px", borderRadius: 18, background: t.container, color: t.onContainer, border: "none", cursor: "pointer", fontSize: 15, fontWeight: 600, display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
                  <Icon id="qr" size={16} color={t.onContainer} /> Send UPI QR Code
                </button>
              )}
              {selectedPerson.amount > 0 && showUPI && (
                <button onClick={() => setShowUPI(false)} style={{ width: "100%", padding: "14px", borderRadius: 18, background: t.container, color: t.onContainer, border: "none", cursor: "pointer", fontSize: 15, fontWeight: 600, display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
                  <Icon id="share" size={16} color={t.onContainer} /> Share QR Code
                </button>
              )}
              <button style={{ width: "100%", padding: "14px", borderRadius: 18, background: selectedPerson.amount > 0 ? t.surfaceVariant : t.container, color: selectedPerson.amount > 0 ? t.onSurfaceVar : t.onContainer, border: "none", cursor: "pointer", fontSize: 15, fontWeight: 600, display: "flex", alignItems: "center", justifyContent: "center", gap: 8 }}>
                <Icon id="check" size={16} color={selectedPerson.amount > 0 ? t.onSurfaceVar : t.onContainer} /> Settle Up
              </button>
            </div>
          </div>
        </div>
      )}

      {showAddExpense && (
        <AddExpenseSheet t={t} onClose={() => setShowAddExpense(false)} />
      )}

      {showSettings && (
        <SettingsSheet t={t} mode={mode} setMode={setMode} accentIdx={accentIdx} setAccentIdx={setAccentIdx} onClose={() => setShowSettings(false)} />
      )}

      <style>{`
        @keyframes fadeIn    { from { opacity: 0 }              to { opacity: 1 } }
        @keyframes slideUp   { from { transform: translateY(100%) } to { transform: translateY(0) } }
        @keyframes expandDown { from { opacity: 0; transform: scaleY(0.92); transform-origin: top } to { opacity: 1; transform: scaleY(1) } }
      `}</style>
    </div>
  )
}
