// Theme personalization & accent tokens for Settl

export const ACCENT_PRESETS = [
  {
    id: 'sage',
    name: 'Sage Green',
    color: '#55735a',
    light: {
      fill: '#55735a',
      hover: '#47654c',
      tint: '#edf2eb',
      tintStrong: '#e2eade',
      outline: '#dce5d8',
      ink: '#526d52',
      muted: '#7a8677',
      green: '#506e55',
      greenDark: '#3f5d46',
      greenSoft: '#edf3ed',
      pageRadial: '#e9f0e5',
    },
    dark: {
      fill: '#709475',
      hover: '#7fa685',
      tint: '#273329',
      tintStrong: '#334334',
      outline: '#435644',
      ink: '#b6d0b2',
      muted: '#9eb29b',
      green: '#a9c7ab',
      greenDark: '#8eb391',
      greenSoft: '#28372b',
      pageRadial: '#273329',
    },
  },
  {
    id: 'teal',
    name: 'Ocean Teal',
    color: '#0f766e',
    light: {
      fill: '#0f766e',
      hover: '#0d5f58',
      tint: '#e6f7f5',
      tintStrong: '#cbf1ed',
      outline: '#b2e5e0',
      ink: '#115e59',
      muted: '#5e9490',
      green: '#0f766e',
      greenDark: '#134e4a',
      greenSoft: '#e6f7f5',
      pageRadial: '#e0f2f1',
    },
    dark: {
      fill: '#2dd4bf',
      hover: '#5eead4',
      tint: '#133835',
      tintStrong: '#1b4d48',
      outline: '#266761',
      ink: '#99f6e4',
      muted: '#73b8b1',
      green: '#2dd4bf',
      greenDark: '#5eead4',
      greenSoft: '#133835',
      pageRadial: '#133835',
    },
  },
  {
    id: 'blue',
    name: 'Sapphire Blue',
    color: '#2563eb',
    light: {
      fill: '#2563eb',
      hover: '#1d4ed8',
      tint: '#eff6ff',
      tintStrong: '#dbeafe',
      outline: '#bfdbfe',
      ink: '#1e40af',
      muted: '#6086b8',
      green: '#2563eb',
      greenDark: '#1e40af',
      greenSoft: '#eff6ff',
      pageRadial: '#e0edff',
    },
    dark: {
      fill: '#60a5fa',
      hover: '#93c5fd',
      tint: '#172554',
      tintStrong: '#1e3a8a',
      outline: '#254a9e',
      ink: '#bfdbfe',
      muted: '#8baad6',
      green: '#60a5fa',
      greenDark: '#93c5fd',
      greenSoft: '#172554',
      pageRadial: '#172554',
    },
  },
  {
    id: 'purple',
    name: 'Iris Violet',
    color: '#7c3aed',
    light: {
      fill: '#7c3aed',
      hover: '#6d28d9',
      tint: '#f5f3ff',
      tintStrong: '#ede9fe',
      outline: '#ddd6fe',
      ink: '#5b21b6',
      muted: '#8e79b8',
      green: '#7c3aed',
      greenDark: '#5b21b6',
      greenSoft: '#f5f3ff',
      pageRadial: '#efeaff',
    },
    dark: {
      fill: '#a78bfa',
      hover: '#c4b5fd',
      tint: '#2e1065',
      tintStrong: '#3b1784',
      outline: '#4c1d95',
      ink: '#ddd6fe',
      muted: '#b29dd9',
      green: '#a78bfa',
      greenDark: '#c4b5fd',
      greenSoft: '#2e1065',
      pageRadial: '#2e1065',
    },
  },
  {
    id: 'amber',
    name: 'Warm Amber',
    color: '#d97706',
    light: {
      fill: '#d97706',
      hover: '#b45309',
      tint: '#fffbeb',
      tintStrong: '#fef3c7',
      outline: '#fde68a',
      ink: '#92400e',
      muted: '#b58f55',
      green: '#d97706',
      greenDark: '#92400e',
      greenSoft: '#fffbeb',
      pageRadial: '#fef3c7',
    },
    dark: {
      fill: '#fbbf24',
      hover: '#fcd34d',
      tint: '#451a03',
      tintStrong: '#5c2406',
      outline: '#78350f',
      ink: '#fde68a',
      muted: '#c7a36f',
      green: '#fbbf24',
      greenDark: '#fcd34d',
      greenSoft: '#451a03',
      pageRadial: '#451a03',
    },
  },
  {
    id: 'rose',
    name: 'Velvet Rose',
    color: '#e11d48',
    light: {
      fill: '#e11d48',
      hover: '#be123c',
      tint: '#fff1f2',
      tintStrong: '#ffe4e6',
      outline: '#fecdd3',
      ink: '#9f1239',
      muted: '#b86675',
      green: '#e11d48',
      greenDark: '#9f1239',
      greenSoft: '#fff1f2',
      pageRadial: '#ffe4e6',
    },
    dark: {
      fill: '#fb7185',
      hover: '#fda4af',
      tint: '#4c0519',
      tintStrong: '#630822',
      outline: '#881337',
      ink: '#fecdd3',
      muted: '#d98b98',
      green: '#fb7185',
      greenDark: '#fda4af',
      greenSoft: '#4c0519',
      pageRadial: '#4c0519',
    },
  },
]

