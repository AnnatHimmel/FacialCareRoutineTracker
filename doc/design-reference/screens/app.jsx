// The Glow Protocol — main app
const { useState: useAppState, useEffect: useAppEffect } = React;

const ONBOARD_KEY = 'glow-onboarded-v1';

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "phoneWidth": 420,
  "phoneHeight": 880,
  "showBezel": true
}/*EDITMODE-END*/;

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  // ---- onboarding gate ----
  const [onboarded, setOnboarded] = useAppState(() => {
    try { return localStorage.getItem(ONBOARD_KEY) === '1'; } catch (_) { return false; }
  });

  // ---- user profile (lifted up so onboarding and Profile share) ----
  const [name, setName] = useAppState(() => {
    try { return localStorage.getItem('glow-name') || ''; } catch (_) { return ''; }
  });
  const [gender, setGender] = useAppState(() => {
    try { return localStorage.getItem('glow-gender') || 'female'; } catch (_) { return 'female'; }
  });
  useAppEffect(() => { try { localStorage.setItem('glow-name', name); } catch (_) {} }, [name]);
  useAppEffect(() => { try { localStorage.setItem('glow-gender', gender); } catch (_) {} }, [gender]);

  // ---- routine state ----
  const [tab, setTab] = useAppState('home');
  const [modal, setModal] = useAppState(null);
  const [selected, setSelected] = useAppState({
    'gentle-cream': true, 'vitc': true, 'ceramide': true, 'spf50': true, 'retinol': true, 'exfoliant': true,
  });
  const [schedule, setSchedule] = useAppState({
    'retinol': { 1: true, 3: true, 5: true },
    'exfoliant': { 0: true, 3: true },
  });
  // ---- user-added (local) products, not from the master catalog ----
  const [customProducts, setCustomProducts] = useAppState(() => {
    try { return JSON.parse(localStorage.getItem('glow-custom') || '[]'); } catch (_) { return []; }
  });
  useAppEffect(() => {
    try { localStorage.setItem('glow-custom', JSON.stringify(customProducts)); } catch (_) {}
  }, [customProducts]);

  const finishOnboarding = () => {
    try { localStorage.setItem(ONBOARD_KEY, '1'); } catch (_) {}
    setOnboarded(true);
    setTab('home');
  };

  const resetOnboarding = () => {
    try { localStorage.removeItem(ONBOARD_KEY); } catch (_) {}
    setOnboarded(false);
  };

  const goTo = (t) => {
    if (t === 'order') {
      setModal({ type: 'order' });
    } else if (t === 'schedule') {
      setModal({ type: 'schedule' });
    } else if (t === 'reset-onboarding') {
      resetOnboarding();
    } else {
      setTab(t);
      setModal(null);
    }
  };
  const openProduct = (id) => setModal({ type: 'product', id });
  const closeModal = () => setModal(null);

  if (!onboarded) {
    return (
      <React.Fragment>
        <div
          className={`phone-shell ${t.showBezel ? '' : 'no-bezel'}`}
          style={{ maxWidth: `${t.phoneWidth}px`, '--phone-h': `${t.phoneHeight}px` }}
        >
          <div className="phone-scroll">
            <OnboardingScreen
              name={name} setName={setName}
              gender={gender} setGender={setGender}
              selected={selected} setSelected={setSelected}
              onFinish={finishOnboarding}
            />
          </div>
        </div>

        <TweaksPanel title="Tweaks">
          <TweakSection label="Phone preview" />
          <TweakSlider
            label="Width"
            value={t.phoneWidth}
            min={320} max={600} step={2} unit="px"
            onChange={(v) => setTweak('phoneWidth', v)}
          />
          <TweakSlider
            label="Height"
            value={t.phoneHeight}
            min={640} max={1100} step={4} unit="px"
            onChange={(v) => setTweak('phoneHeight', v)}
          />
          <TweakToggle
            label="Device bezel"
            value={t.showBezel}
            onChange={(v) => setTweak('showBezel', v)}
          />
          <TweakSelect
            label="Preset"
            value={`${t.phoneWidth}`}
            options={[
              { value: '360', label: 'iPhone SE' },
              { value: '390', label: 'iPhone 13' },
              { value: '420', label: 'iPhone 15' },
              { value: '412', label: 'Galaxy S24 Ultra' },
            ]}
            onChange={(v) => {
              const presets = { 360: 780, 390: 844, 420: 880, 412: 915 };
              setTweak({ phoneWidth: +v, phoneHeight: presets[v] || 880 });
            }}
          />
        </TweaksPanel>
      </React.Fragment>
    );
  }

  let body;
  if (modal && modal.type === 'product') {
    body = <ProductDetailScreen productId={modal.id} goBack={closeModal} />;
  } else if (modal && modal.type === 'order') {
    body = <OrderScreen goBack={closeModal} />;
  } else if (modal && modal.type === 'schedule') {
    body = (
      <ScheduleScreen
        selected={selected}
        schedule={schedule}
        setSchedule={setSchedule}
        customProducts={customProducts}
        goBack={closeModal}
        onDone={() => { closeModal(); setTab('home'); }}
      />
    );
  } else if (tab === 'home') {
    body = <HomeScreen goTo={goTo} userName={name} />;
  } else if (tab === 'products') {
    body = (
      <ProductsScreen
        goTo={goTo}
        openProduct={openProduct}
        selected={selected}
        setSelected={setSelected}
        customProducts={customProducts}
        setCustomProducts={setCustomProducts}
      />
    );
  } else if (tab === 'journal') {
    body = <JournalScreen goTo={goTo} />;
  } else if (tab === 'profile') {
    body = (
      <ProfileScreen
        goTo={goTo}
        name={name} setName={setName}
        gender={gender} setGender={setGender}
      />
    );
  }

  return (
    <React.Fragment>
      <div
        className={`phone-shell ${t.showBezel ? '' : 'no-bezel'}`}
        style={{ maxWidth: `${t.phoneWidth}px`, '--phone-h': `${t.phoneHeight}px` }}
      >
        <div className="phone-scroll">
          {body}
        </div>
        <BottomNav current={tab} onChange={goTo} />
        {/* overlay mount — bottom sheets/modals portal here so they stay clipped to the phone */}
        <div id="phone-overlay"></div>
      </div>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Phone preview" />
        <TweakSlider
          label="Width"
          value={t.phoneWidth}
          min={320} max={600} step={2} unit="px"
          onChange={(v) => setTweak('phoneWidth', v)}
        />
        <TweakSlider
          label="Height"
          value={t.phoneHeight}
          min={640} max={1100} step={4} unit="px"
          onChange={(v) => setTweak('phoneHeight', v)}
        />
        <TweakToggle
          label="Device bezel"
          value={t.showBezel}
          onChange={(v) => setTweak('showBezel', v)}
        />
        <TweakSelect
          label="Preset"
          value={`${t.phoneWidth}`}
          options={[
            { value: '360', label: 'iPhone SE' },
            { value: '390', label: 'iPhone 13' },
            { value: '420', label: 'iPhone 15' },
            { value: '412', label: 'Galaxy S24 Ultra' },
          ]}
          onChange={(v) => {
            const presets = { 360: 780, 390: 844, 420: 880, 412: 915 };
            setTweak({ phoneWidth: +v, phoneHeight: presets[v] || 880 });
          }}
        />
        <TweakSection label="App" />
        <TweakButton
          label="Reset onboarding"
          onClick={() => {
            try { localStorage.removeItem(ONBOARD_KEY); } catch(_){}
            setOnboarded(false);
          }}
        />
      </TweaksPanel>
    </React.Fragment>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
