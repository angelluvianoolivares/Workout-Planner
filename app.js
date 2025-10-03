const EXERCISES = [
  // Compound – barbell/dumbbell/bodyweight alternatives
  {id:'squat', name:'Back Squat', muscle:'legs', type:'compound', equip:['barbell','rack']},
  {id:'fsquat', name:'Front Squat', muscle:'legs', type:'compound', equip:['barbell','rack']},
  {id:'goblet', name:'Goblet Squat', muscle:'legs', type:'compound', equip:['dumbbell','kettlebell']},
  {id:'legpress', name:'Leg Press', muscle:'legs', type:'compound', equip:['machine']},
  {id:'rdl', name:'Romanian Deadlift', muscle:'posterior', type:'compound', equip:['barbell','dumbbell']},
  {id:'dl', name:'Deadlift', muscle:'posterior', type:'compound', equip:['barbell']},
  {id:'hipthrust', name:'Hip Thrust', muscle:'glutes', type:'compound', equip:['barbell','bench']},
  {id:'bench', name:'Barbell Bench Press', muscle:'chest', type:'compound', equip:['barbell','bench']},
  {id:'dbbench', name:'DB Bench Press', muscle:'chest', type:'compound', equip:['dumbbell','bench']},
  {id:'pushup', name:'Push-up', muscle:'chest', type:'compound', equip:['bodyweight']},
  {id:'ohp', name:'Overhead Press', muscle:'shoulders', type:'compound', equip:['barbell']},
  {id:'dbohp', name:'DB Shoulder Press', muscle:'shoulders', type:'compound', equip:['dumbbell']},
  {id:'row', name:'Barbell Row', muscle:'back', type:'compound', equip:['barbell']},
  {id:'dbrow', name:'DB Row', muscle:'back', type:'compound', equip:['dumbbell','bench']},
  {id:'latpulldown', name:'Lat Pulldown', muscle:'back', type:'compound', equip:['machine','cable']},
  {id:'pulldown', name:'Assisted Pull-up / Pull-down', muscle:'back', type:'compound', equip:['machine']},
  {id:'pullup', name:'Pull-up', muscle:'back', type:'compound', equip:['bodyweight','bar']},
  // Accessories
  {id:'curl', name:'Bicep Curl', muscle:'biceps', type:'accessory', equip:['dumbbell','barbell','cable']},
  {id:'tric', name:'Triceps Pushdown', muscle:'triceps', type:'accessory', equip:['cable']},
  {id:'skull', name:'Skullcrusher', muscle:'triceps', type:'accessory', equip:['barbell','dumbbell','bench']},
  {id:'latraise', name:'Lateral Raise', muscle:'shoulders', type:'accessory', equip:['dumbbell','cable']},
  {id:'fly', name:'Chest Fly', muscle:'chest', type:'accessory', equip:['dumbbell','cable','machine']},
  {id:'legcurl', name:'Leg Curl', muscle:'posterior', type:'accessory', equip:['machine']},
  {id:'legext', name:'Leg Extension', muscle:'quads', type:'accessory', equip:['machine']},
  {id:'calf', name:'Calf Raise', muscle:'calves', type:'accessory', equip:['machine','smith','bodyweight']},
  {id:'coreplank', name:'Plank', muscle:'core', type:'core', equip:['bodyweight']},
  {id:'corecable', name:'Cable Crunch', muscle:'core', type:'core', equip:['cable']},
  {id:'hanging', name:'Hanging Knee Raise', muscle:'core', type:'core', equip:['bar']},
];

// Equipment universe (for UI)
const EQUIPMENT = [
  'barbell','dumbbell','machine','cable','kettlebell','bench','rack','smith','bodyweight','bar'
];

// ------------------------------
// 2) Simple parameter maps by level & goal
// ------------------------------
const LEVEL_PARAMS = {
  beginner:    { setsMain:3,  setsAcc:2, repMain:[8,10], repAcc:[10,15], restMain:120, restAcc:60 },
  intermediate:{ setsMain:4,  setsAcc:3, repMain:[6,8],  repAcc:[8,12],  restMain:150, restAcc:75 },
  advanced:    { setsMain:5,  setsAcc:3, repMain:[4,6],  repAcc:[6,10],  restMain:180, restAcc:90 },
};

