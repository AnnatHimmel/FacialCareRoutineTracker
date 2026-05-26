// Onboarding flow — shown once on first launch.
// Step 1: Welcome
// Step 2: Personal info (name + gender)
// Step 3: Product selection (compact grid of master products)
// On finish: writes `glow-onboarded` to localStorage and lands on Home.

const { useState: useOS, useEffect: useOE } = React;

function OnboardingScreen({ selected, setSelected, onFinish, setName, setGender, name, gender }) {
  const [step, setStep] = useOS(1);

  const next = () => setStep(s => Math.min(3, s + 1));
  const back = () => setStep(s => Math.max(1, s - 1));

  // Step 2 form local state mirrors app state
  const canNextStep2 = name.trim().length > 0 && gender;

  // Step 3 — selection count
  const selectedCount = Object.values(selected).filter(Boolean).length;

  // Sun shape background ornament
  return (
    <div className="phone-shell" dir="rtl">
      <div className="relative min-h-[100dvh] bg-surface flex flex-col">
        {/* Top: progress bar */}
        <div className="px-5 pt-6 pb-2">
          <div className="flex items-center justify-between mb-2">
            <button
              onClick={onFinish}
              className="quick text-[13px] text-on-surface-variant font-bold hover:text-primary transition"
            >
              דלגי
            </button>
            <span className="label-sm text-[11px] text-on-surface-variant">
              {step}/3
            </span>
          </div>
          <div className="flex gap-1.5">
            {[1, 2, 3].map(n => (
              <div
                key={n}
                className={`flex-1 h-1.5 rounded-full transition-all ${
                  n <= step ? 'bg-primary' : 'bg-primary-fixed/40'
                }`}
              />
            ))}
          </div>
        </div>

        {/* Step body */}
        <div className="flex-1 flex flex-col px-5 pb-6 overflow-y-auto">
          {step === 1 && <OBWelcome onStart={next} />}
          {step === 2 && (
            <OBPersonal
              name={name} setName={setName}
              gender={gender} setGender={setGender}
            />
          )}
          {step === 3 && (
            <OBProducts selected={selected} setSelected={setSelected} count={selectedCount} />
          )}
        </div>

        {/* Bottom CTAs (not on step 1 — it has its own) */}
        {step > 1 && (
          <div className="sticky bottom-0 z-30 bg-surface/95 backdrop-blur-xl px-5 pt-3 pb-6 border-t border-primary-fixed/30">
            <div className="flex items-center gap-3">
              <button
                onClick={back}
                className="h-13 px-6 rounded-full bg-surface-low text-on-surface quick font-bold text-[15px] flex items-center gap-1 active:scale-95 transition"
                style={{ height: 52 }}
              >
                <Icon name="arrow_forward" size={18} />
                חזרה
              </button>
              <button
                onClick={step === 3 ? onFinish : next}
                disabled={step === 2 && !canNextStep2}
                className="flex-1 rounded-full bg-gradient-to-l from-primary to-primary-container text-white quick font-bold text-[16px] flex items-center justify-center gap-2 shadow-glow-lg active:scale-[0.98] transition disabled:opacity-50 disabled:cursor-not-allowed"
                style={{ height: 52 }}
              >
                {step === 3 ? (
                  <>
                    <Icon name="check" size={20} />
                    סיום והתחלה
                  </>
                ) : (
                  <>
                    המשך
                    <Icon name="arrow_back" size={18} />
                  </>
                )}
              </button>
            </div>
            {step === 3 && (
              <p className="text-center quick text-[12px] text-on-surface-variant mt-2">
                {selectedCount === 0 ? 'תוכלי להוסיף מוצרים גם בהמשך' : `${selectedCount} מוצרים נבחרו`}
              </p>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

// ----- Step 1: Welcome -----
function OBWelcome({ onStart }) {
  return (
    <div className="flex-1 flex flex-col items-center justify-center text-center py-10">
      {/* Logo big */}
      <div className="relative mb-8">
        {/* radial glow behind */}
        <div className="absolute inset-0 -m-8 rounded-full bg-gradient-to-br from-primary-fixed/40 to-primary-container/20 blur-2xl" />
        <div className="relative">
          <LeafLogo size={120} />
        </div>
      </div>

      <h1 className="quick font-bold text-[32px] text-primary leading-tight">
        ברוכה הבאה
      </h1>
      <p className="quick text-[20px] font-bold text-on-surface mt-1">
        ל־The Glow Protocol
      </p>

      <p className="quick text-[15px] text-on-surface-variant mt-6 leading-relaxed max-w-[280px]">
        השגרה שלך, בקצב שלך.
        <br />
        תיעוד יומי, תזמון חכם של מוצרים, וזוהר עקבי.
      </p>

      {/* Feature pills */}
      <div className="grid grid-cols-1 gap-2.5 mt-8 w-full max-w-[300px]">
        {[
          { icon: 'checklist', text: 'מעקב יומי אחר השגרה' },
          { icon: 'event', text: 'תזמון שבועי לפי המוצר' },
          { icon: 'auto_stories', text: 'יומן עור ומצב רוח' },
        ].map((f, i) => (
          <div key={i} className="flex items-center gap-3 bg-white rounded-full ps-4 pe-3 py-2 shadow-glow-sm">
            <div className="w-9 h-9 rounded-full bg-primary-fixed/60 flex items-center justify-center text-primary flex-shrink-0">
              <Icon name={f.icon} size={20} />
            </div>
            <span className="quick text-[14px] text-on-surface font-bold flex-1 text-right">{f.text}</span>
          </div>
        ))}
      </div>

      {/* CTA */}
      <button
        onClick={onStart}
        className="mt-10 w-full max-w-[300px] h-14 rounded-full bg-gradient-to-l from-primary to-primary-container text-white quick font-bold text-[17px] shadow-glow-lg active:scale-[0.98] transition flex items-center justify-center gap-2"
      >
        בואי נתחיל
        <Icon name="arrow_back" size={20} />
      </button>
      <p className="quick text-[12px] text-on-surface-variant mt-3">לוקח פחות מדקה</p>
    </div>
  );
}

// ----- Step 2: Personal info -----
function OBPersonal({ name, setName, gender, setGender }) {
  return (
    <div className="py-6">
      <div className="text-right">
        <h2 className="quick font-bold text-[26px] text-on-surface leading-tight">
          ספרי לנו עלייך
        </h2>
        <p className="quick text-[14px] text-on-surface-variant mt-2 leading-relaxed">
          נשתמש בפרטים האלה כדי להתאים לך תוכן ולפנות אלייך אישית. הכל נשמר על המכשיר שלך.
        </p>
      </div>

      <div className="mt-7 space-y-5" dir="rtl">
        {/* Name */}
        <div>
          <label className="quick text-[13px] font-bold text-on-surface mb-2 block text-right">
            איך לקרוא לך?
          </label>
          <input
            type="text"
            value={name}
            onChange={e => setName(e.target.value)}
            placeholder="השם שלך"
            className="w-full h-13 bg-white rounded-full px-5 quick text-[16px] text-on-surface border border-outline-variant/40 focus:border-primary focus:ring-2 focus:ring-primary/20 outline-none text-right transition shadow-glow-sm"
            style={{ height: 52 }}
            dir="rtl"
            autoFocus
          />
        </div>

        {/* Gender */}
        <div>
          <label className="quick text-[13px] font-bold text-on-surface mb-2 block text-right">
            מגדר
          </label>
          <div className="flex gap-2" dir="rtl">
            {[
              { id: 'female', label: 'נקבה' },
              { id: 'male', label: 'זכר' },
            ].map(o => (
              <button
                key={o.id}
                onClick={() => setGender(o.id)}
                className={`flex-1 rounded-full quick font-bold text-[15px] transition active:scale-95 shadow-glow-sm border ${
                  gender === o.id
                    ? 'bg-primary text-white border-primary shadow-glow'
                    : 'bg-white text-on-surface border-outline-variant/40 hover:border-primary/50'
                }`}
                style={{ height: 52 }}
              >
                {o.label}
              </button>
            ))}
          </div>
        </div>

        {/* Privacy note */}
        <div className="flex items-start gap-2 mt-4 px-1" dir="rtl">
          <Icon name="lock" size={16} className="text-on-surface-variant mt-0.5 flex-shrink-0" />
          <p className="quick text-[12px] text-on-surface-variant leading-relaxed text-right">
            הפרטים נשמרים אך ורק בדפדפן שלך. אין שיתוף עם שרת חיצוני.
          </p>
        </div>
      </div>
    </div>
  );
}

// ----- Step 3: Product selection (compact grid) -----
function OBProducts({ selected, setSelected, count }) {
  const toggle = (id) => setSelected(s => ({ ...s, [id]: !s[id] }));

  return (
    <div className="py-6">
      <div className="text-right">
        <h2 className="quick font-bold text-[26px] text-on-surface leading-tight">
          המוצרים שלך
        </h2>
        <p className="quick text-[14px] text-on-surface-variant mt-2 leading-relaxed">
          סמני את המוצרים שיש לך בארון. תוכלי לערוך, להוסיף ולתזמן אותם בכל זמן.
        </p>
      </div>

      <div className="grid grid-cols-2 gap-2.5 mt-6">
        {MASTER_PRODUCTS.map(p => {
          const on = !!selected[p.id];
          return (
            <button
              key={p.id}
              onClick={() => toggle(p.id)}
              className={`relative text-right rounded-[24px] p-3 transition active:scale-[0.98] border-2 ${
                on
                  ? 'bg-primary-fixed/40 border-primary shadow-glow'
                  : 'bg-white border-transparent shadow-glow-sm hover:border-primary-fixed'
              }`}
              dir="rtl"
            >
              {/* check badge */}
              <div className={`absolute top-2 left-2 w-6 h-6 rounded-full flex items-center justify-center transition ${
                on ? 'bg-primary text-white' : 'bg-surface-low text-outline'
              }`}>
                {on && <Icon name="check" size={16} />}
              </div>
              <ProductThumb id={p.thumb} size={56} fallbackIcon={p.fallbackIcon || 'spa'} />
              <h4 className="quick font-bold text-[13px] text-on-surface mt-2 leading-tight line-clamp-2 text-right" dir="ltr">
                {p.name}
              </h4>
              <p className="quick text-[11px] text-on-surface-variant mt-0.5 line-clamp-1 text-right">
                {p.frequency === 'daily' ? 'יומי' : `עד ${p.frequency.max}× בשבוע`}
              </p>
            </button>
          );
        })}
      </div>
    </div>
  );
}

Object.assign(window, { OnboardingScreen });
