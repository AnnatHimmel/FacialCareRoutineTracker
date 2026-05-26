// The Glow Protocol — main app
const { useState: useAppState, useEffect: useAppEffect } = React;

const ONBOARD_KEY = 'glow-onboarded-v1';

function App() {
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
      <OnboardingScreen
        name={name} setName={setName}
        gender={gender} setGender={setGender}
        selected={selected} setSelected={setSelected}
        onFinish={finishOnboarding}
      />
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
    <div className="phone-shell">
      {body}
      <BottomNav current={tab} onChange={goTo} />
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
