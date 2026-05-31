// Shared layer for the product-selection flow explorations.
// Selection model: a product is selected ONCE. Flexible products (usable
// morning AND evening) carry inline timing TOGGLES (morning / evening — turn
// on either or both). Fixed products show a locked badge. The info button on
// each row reveals the product's details + how to use it.
// Selection state shape: { [pid]: ['AM'] | ['PM'] | ['AM','PM'] }  (absent = unselected)

const { useState: useF } = React;

const SLOT_META = {
  AM: { id: 'AM', label: 'בוקר', routine: 'שגרת בוקר', icon: 'wb_sunny', tint: 'text-primary-container' },
  PM: { id: 'PM', label: 'ערב',  routine: 'שגרת ערב',  icon: 'dark_mode', tint: 'text-tertiary' },
};

// ---- selection helpers (pure) ----
const isOn = (sel, pid) => Array.isArray(sel[pid]) && sel[pid].length > 0;
const usesSlot = (sel, pid, slot) => isOn(sel, pid) && sel[pid].includes(slot);
function toggleSel(sel, pid) {
  const next = { ...sel };
  if (next[pid]) delete next[pid];
  else next[pid] = slotsOf(PROD_BY_ID[pid]); // default to all slots the product allows
  return next;
}
// empty timing => product is removed from the routine
const applyTiming = (sel, pid, slots) => {
  if (!slots || slots.length === 0) { const n = { ...sel }; delete n[pid]; return n; }
  return { ...sel, [pid]: slots };
};
const countSlot = (sel, slot) => PRODUCTS.filter(p => usesSlot(sel, p.id, slot)).length;
const occBadge = (p) => {
  const f = (p.am && p.am.freq) || (p.pm && p.pm.freq);
  return f && f !== 'daily' ? `עד ${f.max}×/שבוע` : null;
};

// ---- weekly scheduling ----
const WEEKDAYS = [
  { id: 0, short: 'א', label: 'ראשון' },
  { id: 1, short: 'ב', label: 'שני' },
  { id: 2, short: 'ג', label: 'שלישי' },
  { id: 3, short: 'ד', label: 'רביעי' },
  { id: 4, short: 'ה', label: 'חמישי' },
  { id: 5, short: 'ו', label: 'שישי' },
  { id: 6, short: 'ש', label: 'שבת' },
];
const slotCfg = (p, slot) => (slot === 'AM' ? p.am : p.pm);
const isDaily = (p, slot) => { const c = slotCfg(p, slot); return c && c.freq === 'daily'; };
const capOf = (p, slot) => { const c = slotCfg(p, slot); return c && c.freq !== 'daily' ? c.freq.max : null; };
// effective scheduled days: explicit schedule wins; daily → every day; else none
function effectiveDays(schedule, p, slot) {
  const stored = schedule[p.id];
  if (stored && Object.values(stored).some(Boolean)) return stored;
  if (isDaily(p, slot)) return { 0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1 };
  return {};
}
const daysCount = (schedule, p, slot) => Object.values(effectiveDays(schedule, p, slot)).filter(Boolean).length;

// incompatibility rules (from incompatibility_rules.json) — all scope withinSlot
const RULES = [
  { a: { type: 'product', id: 'prod-037' }, b: { type: 'product', id: 'prod-016' } },
  { a: { type: 'category', id: 'cat-retinoid' }, b: { type: 'product', id: 'prod-016' } },
];
const ruleHits = (entity, p) =>
  entity.type === 'product' ? entity.id === p.id : entity.type === 'category' ? entity.id === p.cat : false;
function conflictsInList(list) {
  const pairs = [];
  for (const r of RULES) {
    const as = list.filter(p => ruleHits(r.a, p));
    const bs = list.filter(p => ruleHits(r.b, p));
    for (const a of as) for (const b of bs) {
      if (a.id === b.id) continue;
      if (!pairs.some(([x, y]) => (x.id === a.id && y.id === b.id) || (x.id === b.id && y.id === a.id))) pairs.push([a, b]);
    }
  }
  return pairs;
}

// usage instructions per category (shown in the details reveal)
const USAGE = {
  'cat-cleanser-step1': 'עסי על עור יבש להמסת איפור ומסנני הגנה, ושטפי במים פושרים.',
  'cat-cleanser-step2': 'הקציפי עם מעט מים, עסי בעדינות בתנועות מעגליות ושטפי.',
  'cat-retinoid': 'כמות בגודל אפונה על עור יבש, הימנעי מאזור העיניים. ערב בלבד, בהדרגה.',
  'cat-toner': 'טפחי כמה טיפות בכפות הידיים על עור נקי, לפני הסרומים.',
  'cat-serum': 'כמה טיפות על עור נקי. המתיני לספיגה לפני השלב הבא.',
  'cat-moisturizer': 'מרחי שכבה אחידה לנעילת הלחות והרגעת העור.',
  'cat-oil': 'חממי כמה טיפות בין כפות הידיים ולחצי על העור כשלב אחרון.',
  'cat-spf': 'כמות נדיבה (אורך אצבע) כשלב אחרון בבוקר — גם ביום מעונן.',
};

