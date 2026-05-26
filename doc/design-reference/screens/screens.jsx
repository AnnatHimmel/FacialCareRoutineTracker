// Screens for The Glow Protocol prototype
const { useState: useStateS, useEffect: useEffectS, useRef: useRefS, useMemo: useMemoS } = React;

// ===================== DATA =====================
// frequency: 'daily' or { max: N }  — occasional products have max-per-week
// conflictsWith: ids of products that shouldn't run in the same slot+day
const MASTER_PRODUCTS = [
  { id: 'gentle-milk', name: 'Gentle Milk Cleanser', category: 'cleanser', thumb: 'cleanser', subtitle: 'ניקוי • 2 לחיצות', tags: ['AM', 'PM'], frequency: 'daily', desc: 'מנקה עדין על בסיס חלב, שומר על מחסום הלחות הטבעי של העור.' },
  { id: 'gentle-cream', name: 'Gentle Cream Cleanser', category: 'cleanser', thumb: 'cleanser', subtitle: 'תרחיץ פנים מאוזן לשימוש יומיומי', tags: ['AM'], frequency: 'daily', desc: 'תרחיץ קרמי עם פניצן ופנתנול. מתאים לעור רגיש ויבש.' },
  { id: 'vitc', name: 'Vitamin C+ Serum', category: 'serum', thumb: 'vitc', subtitle: 'הבהרה ונוגדי חמצון', tags: ['AM'], frequency: 'daily', conflictsWith: ['retinol', 'exfoliant'], desc: 'סרום ויטמין C בריכוז 15% עם פריצת אנזימית מקדמת לזוהר טבעי ועמיד.' },
  { id: 'vitc-bright', name: 'Vitamin C Brightener', category: 'serum', thumb: 'vitc', subtitle: 'סרום • 3 טיפות', tags: ['AM'], frequency: 'daily', conflictsWith: ['retinol', 'exfoliant'], desc: 'נוסחה מרוכזת לפנים זוהרות במיוחד בבוקר.' },
  { id: 'ceramide', name: 'Ceramide Barrier Cream', category: 'cream', thumb: 'cream', subtitle: 'נעילת לחות אינטנסיבית', tags: ['AM', 'PM'], frequency: 'daily', desc: 'קרם עתיר סרמידים, סקווולן וקוליסטרול לחיזוק שכבת השומנים של העור.' },
  { id: 'spf50', name: 'Invisible Shield SPF 50', category: 'spf', thumb: 'spf', subtitle: 'הגנה מהשמש ללא תחושת כבד', tags: ['AM'], frequency: 'daily', desc: 'הגנה רחבת טווח על בסיס מינרלי, ללא ליפוף לבן.' },
  { id: 'spf-invisible', name: 'Invisible SPF 50', category: 'spf', thumb: 'spf', subtitle: 'הגנה • אורך אצבע', tags: ['AM'], frequency: 'daily', desc: 'נמרח שקוף על כל גוון עור, מתאים כבסיס לאיפור.' },
  { id: 'exfoliant', name: 'Liquid Exfoliant 2% BHA', category: 'serum', thumb: null, subtitle: 'ניקוי בקבוביות עמוק', tags: ['PM'], frequency: { max: 3 }, conflictsWith: ['retinol', 'vitc', 'vitc-bright'], desc: 'BHA לטיהור נקבוביות והבהרת מרקם. שימוש מומלץ 2–3 פעמים בשבוע.' },
  { id: 'eye-cream', name: 'Brightening Eye Cream', category: 'cream', thumb: null, subtitle: 'טיפול בעיגולים כהים ונפיחות', tags: ['AM', 'PM'], frequency: 'daily', desc: 'קומפלקס קפאין ופפטידים להבהרה ומיצוק עור העפעפיים.' },
  { id: 'retinol', name: '0.5% Retinol Serum', category: 'serum', thumb: 'retinol', subtitle: 'טיפול • גודל אפונה', tags: ['PM'], frequency: { max: 3 }, conflictsWith: ['exfoliant', 'vitc', 'vitc-bright'], desc: 'רטינול ממומס בליפידים לחידוש הדרגתי ועדין של פני העור.' },
  { id: 'night-repair', name: 'Night Repair Cream', category: 'cream', thumb: 'cream', subtitle: 'לחות • שכבה נדיבה', tags: ['PM'], frequency: 'daily', desc: 'קרם לילה עשיר עם עץ הצנדל ופפטידים, פועל בעמקי הרבדים בזמן השינה.' },
  { id: 'botanical-barrier', name: 'Botanical Barrier Repair', category: 'serum', thumb: 'bottle', subtitle: 'פורמולה מרגיעה לעור רגיש', tags: ['AM', 'PM'], frequency: 'daily', desc: 'הפורמולה הזו היא הבחירה המועדפת עלינו למצבי עור רגיש. היא מחקה את הליפידים הטבעיים של העור כדי לשקם את המעטפת החומצית ללא תחושת כבדות.' },
];

const WEEKDAYS = [
  { id: 0, short: 'א', label: 'ראשון' },
  { id: 1, short: 'ב', label: 'שני' },
  { id: 2, short: 'ג', label: 'שלישי' },
  { id: 3, short: 'ד', label: 'רביעי' },
  { id: 4, short: 'ה', label: 'חמישי' },
  { id: 5, short: 'ו', label: 'שישי' },
  { id: 6, short: 'ש', label: 'שבת' },
];

const CATEGORIES = [
  { id: 'all', label: 'הכל' },
  { id: 'cleanser', label: 'ניקוי' },
  { id: 'serum', label: 'סרומים' },
  { id: 'cream', label: 'לחות' },
  { id: 'spf', label: 'SPF' },
  { id: 'eye', label: 'עיניים' },
];

const TODAY_ROUTINE = {
  morning: [
    { id: 'gentle-milk', name: 'Gentle Milk Cleanser', thumb: 'cleanser', subtitle: 'ניקוי • 2 לחיצות' },
    { id: 'vitc-bright', name: 'Vitamin C Brightener', thumb: 'vitc', subtitle: 'סרום • 3 טיפות' },
    { id: 'spf-invisible', name: 'Invisible SPF 50', thumb: 'spf', subtitle: 'הגנה • אורך אצבע' },
  ],
  evening: [
    { id: 'retinol', name: '0.5% Retinol Serum', thumb: 'retinol', subtitle: 'טיפול • גודל אפונה' },
    { id: 'night-repair', name: 'Night Repair Cream', thumb: 'cream', subtitle: 'לחות • שכבה נדיבה' },
  ],
};

