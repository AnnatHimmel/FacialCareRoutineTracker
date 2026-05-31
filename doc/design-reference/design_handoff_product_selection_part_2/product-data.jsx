// AUTO-GENERATED from master_products.json — real catalog data.
// am/pm: null = not usable in that slot; object = { order, freq } where
// freq is 'daily' or { max:N } (occasional). Product is FLEXIBLE when both
// am and pm are present (user picks timing), otherwise FIXED to its one slot.
const CATEGORIES = [
  {
    "id": "cat-cleanser-step1",
    "name": "ניקוי שלב 1",
    "order": 1,
    "icon": "wash",
    "en": "Cleanse 1"
  },
  {
    "id": "cat-cleanser-step2",
    "name": "ניקוי שלב 2",
    "order": 2,
    "icon": "soap",
    "en": "Cleanse 2"
  },
  {
    "id": "cat-retinoid",
    "name": "רטינואידים",
    "order": 3,
    "icon": "biotech",
    "en": "Retinoid"
  },
  {
    "id": "cat-toner",
    "name": "טונר / אסנס",
    "order": 4,
    "icon": "water_drop",
    "en": "Toner / Essence"
  },
  {
    "id": "cat-serum",
    "name": "סרום / אקטיב",
    "order": 5,
    "icon": "science",
    "en": "Serum / Active"
  },
  {
    "id": "cat-moisturizer",
    "name": "לחות",
    "order": 6,
    "icon": "spa",
    "en": "Moisturize"
  },
  {
    "id": "cat-oil",
    "name": "שמנים",
    "order": 7,
    "icon": "opacity",
    "en": "Oil"
  },
  {
    "id": "cat-spf",
    "name": "הגנה",
    "order": 8,
    "icon": "wb_sunny",
    "en": "Protect"
  }
];