// ---------------------------------------------------------------------------
// Phone shell
// ---------------------------------------------------------------------------
function Phone({ children }) {
  return (
    <div dir="rtl" className="w-full h-full bg-surface flex flex-col font-body relative overflow-hidden">
      <div className="flex items-center justify-between px-6 pt-3 pb-1 flex-shrink-0">
        <span className="quick text-[13px] font-bold text-on-surface tabular-nums">9:41</span>
        <div className="flex items-center gap-1.5 text-on-surface">
          <Icon name="signal_cellular_alt" size={15} />
          <Icon name="wifi" size={15} />
          <Icon name="battery_full" size={15} />
        </div>
      </div>
      {children}
    </div>
  );
}

function StepGlyph({ icon, active, size = 'md' }) {
  const dim = size === 'lg' ? 'w-12 h-12' : size === 'sm' ? 'w-8 h-8' : 'w-10 h-10';
  const isz = size === 'lg' ? 26 : size === 'sm' ? 18 : 22;
  return (
    <span className={`${dim} rounded-2xl flex items-center justify-center flex-shrink-0 transition-colors ${
      active ? 'bg-primary text-white' : 'bg-primary-fixed/50 text-primary'
    }`}>
      <Icon name={icon} size={isz} fill={active} />
    </span>
  );
}

