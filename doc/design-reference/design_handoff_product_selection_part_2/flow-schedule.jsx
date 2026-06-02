// Weekly schedule — assign which days each product runs, per slot. Shows:
//  • a week-at-a-glance strip (load + conflict markers per day)
//  • soft "over recommended frequency" warnings (never blocks)
//  • same-slot conflict detection (incompatibility rules)
//  • per-product weekday pickers so the weekly split is easy to see/edit.

const { useState: useSc, useRef } = React;

function DayPicker({ schedule, p, slot, onToggle }) {
  const days = effectiveDays(schedule, p, slot);
  return (
    <div className="flex gap-1.5 justify-between" dir="rtl">
      {WEEKDAYS.map(d => {
        const on = !!days[d.id];
        return (
          <button
            key={d.id}
            onClick={() => onToggle(p.id, d.id)}
            className={`flex-1 aspect-square rounded-full quick font-bold text-[13px] transition active:scale-90 ${
              on ? 'bg-primary text-white shadow-glow-sm' : 'bg-surface-low text-on-surface-variant hover:bg-primary-fixed/40'
            }`}
            aria-pressed={on}
            aria-label={d.label}
          >
            {d.short}׳
          </button>
        );
      })}
    </div>
  );
}

function DailyScheduleCard({ p, slot, schedule, onToggle }) {
  const count = daysCount(schedule, p, slot);
  const everyDay = count === 7;
  const [open, setOpen] = useSc(!everyDay);

  const badgeCls = count === 0
    ? 'bg-error text-white'
    : everyDay
      ? 'bg-primary-fixed/60 text-primary'
      : 'bg-black/[0.06] text-on-surface-variant';
  const badgeText = count === 0 ? 'לא נבחר' : everyDay ? 'כל יום' : `${count}/7`;

  return (
    <div className="bg-white rounded-[22px] p-3.5 shadow-glow-sm" dir="rtl">
      {/* header — always visible */}
      <div className="flex items-center gap-3">
        <ProductThumb src={p.image} size={40} fallbackIcon="spa" />
        <div className="flex-1 min-w-0">
          <h4 className="quick font-bold text-[13.5px] text-on-surface truncate" dir="ltr" style={{ textAlign: 'right' }}>{p.name}</h4>
          <p className="quick text-[10.5px] text-on-surface-variant">מומלץ: <span className="font-bold">כל יום</span></p>
        </div>
        <span className={`label-sm text-[11px] px-2.5 py-1 rounded-full flex-shrink-0 ${badgeCls}`}>{badgeText}</span>
      </div>

      {!open ? (
        /* collapsed — customize button */
        <button
          onClick={() => setOpen(true)}
          className="w-full h-9 mt-2.5 rounded-full bg-surface-low quick font-bold text-[12px] text-on-surface-variant hover:text-primary active:scale-[0.98] flex items-center justify-center gap-1.5 transition"
        >
          <Icon name="tune" size={14} />
          התאמת ימים
        </button>
      ) : (
        /* expanded — day picker */
        <div className="mt-2.5">
          <DayPicker schedule={schedule} p={p} slot={slot} onToggle={onToggle} />
          {count === 0 && (
            <div className="mt-2 flex items-center gap-1.5 text-[11px] quick text-error" dir="rtl">
              <Icon name="warning" size={13} />
              לא נבחר יום — המוצר לא ישובץ
            </div>
          )}
          <button
            onClick={() => setOpen(false)}
            className="mt-2.5 mx-auto flex items-center gap-1 quick font-bold text-[11px] text-on-surface-variant hover:text-primary transition"
          >
            <Icon name="expand_less" size={15} />
            סגירה
          </button>
        </div>
      )}
    </div>
  );
}