export function hexToHSL(hex) {
  let c = (hex || '').replace('#', '')
  if (c.length === 3) c = c.split('').map((x) => x + x).join('')
  if (c.length !== 6) return { h: 140, s: 15, l: 40 }
  const r = parseInt(c.substring(0, 2), 16) / 255
  const g = parseInt(c.substring(2, 4), 16) / 255
  const b = parseInt(c.substring(4, 6), 16) / 255
  const max = Math.max(r, g, b)
  const min = Math.min(r, g, b)
  let h = 0
  let s = 0
  const l = (max + min) / 2
  if (max !== min) {
    const d = max - min
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
    switch (max) {
      case r:
        h = (g - b) / d + (g < b ? 6 : 0)
        break
      case g:
        h = (b - r) / d + 2
        break
      case b:
        h = (r - g) / d + 4
        break
    }
    h = Math.round(h * 60)
  }
  return { h, s: Math.round(s * 100), l: Math.round(l * 100) }
}

export function applyAccent(accentId, customHex = null, isDark = false) {
  if (typeof document === 'undefined') return
  const root = document.documentElement
  root.dataset.accent = accentId || 'sage'

  let tokens
  if (accentId === 'custom' && customHex) {
    const { h, s, l } = hexToHSL(customHex)
    tokens = isDark
      ? {
          fill: `hsl(${h}, ${Math.min(s, 75)}%, ${Math.max(l, 58)}%)`,
          hover: `hsl(${h}, ${Math.min(s, 80)}%, ${Math.min(l + 10, 72)}%)`,
          tint: `hsl(${h}, ${Math.min(s, 35)}%, 14%)`,
          tintStrong: `hsl(${h}, ${Math.min(s, 45)}%, 20%)`,
          outline: `hsl(${h}, ${Math.min(s, 35)}%, 28%)`,
          ink: `hsl(${h}, ${Math.min(s, 70)}%, 86%)`,
          muted: `hsl(${h}, 20%, 65%)`,
          green: `hsl(${h}, ${Math.min(s, 75)}%, ${Math.max(l, 58)}%)`,
          greenDark: `hsl(${h}, ${Math.min(s, 75)}%, 72%)`,
          greenSoft: `hsl(${h}, ${Math.min(s, 35)}%, 14%)`,
          pageRadial: `hsl(${h}, ${Math.min(s, 35)}%, 14%)`,
        }
      : {
          fill: customHex,
          hover: `hsl(${h}, ${s}%, ${Math.max(l - 8, 28)}%)`,
          tint: `hsl(${h}, ${Math.min(s, 40)}%, 96%)`,
          tintStrong: `hsl(${h}, ${Math.min(s, 50)}%, 91%)`,
          outline: `hsl(${h}, ${Math.min(s, 40)}%, 86%)`,
          ink: `hsl(${h}, ${s}%, 28%)`,
          muted: `hsl(${h}, 20%, 48%)`,
          green: customHex,
          greenDark: `hsl(${h}, ${s}%, 28%)`,
          greenSoft: `hsl(${h}, ${Math.min(s, 40)}%, 96%)`,
          pageRadial: `hsl(${h}, ${Math.min(s, 35)}%, 93%)`,
        }
  } else {
    const preset = ACCENT_PRESETS.find((p) => p.id === accentId) || ACCENT_PRESETS[0]
    tokens = isDark ? preset.dark : preset.light
  }

  root.style.setProperty('--brand-fill', tokens.fill)
  root.style.setProperty('--brand-hover', tokens.hover)
  root.style.setProperty('--brand-tint', tokens.tint)
  root.style.setProperty('--brand-tint-strong', tokens.tintStrong)
  root.style.setProperty('--brand-outline', tokens.outline)
  root.style.setProperty('--brand-ink', tokens.ink)
  root.style.setProperty('--brand-muted', tokens.muted)
  root.style.setProperty('--green', tokens.green)
  root.style.setProperty('--green-dark', tokens.greenDark)
  root.style.setProperty('--green-soft', tokens.greenSoft)
  root.style.setProperty('--page-radial', tokens.pageRadial)
}