// ===================== HOME (S4) =====================
function HomeScreen({ goTo, userName }) {
  const [done, setDone] = useStateS({ 'gentle-milk': true });
  const toggle = (id) => setDone(d => ({ ...d, [id]: !d[id] }));

  const amDone = TODAY_ROUTINE.morning.filter(p => done[p.id]).length;
  const pmDone = TODAY_ROUTINE.evening.filter(p => done[p.id]).length;
  const totalDone = amDone + pmDone;
  const totalAll = TODAY_ROUTINE.morning.length + TODAY_ROUTINE.evening.length;

  // ring math
  const R = 30;
  const C = 2 * Math.PI * R;
  const dashOffset = C - (totalDone / totalAll) * C;

  return (
    <div className="screen-enter pb-28">
      <AppBar />

      <div className="px-5 pt-2">
        {/* Streak banner */}
        <div className="relative rounded-[28px] p-5 text-white overflow-hidden streak-gradient shadow-glow-lg">
          {/* sparkles */}
          <div className="absolute top-3 left-4 text-white/60 text-xl">✦</div>
          <div className="absolute bottom-5 left-8 text-white/40 text-base">✧</div>
          <div className="absolute top-7 right-32 text-white/40 text-sm">✦</div>

          <div className="flex items-center gap-4">
            {/* progress ring */}
            <div className="relative w-[88px] h-[88px] flex-shrink-0">
              <svg width="88" height="88" viewBox="0 0 88 88" className="rotate-[-90deg]">
                <circle cx="44" cy="44" r={R} stroke="rgba(255,255,255,0.25)" strokeWidth="6" fill="none" />
                <circle
                  cx="44" cy="44" r={R}
                  stroke="white" strokeWidth="6" fill="none"
                  strokeLinecap="round"
                  strokeDasharray={C}
                  strokeDashoffset={dashOffset}
                  style={{ transition: 'stroke-dashoffset .4s ease' }}
                />
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="quick font-bold text-white text-[22px] leading-none">{totalDone}/{totalAll}</span>
                <span className="quick text-[11px] text-white/90 mt-1">היום</span>
              </div>
            </div>

            {/* copy */}
            <div className="flex-1 text-right">
              <p className="quick text-[17px] font-bold leading-tight">רצף של 5 ימים</p>
              <p className="quick text-[13px] text-white/90 leading-snug mt-0.5">את בדרך הנכונה לזוהר מושלם!</p>
              <p className="label text-[11px] text-white/85 mt-2 font-bold tracking-wide">שיא אישי: 12 ימים</p>
            </div>
          </div>
        </div>

        {/* Header */}
        <div className="text-center mt-7 mb-4">
          <p className="quick text-[13px] text-primary font-bold mb-1">יום שני{userName ? ` · שלום ${userName.split(' ')[0]}` : ''}</p>
          <h2 className="quick font-bold text-[24px] text-on-surface">השגרה שלך היום</h2>
        </div>

        {/* Morning slot */}
        <SlotHeader slot="morning" count={amDone} total={TODAY_ROUTINE.morning.length} />
        <div className="space-y-2">
          {TODAY_ROUTINE.morning.map(p => (
            <RoutineRow
              key={p.id}
              item={p}
              variant="done"
              checked={!!done[p.id]}
              onToggle={() => toggle(p.id)}
            />
          ))}
        </div>

        {/* Evening slot */}
        <SlotHeader slot="evening" count={pmDone} total={TODAY_ROUTINE.evening.length} />
        <div className="space-y-2">
          {TODAY_ROUTINE.evening.map(p => (
            <RoutineRow
              key={p.id}
              item={p}
              variant="done"
              checked={!!done[p.id]}
              onToggle={() => toggle(p.id)}
            />
          ))}
        </div>

        {/* Journal CTA */}
        <div className="mt-6 rounded-[28px] p-4 streak-gradient text-white shadow-glow-lg relative overflow-hidden" dir="rtl">
          <div className="flex items-center gap-3" dir="rtl">
            <div className="flex-1 text-right">
              <p className="quick text-[15px] font-bold leading-tight">איך העור מרגיש?</p>
              <p className="quick text-[12px] text-white/90 leading-snug mt-0.5">תעדי את התקדמותך</p>
            </div>
            <button
              onClick={() => goTo('journal')}
              className="flex-shrink-0 h-12 px-6 rounded-full bg-white text-primary quick font-bold text-[15px] active:scale-[0.97] transition shadow-md"
            >
              תיעוד עכשיו
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ===================== PRODUCTS (S1 — selection) =====================
function ProductsScreen({ goTo, openProduct, selected, setSelected }) {
  const [slot, setSlot] = useStateS('morning');
  const [cat, setCat] = useStateS('all');
  const [q, setQ] = useStateS('');

  const toggle = (id) => setSelected(s => ({ ...s, [id]: !s[id] }));
  const totalSelected = Object.values(selected).filter(Boolean).length;
  const occasionalSelectedCount = MASTER_PRODUCTS.filter(p => selected[p.id] && p.frequency !== 'daily').length;

  const filtered = MASTER_PRODUCTS.filter(p => {
    if (cat !== 'all' && p.category !== cat) return false;
    if (slot === 'morning' && !p.tags.includes('AM')) return false;
    if (slot === 'evening' && !p.tags.includes('PM')) return false;
    if (q && !p.name.toLowerCase().includes(q.toLowerCase())) return false;
    return true;
  });

  return (
    <div className="screen-enter pb-40">
      <AppBar />

      <div className="px-5 pt-2">
        {/* Step indicator */}
        <StepIndicator current={1} steps={['בחירה', 'תזמון']} />

        {/* AM/PM toggle */}
        <div className="relative flex p-1 bg-surface-low rounded-full mt-4" role="tablist">
          <button
            role="tab"
            aria-selected={slot === 'morning'}
            onClick={() => setSlot('morning')}
            className={`relative flex-1 h-11 rounded-full quick font-bold text-[15px] flex items-center justify-center gap-2 transition-all ${
              slot === 'morning' ? 'bg-primary-container text-white shadow-glow-sm' : 'text-on-surface-variant'
            }`}
          >
            <Icon name="wb_sunny" fill size={18} />
            בוקר
          </button>
          <button
            role="tab"
            aria-selected={slot === 'evening'}
            onClick={() => setSlot('evening')}
            className={`relative flex-1 h-11 rounded-full quick font-bold text-[15px] flex items-center justify-center gap-2 transition-all ${
              slot === 'evening' ? 'bg-tertiary text-white shadow-glow-sm' : 'text-on-surface-variant'
            }`}
          >
            <Icon name="dark_mode" fill size={18} />
            ערב
          </button>
        </div>
        <p className="text-center quick text-[13px] text-on-surface-variant mt-2">
          בניית שגרת <span className="font-bold text-primary">{slot === 'morning' ? 'הבוקר' : 'הערב'}</span> שלך • <span className="font-bold">{totalSelected}</span> מוצרים נבחרו
        </p>

        {/* Search */}
        <div className="relative mt-4">
          <input
            type="text"
            value={q}
            onChange={e => setQ(e.target.value)}
            placeholder="חיפוש במוצרי המערכת..."
            className="w-full h-12 bg-surface-low rounded-full ps-12 pe-5 quick text-[15px] placeholder:text-outline/60 text-on-surface border-none focus:ring-2 focus:ring-primary/30 outline-none text-right"
          />
          <span className="absolute start-4 top-1/2 -translate-y-1/2 text-outline">
            <Icon name="search" size={20} />
          </span>
        </div>

        {/* Category chips */}
        <div className="mt-3 -mx-1 overflow-x-auto no-scrollbar">
          <div className="flex gap-2 px-1 py-1 min-w-max flex-row-reverse justify-end">
            {CATEGORIES.map(c => {
              const active = cat === c.id;
              return (
                <button
                  key={c.id}
                  onClick={() => setCat(c.id)}
                  className={`px-4 h-9 rounded-full quick text-[14px] font-bold transition whitespace-nowrap ${
                    active
                      ? 'bg-primary text-white shadow-glow-sm'
                      : 'bg-primary-fixed/40 text-on-primary-container hover:bg-primary-fixed/70'
                  }`}
                >
                  {c.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Product list */}
        <div className="mt-4 space-y-2.5">
          {filtered.length === 0 && (
            <div className="text-center py-12 text-on-surface-variant quick text-[14px]">
              לא נמצאו מוצרים תואמים.
            </div>
          )}
          {filtered.map(p => (
            <div
              key={p.id}
              onClick={() => openProduct(p.id)}
              className="cursor-pointer"
            >
              <RoutineRow
                item={{ ...p, subtitle: p.frequency === 'daily' ? p.subtitle : `${p.subtitle} • עד ${p.frequency.max}× בשבוע` }}
                variant="select"
                checked={!!selected[p.id]}
                onToggle={(e) => { if (e && e.stopPropagation) e.stopPropagation(); toggle(p.id); }}
              />
            </div>
          ))}
        </div>
      </div>

      {/* Sticky "Continue to scheduling" CTA */}
      <div className="sticky bottom-24 z-30 px-5 mt-6">
        <button
          onClick={() => goTo('schedule')}
          disabled={totalSelected === 0}
          className="w-full h-14 rounded-full bg-gradient-to-l from-primary to-primary-container text-white quick font-bold text-[16px] shadow-glow-lg active:scale-[0.98] transition flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
        >
          <Icon name="arrow_back" size={20} />
          המשך לתזמון
          {occasionalSelectedCount > 0 && (
            <span className="label-sm text-[11px] bg-white/30 px-2 py-0.5 rounded-full">
              {occasionalSelectedCount} לתזמון
            </span>
          )}
        </button>
      </div>
    </div>
  );
}

// ===================== JOURNAL (S6 + S7 + S8) =====================
function JournalScreen({ goTo }) {
  const [selectedDay, setSelectedDay] = useStateS(3);
  const [mood, setMood] = useStateS('calm');
  const [notes, setNotes] = useStateS('העור מרגיש רגוע במיוחד הבוקר. האדמומיות בלחיים פחתה משמעותית. הקפדתי על שתיית מים מרובה.');
  const [tasks, setTasks] = useStateS({ 'morning-cleanse': true, 'spf50': true, 'vitc': false });

  // Build a small September 2023 calendar grid
  const days = [];
  // Sept 1 2023 was a Friday. RTL Hebrew calendar week starts on Sunday (א').
  // Sunday=0, Mon=1, ... Sat=6. Sept 1 fri => weekday 5. Leading blanks: 5.
  const firstOffset = 5;
  for (let i = 0; i < firstOffset; i++) days.push(null);
  for (let d = 1; d <= 30; d++) days.push(d);

  const statusFor = (d) => {
    if (d === 1) return 'partial';
    if (d === 2) return 'complete';
    if (d === 3) return 'today';
    if (d > 3) return 'future';
    return 'missed';
  };
  const statusColor = (s, isSelected) => {
    if (s === 'today') return 'text-primary font-bold';
    if (s === 'complete') return 'text-on-surface';
    if (s === 'partial') return 'text-on-surface';
    if (s === 'missed') return 'text-outline/60';
    if (s === 'future') return 'text-outline/40';
    return '';
  };
  const dotColor = (s) => {
    if (s === 'complete') return 'bg-secondary'; // green-yellow
    if (s === 'partial') return 'bg-primary-container';
    if (s === 'today') return 'bg-primary';
    if (s === 'missed') return 'bg-error/40';
    return '';
  };

  return (
    <div className="screen-enter pb-28">
      <AppBar />

      <div className="px-5 pt-2">
        {/* Stats row */}
        <div className="grid grid-cols-2 gap-3">
          <Card className="text-center p-4">
            <p className="quick text-[13px] text-on-surface-variant">ממוצע חודשי</p>
            <p className="quick text-[28px] font-bold text-primary mt-1">92%</p>
            <div className="h-1.5 bg-primary-fixed/50 rounded-full overflow-hidden mt-2">
              <div className="h-full bg-primary-container rounded-full" style={{ width: '92%' }} />
            </div>
          </Card>
          <Card className="text-center p-4">
            <p className="quick text-[13px] text-on-surface-variant">התקדמות</p>
            <p className="quick text-[24px] font-bold text-primary mt-1 flex items-center justify-center gap-1">
              <Icon name="trending_up" size={20} className="text-primary-container" />
              +12%
            </p>
            <p className="quick text-[11px] text-on-surface-variant mt-1">שיפור פני העור</p>
          </Card>
        </div>

        {/* Calendar */}
        <Card className="mt-4 p-4">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center gap-1 text-primary">
              <button className="w-7 h-7 rounded-full hover:bg-primary-fixed/50 flex items-center justify-center" aria-label="חודש קודם">
                <Icon name="chevron_right" size={20} />
              </button>
              <button className="w-7 h-7 rounded-full hover:bg-primary-fixed/50 flex items-center justify-center" aria-label="חודש הבא">
                <Icon name="chevron_left" size={20} />
              </button>
            </div>
            <h3 className="quick font-bold text-[18px] text-on-surface">ספטמבר 2023</h3>
          </div>
          {/* week header (Sunday-first as per brief; RTL means א' is rightmost visually) */}
          <div className="grid grid-cols-7 gap-1 text-center label-sm text-on-surface-variant/70 text-[11px] mb-1" dir="rtl">
            {['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'].map(d => (
              <div key={d}>{`'${d}`}</div>
            ))}
          </div>
          {/* day grid */}
          <div className="grid grid-cols-7 gap-1" dir="rtl">
            {days.map((d, i) => {
              if (!d) return <div key={i} className="aspect-square" />;
              const s = statusFor(d);
              const isSelected = d === selectedDay;
              return (
                <button
                  key={i}
                  onClick={() => setSelectedDay(d)}
                  className={`aspect-square rounded-full flex flex-col items-center justify-center quick text-[14px] transition ${
                    isSelected ? 'bg-primary-fixed/60' : 'hover:bg-surface-low'
                  } ${statusColor(s, isSelected)}`}
                >
                  <span className={s === 'today' ? 'text-primary font-bold' : ''}>{d}</span>
                  {dotColor(s) && (
                    <span className={`w-1 h-1 rounded-full mt-0.5 ${dotColor(s)}`} />
                  )}
                </button>
              );
            })}
          </div>
          {/* legend */}
          <div className="flex items-center justify-end gap-3 mt-2 text-[10px] label-sm text-on-surface-variant">
            <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-secondary"></span>הושלם</span>
            <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-primary-container"></span>חלקי</span>
            <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-primary"></span>היום</span>
          </div>
        </Card>

        {/* Day detail header */}
        <div className="flex items-center justify-between mt-5 mb-3 px-1">
          <button className="quick text-[13px] text-primary font-bold flex items-center gap-1">
            <Icon name="edit" size={16} />
            ערוך
          </button>
          <h3 className="quick font-bold text-[17px] text-on-surface">
            יומן יומיומי: 3 בספטמבר
          </h3>
        </div>

        {/* Photo + add slot */}
        <div className="grid grid-cols-2 gap-3">
          {/* Add photo */}
          <button className="aspect-square rounded-[28px] border-2 border-dashed border-primary-container/60 bg-primary-fixed/20 flex flex-col items-center justify-center gap-2 active:scale-[0.98] transition">
            <div className="w-12 h-12 rounded-full bg-primary-fixed/60 flex items-center justify-center text-primary">
              <Icon name="add_a_photo" size={24} />
            </div>
            <span className="quick text-[14px] text-primary font-bold">הוסף תמונה</span>
          </button>
          {/* Existing photo with caption */}
          <div className="relative aspect-square rounded-[28px] overflow-hidden bg-surface-high">
            <img
              src="https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=400&fit=crop"
              alt=""
              className="w-full h-full object-cover"
            />
            <div className="absolute bottom-2 left-2 right-2 bg-white/95 backdrop-blur rounded-full py-1 px-3 text-center quick text-[12px] text-on-surface-variant">
              פרופיל קדמי
            </div>
          </div>
        </div>

        {/* Mood + notes */}
        <Card className="mt-4 p-4">
          <div className="flex items-center gap-2 justify-between mb-2">
            <div className="w-9 h-9 rounded-full bg-secondary-fixed flex items-center justify-center">
              <Icon name="mood" size={20} className="text-on-secondary-container" />
            </div>
            <h4 className="quick font-bold text-[16px] text-on-surface">מצב העור היום</h4>
          </div>
          <p className="quick text-[14px] text-on-surface-variant leading-relaxed text-right" dir="rtl">
            {notes}
          </p>
          <div className="flex items-center justify-end gap-2 mt-3">
            {[
              { id: 'calm', label: 'רגוע', color: 'bg-tertiary-fixed text-on-tertiary-container' },
              { id: 'moist', label: 'לח', color: 'bg-secondary-fixed text-on-secondary-container' },
              { id: 'oily', label: 'שמני', color: 'bg-primary-fixed text-on-primary-container' },
            ].map(t => (
              <button
                key={t.id}
                onClick={() => setMood(t.id)}
                className={`px-3 h-7 rounded-full label text-[12px] font-bold transition ${
                  mood === t.id ? `${t.color} ring-2 ring-primary/30` : 'bg-surface-low text-on-surface-variant'
                }`}
              >
                {t.label}
              </button>
            ))}
          </div>
        </Card>

        {/* Today's tasks */}
        <div className="mt-4 rounded-[28px] bg-primary-fixed/25 p-5 border border-primary-fixed/40">
          <h4 className="quick font-bold text-[16px] text-primary text-right mb-3">משימות שביצעו היום:</h4>
          <ul className="space-y-2">
            {[
              { id: 'morning-cleanse', label: 'ניקוי פנים בוקר' },
              { id: 'spf50', label: 'קרם הגנה (SPF 50)' },
              { id: 'vitc', label: 'סרום ויטמין C' },
            ].map(t => {
              const done = !!tasks[t.id];
              return (
                <li key={t.id}>
                  <button
                    onClick={() => setTasks(prev => ({ ...prev, [t.id]: !prev[t.id] }))}
                    className="w-full bg-white rounded-full px-4 h-12 flex items-center justify-between shadow-glow-sm active:scale-[0.99] transition"
                  >
                    <span className={`flex-shrink-0 w-7 h-7 rounded-full flex items-center justify-center transition ${
                      done ? 'bg-secondary text-white' : 'bg-surface-low border-2 border-outline-variant'
                    }`}>
                      {done && <Icon name="check" size={16} />}
                    </span>
                    <span className={`quick text-[15px] ${done ? 'text-on-surface' : 'text-on-surface-variant'}`}>
                      {t.label}
                    </span>
                  </button>
                </li>
              );
            })}
          </ul>
        </div>
      </div>
    </div>
  );
}

// ===================== PROFILE (S11 — settings) =====================
function ProfileScreen({ goTo, name, setName, gender, setGender }) {

  const items = [
    { id: 'select', icon: 'tune', label: 'בחירה ותזמון מוצרים', subtitle: 'שני שלבים: בחירה ↔ תזמון שבועי', screen: 'products' },
    { id: 'order', icon: 'reorder', label: 'סדר השגרה', subtitle: 'גרור לסידור אישי', screen: 'order' },
    { id: 'export', icon: 'cloud_download', label: 'ייצוא וייבוא', subtitle: 'גיבוי מקומי של הנתונים' },
    { id: 'reset-onboarding', icon: 'restart_alt', label: 'שחזר הצגת מסך הפתיחה', subtitle: 'לצרכי תצוגה / דמו' },
    { id: 'about', icon: 'info', label: 'אודות ומה חדש', subtitle: 'גרסה 1.0 • יומן שינויים' },
  ];

  const genderOptions = [
    { id: 'female', label: 'נקבה' },
    { id: 'male', label: 'זכר' },
  ];

  return (
    <div className="screen-enter pb-28">
      <AppBar back onBack={() => goTo('home')} />

      <div className="px-5 pt-2">
        {/* Greeting */}
        <div className="text-right mb-4" dir="rtl">
          <h2 className="quick font-bold text-[24px] text-on-surface">שלום{name ? `, ${name.split(' ')[0]}` : ''}</h2>
          <p className="quick text-[13px] text-on-surface-variant mt-0.5">חברה ב־הGlow Protocol מאז ינואר</p>
        </div>

        {/* Quick stats */}
        <Card className="p-4">
          <div className="grid grid-cols-3 gap-2">
            <div className="text-center">
              <p className="quick text-[24px] font-bold text-primary leading-none">5</p>
              <p className="quick text-[11px] text-on-surface-variant mt-1">ימי רצף</p>
            </div>
            <div className="text-center border-x border-outline-variant/30">
              <p className="quick text-[24px] font-bold text-primary leading-none">92%</p>
              <p className="quick text-[11px] text-on-surface-variant mt-1">השלמה</p>
            </div>
            <div className="text-center">
              <p className="quick text-[24px] font-bold text-primary leading-none">7</p>
              <p className="quick text-[11px] text-on-surface-variant mt-1">מוצרים</p>
            </div>
          </div>
        </Card>

        {/* Personal Info */}
        <h3 className="quick font-bold text-[14px] text-on-surface-variant text-right mt-5 mb-2 px-1">פרטים אישיים</h3>
        <Card className="p-4 space-y-4" dir="rtl">
          {/* Name */}
          <div>
            <label className="quick text-[12px] font-bold text-on-surface-variant mb-1 block text-right">שם מלא</label>
            <input
              type="text"
              value={name}
              onChange={e => setName(e.target.value)}
              className="w-full h-11 bg-surface-low rounded-full px-4 quick text-[15px] text-on-surface border border-transparent focus:border-primary-container focus:bg-white focus:ring-2 focus:ring-primary/20 outline-none text-right transition"
              dir="rtl"
              placeholder="הקלידי את שמך"
            />
          </div>

          {/* Gender */}
          <div>
            <label className="quick text-[12px] font-bold text-on-surface-variant mb-1.5 block text-right">מגדר</label>
            <div className="flex gap-1.5" dir="rtl">
              {genderOptions.map(o => (
                <button
                  key={o.id}
                  onClick={() => setGender(o.id)}
                  className={`flex-1 h-10 rounded-full quick font-bold text-[14px] transition active:scale-95 ${
                    gender === o.id
                      ? 'bg-primary text-white shadow-glow-sm'
                      : 'bg-surface-low text-on-surface-variant hover:bg-primary-fixed/40'
                  }`}
                >
                  {o.label}
                </button>
              ))}
            </div>
          </div>
        </Card>

        {/* Settings list */}
        <h3 className="quick font-bold text-[14px] text-on-surface-variant text-right mt-5 mb-2 px-1">הגדרות</h3>
        <div className="space-y-2">
          {items.map(it => (
            <button
              key={it.id}
              onClick={() => it.screen && goTo(it.screen)}
              className="w-full bg-white rounded-[24px] shadow-glow-sm p-4 flex items-center gap-3 active:scale-[0.99] transition"
              dir="rtl"
            >
              <div className="w-11 h-11 rounded-2xl bg-primary-fixed/50 flex items-center justify-center text-primary flex-shrink-0">
                <Icon name={it.icon} size={22} />
              </div>
              <div className="flex-1 text-right min-w-0">
                <p className="quick font-bold text-[15px] text-on-surface truncate">{it.label}</p>
                <p className="quick text-[12px] text-on-surface-variant truncate">{it.subtitle}</p>
              </div>
              <div className="text-on-surface-variant">
                <Icon name="chevron_left" size={22} />
              </div>
            </button>
          ))}
        </div>

        {/* Storage warning */}
        <div className="mt-5 rounded-[24px] bg-error-container/60 border border-error/20 p-4" dir="rtl">
          <div className="flex items-center gap-2">
            <Icon name="cloud_off" size={18} className="text-error" />
            <h4 className="quick font-bold text-[14px] text-error">תזכורת גיבוי</h4>
          </div>
          <p className="quick text-[12px] text-on-surface-variant mt-1 text-right">
            עברו 32 ימים מאז הגיבוי האחרון. מומלץ לייצא עותק עכשיו.
          </p>
        </div>
      </div>
    </div>
  );
}

// ===================== ORDER CUSTOMIZATION (S3) =====================
function OrderScreen({ goBack }) {
  const [slot, setSlot] = useStateS('morning');
  const [items, setItems] = useStateS({
    morning: [
      { id: 'cleanser', name: 'Gentle Cleanser', subtitle: 'ניקוי ראשוני עדין', thumb: 'cleanser' },
      { id: 'vitc', name: 'Vitamin C Serum', subtitle: 'הבהרה והגנה מחמצון', thumb: 'vitc' },
      { id: 'ha', name: 'Hyaluronic Acid', subtitle: 'לחות עמוקה', thumb: null, fallbackIcon: 'water_drop' },
      { id: 'eye', name: 'Caffeine Eye Cream', subtitle: 'טיפול בנפיחות מתחת לעיניים', thumb: null, fallbackIcon: 'visibility' },
      { id: 'moist', name: 'Moisturizing Gel', subtitle: 'לחות קלילה ליום', thumb: null, fallbackIcon: 'water_drop' },
      { id: 'spf', name: 'SPF 50 Sunscreen', subtitle: 'הגנה יומית קריטית', thumb: 'spf' },
      { id: 'mist', name: 'Face Mist', subtitle: 'רענון ונעילת לחות', thumb: null, fallbackIcon: 'air' },
    ],
    evening: [
      { id: 'oil', name: 'Cleansing Oil', subtitle: 'הסרת איפור ולכלוך שומני', thumb: 'bottle' },
      { id: 'foam', name: 'Foam Cleanser', subtitle: 'ניקוי שני על בסיס מים', thumb: null, fallbackIcon: 'soap' },
      { id: 'retinol', name: '0.5% Retinol', subtitle: 'חידוש העור', thumb: 'retinol' },
      { id: 'pep', name: 'Peptide Serum', subtitle: 'שיפור אלסטיות העור', thumb: null, fallbackIcon: 'science' },
      { id: 'night', name: 'Night Recovery Balm', subtitle: 'הזנה עמוקה בלילה', thumb: 'cream' },
    ],
  });

  const list = items[slot];
  const dragIdx = useRefS(null);

  const onDragStart = (i) => (e) => {
    dragIdx.current = i;
    try { e.dataTransfer.setData('text/plain', ''); } catch (_) {}
    e.currentTarget.classList.add('opacity-50');
  };
  const onDragOver = (i) => (e) => {
    e.preventDefault();
    const from = dragIdx.current;
    if (from == null || from === i) return;
    setItems(prev => {
      const next = [...prev[slot]];
      const [m] = next.splice(from, 1);
      next.splice(i, 0, m);
      dragIdx.current = i;
      return { ...prev, [slot]: next };
    });
  };
  const onDragEnd = (e) => {
    e.currentTarget.classList.remove('opacity-50');
    dragIdx.current = null;
  };

  return (
    <div className="screen-enter pb-28">
      <AppBar back onBack={goBack} />

      <div className="px-5 pt-2">
        <div className="text-right mb-4">
          <h2 className="quick font-bold text-[24px] text-on-surface">קביעת סדר שגרה</h2>
          <p className="quick text-[13px] text-on-surface-variant mt-1">גררו את המוצרים כדי לסדר את השגרה שלכם</p>
        </div>

        {/* slot tabs */}
        <div className="flex p-1 bg-surface-low rounded-full">
          <button
            onClick={() => setSlot('morning')}
            className={`flex-1 h-10 rounded-full quick font-bold text-[14px] transition ${
              slot === 'morning' ? 'bg-primary text-white shadow-glow-sm' : 'text-on-surface-variant'
            }`}
          >
            בוקר
          </button>
          <button
            onClick={() => setSlot('evening')}
            className={`flex-1 h-10 rounded-full quick font-bold text-[14px] transition ${
              slot === 'evening' ? 'bg-tertiary text-white shadow-glow-sm' : 'text-on-surface-variant'
            }`}
          >
            ערב
          </button>
        </div>

        {/* slot heading */}
        <div className="flex items-center gap-2 mt-4 mb-2 justify-end" dir="rtl">
          <Icon name={slot === 'morning' ? 'wb_sunny' : 'dark_mode'} fill size={20}
                className={slot === 'morning' ? 'text-primary-container' : 'text-tertiary'} />
          <h3 className="quick font-bold text-[16px] text-on-surface">
            סדר שגרת {slot === 'morning' ? 'בוקר' : 'ערב'}
          </h3>
        </div>

        <div className="space-y-2">
          {list.map((p, i) => (
            <div
              key={p.id}
              draggable
              onDragStart={onDragStart(i)}
              onDragOver={onDragOver(i)}
              onDragEnd={onDragEnd}
              onDrop={(e) => e.preventDefault()}
              className="cursor-grab active:cursor-grabbing"
            >
              <RoutineRow item={p} variant="drag" draggable={false} />
            </div>
          ))}
        </div>

        {/* Reset & save */}
        <div className="mt-5 flex flex-col gap-2">
          <button className="w-full h-12 rounded-full bg-surface-low quick font-bold text-[14px] text-primary border border-primary-fixed">
            איפוס לסדר המומלץ
          </button>
          <button className="w-full h-14 rounded-full bg-gradient-to-l from-primary to-primary-container text-white quick font-bold text-[16px] shadow-glow-lg active:scale-[0.98] transition">
            שמירת הסדר החדש
          </button>
        </div>
      </div>
    </div>
  );
}

// ===================== PRODUCT DETAIL =====================
function ProductDetailScreen({ productId, goBack }) {
  const p = MASTER_PRODUCTS.find(x => x.id === productId) || MASTER_PRODUCTS.find(x => x.id === 'botanical-barrier');

  const ingredients = ['Gotu Kola', 'Ceramides NP', 'Oat Extract', 'Squalane', 'Niacinamide'];

  return (
    <div className="screen-enter pb-28">
      <AppBar back onBack={goBack} title="The Glow Protocol" />

      {/* Hero photo */}
      <div className="relative h-[42vh] min-h-[280px] max-h-[360px] bg-gradient-to-b from-[#f3d8c2] via-[#ead2bd] to-[#e7c9b0] overflow-hidden">
        {PRODUCT_IMAGES[p.thumb] && (
          <img src={PRODUCT_IMAGES[p.thumb]} alt="" className="w-full h-full object-cover" />
        )}
        {!PRODUCT_IMAGES[p.thumb] && (
          <div className="w-full h-full flex items-center justify-center">
            <div className="w-44 h-56 rounded-3xl bg-white/40 backdrop-blur border border-white/60 flex items-center justify-center text-on-surface-variant quick">
              product shot
            </div>
          </div>
        )}
        {/* soft white pebble peeking */}
        <div className="absolute -bottom-8 left-0 right-0 h-16 bg-white rounded-t-[48px]" />
      </div>

      <div className="bg-white rounded-t-[48px] -mt-8 relative z-10 px-6 pt-5 pb-6">
        {/* category pill */}
        <div className="flex justify-center">
          <span className="quick text-[12px] font-bold bg-secondary-fixed text-on-secondary-container px-4 h-7 rounded-full inline-flex items-center">
            {p.category === 'serum' ? 'סרום מרוכז' : p.category === 'cleanser' ? 'תכשיר ניקוי' : p.category === 'cream' ? 'קרם פנים' : p.category === 'spf' ? 'הגנה מהשמש' : 'מוצר טיפוח'}
          </span>
        </div>

        <h1 className="quick font-bold text-[28px] leading-tight text-on-surface text-center mt-3" dir="ltr">{p.name}</h1>
        <p className="quick text-[14px] text-on-surface-variant text-center mt-1">{p.subtitle}</p>

        {/* spec pills */}
        <div className="grid grid-cols-2 gap-3 mt-5">
          <div className="bg-primary-fixed/40 rounded-[24px] p-4 text-center">
            <div className="flex items-center justify-center gap-1 text-primary">
              <Icon name="dark_mode" fill size={18} />
              <Icon name="wb_sunny" fill size={18} />
            </div>
            <p className="quick text-[11px] text-on-surface-variant mt-1">שגרה</p>
            <p className="quick font-bold text-[15px] text-primary mt-1">
              {p.tags.includes('AM') && p.tags.includes('PM') ? 'בוקר + ערב' : p.tags.includes('AM') ? 'בוקר' : 'ערב'}
            </p>
          </div>
          <div className="bg-primary-fixed/40 rounded-[24px] p-4 text-center">
            <Icon name="event" size={20} className="text-primary" />
            <p className="quick text-[11px] text-on-surface-variant mt-1">תדירות</p>
            <p className="quick font-bold text-[15px] text-primary mt-1">יומי</p>
          </div>
        </div>

        {/* curator note */}
        <div className="flex items-center gap-2 justify-end mt-5">
          <h3 className="quick font-bold text-[16px] text-on-surface">כמה מילים...</h3>
          <div className="w-7 h-7 rounded-full bg-primary-container flex items-center justify-center text-white">
            <Icon name="auto_awesome" fill size={16} />
          </div>
        </div>
        <div className="mt-2 bg-primary-fixed/40 rounded-[24px] p-4 border-e-4 border-primary-container" dir="rtl">
          <p className="quick text-[14px] italic text-on-surface leading-relaxed text-right">
            "{p.desc}"
          </p>
        </div>

        {/* ingredients */}
        <h3 className="quick font-bold text-[16px] text-on-surface text-right mt-5">מרכיבים עיקריים</h3>
        <div className="flex flex-wrap gap-2 mt-2 justify-end">
          {ingredients.map(ing => (
            <span key={ing} className="label text-[12px] font-bold bg-white border border-outline-variant px-4 h-8 rounded-full inline-flex items-center" dir="ltr">
              {ing}
            </span>
          ))}
        </div>
      </div>

      {/* sticky CTA */}
      <div className="px-5 pb-3 mt-2">
        <button className="w-full h-14 rounded-full bg-gradient-to-l from-primary to-primary-container text-white quick font-bold text-[16px] shadow-glow-lg active:scale-[0.98] transition flex items-center justify-center gap-2">
          <Icon name="shopping_bag" size={20} />
          הוספה למוצרים שלי
        </button>
      </div>
    </div>
  );
}

Object.assign(window, {
  HomeScreen, ProductsScreen, JournalScreen, ProfileScreen, OrderScreen, ProductDetailScreen,
  ScheduleScreen,
  MASTER_PRODUCTS, TODAY_ROUTINE, CATEGORIES, WEEKDAYS,
});

// ===================== SCHEDULE SETUP (S2) =====================
// For each selected occasional product: pick weekdays. Show:
//  - per-product weekly cap soft warning when over
//  - day-level conflict warnings (same slot, incompatible actives)
function ScheduleScreen({ selected, schedule, setSchedule, goBack, onDone }) {
  const [slot, setSlot] = useStateS('evening'); // most occasional products are PM

  // selected occasional products in the chosen slot
  const occasionalInSlot = MASTER_PRODUCTS.filter(p =>
    selected[p.id] && p.frequency !== 'daily' && p.tags.includes(slot === 'morning' ? 'AM' : 'PM')
  );

  // Daily products that auto-run every day (read-only context for conflict checking)
  const dailyInSlot = MASTER_PRODUCTS.filter(p =>
    selected[p.id] && p.frequency === 'daily' && p.tags.includes(slot === 'morning' ? 'AM' : 'PM')
  );

  const toggleDay = (productId, dayId) => {
    setSchedule(prev => {
      const cur = prev[productId] || {};
      const next = { ...cur };
      if (next[dayId]) delete next[dayId];
      else next[dayId] = true;
      return { ...prev, [productId]: next };
    });
  };

  // Returns count of days a product is scheduled this week.
  const daysCount = (productId) => Object.values(schedule[productId] || {}).filter(Boolean).length;

  // Build day -> products list for this slot (occasional + daily)
  const productsOnDay = (dayId) => {
    const list = [...dailyInSlot]; // daily are everyday
    occasionalInSlot.forEach(p => {
      if (schedule[p.id] && schedule[p.id][dayId]) list.push(p);
    });
    return list;
  };

  // Detect conflicts on a given day: any two products where one's conflictsWith includes the other.
  const conflictsOnDay = (dayId) => {
    const list = productsOnDay(dayId);
    const pairs = [];
    for (let i = 0; i < list.length; i++) {
      for (let j = i + 1; j < list.length; j++) {
        const a = list[i], b = list[j];
        const aCon = (a.conflictsWith || []).includes(b.id);
        const bCon = (b.conflictsWith || []).includes(a.id);
        if (aCon || bCon) pairs.push([a, b]);
      }
    }
    return pairs;
  };

  // Collect all conflicting days across the week
  const weekConflicts = WEEKDAYS
    .map(d => ({ day: d, pairs: conflictsOnDay(d.id) }))
    .filter(x => x.pairs.length > 0);

  return (
    <div className="screen-enter pb-40">
      <AppBar back onBack={goBack} />

      <div className="px-5 pt-2">
        <StepIndicator current={2} steps={['בחירה', 'תזמון']} />

        <div className="text-center mt-4 mb-4">
          <h2 className="quick font-bold text-[22px] text-on-surface">תזמון מוצרים שבועי</h2>
          <p className="quick text-[13px] text-on-surface-variant mt-1">
            בחרי באילו ימים להשתמש במוצרים שאינם יומיומיים
          </p>
        </div>

        {/* Slot toggle */}
        <div className="relative flex p-1 bg-surface-low rounded-full" role="tablist">
          <button
            onClick={() => setSlot('morning')}
            className={`flex-1 h-10 rounded-full quick font-bold text-[14px] flex items-center justify-center gap-2 transition ${
              slot === 'morning' ? 'bg-primary-container text-white shadow-glow-sm' : 'text-on-surface-variant'
            }`}
          >
            <Icon name="wb_sunny" fill size={16} />
            בוקר
          </button>
          <button
            onClick={() => setSlot('evening')}
            className={`flex-1 h-10 rounded-full quick font-bold text-[14px] flex items-center justify-center gap-2 transition ${
              slot === 'evening' ? 'bg-tertiary text-white shadow-glow-sm' : 'text-on-surface-variant'
            }`}
          >
            <Icon name="dark_mode" fill size={16} />
            ערב
          </button>
        </div>

        {/* Conflicts summary (top-of-screen) */}
        {weekConflicts.length > 0 && (
          <div className="mt-4 rounded-[24px] bg-error-container/60 border border-error/30 p-4" dir="rtl">
            <div className="flex items-center gap-2 mb-2">
              <Icon name="warning" fill size={20} className="text-error" />
              <h3 className="quick font-bold text-[14px] text-error">התנגשות בין מוצרים</h3>
            </div>
            <p className="quick text-[12px] text-on-surface-variant mb-2.5">
              מצאנו פעילים שלא מומלץ לשלב באותו {slot === 'morning' ? 'בוקר' : 'ערב'}. ניתן לשמור בכל מקרה.
            </p>
            <ul className="space-y-1.5">
              {weekConflicts.map(({ day, pairs }) => (
                <li key={day.id} className="text-[12px] quick text-on-surface flex items-start gap-2">
                  <span className="label-sm text-[10px] bg-error text-white rounded-full px-2 py-0.5 mt-0.5 flex-shrink-0">
                    יום {day.label}
                  </span>
                  <span className="leading-snug">
                    {pairs.map((pair, i) => (
                      <React.Fragment key={i}>
                        {i > 0 && <span className="text-error">, </span>}
                        <span dir="ltr" className="font-bold">{pair[0].name}</span>
                        <span className="text-on-surface-variant"> + </span>
                        <span dir="ltr" className="font-bold">{pair[1].name}</span>
                      </React.Fragment>
                    ))}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* Daily products (informational, no toggles) */}
        {dailyInSlot.length > 0 && (
          <div className="mt-4">
            <h3 className="quick font-bold text-[14px] text-on-surface-variant text-right mb-2 px-1">
              מוצרים יומיים <span className="quick text-[12px] font-medium opacity-70">({dailyInSlot.length})</span>
            </h3>
            <div className="bg-surface-low rounded-[24px] p-3 space-y-1.5" dir="rtl">
              {dailyInSlot.map(p => (
                <div key={p.id} className="flex items-center gap-2 px-2">
                  <Icon name="check_circle" fill size={16} className="text-secondary" />
                  <span className="quick text-[14px] text-on-surface" dir="ltr">{p.name}</span>
                  <span className="quick text-[12px] text-on-surface-variant me-auto">כל יום</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Occasional products with weekday picker */}
        <h3 className="quick font-bold text-[14px] text-on-surface-variant text-right mt-5 mb-2 px-1">
          מוצרים אקראיים <span className="quick text-[12px] font-medium opacity-70">({occasionalInSlot.length})</span>
        </h3>

        {occasionalInSlot.length === 0 && (
          <div className="rounded-[24px] bg-surface-low p-6 text-center quick text-[13px] text-on-surface-variant">
            אין מוצרים שדורשים תזמון בשגרת {slot === 'morning' ? 'הבוקר' : 'הערב'}.
          </div>
        )}

        <div className="space-y-3">
          {occasionalInSlot.map(p => {
            const cap = p.frequency.max;
            const count = daysCount(p.id);
            const overCap = count > cap;

            return (
              <div key={p.id} className="bg-white rounded-[24px] p-4 shadow-glow-sm" dir="rtl">
                <div className="flex items-center gap-3 mb-3">
                  <ProductThumb id={p.thumb} size={44} fallbackIcon={p.fallbackIcon || 'spa'} />
                  <div className="flex-1 min-w-0">
                    <h4 className="quick font-bold text-[15px] text-on-surface truncate text-right" dir="ltr">{p.name}</h4>
                    <p className="quick text-[11px] text-on-surface-variant text-right">
                      מומלץ: עד <span className="font-bold">{cap}×</span> בשבוע
                    </p>
                  </div>
                  <span className={`label-sm text-[11px] px-2.5 py-1 rounded-full ${
                    count === 0 ? 'bg-surface-high text-on-surface-variant' :
                    overCap ? 'bg-error-container text-error' :
                    'bg-secondary-fixed text-on-secondary-container'
                  }`}>
                    {count}/{cap}
                  </span>
                </div>

                {/* Weekday picker — Sunday first (right side in RTL) */}
                <div className="flex gap-1.5 justify-between" dir="rtl">
                  {WEEKDAYS.map(d => {
                    const on = !!(schedule[p.id] && schedule[p.id][d.id]);
                    return (
                      <button
                        key={d.id}
                        onClick={() => toggleDay(p.id, d.id)}
                        className={`flex-1 aspect-square rounded-full quick font-bold text-[14px] transition active:scale-90 ${
                          on
                            ? 'bg-primary text-white shadow-glow-sm'
                            : 'bg-surface-low text-on-surface-variant hover:bg-primary-fixed/40'
                        }`}
                        aria-pressed={on}
                        aria-label={`${d.label} ${on ? 'מסומן' : ''}`}
                      >
                        {d.short}'
                      </button>
                    );
                  })}
                </div>

                {/* Over-cap warning */}
                {overCap && (
                  <div className="mt-2.5 flex items-center gap-1.5 text-[11px] quick text-error" dir="rtl">
                    <Icon name="warning" size={14} />
                    מעבר למומלץ — שקלי להפחית
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Sticky save CTA */}
      <div className="sticky bottom-24 z-30 px-5 mt-6">
        <button
          onClick={onDone}
          className="w-full h-14 rounded-full bg-gradient-to-l from-primary to-primary-container text-white quick font-bold text-[16px] shadow-glow-lg active:scale-[0.98] transition flex items-center justify-center gap-2"
        >
          <Icon name="check" size={20} />
          סיום ושמירת השגרה
        </button>
        {weekConflicts.length > 0 && (
          <p className="text-center quick text-[11px] text-error mt-2">
            עדיין יש {weekConflicts.length} ימי התנגשות
          </p>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { ScheduleScreen });