function ScheduleView({ sel, schedule, setSchedule, onBack }) {
  const activeSlots = ['AM', 'PM'].filter(s => PRODUCTS.some(p => usesSlot(sel, p.id, s)));
  const startSlot = activeSlots[0] || 'AM';
  const [slot, setSlot] = useSc(startSlot);
  const [visited, setVisited] = useSc({ [startSlot]: true });
  const [openDay, setOpenDay] = useSc(null);
  const scrollRef = useRef(null);

  const m = SLOT_META[slot];

  const switchSlot = (s) => {
    setSlot(s); setOpenDay(null);
    setVisited(v => ({ ...v, [s]: true }));
    if (scrollRef.current) scrollRef.current.scrollTop = 0;
  };

  const bothSlots = activeSlots.length > 1;
  const slotIdx = activeSlots.indexOf(slot);
  const allVisited = activeSlots.every(s => visited[s]);
  const nextSlot = (!allVisited && slotIdx < activeSlots.length - 1)
    ? activeSlots[slotIdx + 1] : null;

  const selectedInSlot = PRODUCTS.filter(p => usesSlot(sel, p.id, slot));
  const occasional = selectedInSlot.filter(p => capOf(p, slot) != null);
  const daily = selectedInSlot.filter(p => isDaily(p, slot));

  const toggleDay = (pid, dayId) => setSchedule(prev => {
    const p = PROD_BY_ID[pid];
    let cur = prev[pid];
    if ((!cur || !Object.values(cur).some(Boolean)) && isDaily(p, slot)) cur = { 0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1 };
    const next = { ...(cur || {}) };
    if (next[dayId]) delete next[dayId]; else next[dayId] = 1;
    return { ...prev, [pid]: next };
  });

  const productsOnDay = (dayId) => selectedInSlot.filter(p => effectiveDays(schedule, p, slot)[dayId]);
  const weekConflicts = WEEKDAYS.map(d => ({ day: d, pairs: conflictsInList(productsOnDay(d.id)) })).filter(x => x.pairs.length);
  const conflictDays = new Set(weekConflicts.map(x => x.day.id));

  const conflictDaysForSlot = (s) => {
    const inSlot = PRODUCTS.filter(p => usesSlot(sel, p.id, s));
    return WEEKDAYS.filter(d => conflictsInList(inSlot.filter(p => effectiveDays(schedule, p, s)[d.id])).length).length;
  };
  const slotConflictCount = { AM: conflictDaysForSlot('AM'), PM: conflictDaysForSlot('PM') };

  return (
    <Phone>
      <div className="px-4 pt-2 pb-3 flex-shrink-0">
        <div className="flex items-center gap-2 mb-2">
          {onBack && (
            <button onClick={onBack} className="w-9 h-9 -ms-1 rounded-full flex items-center justify-center text-primary hover:bg-primary-fixed/40 transition flex-shrink-0">
              <Icon name="arrow_forward" size={22} />
            </button>
          )}
          <h2 className="quick font-bold text-[20px] text-on-surface leading-tight flex-1">תזמון שבועי</h2>
          {bothSlots && (
            <span className="quick font-bold text-[11px] text-on-surface-variant bg-surface-low rounded-full px-2.5 py-1 flex-shrink-0">
              שלב {slotIdx + 1} מתוך {activeSlots.length}
            </span>
          )}
        </div>
        <p className="quick text-[12px] text-on-surface-variant mb-2.5 px-1 leading-snug">
          {bothSlots
            ? 'תזמני קודם את שגרת הבוקר, וכך נמשיך יחד גם לשגרת הערב. אפשר לחרוג מהמומלץ — רק נזכיר.'
            : `באילו ימים להשתמש בכל מוצר ב${m.routine}…`}
        </p>
        <div className="flex p-1 bg-surface-low rounded-full" dir="rtl">
          {['AM', 'PM'].map(s => {
            const active = slot === s;
            const onCls = s === 'AM' ? 'bg-primary-container text-white' : 'bg-tertiary text-white';
            const hasConflict = slotConflictCount[s] > 0;
            const seen = !!visited[s] && !active && !hasConflict;
            return (
              <button key={s} onClick={() => switchSlot(s)} className={`relative flex-1 h-10 rounded-full quick font-bold text-[14px] flex items-center justify-center gap-1.5 transition ${active ? `${onCls} shadow-glow-sm` : 'text-on-surface-variant'}`}>
                <Icon name={SLOT_META[s].icon} fill={active} size={16} />
                {SLOT_META[s].label}
                {hasConflict && (
                  <span className={`w-4 h-4 rounded-full flex items-center justify-center ${active ? 'bg-white text-error' : 'bg-error text-white'}`}>
                    <Icon name="priority_high" size={11} />
                  </span>
                )}
                {seen && (
                  <span className="w-4 h-4 rounded-full flex items-center justify-center bg-primary/15 text-primary">
                    <Icon name="check" size={11} />
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      <div ref={scrollRef} className="flex-1 min-h-0 overflow-y-auto px-4 pb-4">
        {/* week at a glance — tap a flagged day to see its conflict */}
        <div className="bg-white rounded-[22px] p-3 shadow-glow-sm mb-3">
          <div className="flex items-center justify-between mb-2 px-0.5" dir="rtl">
            <span className="quick font-bold text-[12.5px] text-on-surface">מבט שבועי</span>
            {weekConflicts.length > 0
              ? <span className="quick text-[10.5px] text-error font-bold flex items-center gap-1"><Icon name="touch_app" size={12} />הקישי על יום מסומן</span>
              : <span className="quick text-[10.5px] text-on-surface-variant">מספר מוצרים ביום</span>}
          </div>
          <div className="flex gap-1.5 justify-between" dir="rtl">
            {WEEKDAYS.map(d => {
              const n = productsOnDay(d.id).length;
              const conflict = conflictDays.has(d.id);
              const isOpen = openDay === d.id;
              return (
                <div key={d.id} className="flex-1 flex flex-col items-center gap-1">
                  <span className={`quick text-[10px] ${conflict ? 'text-error font-bold' : 'text-on-surface-variant'}`}>{d.short}׳</span>
                  <button
                    onClick={() => conflict && setOpenDay(isOpen ? null : d.id)}
                    disabled={!conflict}
                    className={`w-full aspect-square rounded-xl flex items-center justify-center relative quick font-bold text-[13px] transition ${
                      conflict ? `bg-error text-white ${isOpen ? 'ring-2 ring-error ring-offset-1' : ''} active:scale-90 cursor-pointer` : n ? 'bg-black/[0.06] text-on-surface' : 'bg-black/[0.02] text-on-surface-variant/40'
                    }`}
                    aria-label={conflict ? `${d.label} — התנגשות, הקישי לפרטים` : d.label}
                  >
                    {n || '·'}
                    {conflict && <span className="absolute -top-1 -end-1 w-3.5 h-3.5 rounded-full bg-white text-error flex items-center justify-center ring-1 ring-error"><Icon name="priority_high" size={9} /></span>}
                  </button>
                </div>
              );
            })}
          </div>

          {/* inline conflict detail — opens like the product details, with a close */}
          {openDay != null && conflictDays.has(openDay) && (
            <div className="mt-3 rounded-[18px] bg-error-container/50 border border-error/25 p-3" dir="rtl">
              <div className="flex items-center gap-2 mb-2">
                <span className="label-sm text-[10px] bg-error text-white rounded-full px-2 py-0.5 flex-shrink-0">
                  {WEEKDAYS.find(d => d.id === openDay).label}
                </span>
                <h3 className="quick font-bold text-[12.5px] text-error flex-1">לא מומלץ לשלב</h3>
                <button onClick={() => setOpenDay(null)} className="w-6 h-6 -m-1 rounded-full flex items-center justify-center text-error hover:bg-error/10 transition flex-shrink-0" aria-label="סגור">
                  <Icon name="close" size={17} />
                </button>
              </div>
              <ul className="space-y-2">
                {conflictsInList(productsOnDay(openDay)).map((pair, i) => (
                  <li key={i} className="flex items-center gap-2">
                    <ProductThumb src={pair[0].image} size={28} fallbackIcon="spa" />
                    <span dir="ltr" className="quick text-[11.5px] font-bold text-on-surface truncate flex-1 text-right" style={{ textAlign: 'right' }}>{pair[0].name}</span>
                    <Icon name="close" size={12} className="text-error flex-shrink-0" />
                    <span dir="ltr" className="quick text-[11.5px] font-bold text-on-surface truncate flex-1" style={{ textAlign: 'left' }}>{pair[1].name}</span>
                    <ProductThumb src={pair[1].image} size={28} fallbackIcon="spa" />
                  </li>
                ))}
              </ul>
              <p className="quick text-[11px] text-on-surface-variant mt-2 leading-snug">הזיזי אחד מהם ליום אחר, או השאירי כך — לא נחסום.</p>
            </div>
          )}
        </div>

        {/* cross-slot hint — current slot clean, the other has a conflict */}
        {weekConflicts.length === 0 && slotConflictCount[slot === 'AM' ? 'PM' : 'AM'] > 0 && (
          <button
            onClick={() => switchSlot(slot === 'AM' ? 'PM' : 'AM')}
            className="w-full rounded-[18px] bg-error-container/50 border border-error/25 p-3 mb-3 flex items-center gap-2.5 text-right active:scale-[0.99] transition"
            dir="rtl"
          >
            <Icon name="warning" fill size={17} className="text-error flex-shrink-0" />
            <span className="quick text-[12px] text-on-surface flex-1 leading-snug">
              יש התנגשות ב{SLOT_META[slot === 'AM' ? 'PM' : 'AM'].routine} — הקישי לתיקון
            </span>
            <Icon name="chevron_left" size={18} className="text-error flex-shrink-0" />
          </button>
        )}

        {/* occasional products — day picker always open (per-week cap makes split meaningful) */}
        {occasional.length > 0 && (
          <>
            <h3 className="quick font-bold text-[13px] text-on-surface-variant text-right mt-1 mb-2 px-1">
              לא לשימוש יומי <span className="font-medium opacity-70">({occasional.length})</span>
            </h3>
            <div className="space-y-2.5 mb-4">
              {occasional.map(p => {
                const cap = capOf(p, slot);
                const count = daysCount(schedule, p, slot);
                const over = count > cap;
                return (
                  <div key={p.id} className="bg-white rounded-[22px] p-3.5 shadow-glow-sm" dir="rtl">
                    <div className="flex items-center gap-3 mb-2.5">
                      <ProductThumb src={p.image} size={40} fallbackIcon="spa" />
                      <div className="flex-1 min-w-0">
                        <h4 className="quick font-bold text-[13.5px] text-on-surface truncate text-right" dir="ltr" style={{ textAlign: 'right' }}>{p.name}</h4>
                        <p className="quick text-[10.5px] text-on-surface-variant text-right">מומלץ: עד <span className="font-bold">{cap}×</span> בשבוע</p>
                      </div>
                      <span className={`label-sm text-[11px] px-2.5 py-1 rounded-full flex-shrink-0 ${
                        over ? 'bg-error text-white' : 'bg-black/[0.06] text-on-surface-variant'
                      }`}>{count}/{cap}</span>
                    </div>
                    <DayPicker schedule={schedule} p={p} slot={slot} onToggle={toggleDay} />
                    {over && (
                      <div className="mt-2 flex items-center gap-1.5 text-[11px] quick text-error" dir="rtl">
                        <Icon name="warning" size={13} />
                        מעבר למומלץ — שקלי להפחית ל־{cap} ימים
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </>
        )}

        {/* daily products — collapsed by default when every-day, auto-expanded when narrowed */}
        {daily.length > 0 && (
          <>
            <h3 className="quick font-bold text-[13px] text-on-surface-variant text-right mb-2 px-1">
              יומיים <span className="font-medium opacity-70">({daily.length})</span> · כברירת מחדל כל יום
            </h3>
            <div className="space-y-2.5">
              {daily.map(p => (
                <DailyScheduleCard key={p.id} p={p} slot={slot} schedule={schedule} onToggle={toggleDay} />
              ))}
            </div>
          </>
        )}
      </div>

      <div className="flex-shrink-0 px-4 pt-3 pb-5 bg-surface/95 backdrop-blur-xl border-t border-primary-fixed/30">
        <button
          onClick={nextSlot ? () => switchSlot(nextSlot) : undefined}
          className="w-full rounded-full bg-gradient-to-l from-primary to-primary-container text-white quick font-bold text-[15.5px] flex items-center justify-center gap-2 shadow-glow-lg active:scale-[0.98] transition"
          style={{ height: 52 }}
        >
          {nextSlot ? (
            <>
              <Icon name={SLOT_META[nextSlot].icon} fill size={18} />
              המשך ל{SLOT_META[nextSlot].routine}
              <Icon name="arrow_back" size={19} />
            </>
          ) : (
            <>
              <Icon name="check" size={19} />
              סיום ושמירת השגרה
            </>
          )}
        </button>
        {nextSlot ? (
          <p className="text-center quick text-[11px] text-on-surface-variant mt-2">
            נשאר עוד שלב — {SLOT_META[nextSlot].routine} מחכה לתזמון
          </p>
        ) : weekConflicts.length > 0 ? (
          <p className="text-center quick text-[11px] text-error mt-2">עדיין יש {weekConflicts.length} ימי התנגשות ב{m.label}</p>
        ) : null}
      </div>
    </Phone>
  );
}

// Standalone artboard
function ScheduleFlow() {
  const [schedule, setSchedule] = useSc(SEED_SCHEDULE);
  return <ScheduleView sel={SEED_SEL} schedule={schedule} setSchedule={setSchedule} />;
}

Object.assign(window, { ScheduleView, ScheduleFlow, DayPicker });
