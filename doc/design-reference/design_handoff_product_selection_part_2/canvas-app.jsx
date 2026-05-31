// Canvas composition — the three screens of one connected flow, side by side:
// guided selection → summary → weekly schedule. Real catalog data.
const PW = 384, PH = 800;

function FlowCanvas() {
  return (
    <DesignCanvas>
      <DCSection
        id="flows"
        title="בחירת מוצרים · בחירה → סיכום → תזמון"
        subtitle="One connected flow: guided selection · filterable summary · weekly schedule with frequency + conflict warnings"
      >
        <DCArtboard id="guided" label="1 · בחירה מודרכת" width={PW} height={PH}>
          <GuidedFlow />
        </DCArtboard>

        <DCArtboard id="summary" label="2 · סיכום (מבט כללי + סינון)" width={PW} height={PH}>
          <OverviewFlow />
        </DCArtboard>

        <DCArtboard id="schedule" label="3 · תזמון שבועי" width={PW} height={PH}>
          <ScheduleFlow />
        </DCArtboard>

        <DCPostIt top={-16} left={PW + 96} rotate={-3} width={222}>
          לוחצים על שורה כדי להוסיף · ⓘ לפרטים והוראות שימוש · מוצר גמיש → בוקר/ערב · מוצר קבוע → תגית נעולה.
        </DCPostIt>
        <DCPostIt top={PH + 28} left={PW + 60} rotate={2} width={236}>
          תזמון שבועי: בורר ימים לכל מוצר בכל סלוט. אזהרה רכה בחריגה מהתדירות המומלצת (לא חוסם), זיהוי התנגשויות באותו סלוט, ומבט שבועי לחלוקה.
        </DCPostIt>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<FlowCanvas />);
