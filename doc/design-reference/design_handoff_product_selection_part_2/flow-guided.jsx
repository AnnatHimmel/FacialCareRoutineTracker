// Direction 1 — Guided Steps (the recommended selection path). One category
// per screen in real catalog order. Each product is selected once; flexible
// ones get inline timing toggles. "Skip to summary" (and the final step) lands
// on the Overview/summary (option 2) — one connected flow.

const { useState: useG } = React;

const CAT_HINT = {
  'cat-cleanser-step1': 'הסרת איפור ומסנני הגנה — לרוב בערב.',
  'cat-cleanser-step2': 'ניקוי פנים יומיומי ועדין.',
  'cat-retinoid': 'חידוש העור — ערב בלבד, בהדרגה.',
  'cat-toner': 'איזון העור והכנה לספיגת השלבים הבאים.',
  'cat-serum': 'החומרים הפעילים שלך. אפשר לבחור כמה שתרצי.',
  'cat-moisturizer': 'נעילת הלחות והרגעת העור.',
  'cat-oil': 'שכבת הזנה אחרונה, לרוב בערב.',
  'cat-spf': 'הגנה מהשמש — שלב הבוקר האחרון, חובה.',
};

function GuidedFlow() {
  const [view, setView] = useG('step');     // 'step' | 'summary' | 'schedule'
  const [i, setI] = useG(0);
  const [sel, setSel] = useG(SEED_SEL);
  const [schedule, setSchedule] = useG(SEED_SCHEDULE);

  const cat = CATEGORIES[i];
  const prods = productsInCat(cat.id);
  const toggle = (pid) => setSel(s => toggleSel(s, pid));
  const timing = (pid, slots) => setSel(s => applyTiming(s, pid, slots));
  const catSelCount = prods.filter(p => isOn(sel, p.id)).length;
  const total = Object.keys(sel).filter(pid => isOn(sel, pid)).length;
  const next = () => { if (i < CATEGORIES.length - 1) setI(i + 1); else setView('summary'); };
  const back = () => { if (i > 0) setI(i - 1); };

  // ---------------- Summary === Overview (option 2) ----------------
  if (view === 'summary') {
    return (
      <SummaryView
        sel={sel}
        setSel={setSel}
        onBack={() => setView('step')}
        onNext={() => setView('schedule')}
        title="סיכום · הארון שלך"
        cta="המשך לתזמון"
      />
    );
  }

  // ---------------- Weekly schedule ----------------
  if (view === 'schedule') {
    return <ScheduleView sel={sel} schedule={schedule} setSchedule={setSchedule} onBack={() => setView('summary')} />;
  }

  // ---------------- Step ----------------
  return (
    <Phone>
      <div className="px-5 pt-2 pb-3 flex-shrink-0">
        <div className="flex items-center justify-between mb-2.5">
          <span className="label-sm text-[11px] text-on-surface-variant">שלב {i + 1} מתוך {CATEGORIES.length}</span>
          <button onClick={() => setView('summary')} className="quick text-[12.5px] font-bold text-primary flex items-center gap-0.5 hover:opacity-70 transition">
            דלג לסיכום
            <Icon name="chevron_left" size={16} />
          </button>
        </div>
        <div className="flex gap-1">
          {CATEGORIES.map((_, n) => (
            <div key={n} className={`flex-1 h-1.5 rounded-full transition-all ${n <= i ? 'bg-primary' : 'bg-primary-fixed/40'}`} />
          ))}
        </div>
      </div>

      <div className="flex-1 min-h-0 overflow-y-auto px-5">
        <div className="flex items-center gap-3 mt-1">
          <StepGlyph icon={cat.icon} active size="lg" />
          <div className="text-right min-w-0">
            <span className="label-sm text-[10px] text-primary tracking-[0.12em] uppercase">{cat.en}</span>
            <h2 className="quick font-bold text-[22px] text-on-surface leading-tight">{cat.name}</h2>
          </div>
        </div>
        <p className="quick text-[13px] text-on-surface-variant mt-2.5 leading-relaxed">{CAT_HINT[cat.id]}</p>

        <div className="mt-4 space-y-2.5 pb-4">
          {prods.map(p => (
            <SelectRow key={p.id} pid={p.id} sel={sel} onToggle={() => toggle(p.id)} onTiming={(v) => timing(p.id, v)} />
          ))}
        </div>
      </div>

      <div className="flex-shrink-0 px-5 pt-3 pb-5 bg-surface/95 backdrop-blur-xl border-t border-primary-fixed/30">
        <div className="flex items-center gap-2.5">
          {i > 0 && (
            <button onClick={back} className="rounded-full bg-surface-low text-on-surface quick font-bold text-[15px] flex items-center justify-center px-5 active:scale-95 transition" style={{ height: 52 }}>
              <Icon name="arrow_forward" size={18} />
            </button>
          )}
          <button onClick={next} className="flex-1 rounded-full bg-gradient-to-l from-primary to-primary-container text-white quick font-bold text-[16px] flex items-center justify-center gap-2 shadow-glow-lg active:scale-[0.98] transition" style={{ height: 52 }}>
            {i === CATEGORIES.length - 1 ? 'לסיכום' : catSelCount > 0 ? 'המשך' : 'דלג על השלב'}
            <Icon name="arrow_back" size={18} />
          </button>
        </div>
        <p className="text-center quick text-[11.5px] text-on-surface-variant mt-2">
          {catSelCount === 0 ? 'אין בחירה בקטגוריה זו — אפשר להמשיך' : `${catSelCount} נבחרו · ${total} בסך הכל`}
        </p>
      </div>
    </Phone>
  );
}

Object.assign(window, { GuidedFlow });
