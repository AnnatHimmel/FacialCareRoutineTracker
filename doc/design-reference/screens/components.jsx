// Shared components for The Glow Protocol prototype
const { useState, useEffect, useRef, useMemo, useCallback } = React;

// ---------- Icon helper ----------
function Icon({ name, fill = false, size = 24, className = "", style = {} }) {
  return (
    <span
      className={`ms ${fill ? 'ms-fill' : ''} ${className}`}
      style={{ fontSize: size, ...style }}
      aria-hidden="true"
    >
      {name}
    </span>
  );
}

// ---------- Product image (uses provided lh3 images where available) ----------
const PRODUCT_IMAGES = {
  cleanser: "https://lh3.googleusercontent.com/aida-public/AB6AXuBccLMZbLvZrX7Zp0eGm05oGERUAVIzIkJRF1ZF0oN7zu7H387YsYS-gLyXVyladmK4nFspnQCHlKc9l5ydq3a6PslXg8VLY8eWxP9DU5AfG7H_SgpufOO-xSP95E3NJMcq5pu9lVo_Aa3LQ2PWUypnqk9GdFFU2i2VyefzIXxLNUJvOOi164ffRHzFrZHyO-gESpAp8wr-nuVaj1fL5MQ9h-LCfvcf-XlJnaSjOwCdF4H5qIjnldFmkgRUNuyNJwPkYWeS7jzUGGF_",
  serum: "https://lh3.googleusercontent.com/aida-public/AB6AXuC08JMM_rIARnn8-EctOukpfc382YTSqT56s7aJBMLMaMa-ZD9IvWuFMI9jhWCxGa8fUKZKukfEqzqIc8ew08O-Lkh1_6FE7vVsMRGCm0oyUWqCN1uux0dCsNcM1E93VhTjM_TYqd8gD6qO2wYgZipg9-XgRllcMP5L_nfPdgoT0Dr1Kly977Zgv7Rk9mr8Ivjx2oZGbPz7faqUuVTdcPBQdvRsIgCB9tL9jrwqapPIns6HLIAgRAn-680_2alov6LAtiH-7qIFVYok",
  cream: "https://lh3.googleusercontent.com/aida-public/AB6AXuA0k9EO5vSPcGspkyilVGeD3y9pIDrkOeUKzJ98GjE12Zctmsp_m6J6Tu33N35dYFIxmdUrBJNVOGwdWybqvoc4Edopym2EUctzThbGTm6hyb-Nbg-8x9G6Y2LjsrnvHqhck0NOLAWTk1G_CB7xAy92dQcyPfSBxrmp9GiMjnjRRul-y_ZwBwic66JgRt5Bl3PcykKq6fadKfEptRygCoJwvantXlUR-5Vvb2UsDSWpyzoWH_Q6LWMF0iREvvcNmCk9ezmOjpzZ87Qb",
  spf: "https://lh3.googleusercontent.com/aida-public/AB6AXuC13Eee4w0jS1pDOpvZW3uixDyIsOX_Kf8PxnyQLkAmcvRVB8mcVaWLqlW2nmNczAEbYmE8Bh2TZSH_MHkjl5DOJTrhSUi8vFoiSggfsKEZ1lpcvZm99QAX4a8Ygkrh1d_1snDSoFfjG2QIKenoF3Mm1TgW9UJpm4T8OPEOfgUKeuF1MHwiVa1tfC6cf4y9V7vuokwxpA3Xbcm0Rj5bmHy-XMsMJxSwTz74Jnr6r77B_NH-ZtSXAnIDDyobokmC-aln4HCTqFc423FH",
  retinol: "https://lh3.googleusercontent.com/aida-public/AB6AXuBsU50ZYy7HQdOEwQVNmz22GJEGCK5O3wD1-_jdZDrfdJcQZUjnImUiNZq2paNK7KbcmSv7XzlIhHn4eoZTL_OgEooj9UbpeE6entZVpiZPFWUMU5tDBXhsucCr-X3w5zdo4g1v6NgRfkGTZNKP2Qw81mdp2hg4MVgwGS5A2aqap1m0eeTsLw27Ial18JgiTvAnhP823gj9p2rVmta_qBqsH0YfffkLUG2YEQPC356S2FYEP0H0UVMxSjHUontrnt_dKkQd_vI9ALDp",
  vitc: "https://lh3.googleusercontent.com/aida-public/AB6AXuAzL0ZI7-YHdnZYAWv8G4BXMyxqvw6s691JmNzNndl8H36vyWEmDw4I0PsUPBDgsbTmiCW3ulMvE5SOQMSV2-GfA4T8Bq87Owj2IywTC_uuPBca5RdRZLzBhWO7dLmpLYw8ojwpWgFxEmLmozTRKWQpooaf3U-FqWvTa7A2maioLch98OoXI4ARqTWRmlCmX62N6i2QXyD5Pn-0UW81zVtG558ZaoLxb0Y3LR6HdeNWddmpVlz0XxSz12MY8Vucuflaxci4pb44nE7S",
  bottle: "https://lh3.googleusercontent.com/aida-public/AB6AXuCS3dHdFP0aGvW4ogyTKKMxUPQ0ZGOE64a2PvsCokP9dQko4BfIvaagXfMqg0zfCC864RmTsinQm2A8AyFg8sF_HUtzjgDY7-NfoXPGH2ojaPj1zlQTB7MeSQlAbspLIivggN2IjwMi_CEuY2QP46g1TUml9hqEsI_wyHAdF34kcWmPO02g7cuMc-0hRRTEamrceXLwUB3Bs16RKElnPmg18Wi2uW3jr4e1yOl8_aUlP_kW-Z1fM1EjOm0fGqJcE1RzvMfTw7oU38jA",
};