// ---------------------------------------------------------------------------
// TimingControl — two independent toggles for a selected flexible product.
// Turn on morning, evening, or both. Turning both off removes the product.
// ---------------------------------------------------------------------------
function TimingControl({ slots, onChange }) {
  const has = (s) => slots.includes(s);
  const toggleSlot = (s) => onChange(has(s) ? slots.filter(x => x !== s) : [...slots, s]);
  const opts = [
    { key: 'AM', label: 'בוקר', icon: 'wb_sunny', on: 'bg-primary-container text-white border-transparent' },
    { key: 'PM', label: 'ערב', icon: 'dark_mode', on: 'bg-tertiary text-white border-transparent' },
  ];
  return (
    <div className="flex items-center gap-2 px-3 pb-2.5 pt-0.5" dir="rtl" onClick={(e) => e.stopPropagation()}>
      <span className="quick text-[11px] font-bold text-on-surface-variant flex items-center gap-1 flex-shrink-0">
        <Icon name="schedule" size={13} />
        מתי?
      </span>
      <div className="flex-1 flex gap-1.5">
        {opts.map(o => {
          const active = has(o.key);
          return (
            <button
              key={o.key}
              onClick={() => toggleSlot(o.key)}
              className={`flex-1 h-8 rounded-full border quick text-[12px] font-bold flex items-center justify-center gap-1.5 transition active:scale-95 ${
                active ? o.on : 'bg-white text-on-surface-variant border-outline-variant/50'
              }`}
            >
              <Icon name={active ? 'check' : o.icon} fill={active} size={14} />
              {o.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// SelectRow — tap the row to add/remove; the info button reveals details
// (description + how to use). Selected products show a check on the thumb and
// a tinted row; flexible selected products reveal the timing toggles.
// ---------------------------------------------------------------------------
function SelectRow({ pid, sel, onToggle, onTiming }) {
  const [open, setOpen] = useF(false);
  const p = PROD_BY_ID[pid];
  const flex = isFlexible(p);
  const on = isOn(sel, pid);
  const slots = sel[pid] || [];
  const occ = occBadge(p);
  const showTiming = flex && on;
  const rounded = (showTiming || open) ? 'rounded-[26px]' : 'rounded-full';

  // capability chip: ONLY for fixed (single-slot) products — the exception.
  // Flexible is the default (majority), so it carries no chip; frequency and
  // the product comment live in the ⓘ reveal / schedule, not on the row.
  let cap = null;
  if (!flex) {
    const s = p.am ? 'AM' : 'PM';
    cap = { label: `${SLOT_META[s].label} בלבד`,
            cls: s === 'AM' ? 'text-primary bg-primary-fixed/60' : 'text-tertiary bg-tertiary-container/50' };
  }

  return (
    <div className={`transition-all border ${rounded} ${
      on ? 'bg-primary-fixed/30 border-primary/30' : 'bg-white border-transparent shadow-glow-sm'
    }`}>
      <div className="flex items-center gap-3 p-2 ps-3.5 pe-2">
        <button onClick={onToggle} className="flex items-center gap-3 flex-1 min-w-0 text-right active:scale-[0.99] transition" dir="rtl">
          <span className="relative flex-shrink-0">
            <ProductThumb src={p.image} size={50} fallbackIcon="spa" />
            {on && (
              <span className="absolute -bottom-0.5 -start-0.5 w-6 h-6 rounded-full bg-primary text-white flex items-center justify-center border-2 border-white shadow-sm">
                <Icon name="check" size={13} />
              </span>
            )}
          </span>
          <span className="flex-1 min-w-0 text-right">
            <span className="quick font-bold text-[14.5px] text-on-surface leading-tight block truncate" dir="ltr" style={{ textAlign: 'right' }}>{p.name}</span>
            {cap && (
              <span className="flex items-center mt-1 justify-start">
                <span className={`label-sm text-[9.5px] px-1.5 py-0.5 rounded-full flex items-center gap-0.5 flex-shrink-0 ${cap.cls}`}>
                  <Icon name="lock" size={10} />
                  {cap.label}
                </span>
              </span>
            )}
          </span>
        </button>
        <button
          onClick={(e) => { e.stopPropagation(); setOpen(o => !o); }}
          className={`flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center transition-all active:scale-90 ${
            open ? 'bg-primary text-white' : 'bg-surface-low text-on-surface-variant hover:text-primary'
          }`}
          aria-label={open ? 'הסתר פרטים' : 'פרטים נוספים'}
          aria-expanded={open}
        >
          <Icon name="info" fill={open} size={22} />
        </button>
      </div>

      {open && (
        <div className="px-4 pb-3 pt-0.5 text-right" dir="rtl">
          <div className="border-t border-outline-variant/30 pt-2.5">
            <p className="quick text-[12.5px] text-on-surface leading-relaxed">{p.comment}</p>
            <div className="flex items-start gap-1.5 mt-2">
              <Icon name="tips_and_updates" size={14} className="text-primary mt-0.5 flex-shrink-0" />
              <p className="quick text-[12px] text-on-surface-variant leading-relaxed">{USAGE[p.cat]}</p>
            </div>
            <div className="flex items-center gap-1.5 mt-2">
              <Icon name="event_repeat" size={14} className="text-on-surface-variant flex-shrink-0" />
              <p className="quick text-[12px] text-on-surface-variant">
                תדירות מומלצת: <span className="font-bold text-on-surface">{occ ? occ.replace('עד ', 'עד ') : 'יומי'}</span>
              </p>
            </div>
          </div>
        </div>
      )}

      {showTiming && <TimingControl slots={slots} onChange={(v) => onTiming(v)} />}
    </div>
  );
}

// ---------------------------------------------------------------------------
// SlotFilter — All / Morning / Evening segmented control (overview + summary).
// ---------------------------------------------------------------------------
function SlotFilter({ value, onChange, counts }) {
  const opts = [
    { key: 'all', label: 'הכל', icon: 'apps' },
    { key: 'AM', label: 'בוקר', icon: 'wb_sunny' },
    { key: 'PM', label: 'ערב', icon: 'dark_mode' },
  ];
  return (
    <div className="flex p-1 bg-surface-low rounded-full" dir="rtl">
      {opts.map(o => {
        const active = value === o.key;
        const onCls = o.key === 'PM' ? 'bg-tertiary text-white' : o.key === 'AM' ? 'bg-primary-container text-white' : 'bg-primary text-white';
        return (
          <button
            key={o.key}
            onClick={() => onChange(o.key)}
            className={`relative flex-1 h-10 rounded-full quick font-bold text-[14px] flex items-center justify-center gap-1.5 transition-all active:scale-95 ${
              active ? `${onCls} shadow-glow-sm` : 'text-on-surface-variant'
            }`}
          >
            <Icon name={o.icon} fill={active} size={16} />
            {o.label}
            {counts && counts[o.key] != null && (
              <span className={`label-sm text-[10px] rounded-full px-1.5 py-0.5 ${active ? 'bg-white/25 text-white' : 'bg-primary-fixed/60 text-primary'}`}>{counts[o.key]}</span>
            )}
          </button>
        );
      })}
    </div>
  );
}

Object.assign(window, {
  SLOT_META, isOn, usesSlot, toggleSel, applyTiming, countSlot, occBadge, USAGE,
  WEEKDAYS, slotCfg, isDaily, capOf, effectiveDays, daysCount, RULES, ruleHits, conflictsInList,
  Phone, StepGlyph, TimingControl, SelectRow, SlotFilter,
});