const GOAL_TWEAKS = {
  strength:    { repMainDelta:-2, repAccDelta:-2, restBoost:1.2 },
  hypertrophy: { repMainDelta:+2, repAccDelta:+2, restBoost:0.9 },
  endurance:   { repMainDelta:+4, repAccDelta:+4, restBoost:0.8 },
  recomp:      { repMainDelta:+0, repAccDelta:+0, restBoost:1.0 },
};

// ------------------------------
// 3) Progression engine: adjust volume +/- based on adherence & RPE
// ------------------------------
function progressionAdjust(levelParams, adherence, rpe){
  const p = {...levelParams};
  if(adherence==='yes' && rpe<=7){ // nudge up
    p.setsMain += 1; // add a set to mains
  }
  if(adherence==='no' || rpe>=9){ // deload light
    p.setsMain = Math.max(2, p.setsMain-1);
    p.setsAcc = Math.max(1, p.setsAcc-1);
  }
  return p;
}

// ------------------------------
// 4) Utility helpers
// ------------------------------
const rng = (min,max)=> Math.floor(Math.random()*(max-min+1))+min;
const pick = (arr)=> arr[Math.floor(Math.random()*arr.length)];
function withinEquip(ex, avail){
  return ex.equip.some(e => avail.has(e));
}
function repRange(base, delta){
  return [Math.max(3, base[0]+delta), Math.max(4, base[1]+delta)];
}
function fmtRange([a,b]){return `${a}–${b}`}

// group exercises by muscle for quick lookup (kept in case you expand)
const byMuscle = EXERCISES.reduce((m,e)=>{(m[e.muscle]??=[]).push(e); return m;},{});

// ------------------------------
// 5) Split templates by days
// ------------------------------
const SPLITS = {
  2: [ ['full'], ['full'] ],
  3: [ ['push'], ['pull'], ['legs'] ],
  4: [ ['upper'], ['lower'], ['upper'], ['lower'] ],
  5: [ ['upper'], ['lower'], ['push'], ['pull'], ['full'] ],
  6: [ ['push'], ['pull'], ['legs'], ['upper'], ['lower'], ['full'] ],
};

// Exercise blueprints per day focus
const BLUEPRINT = {
  full: {
    main:  ['squat/goblet/legpress', 'bench/dbbench/pushup', 'row/dbrow/latpulldown/pullup'],
    acc:   ['rdl/hipthrust', 'latraise/fly', 'curl/tric', 'coreplank/corecable/hanging']
  },
  upper: {
    main:  ['bench/dbbench/pushup', 'row/latpulldown/pullup', 'ohp/dbohp'],
    acc:   ['latraise/fly', 'curl', 'tric', 'coreplank/corecable/hanging']
  },
  lower: {
    main:  ['squat/goblet/legpress', 'rdl/dl/hipthrust'],
    acc:   ['legext', 'legcurl', 'calf', 'coreplank']
  },
  push: {
    main:  ['bench/dbbench/pushup', 'ohp/dbohp'],
    acc:   ['fly', 'tric', 'latraise', 'coreplank']
  },
  pull: {
    main:  ['row/dbrow/latpulldown/pullup', 'rdl/dl'],
    acc:   ['curl', 'legcurl', 'coreplank/corecable/hanging']
  },
  legs: {
    main:  ['squat/goblet/legpress', 'rdl/hipthrust/dl'],
    acc:   ['legext', 'legcurl', 'calf', 'coreplank']
  }
};

// resolve a slot like 'bench/dbbench/pushup' to a concrete exercise that fits equipment
function resolveSlot(slot, avail){
  const options = slot.split('/').map(id=>EXERCISES.find(e=>e.id===id)).filter(Boolean);
  const fit = options.filter(e=>withinEquip(e, avail));
  return (fit.length? pick(fit) : pick(options));
}