function ProductThumb({ id, src: srcProp, size = 56, fallbackIcon = "spa" }) {
  const src = srcProp || PRODUCT_IMAGES[id];
  if (src) {
    return (
      <div
        className="rounded-full overflow-hidden flex-shrink-0 bg-surface-container shadow-glow-sm"
        style={{ width: size, height: size }}
      >
        <img src={src} alt="" className="w-full h-full object-cover" />
      </div>
    );
  }
  return (
    <div
      className="rounded-full flex-shrink-0 bg-primary-fixed/60 flex items-center justify-center text-on-primary-fixed-variant"
      style={{ width: size, height: size }}
    >
      <Icon name={fallbackIcon} size={Math.floor(size * 0.5)} />
    </div>
  );
}

// ---------- Brand mark (sun) ----------
// "The Glow Protocol" — a stylized sun: hollow ring center with 12 alternating
// long/short pill rays in a two-tone peach. No plants, no figures.
function LeafLogo({ size = 28, color = "#9e412c", colorLight = "#c66a52" }) {
  const cx = 16, cy = 16;
  // 12 rays, alternating long/short. Start from top (-90deg) going clockwise.
  const rays = Array.from({ length: 12 }, (_, i) => {
    const angle = (-90 + i * 30) * (Math.PI / 180);
    const isLong = i % 2 === 0;          // long rays at cardinal-ish positions
    const isDark = i % 2 === 0;          // darker rays match long ones for rhythm
    const r1 = isLong ? 9.2 : 9.5;       // inner gap from ring
    const r2 = isLong ? 13.6 : 12.2;     // outer reach
    const x1 = cx + r1 * Math.cos(angle);
    const y1 = cy + r1 * Math.sin(angle);
    const x2 = cx + r2 * Math.cos(angle);
    const y2 = cy + r2 * Math.sin(angle);
    return { x1, y1, x2, y2, color: isDark ? color : colorLight };
  });

  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none" aria-hidden="true">
      <defs>
        <linearGradient id="gp-ring" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor={color} />
          <stop offset="100%" stopColor={colorLight} />
        </linearGradient>
      </defs>
      {/* hollow ring center */}
      <circle cx={cx} cy={cy} r="6.2" stroke="url(#gp-ring)" strokeWidth="2.1" fill="none" />
      {/* rays */}
      {rays.map((r, i) => (
        <line
          key={i}
          x1={r.x1} y1={r.y1} x2={r.x2} y2={r.y2}
          stroke={r.color}
          strokeWidth="1.7"
          strokeLinecap="round"
        />
      ))}
    </svg>
  );
}

