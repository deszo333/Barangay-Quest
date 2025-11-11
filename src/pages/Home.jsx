import React, { useEffect, useRef, useState } from "react";
import { useOutletContext, useNavigate, Link } from "react-router-dom";
import { db } from "../firebase";
import { collection, query, where, orderBy, limit, getDocs, doc, getDoc } from 'firebase/firestore';
import "./Home.css"; 

const AUTOPLAY_MS = 2000; 


const HERO_SLIDES = [
  {
    id: 1,
    bgUrl: "/sunset-background.jpg", 
    figureUrl: "/figure.png", 
    figurePos: { top: '60px', right: '5vw', left: 'auto', width: '45%' },
    title: <>Find quest.<br /> <span>EMPOWER COMMUNITY</span></>,
    sub: "Vouched Jobs"
  },
  {
    id: 2,
    bgUrl: "/sunset-background.jpg", 
    figureUrl: "/figure-2.png", 
    figurePos: { top: '10px', right: '5vw', left: 'auto', width: '45%' },
    title: <>Post Tasks.<br /> <span>GET TRUSTED HELP</span></>,
    sub: "From verified members"
  },
  {
    id: 3,
    bgUrl: "/sunset-background.jpg", // A third background
    figureUrl: "/figure-3.png", // A third character
    figurePos: { top: '60px', right: '5vw', left: 'auto', width: '45%' },
    title: <>Earn Safely.<br /> <span>WITH ESCROW</span></>,
    sub: "Secure, vouched payouts"
  }
];