const PRODUCTS = [
  {
    "id": "prod-007",
    "name": "Beauty of Joseon Relief Sun: Rice + Probiotics",
    "cat": "cat-spf",
    "image": "products/prod-007.jpg",
    "comment": "קרם הגנה קוריאני קל ומרגיע עם אורז ופרוביוטיקה, SPF50+ PA+++",
    "am": {
      "order": 4,
      "freq": "daily"
    },
    "pm": null
  },
  {
    "id": "prod-008",
    "name": "Heimish All Clean Balm",
    "cat": "cat-cleanser-step1",
    "image": "products/heimish_all_clean_balm.jpg",
    "comment": "באלם ניקוי להסרת איפור ומסנני הגנה",
    "am": null,
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-009",
    "name": "Heimish All Clean Green Foam",
    "cat": "cat-cleanser-step2",
    "image": "products/heimish_all_clean_green_foam.jpg",
    "comment": "סבון פנים עדין ומאזן לחומציות מומלצת",
    "am": null,
    "pm": {
      "order": 1,
      "freq": "daily"
    }
  },
  {
    "id": "prod-010",
    "name": "MarulaLab Anti-Aging Marula Oil",
    "cat": "cat-oil",
    "image": "products/marulalab_marula_oil.jpg",
    "comment": "שמן מרולה טהור להזנה מוגברת ואנטי אייג'ינג",
    "am": null,
    "pm": {
      "order": 6,
      "freq": "daily"
    }
  },
  {
    "id": "prod-011",
    "name": "ILLIYOON Ceramide Ato Concentrate Cream",
    "cat": "cat-moisturizer",
    "image": "products/illiyoon_ceramide_ato_cream.jpg",
    "comment": "קרם לחות עשיר בסרמידים לשיקום והרגעת מחסום העור",
    "am": {
      "order": 2,
      "freq": "daily"
    },
    "pm": {
      "order": 4,
      "freq": "daily"
    }
  },
  {
    "id": "prod-012",
    "name": "Purito SEOUL Daily Soft Touch Sunscreen",
    "cat": "cat-spf",
    "image": "products/purito_seoul_soft_touch_sunscreen.jpg",
    "comment": "קרם הגנה לחותי במרקם קל ונעים לשימוש יומיומי",
    "am": {
      "order": 5,
      "freq": "daily"
    },
    "pm": null
  },
  {
    "id": "prod-013",
    "name": "AXIS-Y Heartleaf My-Type Calming Cream",
    "cat": "cat-moisturizer",
    "image": "products/axis_y_heartleaf_calming_cream.jpg",
    "comment": "קרם לחות קליל ומרגיע עם הארטליף להפחתת אדמומיות",
    "am": {
      "order": 1,
      "freq": "daily"
    },
    "pm": {
      "order": 3,
      "freq": "daily"
    }
  },
  {
    "id": "prod-014",
    "name": "iUNIK Tea Tree Relief Serum",
    "cat": "cat-serum",
    "image": "products/iunik_tea_tree_relief_serum.jpg",
    "comment": "סרום עץ התה להרגעה, איזון והפחתת פגמים בעור",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 2,
      "freq": "daily"
    }
  },
  {
    "id": "prod-015",
    "name": "S.NATURE Aqua Squalane Moisturizing Cream",
    "cat": "cat-moisturizer",
    "image": "products/snature_aqua_squalane_cream.jpg",
    "comment": "קרם לחות עשיר בסקוואלן להזנה, ריכוך ושמירה על לחות העור",
    "am": {
      "order": 1,
      "freq": "daily"
    },
    "pm": {
      "order": 3,
      "freq": "daily"
    }
  },
  {
    "id": "prod-016",
    "name": "Beauty of Joseon Light On Serum Centella + Vita C",
    "cat": "cat-serum",
    "image": "products/beauty_of_joseon_light_on_serum.jpg",
    "comment": "סרום ויטמין C וסנטלה להבהרה, האחדת גוון העור והגנה אנטיאוקסידנטית",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": null
  },
  {
    "id": "prod-017",
    "name": "Isntree Hyper Acid 4 AHA BHA PHA LHA 30 Serum",
    "cat": "cat-serum",
    "image": "products/isntree_hyper_acid_30_serum.jpg",
    "comment": "סרום פילינג עוצמתי המשלב 4 חומצות לחידוש מרקם העור, ניקוי נקבוביות והבהרה",
    "am": null,
    "pm": {
      "order": 2,
      "freq": {
        "max": 3
      }
    }
  },
  {
    "id": "prod-018",
    "name": "Dr.Jart+ Cicapair Intensive Soothing Repair Treatment Lotion",
    "cat": "cat-moisturizer",
    "image": "products/dr_jart_cicapair_treatment_lotion.jpg",
    "comment": "תחליב טיפולי אינטנסיבי להרגעה מהירה, שיקום מחסום העור והפחתת אדמומיות עם קומפלקס סינטלה",
    "am": {
      "order": 1,
      "freq": "daily"
    },
    "pm": {
      "order": 3,
      "freq": "daily"
    }
  },
  {
    "id": "prod-019",
    "name": "Beauty of Joseon Relief Sun Aqua Fresh Rice+B5",
    "cat": "cat-spf",
    "image": "products/beauty_of_joseon_relief_sun_aqua_fresh.jpg",
    "comment": "קרם הגנה קליל במרקם קל ומרענן, מועשר באורז וויטמין B5 להגנה ולחות מוגברת",
    "am": {
      "order": 4,
      "freq": "daily"
    },
    "pm": null
  },
  {
    "id": "prod-020",
    "name": "Kisocare Azelaic Acid Cream 20%",
    "cat": "cat-serum",
    "image": "products/kisocare_azelaic_acid_cream_20.jpg",
    "comment": "קרם טיפולי פעיל בריכוז 20% חומצה אזלאית להבהרת כתמים, טיפול בפגמי עור ושיפור מרקם העור",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-021",
    "name": "JUMISO Niacinamide 20 Serum",
    "cat": "cat-serum",
    "image": "products/jumiso_niacinamide_20_serum.jpg",
    "comment": "סרום פעיל בריכוז 20% ניאצינמיד להבהרה, איזון סבום, כיווץ נקבוביות ושיפור מרקם העור",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-022",
    "name": "PURCELL 88B/mL L-Glutathione Flexible Liposome",
    "cat": "cat-toner",
    "image": "products/purcell_l_glutathione_liposome.jpg",
    "comment": "סרום אנטיאוקסידנטי מתקדם עם גלוטתיון ליפוזומלי להבהרה, הגנה מפני רדיקלים חופשיים והאחדת גוון העור",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-023",
    "name": "Cos De BAHA T15 Serum",
    "cat": "cat-serum",
    "image": "products/cos_de_baha_t15_serum.jpg",
    "comment": "סרום טיפולי פעיל בריכוז 15% חומצה טרנקסמית להבהרת פיגמנטציה, טיפול בכתמי עור עקשניים והאחדת גוון העור",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-024",
    "name": "Genabelle PDRN 3% Hyper Boost Ampoule",
    "cat": "cat-serum",
    "image": "products/genabelle_pdrn_hyper_boost_ampoule.jpg",
    "comment": "אמפולה טיפולית מרוכזת עם 3% PDRN לשיקום עמוק, שיפור אלסטיות העור, עידוד התחדשות התאים וחיזוק מחסום העור",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-025",
    "name": "DERMA E Acne Blemish Control Treatment Serum",
    "cat": "cat-serum",
    "image": "products/derma_e_acne_blemish_control_serum.jpg",
    "comment": "סרום טיפולי לעור מעורב עד שמן, מסייע במניעה וטיפול בפגמי עור, ניקוי נקבוביות והאיזון בלוטות החלב",
    "am": null,
    "pm": {
      "order": 0,
      "freq": {
        "max": 3
      }
    }
  },
  {
    "id": "prod-026",
    "name": "Cos De BAHA AZ15 Serum",
    "cat": "cat-serum",
    "image": "products/cos_de_baha_az15_serum.jpg",
    "comment": "סרום טיפולי המכיל 15% חומצה אזלאית להרגעת אדמומיות, טיפול בדלקתיות ועור מגורה, והבהרת פגמי עור",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-027",
    "name": "boben Ectoin Moisturizing Soothing Sensitivity Repair Cream",
    "cat": "cat-moisturizer",
    "image": "products/boben_ectoin_sensitivity_repair_cream.jpg",
    "comment": "קרם לחות טיפולי משקם להרגעת עור רגיש ומגורה, חיזוק מחסום העור והפחתת רגישות בעזרת אקטואין",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-028",
    "name": "I'm from Rice Toner",
    "cat": "cat-toner",
    "image": "products/im_from_rice_toner.jpg",
    "comment": "טונר אורז עשיר להזנה אינטנסיבית, הבהרה, והענקת מראה חיוני וקורן לעור",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-029",
    "name": "By Wishtrend Vitamin A-mazing Bakuchiol Night Cream",
    "cat": "cat-retinoid",
    "image": "products/by_wishtrend_vitamin_amazing_bakuchiol_cream.jpg",
    "comment": "קרם לילה טיפולי המשלב רטינאל ובקוצ'יול לחידוש אינטנסיבי של תאי העור, טשטוש קמטוטים ושיפור מוצקות העור ללא גירוי",
    "am": null,
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-030",
    "name": "Anua Niacinamide 10% + TXA 4% Serum",
    "cat": "cat-serum",
    "image": "products/anua_niacinamide_txa_serum.jpg",
    "comment": "סרום מתקדם המשלב 10% ניאצינמיד ו-4% חומצה טרנקסמית להבהרה עוצמתית של פיגמנטציה, טשטוש כתמים כהים והאחדת גוון העור",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-031",
    "name": "Beauty of Joseon Dynasty Cream",
    "cat": "cat-moisturizer",
    "image": "products/beauty_of_joseon_dynasty_cream.jpg",
    "comment": "קרם לחות עשיר ומזין המבוסס על רכיבים קוריאניים מסורתיים להזנה עמוקה, הבהרה וחיזוק מחסום הלחות של העור",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-032",
    "name": "Medicube Deep Vita A Retinol Serum",
    "cat": "cat-retinoid",
    "image": "products/medicube_deep_vita_a_retinol_serum.jpg",
    "comment": "סרום אנטי-אייג'ינג מרוכז עם רטינול (ויטמין A) המסייע בצמצום מראה קמטים, מיצוק העור, שיפור האלסטיות וחידוש המרקם יחד עם הזנה עמוקה",
    "am": null,
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-033",
    "name": "haruharu wonder Black Rice Moisture Airyfit Sunscreen",
    "cat": "cat-spf",
    "image": "products/haruharu_wonder_black_rice_airyfit_sunscreen.jpg",
    "comment": "קרם הגנה קליל במרקם אוורירי, מועשר בתמצית אורז שחור מותסס להגנה גבוהה מפני השמש והזנת העור בנוגדי חמצון",
    "am": {
      "order": 4,
      "freq": "daily"
    },
    "pm": null
  },
  {
    "id": "prod-034",
    "name": "Beauty of Joseon Glow Replenishing Rice Milk",
    "cat": "cat-toner",
    "image": "products/beauty_of_joseon_glow_replenishing_rice_milk.jpg",
    "comment": "טונר חלבי מזין המבוסס על תמצית אורז להענקת לחות עמוקה, ריכוך מרקם העור ומראה קורן וגלוסי",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-035",
    "name": "COSRX The 6 Peptide Skin Booster",
    "cat": "cat-toner",
    "image": "products/cosrx_the_6_peptide_skin_booster.jpg",
    "comment": "סרום-בוסטר קליל המשלב 6 סוגי פפטידים לשיפור גמישות העור, החלקת מרקם העור, הבהרה והכנת העור לספיגה מיטבית של השלבים הבאים בשגרה",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-036",
    "name": "medicube PDRN Pink Peptide Serum",
    "cat": "cat-serum",
    "image": "products/medicube_pdrn_pink_peptide_serum.jpg",
    "comment": "סרום אנטי-אייג'ינג מתקדם המשלב PDRN וקומפלקס פפטידים לשיפור מוצקות וצפיפות העור, הבהרת גוון העור והענקת מראה חיוני וקורן",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  },
  {
    "id": "prod-037",
    "name": "THE ORDINARY Argireline Solution 10%",
    "cat": "cat-serum",
    "image": "products/the_ordinary_argireline_solution_10.jpg",
    "comment": "תמיסת פפטידים מרוכזת המכילה 10% ארגירלין, המיועדת לטיפול ממוקד במראה קמטי הבעה דינמיים וקמטוטים באזורי המצח ומסביב לעיניים",
    "am": {
      "order": 0,
      "freq": "daily"
    },
    "pm": {
      "order": 0,
      "freq": "daily"
    }
  }
];

// id -> product, and quick helpers
const PROD_BY_ID = Object.fromEntries(PRODUCTS.map(p => [p.id, p]));
const slotsOf = (p) => [p.am && 'AM', p.pm && 'PM'].filter(Boolean);
const isFlexible = (p) => !!(p.am && p.pm);
const freqFor = (p, slot) => (slot === 'AM' ? p.am : p.pm)?.freq;
const productsInCat = (catId) => PRODUCTS.filter(p => p.cat === catId);

Object.assign(window, { CATEGORIES, PRODUCTS, PROD_BY_ID, slotsOf, isFlexible, freqFor, productsInCat });