// Wordmark + symbol (app icon, splash). Uses Quicksand to match the app.
function BrandMark({ size = 96, color = "#9e412c", colorLight = "#c66a52", showTagline = false }) {
  return (
    <div className="inline-flex flex-col items-center" dir="ltr">
      <LeafLogo size={size} color={color} colorLight={colorLight} />
      <div
        className="quick font-semibold tracking-tight mt-3"
        style={{ color, fontSize: size * 0.22, letterSpacing: '-0.01em' }}
      >
        The Glow Protocol
      </div>
      {showTagline && (
        <span className="label text-[10px] mt-1 tracking-[0.22em] uppercase text-on-surface-variant">
          Skincare · Tracked
        </span>
      )}
    </div>
  );
}

Object.assign(window, { BrandMark });

// ---------- Top app bar ----------
// Layout in RTL (3 slots, flex justify-between):
//   visual right (start) : back arrow / nothing
//   visual center        : title + logo
//   visual left  (end)   : settings cog / bell / nothing
// `back` and `action` are separate so they never collide.
function AppBar({
  back = false, onBack,                      // visual right
  action = null, onAction,                   // visual left: 'settings' | 'bell' | null
  title = "The Glow Protocol",
  onLogoClick,
}) {
  return (
    <header className="sticky top-0 z-30 px-5 pt-3 pb-3 bg-surface/85 backdrop-blur-xl">
      <div className="flex items-center justify-between gap-3">
        {/* Visual right (RTL start): back */}
        <div className="w-10 h-10 flex items-center justify-center">
          {back && (
            <button
              onClick={onBack}
              className="w-10 h-10 rounded-full flex items-center justify-center text-primary hover:bg-primary-fixed/40 active:scale-95 transition"
              aria-label="חזרה"
            >
              {/* in RTL, back is a right-pointing arrow */}
              <Icon name="arrow_forward" size={24} />
            </button>
          )}
        </div>

        {/* Center: title + logo */}
        <div className="flex items-center gap-2" onClick={onLogoClick}>
          <h1 className="quick text-[20px] leading-none font-bold text-primary tracking-tight whitespace-nowrap">{title}</h1>
          <LeafLogo size={24} />
        </div>

        {/* Visual left (RTL end): settings / bell */}
        <div className="w-10 h-10 flex items-center justify-center">
          {action === 'settings' && (
            <button
              onClick={onAction}
              className="w-10 h-10 rounded-full flex items-center justify-center text-on-surface-variant hover:bg-surface-high active:scale-95 transition"
              aria-label="הגדרות"
            >
              <Icon name="settings" size={22} />
            </button>
          )}
          {action === 'bell' && (
            <button
              onClick={onAction}
              className="w-10 h-10 rounded-full flex items-center justify-center text-primary hover:bg-primary-fixed/40 active:scale-95 transition"
              aria-label="התראות"
            >
              <Icon name="notifications" size={22} />
            </button>
          )}
        </div>
      </div>
    </header>
  );
}