// SVG Icons
function Svg({ children, size = 22 }) { return ( <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" focusable="false"> {children} </svg> ); }
function IconBook(){ return (<Svg><path d="M4 19V5a2 2 0 0 1 2-2h11"/><path d="M20 22V6a2 2 0 0 0-2-2H6"/><path d="M4 19a2 2 0 0 0 2 2h12"/></Svg>); }
function IconWrench(){ return (<Svg><path d="M14.7 6.3a5 5 0 1 0-1 1l6.6 6.6a1 1 0 0 1 0 1.4l-1.6 1.6a1 1 0 0 1-1.4 0L10.7 10.3"/></Svg>); }
function IconLeaf(){ return (<Svg><path d="M3 21s3-9 13-9c0 10-13 9-13 9Z"/><path d="M9 15c-2-6 6-12 12-12-2 6-8 10-12 12Z"/></Svg>); }
function IconCamera(){ return (<Svg><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h3l2-3h8l2 3h3a2 2 0 0 1 2 2v10Z"/><circle cx="12" cy="14" r="4"/></Svg>); }
function IconClipboard(){ return (<Svg><rect x="6" y="4" width="12" height="16" rx="2"/><path d="M9 4V2h6v2"/></Svg>); }
function IconBaby(){ return (<Svg><circle cx="12" cy="8" r="3"/><path d="M6 22v-4a6 6 0 0 1 12 0v4"/></Svg>); }
function IconElder(){ return (<Svg><circle cx="9" cy="6" r="3"/><path d="M2 22l4-9 4 4 3-5 5 2"/><path d="M17 16v6"/></Svg>); }
function IconBroom(){ return (<Svg><path d="M3 21h7l7-7a4 4 0 0 0-6-6L3 21Z"/><path d="M15 7l2 2"/></Svg>); }
function IconPaw(){ return (<Svg><path d="M11 19c-2.8 0-4-2-4-3.5S8.2 12 11 12s4 1.5 4 3.5S13.8 19 11 19Z"/><circle cx="5.5" cy="10.5" r="1.5"/><circle cx="8.5" cy="8" r="1.5"/><circle cx="13.5" cy="8" r="1.5"/><circle cx="16.5" cy="10.5" r="1.5"/></Svg>); }
function IconCar(){ return (<Svg><rect x="3" y="11" width="18" height="5" rx="2"/><path d="M5 11l2-4h10l2 4"/><circle cx="7" cy="17" r="1.5"/><circle cx="17" cy="17" r="1.5"/></Svg>); }
function IconCap(){ return (<Svg><path d="M22 10L12 5 2 10l10 5 10-5Z"/><path d="M6 12v5a8 8 0 0 0 12 0v-5"/></Svg>); }
function IconCalc(){ return (<Svg><rect x="5" y="3" width="14" height="18" rx="2"/><path d="M9 7h6"/><path d="M9 11h6"/><path d="M9 15h2"/><path d="M13 15h2"/></Svg>); }
function IconPlate(){ return (<Svg><circle cx="12" cy="12" r="8"/><circle cx="12" cy="12" r="4"/></Svg>); }
function IconLaptop(){ return (<Svg><rect x="3" y="5" width="18" height="10" rx="2"/><path d="M2 19h20"/></Svg>); }
function IconPalette(){ return (<Svg><path d="M13.5 21a8.5 8.5 0 1 1 7.9-11.5c.5 1.4-.5 2.5-2 2.5h-1a2.5 2.5 0 0 0-2.3 3.4c.3.8.5 1.3-.1 1.9a2.8 2.8 0 0 1-2 0z"/><circle cx="7.5" cy="10.5" r="1"/><circle cx="9.5" cy="7.5" r="1"/><circle cx="12.5" cy="6.5" r="1"/><circle cx="16.5" cy="8" r="1"/></Svg>); }
function IconMic(){ return (<Svg><rect x="9" y="2" width="6" height="12" rx="3"/><path d="M12 14v6"/><path d="M8 10a4 4 0 0 0 8 0"/></Svg>); }
function IconShield(){ return (<Svg><path d="M12 2l8 4v6c0 5-4 8-8 10-4-2-8-5-8-10V6l8-4Z"/></Svg>); }
function IconCard(){ return (<Svg><rect x="3" y="6" width="18" height="12" rx="2"/><path d="M3 10h18"/></Svg>); }
function IconHandshake(){ return (<Svg><path d="M8 13l4 4 5-5"/><path d="M2 12l6-6 6 6 6-6"/></Svg>); }
function IconMegaphone(){ return (<Svg><path d="M3 11l11-5v12L3 13v-2Z"/><path d="M14 6v12"/><path d="M7 14v6"/></Svg>); }
function IconStar(){ return (<Svg size={16}><path d="M12 3l2.7 5.5 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.8 1-6.1L3 9.4l6.1-.9L12 3Z"/></Svg>); }
function IconPhone(){ return (<Svg><rect x="5" y="2" width="14" height="20" rx="2" ry="2"/><line x1="12" y1="18" x2="12.01" y2="18"/></Svg>); } 

// Category Icon Mapping
const CATEGORY_ICONS = {
  "Tutoring": IconBook, "Home Repair": IconWrench, "Gardening": IconLeaf,
  "Photography": IconCamera, "Errands": IconClipboard, "Child Care": IconBaby,
  "Elder Care": IconElder, "Cleaning": IconBroom, "Pet Care": IconPaw,
  "Transport": IconCar, "Test Prep": IconCap, "Bookkeeping": IconCalc,
  "Catering": IconPlate, "PC Help": IconLaptop, "Design": IconPalette,
  "Events": IconMic,
  "Default": IconClipboard
};
const CATEGORIES_DISPLAY = Object.keys(CATEGORY_ICONS).filter(k => k !== "Default");

// Hook for reveal animation
function useRevealOnScroll() {
  useEffect(() => {
    const nodes = document.querySelectorAll(".reveal-up");
    nodes.forEach((n) => n.classList.add("in"));
    const io = new IntersectionObserver( (entries) => entries.forEach((e) => e.isIntersecting && e.target.classList.add("in")), { threshold: 0.15 } );
    nodes.forEach((n) => io.observe(n));
    return () => io.disconnect();
  }, []);
}

// formatDate helper
function formatDate(timestamp) {
  if (!timestamp) return "";
  const seconds = Math.floor((new Date() - timestamp.toDate()) / 1000);
  let interval = seconds / 86400; if (interval > 1) return Math.floor(interval) + " days ago";
  interval = seconds / 3600; if (interval > 1) return Math.floor(interval) + " hours ago";
  interval = seconds / 60; if (interval > 1) return Math.floor(interval) + " minutes ago";
  return "Just now";
}

// Main Home Component
export default function Home() {
  useRevealOnScroll();
  const { user } = useOutletContext();
  const navigate = useNavigate();

  // --- NEW: Carousel State ---
  const [index, setIndex] = useState(0);
  const autoRef = useRef(null);

  // --- NEW: Autoplay Logic ---
  useEffect(() => {
    const startAuto = () => {
      autoRef.current = setInterval(() => {
        setIndex((prevIndex) => (prevIndex + 1) % HERO_SLIDES.length);
      }, AUTOPLAY_MS);
    };
    startAuto(); // Start on mount
    return () => {
      if (autoRef.current) clearInterval(autoRef.current); // Clear on unmount
    };
  }, []);

  // --- NEW: Dot click handler ---
  const goTo = (i) => {
    setIndex(i);
    // Reset autoplay timer
    if (autoRef.current) clearInterval(autoRef.current);
    autoRef.current = setInterval(() => {
      setIndex((prevIndex) => (prevIndex + 1) % HERO_SLIDES.length);
    }, AUTOPLAY_MS);
  };

  const requireAuth = (e, path = "/login") => { if (!user) { e.preventDefault(); navigate(path); } };

  // Top Questers State & Fetch
  const [topQuesters, setTopQuesters] = useState([]);
  const [questersLoading, setQuestersLoading] = useState(true);
  useEffect(() => {
      const fetchTopQuesters = async () => {
          setQuestersLoading(true);
          try {
              const usersRef = collection(db, "users");
              const q = query( usersRef, where("status", "==", "approved"), orderBy("questsCompleted", "desc"), limit(4) );
              const querySnapshot = await getDocs(q);
              const usersData = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data(), avgRating: (doc.data().numberOfRatings > 0) ? (doc.data().totalRatingScore / doc.data().numberOfRatings) : 0 }));
              setTopQuesters(usersData);
          } catch (err) { console.error("Error fetching top questers:", err); /* Index error check */ }
          finally { setQuestersLoading(false); }
      };
      fetchTopQuesters();
  }, []);

  // Top Quest Givers State & Fetch
  const [topQuestGivers, setTopQuestGivers] = useState([]);
  const [giversLoading, setGiversLoading] = useState(true);
   useEffect(() => {
      const fetchTopQuestGivers = async () => {
          setGiversLoading(true);
          try {
              const usersRef = collection(db, "users");
              const q = query( usersRef, where("status", "==", "approved"), orderBy("questsGivenCompleted", "desc"), limit(4) );
              const querySnapshot = await getDocs(q);
              const usersData = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data(), avgRating: (doc.data().numberOfRatings > 0) ? (doc.data().totalRatingScore / doc.data().numberOfRatings) : 0 }));
              setTopQuestGivers(usersData);
          } catch (err) { console.error("Error fetching top quest givers:", err); /* Index error check */ }
          finally { setGiversLoading(false); }
      };
      fetchTopQuestGivers();
  }, []);

  // Community Buzz State & Fetch
  const [buzzItems, setBuzzItems] = useState([]);
  const [buzzLoading, setBuzzLoading] = useState(true);
  useEffect(() => {
    const fetchBuzz = async () => {
      setBuzzLoading(true);
      try {
        const questsRef = collection(db, "quests");
        const q = query( questsRef, where("status", "==", "completed"), orderBy("completedAt", "desc"), limit(3) );
        const querySnapshot = await getDocs(q);
        const buzzPromises = querySnapshot.docs.map(async (questDoc) => {
          const quest = { id: questDoc.id, ...questDoc.data() };
          let questerName = "A Quester";
          if (quest.hiredApplicantId) {
            try {
                const userRef = doc(db, "users", quest.hiredApplicantId);
                const userSnap = await getDoc(userRef);
                if (userSnap.exists()) { questerName = userSnap.data().name; }
            } catch (userErr) { console.error("Error fetching user for buzz:", userErr); }
          }
          const IconComponent = CATEGORY_ICONS[quest.category] || CATEGORY_ICONS["Default"];
          return { name: questerName, text: `Completed a ${quest.category} quest: "${quest.title}"`, ago: formatDate(quest.completedAt), icon: IconComponent };
        });
        const resolvedBuzzItems = await Promise.all(buzzPromises);
        setBuzzItems(resolvedBuzzItems);
      } catch (err) { console.error("Error fetching buzz:", err); /* Index error check */ }
      finally { setBuzzLoading(false); }
    };
    fetchBuzz();
  }, []);

  // Render the Home page
  return (
    <main className="home">
      
      {/* --- CONTAINER WRAPPER --- */}
      <div className="hero-container">

        {/* --- HERO Section (MODIFIED) --- */}
        <section
          className="hero polished reveal-up"
          tabIndex={0}
        >
          {/* --- NEW: Background Track --- */}
          <div className="hero-bg-track">
            {HERO_SLIDES.map((slide, i) => (
              <div
                key={slide.id}
                className="hero-bg-slide"
                style={{
                  backgroundImage: `url(${slide.bgUrl})`,
                  opacity: i === index ? 1 : 0
                }}
              />
            ))}
          </div>

          <div className="hero-overlay" aria-hidden="true" />

          {/* --- NEW: Text and Dots --- */}
          <div className="bq-container hero-grid">
            {/* Add key={index} to force fade animation */}
            <div className="hero-copy" key={index}>
              <h1>{HERO_SLIDES[index].title}</h1>
              <p className="sub">{HERO_SLIDES[index].sub}</p>
              <div className="hero-cta">
                <Link to="/find-jobs" className="btn btn-accent">Browse</Link>
                {user && user.status === 'approved' ? (
                    <Link to="/post-job" className="btn btn-secondary"> Post </Link>
                ) : (
                     <Link to="/signup" className="btn btn-secondary" onClick={(e) => { if(user) { e.preventDefault(); navigate('/pending-approval'); } }}> Post </Link>
                )}
              </div>
            </div>
          </div>
          
          {/* --- NEW: Dots Restored --- */}
          <div className="hero-dots">
            {HERO_SLIDES.map((s, i) => (
              <button
                key={s.id}
                type="button"
                className={`dot ${i === index ? "active" : ""}`}
                onClick={() => goTo(i)}
                aria-label={`Go to slide ${i + 1}`}
              />
            ))}
          </div>
          
        </section>

        {/* --- NEW: Figure Track (renders all figures) --- */}
        <div className="hero-figure-track">
          {HERO_SLIDES.map((slide, i) => (
            <img
              key={slide.id}
              src={slide.figureUrl}
              alt=""
              className="hero-figure"
              style={{
                ...slide.figurePos, // Applies top, left, right, width
                opacity: i === index ? 1 : 0
              }}
              aria-hidden="true"
            />
          ))}
        </div>

      {/* --- CLOSE THE CONTAINER --- */}
      </div>


      {/* --- AFTER HERO Section --- */}
      <section className="content-wrap reveal-up">
        <div className="bq-container content-grid">
          {/* Main column */}
          <div className="main-col">
            {/* Find Here Section */}
            <div className="card section">
              <div className="section-head"><h3>Here you can find jobs like: </h3></div>
              <p className="section-note"> </p>
              <div className="categories-grid">
                {CATEGORIES_DISPLAY.map((label) => (
                  <CategoryCard key={label} Icon={CATEGORY_ICONS[label]} label={label} />
                ))}
              </div>
            </div>

            {/* Community Buzz Section */}
            <div className="card section">
              <div className="section-head"><h3>Community Buzz</h3></div>
              {buzzLoading ? ( <p>Loading recent activity...</p> ) : buzzItems.length === 0 ? ( <p>No recent community activity.</p> ) : (
                <div className="buzz-list">
                  {buzzItems.map((b, i) => (
                    <div key={i} className="buzz-item">
                      <div className="buzz-icon" aria-hidden="true"><b.icon /></div>
                      <div className="buzz-body">
                        <div className="buzz-top"> <strong>{b.name}</strong><span className="dotsep">•</span> <span className="ago">{b.ago}</span> </div>
                        <p className="buzz-text">{b.text}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Safety & Trust Section */}
            <div className="card section safety">
              <div className="section-head"><h3>Safety & Trust</h3></div>
              <ul className="safety-list">
                <li><span className="s-ico"><IconShield /></span> Verified</li>
                <li><span className="s-ico"><IconCard /></span> Secure Pay</li>
                <li><span className="s-ico"><IconHandshake /></span> Support</li>
                <li><span className="s-ico"><IconMegaphone /></span> Endorsed</li>
              </ul>
            </div>

            {/* --- NEW DOWNLOAD APP CARD --- */}
            <div className="card section download-app-card">
              <div className="download-app-icon">
                <IconPhone />
              </div>
              <div className="download-app-text">
                <h3>Download the Mobile App</h3>
                <p>Get the full Barangay Quest experience on your device.</p>
              </div>
              <div className="download-app-action">
                <a 
                  href="https://drive.google.com/file/d/1mW1PGPJTrY-OoH6Enk4HbXyU5V7vEi8c/view?usp=sharing" 
                  className="btn btn-accent" 
                  target="_blank" 
                  rel="noopener noreferrer"
                >
                  Download APK
                </a>
              </div>
            </div>
            {/* --- END NEW CARD --- */}

          </div>

          {/* Side column */}
          <aside className="side-col">
            {/* Top Questers Section */}
            <div className="card section top-questers">
              <div className="section-head"> <h3>Top Questers</h3> </div>
              {questersLoading ? ( <p>Loading...</p> ) : topQuesters.length === 0 ? ( <p>None yet.</p> ) : (
                <div className="questers">
                  {topQuesters.map((q) => (
                    <Quester
                      key={q.id} id={q.id} name={q.name} role={q.role || 'Quester'}
                      img={q.avatarUrl || `https://ui-avatars.com/api/?name=${q.name}&background=random`}
                      completed={q.questsCompleted || 0} rating={q.avgRating}
                      user={user} onRequireAuth={requireAuth} statLabel="Done"
                    />
                  ))}
                </div>
              )}
            </div>

            {/* Top Quest Givers Section */}
             <div className="card section top-questers">
              <div className="section-head"> <h3>Top Givers</h3> </div>
              {giversLoading ? ( <p>Loading...</p> ) : topQuestGivers.length === 0 ? ( <p>None yet.</p> ) : (
                <div className="questers">
                  {topQuestGivers.map((g) => (
                    <Quester
                      key={g.id} id={g.id} name={g.name} role={g.role || 'Quest Giver'}
                      img={g.avatarUrl || `https://ui-avatars.com/api/?name=${g.name}&background=random`}
                      completed={g.questsGivenCompleted || 0} rating={g.avgRating}
                      statLabel="Completed" user={user} onRequireAuth={requireAuth}
                    />
                  ))}
                </div>
              )}
              {/* Buttons Section */}
              <div className="tq-actions">
                {/* <Link to="/achievements" className="btn btn-accent">Achievements</Link> */}
                {!user && ( <Link to="/signup" className="btn btn-secondary">Become Quester</Link> )}
              </div>
            </div>
          </aside>
        </div>
      </section>

      {/* --- "JOIN MOVEMENT" SECTION REMOVED --- */}
      
    </main>
  );
}

// Subcomponents
function CategoryCard({ Icon, label }) {
  return ( <button type="button" className="category"> <span className="cat-ico"><Icon /></span> <span className="cat-label">{label}</span> </button> );
}

// Quester/Giver Card Component
function Quester({ id, name, role, img, completed, rating, user, onRequireAuth, statLabel = "Done" }) {
  return (
    <div className="quester">
      <div className="avatar-wrap">
        <img src={img} alt={`${name} – ${role}`} className="avatar" loading="lazy" decoding="async" sizes="56px" />
        {/* Medal logic removed */}
      </div>
      <div className="q-body">
        <div className="q-line">
            <Link to={`/profile/${id}`} style={{fontWeight: 'bold', color: 'inherit'}}>{name}</Link>
            <span className="pill tiny">{completed} {statLabel}</span>
        </div>
        <div className="q-sub">
            {role} <span className="dotsep">•</span>
            <span className="stars"><IconStar /> {rating > 0 ? rating.toFixed(1) : 'New'}</span>
        </div>
      </div>
      <div className="q-cta">
        <Link to={`/profile/${id}`} className="btn btn-ghost">View</Link>
      </div>
    </div>
  );
}