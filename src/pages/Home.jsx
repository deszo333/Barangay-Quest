import React, { useEffect, useRef, useState } from "react";
import { useOutletContext, useNavigate, Link } from "react-router-dom";
import "./Home.css";

/* ============================================================
   IMAGE / DATA REPLACEMENT NOTES
   - Replace any portrait/photo URLs below with your own.
   - For local assets, place files in /public and use e.g. "/imgs/portrait1.jpg".
   - Change AUTOPLAY_MS to adjust hero autoplay speed.
============================================================ */

const AUTOPLAY_MS = 6000;

/* --- HERO CAROUSEL IMAGES --- */
const HERO_SLIDES = [
  { url: "https://images.unsplash.com/photo-1519389950473-47ba0277781c?q=80&w=2000&auto=format&fit=crop", caption: "Laptop teamwork (sample)" },
  { url: "https://images.unsplash.com/photo-1520975682031-b9ca8a0b5b06?q=80&w=2000&auto=format&fit=crop", caption: "Community gathering (sample)" },
  { url: "https://images.unsplash.com/photo-1560518883-ce09059eeffa?q=80&w=2000&auto=format&fit=crop", caption: "Helpers in barangay (sample)" },
];

/* --- TOP QUESTERS (swap images as needed) --- */
const TOP_QUESTERS = [
  { name: "Marta K.",  role: "Photographer", img: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=600&auto=format&fit=crop", lvl: 42, rating: 4.9, medal: "gold",  weeklyScore: 120, allTimeScore: 2200 },
  { name: "Joseph L.", role: "Handyman",    img: "https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=600&auto=format&fit=crop", lvl: 35, rating: 4.8, medal: "silver",weeklyScore: 95,  allTimeScore: 1800 },
  { name: "Ben T.",    role: "Math Tutor",  img: "https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?q=80&w=600&auto=format&fit=crop", lvl: 33, rating: 4.8, medal: "bronze",weeklyScore: 88,  allTimeScore: 1650 },
  { name: "Aira P.",   role: "Event Host",  img: "https://images.unsplash.com/photo-1544717305-2782549b5136?q=80&w=600&auto=format&fit=crop", lvl: 28, rating: 4.7, medal: "none", weeklyScore: 70,  allTimeScore: 900  },
];

/* --- “Jobs & Quests You’ll Find Here” (representative list) --- */
const CATEGORIES = [
  { icon: IconBook,     label: "Tutoring" },
  { icon: IconWrench,   label: "Home Repair" },
  { icon: IconLeaf,     label: "Gardening" },
  { icon: IconCamera,   label: "Photography" },
  { icon: IconClipboard,label: "Errands" },
  { icon: IconBaby,     label: "Child Care" },
  { icon: IconElder,    label: "Elder Care" },
  { icon: IconBroom,    label: "Cleaning" },
  { icon: IconPaw,      label: "Pet Care" },
  { icon: IconCar,      label: "Transport" },
  { icon: IconCap,      label: "Test Prep" },
  { icon: IconCalc,     label: "Bookkeeping" },
  { icon: IconPlate,    label: "Catering" },
  { icon: IconLaptop,   label: "PC Help" },
  { icon: IconPalette,  label: "Design" },
  { icon: IconMic,      label: "Events" },
];

/* --- COMMUNITY BUZZ (recent completions) --- */
const BUZZ = [
  { name: "Reynal",    text: "Just completed a Garden Service quest for my neighbor. Happy to help out!", ago: "2 days ago", icon: IconLeaf },
  { name: "Marta K.",  text: "Covered a community event—200+ photos delivered with edits!",               ago: "4 days ago",  icon: IconCamera },
  { name: "Joseph L.", text: "Fixed water leak and replaced kitchen faucet for a senior.",                 ago: "1 week ago",  icon: IconWrench },
];

/* ---------- reveal on scroll ---------- */
function useRevealOnScroll() {
  useEffect(() => {
    const nodes = document.querySelectorAll(".reveal-up");
    // Immediately visible on mount
    nodes.forEach((n) => n.classList.add("in"));
    // Observe for future sections / SSR hydration
    const io = new IntersectionObserver(
      (entries) => entries.forEach((e) => e.isIntersecting && e.target.classList.add("in")),
      { threshold: 0.15 }
    );
    nodes.forEach((n) => io.observe(n));
    return () => io.disconnect();
  }, []);
}

export default function Home() {
  useRevealOnScroll();

  // Get 'user' from the App.jsx layout
  const { user } = useOutletContext();
  const navigate = useNavigate();

  // This function will be called by protected buttons
  const requireAuth = (e, path = "/login") => {
    if (!user) {
      e.preventDefault(); // Stop the default action
      navigate(path);   // Redirect to login
    }
    // If user exists, do nothing and let the action/link proceed
  };

  /* ----- HERO CAROUSEL STATE ----- */
  const [index, setIndex] = useState(0);
  const [isPaused, setIsPaused] = useState(false);
  const autoRef = useRef(null);
  const touchStartX = useRef(0);
  const touchDeltaX = useRef(0);

  const prefersReduced = typeof window !== "undefined" &&
    window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // Autoplay & progress
  useEffect(() => {
    if (prefersReduced) return; // respect reduced motion
    startAuto();
    return () => { stopAuto(); };
  }, [index, isPaused, prefersReduced]);

  function stopAuto() { if (autoRef.current) clearInterval(autoRef.current); }
  function startAuto() {
    stopAuto();
    if (!isPaused) {
      autoRef.current = setInterval(() => setIndex((i) => (i + 1) % HERO_SLIDES.length), AUTOPLAY_MS);
    }
  }


  const goTo = (i) => { setIndex(i);};
  const onTouchStart = (e) => { touchStartX.current = e.touches[0].clientX; touchDeltaX.current = 0; };
  const onTouchMove  = (e) => { touchDeltaX.current = e.touches[0].clientX - touchStartX.current; };
  const onTouchEnd   = ()  => {
    const threshold = 60; // px
    if (touchDeltaX.current > threshold) setIndex((i) => (i - 1 + HERO_SLIDES.length) % HERO_SLIDES.length);
    else if (touchDeltaX.current < -threshold) setIndex((i) => (i + 1) % HERO_SLIDES.length);
  };
  const onKeyDown = (e) => {
    if (e.key === "ArrowRight") setIndex((i) => (i + 1) % HERO_SLIDES.length);
    if (e.key === "ArrowLeft")  setIndex((i) => (i - 1 + HERO_SLIDES.length) % HERO_SLIDES.length);
  };

  /* ----- LEADERBOARD TOGGLE ----- */
  const [lbMode, setLbMode] = useState("weekly"); // "weekly" | "all-time"
  const displayedQuesters = [...TOP_QUESTERS].sort((a, b) =>
    lbMode === "weekly" ? b.weeklyScore - a.weeklyScore : b.allTimeScore - a.allTimeScore
  );

  return (
    <main className="home">
      {/* ===================== HERO ===================== */}
      <section
        className="hero polished reveal-up"
        onTouchStart={onTouchStart}
        onTouchMove={onTouchMove}
        onTouchEnd={onTouchEnd}
        onKeyDown={onKeyDown}
        tabIndex={0} /* keyboard support */
        onMouseEnter={() => setIsPaused(true)}
        onMouseLeave={() => setIsPaused(false)}
        onFocus={() => setIsPaused(true)}
        onBlur={() => setIsPaused(false)}
      >
        <div
          className="hero-bg"
          style={{ backgroundImage: `url(${HERO_SLIDES[index].url})` }}
          aria-hidden="true"
        />
        <div className="hero-overlay" aria-hidden="true" />

        <div className="bq-container hero-grid">
          <div className="hero-copy">
            <h1>
              Find your quest.<br />
              <span>EMPOWER YOUR COMMUNITY</span>
            </h1>
            <p className="sub">Barangay-Vouched Jobs &amp; Services</p>
            <div className="hero-cta">
              <Link to="/find-jobs" className="btn btn-accent">Browse Quests</Link>
              <Link 
                to="/post-job" 
                className="btn btn-secondary" 
                onClick={(e) => requireAuth(e, "/post-job")}
              >
                Post a Quest
              </Link>
            </div>
          </div>
        </div>

        <div className="hero-dots" role="tablist" aria-label="Hero slides">
          {HERO_SLIDES.map((_, i) => (
            <button
              key={i}
              type="button"
              role="tab"
              aria-selected={index === i}
              aria-label={`Go to slide ${i + 1}`}
              className={"dot" + (index === i ? " active" : "")}
              onClick={() => goTo(i)}
            />
          ))}
        </div>
      </section>

      {/* ===================== AFTER HERO ===================== */}
      <section className="content-wrap reveal-up">
        <div className="bq-container content-grid">
          {/* Main column */}
          <div className="main-col">
            {/* Jobs & Quests */}
            <div className="card section">
              <div className="section-head">
                <h3>Jobs &amp; Quests You’ll Find Here</h3>
              </div>
              <p className="section-note">
                These are common examples—<strong>and many more.</strong> Any miscellaneous job can be found or created here.
              </p>
              <div className="categories-grid">
                {CATEGORIES.map((c, i) => (
                  <CategoryCard key={i} Icon={c.icon} label={c.label} />
                ))}
              </div>
            </div>

            {/* Community Buzz */}
            <div className="card section">
              <div className="section-head"><h3>Community Buzz</h3></div>
              <div className="buzz-list">
                {BUZZ.map((b, i) => (
                  <div key={i} className="buzz-item">
                    <div className="buzz-icon" aria-hidden="true"><b.icon /></div>
                    <div className="buzz-body">
                      <div className="buzz-top">
                        <strong>{b.name}</strong><span className="dotsep">•</span>
                        <span className="ago">{b.ago}</span>
                      </div>
                      <p className="buzz-text">{b.text}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Safety & Trust */}
            <div className="card section safety">
              <div className="section-head"><h3>Safety &amp; Trust</h3></div>
              <ul className="safety-list">
                <li><span className="s-ico"><IconShield /></span> Verified Profiles</li>
                <li><span className="s-ico"><IconCard /></span> Secure Payments</li>
                <li><span className="s-ico"><IconHandshake /></span> Community Support</li>
                <li><span className="s-ico"><IconMegaphone /></span> Barangay Endorsements</li>
              </ul>
            </div>
          </div>

          {/* Side column */}
          <aside className="side-col">
            {/* Top Questers */}
            <div className="card section top-questers">
              <div className="section-head">
                <h3>Top Questers</h3>
                <div className="mini-legend">
                  <button
                    type="button"
                    className={"pill gold clickable" + (lbMode === "weekly" ? " active" : "")}
                    aria-pressed={lbMode === "weekly"}
                    onClick={() => setLbMode("weekly")}
                  >Weekly</button>
                  <button
                    type="button"
                    className={"pill slate clickable" + (lbMode === "all-time" ? " active" : "")}
                    aria-pressed={lbMode === "all-time"}
                    onClick={() => setLbMode("all-time")}
                  >All-time</button>
                </div>
              </div>

              <div className="questers">
                {displayedQuesters.map((q, i) => (
                  <Quester key={i} {...q} user={user} onRequireAuth={requireAuth} />
                ))}
              </div>

              <div className="tq-actions">
                <Link to="/leaderboard" className="btn btn-accent">View Leaderboard</Link>
                <Link 
                  to="/signup" 
                  className="btn btn-secondary"
                  onClick={(e) => requireAuth(e, "/signup")} // Or send to a "become a quester" page
                >
                  Become a Quester
                </Link>
              </div>
            </div>
          </aside>
        </div>
      </section>

      {/* ===================== JOIN (keep) ===================== */}
      <section className="join reveal-up" style={{ animationDelay: ".1s" }}>
        <div className="bq-container join-inner">
          <div className="join-illustration">
            <img
              src="https://images.unsplash.com/photo-1600880292203-757bb62b4baf?q=80&w=1400&auto=format&fit=crop"
              alt="Community working together"
              loading="lazy"
              decoding="async"
              sizes="(max-width: 980px) 92vw, 550px"
            />
          </div>
          <div className="join-copy">
            <h2>Join the Movement</h2>
            <ul className="ticks">
              <li>Vetted Opportunities</li>
              <li>Community Support</li>
              <li>Local Impact</li>
            </ul>
            <button type="button" className="btn btn-primary lg">Sign up today</button>
          </div>
        </div>
      </section>
    </main>
  );
}

/* ================= SVG ICONS (no emojis) ================= */

function Svg({ children, size = 22 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
      stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"
      aria-hidden="true" focusable="false">
      {children}
    </svg>
  );
}
function IconBook(){     return (<Svg><path d="M4 19V5a2 2 0 0 1 2-2h11"/><path d="M20 22V6a2 2 0 0 0-2-2H6"/><path d="M4 19a2 2 0 0 0 2 2h12"/></Svg>); }
function IconWrench(){   return (<Svg><path d="M14.7 6.3a5 5 0 1 0-1 1l6.6 6.6a1 1 0 0 1 0 1.4l-1.6 1.6a1 1 0 0 1-1.4 0L10.7 10.3"/></Svg>); }
function IconLeaf(){     return (<Svg><path d="M3 21s3-9 13-9c0 10-13 9-13 9Z"/><path d="M9 15c-2-6 6-12 12-12-2 6-8 10-12 12Z"/></Svg>); }
function IconCamera(){   return (<Svg><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h3l2-3h8l2 3h3a2 2 0 0 1 2 2v10Z"/><circle cx="12" cy="14" r="4"/></Svg>); }
function IconClipboard(){return (<Svg><rect x="6" y="4" width="12" height="16" rx="2"/><path d="M9 4V2h6v2"/></Svg>); }
function IconBaby(){     return (<Svg><circle cx="12" cy="8" r="3"/><path d="M6 22v-4a6 6 0 0 1 12 0v4"/></Svg>); }
function IconElder(){    return (<Svg><circle cx="9" cy="6" r="3"/><path d="M2 22l4-9 4 4 3-5 5 2"/><path d="M17 16v6"/></Svg>); }
function IconBroom(){    return (<Svg><path d="M3 21h7l7-7a4 4 0 0 0-6-6L3 21Z"/><path d="M15 7l2 2"/></Svg>); }
function IconPaw(){      return (<Svg><path d="M11 19c-2.8 0-4-2-4-3.5S8.2 12 11 12s4 1.5 4 3.5S13.8 19 11 19Z"/><circle cx="5.5" cy="10.5" r="1.5"/><circle cx="8.5" cy="8" r="1.5"/><circle cx="13.5" cy="8" r="1.5"/><circle cx="16.5" cy="10.5" r="1.5"/></Svg>); }
function IconCar(){      return (<Svg><rect x="3" y="11" width="18" height="5" rx="2"/><path d="M5 11l2-4h10l2 4"/><circle cx="7" cy="17" r="1.5"/><circle cx="17" cy="17" r="1.5"/></Svg>); }
function IconCap(){      return (<Svg><path d="M22 10L12 5 2 10l10 5 10-5Z"/><path d="M6 12v5a8 8 0 0 0 12 0v-5"/></Svg>); }
function IconCalc(){     return (<Svg><rect x="5" y="3" width="14" height="18" rx="2"/><path d="M9 7h6"/><path d="M9 11h6"/><path d="M9 15h2"/><path d="M13 15h2"/></Svg>); }
function IconPlate(){    return (<Svg><circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4"/></Svg>); }
function IconLaptop(){   return (<Svg><rect x="3" y="5" width="18" height="10" rx="2"/><path d="M2 19h20"/></Svg>); }
function IconPalette(){  return (<Svg><path d="M13.5 21a8.5 8.5 0 1 1 7.9-11.5c.5 1.4-.5 2.5-2 2.5h-1a2.5 2.5 0 0 0-2.3 3.4c.3.8.5 1.3-.1 1.9a2.8 2.8 0 0 1-2 0z"/><circle cx="7.5" cy="10.5" r="1"/><circle cx="9.5" cy="7.5" r="1"/><circle cx="12.5" cy="6.5" r="1"/><circle cx="16.5" cy="8" r="1"/></Svg>); }
function IconMic(){      return (<Svg><rect x="9" y="2" width="6" height="12" rx="3"/><path d="M12 14v6"/><path d="M8 10a4 4 0 0 0 8 0"/></Svg>); }
function IconShield(){   return (<Svg><path d="M12 2l8 4v6c0 5-4 8-8 10-4-2-8-5-8-10V6l8-4Z"/></Svg>); }
function IconCard(){     return (<Svg><rect x="3" y="6" width="18" height="12" rx="2"/><path d="M3 10h18"/></Svg>); }
function IconHandshake(){return (<Svg><path d="M8 13l4 4 5-5"/><path d="M2 12l6-6 6 6 6-6"/></Svg>); }
function IconMegaphone(){return (<Svg><path d="M3 11l11-5v12L3 13v-2Z"/><path d="M14 6v12"/><path d="M7 14v6"/></Svg>); }
function IconMedal({ tone="gold" }) {
  const fill = tone==="gold" ? "#FFD166" : tone==="silver" ? "#D1D5DB" : tone==="bronze" ? "#D97706" : "#7FD2FF";
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="none" aria-hidden="true" focusable="false">
      <circle cx="12" cy="12" r="7" fill={fill} />
      <path d="M8 3l4 5 4-5" stroke={fill} strokeWidth="2" fill="none" />
    </svg>
  );
}
function IconStar(){     return (<Svg size={16}><path d="M12 3l2.7 5.5 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.8 1-6.1L3 9.4l6.1-.9L12 3Z"/></Svg>); }

/* ---------- UI subcomponents ---------- */

function CategoryCard({ Icon, label }) {
  return (
    <button type="button" className="category">
      <span className="cat-ico" aria-hidden="true"><Icon /></span>
      <span className="cat-label">{label}</span>
    </button>
  );
}

function Quester({ name, role, img, lvl, rating, medal, user, onRequireAuth }) {
  
  const handleHire = (e) => {
    // This is the protected action
    if (!user) {
      e.preventDefault(); // Stop button click
      onRequireAuth(e);   // Run the auth check (which navigates to /login)
    } else {
      // User is logged in, proceed with hire logic
      console.log(`Hiring ${name}...`);
      // You might navigate to a /hire/joseph-l page
    }
  };
  
  return (
    <div className="quester">
      <div className="avatar-wrap">
        <img
          src={img}
          alt={`${name} – ${role}`}
          className="avatar"
          loading="lazy"
          decoding="async"
          sizes="56px"
        />
        <span className="q-badge" title="Medal">
          <IconMedal tone={medal} />
        </span>
      </div>
      <div className="q-body">
        <div className="q-line">
          <strong>{name}</strong>
          <span className="pill tiny">Lv {lvl}</span>
        </div>
        <div className="q-sub">
          {role} <span className="dotsep">•</span>{" "}
          <span className="stars"><IconStar /> {rating.toFixed(1)}</span>
        </div>
      </div>
      <div className="q-cta">
        <button type="button" className="btn btn-ghost">View</button>
        <button 
          type="button" 
          className="btn btn-accent"
          onClick={handleHire}
        >
          Hire
        </button>
      </div>
    </div>
  );
}