// ------------------------------
// 6) Core generator
// ------------------------------
function generatePlan({level='beginner', days=3, goal='recomp', equipment=[], adherence='yes', rpe=7, week=1}){
  days = Math.min(6, Math.max(2, Number(days)||3));
  const split = SPLITS[days] || SPLITS[3];
  const base = LEVEL_PARAMS[level] || LEVEL_PARAMS.beginner;
  const tweaked = {...base};
  const g = GOAL_TWEAKS[goal] || GOAL_TWEAKS.recomp;
  const repMain = repRange(base.repMain, g.repMainDelta);
  const repAcc  = repRange(base.repAcc,  g.repAccDelta);
  tweaked.restMain = Math.round(base.restMain * g.restBoost);
  tweaked.restAcc  = Math.round(base.restAcc  * g.restBoost);

  // progression
  const prog = progressionAdjust({ ...tweaked }, adherence, rpe);

  const avail = new Set(equipment);
  const daysOut = [];

  split.forEach((focusArr, i)=>{
    const focus = focusArr[0];
    const bp = BLUEPRINT[focus];
    const mains = bp.main.map(s=>resolveSlot(s, avail));
    const accs  = bp.acc
      .slice()
      .sort(()=>Math.random()-0.5)
      .slice(0, 3)
      .map(s=>resolveSlot(s, avail));

    const dayName = `${['Mon','Tue','Wed','Thu','Fri','Sat'][i%6] || 'Day'} – ${focus.toUpperCase()}`;

    daysOut.push({
      name: dayName,
      focus,
      main: mains.map(x=>({ id:x.id, name:x.name, sets:prog.setsMain, reps:repMain, rest:prog.restMain })),
      accessories: accs.map(x=>({ id:x.id, name:x.name, sets:prog.setsAcc, reps:repAcc, rest:prog.restAcc })),
      note: week%4===0? 'Deload week: leave 3–4 reps in reserve (RIR) and reduce weight ~10–15%.' : 'Aim to leave 1–2 reps in reserve (RIR). Increase weight next week if all top sets feel ≤7 RPE.'
    });
  });

  return { meta:{ level, days, goal, week, adherence, rpe }, plan: daysOut };
}

// ------------------------------
// 7) Minimal persistence to show progress working
// ------------------------------
const STORAGE_KEY = 'simple_ai_plan_v1';
function saveState(s){ localStorage.setItem(STORAGE_KEY, JSON.stringify(s)); }
function loadState(){ try{ return JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}'); }catch{ return {}; } }

// ------------------------------
// 8) UI wiring (demo only)
// ------------------------------
const equipRow = document.getElementById('equipRow');
EQUIPMENT.forEach(e=>{
  const label = document.createElement('label'); label.className='chip';
  label.innerHTML = `<input type="checkbox" value="${e}"> ${e}`;
  equipRow.appendChild(label);
});

function getSelectedEquip(){
  return Array.from(equipRow.querySelectorAll('input:checked')).map(x=>x.value);
}

function render(out){
  const el = document.getElementById('out');
  el.innerHTML = '';
  out.plan.forEach(day=>{
    const wrap = document.createElement('div'); wrap.className='day';
    const h = document.createElement('h4'); h.textContent = day.name; wrap.appendChild(h);

    const exs = document.createElement('div'); exs.className = 'exs'; wrap.appendChild(exs);
    const mk = (e,isMain)=>{
      const d = document.createElement('div'); d.className='ex';
      const sets = `${e.sets} x ${fmtRange(e.reps)} reps`;
      d.innerHTML = `<strong>${e.name}</strong><br><small>${isMain?'Main':'Accessory'} • ${sets} • Rest ${e.rest}s</small>`;
      return d;
    };
    day.main.forEach(m=>exs.appendChild(mk(m,true)));
    day.accessories.forEach(a=>exs.appendChild(mk(a,false)));

    const p = document.createElement('p'); p.className='note'; p.textContent = day.note; wrap.appendChild(p);
    el.appendChild(wrap);
  });
}

function currentWeek(){
  const s = loadState();
  return Number(s.week)||1;
}

function setWeekBadge(w){
  document.getElementById('weekBadge').textContent = `Week ${w}`;
}

// initial state
setWeekBadge(currentWeek());

// Generate click
const genBtn = document.getElementById('gen');

function handleGenerate(){
  const profile = {
    level: document.getElementById('level').value,
    days: document.getElementById('days').value,
    goal: document.getElementById('goal').value,
    equipment: getSelectedEquip(),
    adherence: document.getElementById('adherence').value,
    rpe: Number(document.getElementById('rpe').value)||7,
    week: currentWeek()
  };
  const plan = generatePlan(profile);
  render(plan);
  // Save next-week progression hint
  const nextWeek = Math.min(12, profile.week + 1);
  saveState({ week: nextWeek });
  setWeekBadge(profile.week);
}

genBtn.addEventListener('click', handleGenerate);

// Auto-generate on first load
handleGenerate();

// ------------------------------
// 9) Export generator for your app (global)
// ------------------------------
window.SimpleAIWorkout = { generatePlan };
