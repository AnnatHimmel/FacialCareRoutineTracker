// Direction 2 — Overview / Summary. Every category on one calm screen as
// collapsed sections, with a live All / Morning / Evening filter. Used in two
// places: as a standalone artboard, and as the SUMMARY that the Guided flow's
// "skip to summary" jumps to — one connected flow.

const { useState: useO } = React;

const SEED_SEL = {
  'prod-009': ['PM'], 'prod-008': ['PM'],            // cleansers (PM)
  'prod-028': ['AM', 'PM'],                          // rice toner (flexible)
  'prod-016': ['AM'],                                // BoJ Light On serum (AM) — conflict source
  'prod-037': ['AM', 'PM'],                          // Argireline (flexible) — conflicts w/ prod-016 in AM
  'prod-017': ['PM'], 'prod-025': ['PM'],            // occasional actives (weeklyMax 3)
  'prod-029': ['PM'],                                // bakuchiol night (PM retinoid)
  'prod-011': ['AM', 'PM'],                          // ceramide cream (flexible)
  'prod-010': ['PM'],                                // marula oil (PM)
  'prod-019': ['AM'],                                // BoJ relief sun SPF (AM)
};

// explicit weekday overrides; daily products default to every day
const SEED_SCHEDULE = {
  'prod-037': { 0: 1, 2: 1, 4: 1 }, // Argireline on Sun/Tue/Thu AM → conflicts prod-016 those days
  'prod-017': { 1: 1, 4: 1 },       // BHA 2/3 — within recommended
  'prod-025': { 0: 1, 2: 1, 4: 1, 6: 1 }, // Derma E 4× — OVER the recommended 3
};

// SummaryView — the filterable collapsed-category screen. Receives selection
// state from its parent so the Guided flow and the standalone artboard can
// both reuse it.
function SummaryView({ sel, setSel, onBack, onNext, title = 'הארון שלך', cta = 'צרי את השגרה' }) {
  const [filter, setFilter] = useO('all');
  const [open, setOpen] = useO('cat-serum');

  const toggle = (pid) => setSel(s => {
    const next = { ...s };
    if (next[pid]) { delete next[pid]; return next; }
    const all = slotsOf(PROD_BY_ID[pid]);
    next[pid] = (filter !== 'all' && all.includes(filter)) ? [filter] : all;
    return next;
  });
  const timing = (pid, slots) => setSel(s => applyTiming(s, pid, slots));

  const counts = {
    all: Object.keys(sel).filter(pid => isOn(sel, pid)).length,
    AM: countSlot(sel, 'AM'),
    PM: countSlot(sel, 'PM'),
  };
  const visibleIn = (catId) => productsInCat(catId).filter(p => filter === 'all' || (filter === 'AM' ? p.am : p.pm));
  const catSelCount = (catId) => visibleIn(catId).filter(p => filter === 'all' ? isOn(sel, p.id) : usesSlot(sel, p.id, filter)).length;
  const visibleCats = CATEGORIES.filter(c => visibleIn(c.id).length > 0);

  return (
    <Phone>
      <div className="px-4 pt-2 pb-3 flex-shrink-0">
        <div className="flex items-center gap-2 mb-2">
          {onBack && (
            <button onClick={onBack} className="w-9 h-9 -ms-1 rounded-full flex items-center justify-center text-primary hover:bg-primary-fixed/40 transition flex-shrink-0">
              <Icon name="arrow_forward" size={22} />
            </button>
          )}
          <div className="flex-1 min-w-0">
            <h2 className="quick font-bold text-[20px] text-on-surface leading-tight">{title}</h2>
          </div>
        </div>
        <p className="quick text-[12px] text-on-surface-variant mt-0.5 mb-2.5 px-1 leading-snug">
          בחרי מוצר פעם אחת. סנני בוקר/ערב כדי לראות כל שגרה בנפרד.
        </p>
        <SlotFilter value={filter} onChange={setFilter} counts={counts} />
      </div>

      <div className="flex-1 min-h-0 overflow-y-auto px-4 pb-4">
        <div className="space-y-2.5">
          {visibleCats.map(c => {
            const isOpen = open === c.id;
            const items = visibleIn(c.id);
            const cc = catSelCount(c.id);
            return (
              <div key={c.id} className={`rounded-[26px] transition-all overflow-hidden border ${
                isOpen ? 'bg-white border-primary-fixed/60 shadow-glow-sm' : 'bg-white/70 border-transparent'
              }`}>
                <button onClick={() => setOpen(isOpen ? null : c.id)} className="w-full flex items-center gap-3 p-3 ps-3.5 text-right active:scale-[0.99] transition" dir="rtl">
                  <StepGlyph icon={c.icon} active={isOpen} />
                  <span className="flex-1 text-right min-w-0">
                    <span className="quick font-bold text-[15px] text-on-surface truncate block">{c.name}</span>
                    <span className="quick text-[11.5px] text-on-surface-variant block leading-tight mt-0.5">
                      {cc === 0 ? `${items.length} אפשרויות` : `${cc} נבחרו`}
                    </span>
                  </span>
                  {cc > 0 && (
                    <span className="flex-shrink-0 min-w-[24px] h-6 px-1.5 rounded-full bg-primary text-white quick font-bold text-[12px] flex items-center justify-center">{cc}</span>
                  )}
                  <Icon name="expand_more" size={22} className={`flex-shrink-0 text-outline transition-transform ${isOpen ? 'rotate-180' : ''}`} />
                </button>

                {isOpen && (
                  <div className="px-2.5 pb-3 -mt-0.5 space-y-2">
                    {items.map(p => (
                      <SelectRow key={p.id} pid={p.id} sel={sel} onToggle={() => toggle(p.id)} onTiming={(v) => timing(p.id, v)} />
                    ))}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      <div className="flex-shrink-0 px-4 pt-3 pb-5 bg-surface/95 backdrop-blur-xl border-t border-primary-fixed/30">
        <div className="flex items-center gap-3">
          <div className="flex-shrink-0 flex items-center gap-2.5">
            {['AM', 'PM'].map(s => (
              <span key={s} className="flex items-center gap-1 text-on-surface-variant">
                <Icon name={SLOT_META[s].icon} fill size={15} className={SLOT_META[s].tint} />
                <span className="quick font-bold text-[15px] text-on-surface tabular-nums">{counts[s]}</span>
              </span>
            ))}
          </div>
          <button onClick={onNext} className="flex-1 rounded-full bg-gradient-to-l from-primary to-primary-container text-white quick font-bold text-[15.5px] flex items-center justify-center gap-2 shadow-glow-lg active:scale-[0.98] transition" style={{ height: 52 }}>
            <Icon name={onNext ? 'event' : 'check'} size={19} />
            {cta}
          </button>
        </div>
      </div>
    </Phone>
  );
}

// Standalone artboard — manages its own summary → schedule navigation so the
// connection is demonstrable here too.
function OverviewFlow() {
  const [sel, setSel] = useO(SEED_SEL);
  const [schedule, setSchedule] = useO(SEED_SCHEDULE);
  const [view, setView] = useO('summary');
  if (view === 'schedule') {
    return <ScheduleView sel={sel} schedule={schedule} setSchedule={setSchedule} onBack={() => setView('summary')} />;
  }
  return (
    <SummaryView
      sel={sel}
      setSel={setSel}
      onNext={() => setView('schedule')}
      title="בנו את הארון"
      cta="המשך לתזמון"
    />
  );
}

Object.assign(window, { SummaryView, OverviewFlow, SEED_SEL, SEED_SCHEDULE });
