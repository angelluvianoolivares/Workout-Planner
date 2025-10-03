:root{
--bg:#0b1020; --card:#121836; --text:#e7e9f5; --muted:#a7b0d6; --accent:#6e6af6; --ok:#48d597; --warn:#f6b26e;
--shadow:0 10px 25px rgba(0,0,0,.35);
}
*{box-sizing:border-box}
body{margin:0; font-family:Inter,system-ui,Segoe UI,Roboto,Apple Color Emoji,Noto Color Emoji,Arial,Helvetica,sans-serif; background:radial-gradient(1200px 700px at 20% -10%, #1b2250, transparent), var(--bg); color:var(--text)}
.wrap{max-width:1000px; margin:32px auto; padding:0 16px}
header{display:flex; justify-content:space-between; align-items:center; gap:12px; margin-bottom:16px}
h1{font-size:26px; margin:0}
.card{background:var(--card); border:1px solid rgba(255,255,255,.06); border-radius:18px; box-shadow:var(--shadow)}
.controls{display:grid; grid-template-columns: repeat(12, 1fr); gap:12px; padding:16px}
.controls .field{grid-column: span 12; background:rgba(255,255,255,.03); border:1px solid rgba(255,255,255,.06); padding:12px; border-radius:14px}
@media(min-width:720px){.controls .field{grid-column: span 6}}
.field h3{margin:0 0 10px; font-size:14px; color:var(--muted); letter-spacing:.3px}
.row{display:flex; flex-wrap:wrap; gap:8px}
.chip{display:inline-flex; align-items:center; gap:8px; padding:8px 12px; border-radius:999px; border:1px solid rgba(255,255,255,.08); background:rgba(255,255,255,.04); cursor:pointer}
.chip input{accent-color:var(--accent)}
select, input[type="number"], button{width:100%; padding:10px 12px; border-radius:12px; border:1px solid rgba(255,255,255,.1); background:#0f1430; color:var(--text)}
button{background:linear-gradient(180deg, var(--accent), #4b47d8); border:none; cursor:pointer; font-weight:600}
button:hover{filter:brightness(1.05)}
.out{margin-top:18px; padding:8px 0 0}
.day{margin:14px 0; padding:14px; border-radius:14px; background:rgba(255,255,255,.035); border:1px solid rgba(255,255,255,.06)}
.day h4{margin:0 0 8px; font-size:16px}
.exs{display:grid; grid-template-columns:1fr; gap:8px}
@media(min-width:720px){.exs{grid-template-columns:1fr 1fr}}
.ex{padding:10px; border-radius:12px; background:#0d132b; border:1px solid rgba(255,255,255,.06)}
.ex small{color:var(--muted)}
.note{color:var(--muted); font-size:13px}
.badge{font-size:12px; padding:4px 8px; background:rgba(255,255,255,.08); border:1px solid rgba(255,255,255,.1); border-radius:999px}
.stack{display:flex; gap:8px; align-items:center; flex-wrap:wrap}
.grid-2{display:grid; grid-template-columns:1fr; gap:12px}
@media(min-width:800px){.grid-2{grid-template-columns:1fr 1fr}}
a.link{color:var(--accent)}
.footer{margin-top:22px; color:var(--muted); font-size:12px}
.muted-box{padding:10px 12px; border-radius:10px; background:rgba(255,255,255,.05); border:1px dashed rgba(255,255,255,.1)}