// ---------- Bottom nav ----------
// In RTL flex, first DOM item appears visually rightmost.
// Order (right -> left): home, products, journal, settings.
function BottomNav({ current, onChange }) {
  const items = [
    { id: 'home', label: 'בית', icon: 'home' },
    { id: 'products', label: 'מוצרים', icon: 'category' },
    { id: 'journal', label: 'יומן', icon: 'auto_stories' },
    { id: 'profile', label: 'הגדרות', icon: 'settings' },
  ];
  return (
    <nav className="absolute bottom-0 left-0 right-0 z-40 bg-surface-low/95 backdrop-blur-xl border-t border-primary-fixed/30 px-2 pt-2 pb-3">
      <ul className="flex items-center justify-around">
        {items.map(it => {
          const active = current === it.id;
          return (
            <li key={it.id}>
              <button
                onClick={() => onChange(it.id)}
                className={`flex flex-col items-center justify-center gap-0.5 px-5 py-2 rounded-2xl transition-all active:scale-95 ${
                  active ? 'bg-primary-fixed/60 text-primary' : 'text-on-surface-variant'
                }`}
                aria-current={active ? 'page' : undefined}
              >
                <Icon name={it.icon} fill={active} size={24} />
                <span className={`quick text-[12px] mt-0.5 ${active ? 'font-bold' : 'font-semibold'}`}>{it.label}</span>
              </button>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}

// ---------- Routine item row (collapsed) ----------
// Used on S1 (selection / "I own this"), S4 (daily home / "I did this today"), S3 (reorder).
// `variant`: "select" | "done" | "drag"
function RoutineRow({ item, variant = "done", checked, onToggle, draggable, onDragStart, onDragOver, onDrop, deprecated = false, badge = null, expanded = false, onExpand, details }) {
  const isCheckedDone = variant === 'done' && checked;
  const isDoneVariant = variant === 'done';
  const bgCls = isCheckedDone
    ? 'bg-primary-fixed/45 border-transparent'
    : 'bg-white border-outline-variant/20';
  const shapeCls = expanded ? 'rounded-[26px]' : 'rounded-full';
  const baseCls = `group ${shapeCls} p-2 ps-4 pe-3 shadow-glow-sm border transition-all ${bgCls} ${isDoneVariant ? 'cursor-pointer select-none active:scale-[0.99]' : ''}`;

  const handleRowClick = isDoneVariant ? () => onToggle && onToggle() : undefined;

  return (
    <div
      className={baseCls}
      draggable={draggable}
      onDragStart={onDragStart}
      onDragOver={onDragOver}
      onDrop={onDrop}
      onClick={handleRowClick}
      role={isDoneVariant ? 'button' : undefined}
      aria-pressed={isDoneVariant ? !!checked : undefined}
    >
      <div className="flex items-center gap-3">
        {variant === "drag" ? (
          <div className="text-outline/40 cursor-grab active:cursor-grabbing pe-1" aria-hidden="true">
            <Icon name="drag_indicator" size={22} />
          </div>
        ) : null}

        {/* Thumbnail with a small "done" check badge overlay (no horizontal space cost) */}
        <div className="relative flex-shrink-0">
          <ProductThumb id={item.thumb} src={item.image} size={50} fallbackIcon={item.fallbackIcon || "spa"} />
          {isCheckedDone && (
            <span className="absolute -bottom-0.5 -start-0.5 w-6 h-6 rounded-full bg-primary text-white flex items-center justify-center border-2 border-white shadow-sm">
              <Icon name="check" size={14} />
            </span>
          )}
        </div>

        <div className="flex-1 min-w-0 text-right">
          <div className="flex items-center gap-2 justify-start">
            {deprecated && (
              <span className="label-sm text-[10px] text-error bg-error-container px-1.5 py-0.5 rounded-full" title="לא מומלץ עוד">לא מומלץ</span>
            )}
            {badge && (
              <span className="label-sm text-[10px] text-primary bg-primary-fixed/70 px-1.5 py-0.5 rounded-full flex items-center gap-0.5">
                <Icon name="person" size={11} />
                {badge}
              </span>
            )}
            <h4 className={`quick font-bold text-[16px] leading-tight truncate text-right flex-1 ${
              isCheckedDone ? 'text-on-surface-variant/70 line-through decoration-1 decoration-on-surface-variant/60' : 'text-on-surface'
            }`}>{item.name}</h4>
          </div>
          <p className={`quick text-[12px] leading-tight mt-0.5 truncate text-right ${
            isCheckedDone ? 'text-on-surface-variant/70' : 'text-on-surface-variant'
          }`}>
            {item.subtitle}
          </p>
        </div>

        {/* expand chevron — specific tap target, doesn't toggle done */}
        {isDoneVariant && onExpand && (
          <button
            onClick={(e) => { e.stopPropagation(); onExpand(); }}
            className="flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-on-surface-variant hover:bg-surface-high transition"
            aria-label={expanded ? 'כווץ פרטים' : 'הצג פרטים'}
            aria-expanded={expanded}
          >
            <Icon name={expanded ? 'expand_less' : 'expand_more'} size={20} />
          </button>
        )}

        {variant === "select" ? (
          <button
            onClick={onToggle}
            className={`flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center transition-all active:scale-90 ${
              checked
                ? 'bg-primary text-white shadow-glow-sm'
                : 'bg-primary-fixed/60 text-primary hover:bg-primary-fixed'
            }`}
            aria-label={checked ? 'הסר מהבחירה' : 'בחר מוצר'}
          >
            <Icon name={checked ? "check" : "add"} size={22} />
          </button>
        ) : null}
      </div>

      {/* expandable details */}
      {isDoneVariant && expanded && (
        <div className="mt-2 pt-3 ps-1 pe-1 border-t border-outline-variant/30 text-right" dir="rtl" onClick={(e) => e.stopPropagation()}>
          <p className="quick text-[13px] text-on-surface-variant leading-relaxed">
            {details || item.desc || 'אין פרטים נוספים על מוצר זה.'}
          </p>
        </div>
      )}
    </div>
  );
}

// ---------- Slot section header (Morning / Evening) ----------
function SlotHeader({ slot, count, total }) {
  const isMorning = slot === 'morning';
  return (
    <div className="flex items-center justify-end gap-2 mt-5 mb-3 px-1" dir="rtl">
      <span className={`quick font-bold text-[16px] ${isMorning ? 'text-primary' : 'text-secondary'}`}>
        {isMorning ? 'בוקר' : 'ערב'}
      </span>
      <Icon
        name={isMorning ? 'wb_sunny' : 'dark_mode'}
        fill
        size={20}
        className={isMorning ? 'text-primary-container' : 'text-secondary-fixed-dim'}
      />
    </div>
  );
}

// ---------- Section card (white pebble) ----------
function Card({ children, className = "" }) {
  return (
    <div className={`bg-white rounded-[28px] shadow-glow p-5 ${className}`}>{children}</div>
  );
}

// ---------- Step indicator (for multi-step flows) ----------
function StepIndicator({ current, steps }) {
  return (
    <div className="flex items-center justify-center gap-2" dir="rtl">
      {steps.map((s, i) => {
        const stepNum = i + 1;
        const active = stepNum === current;
        const done = stepNum < current;
        return (
          <React.Fragment key={i}>
            <div className="flex items-center gap-1.5">
              <span className={`flex items-center justify-center w-6 h-6 rounded-full text-[11px] font-bold quick transition ${
                done ? 'bg-secondary text-white' :
                active ? 'bg-primary text-white' :
                'bg-surface-high text-on-surface-variant'
              }`}>
                {done ? <Icon name="check" size={14} /> : stepNum}
              </span>
              <span className={`quick text-[13px] font-bold ${
                active ? 'text-primary' : done ? 'text-on-surface' : 'text-on-surface-variant/70'
              }`}>{s}</span>
            </div>
            {i < steps.length - 1 && (
              <span className={`h-px w-6 ${done ? 'bg-secondary' : 'bg-outline-variant/50'}`} />
            )}
          </React.Fragment>
        );
      })}
    </div>
  );
}

Object.assign(window, { StepIndicator });

// expose to globals for the other Babel script files
Object.assign(window, { Icon, ProductThumb, LeafLogo, AppBar, BottomNav, RoutineRow, SlotHeader, Card, StepIndicator, PRODUCT_IMAGES });
