import React, { useEffect, useRef, useState } from "react";
import "./HeroCarousel.css";

const SLIDES = [
  {
    id: 1,
    image:
      "https://images.unsplash.com/photo-1521737604893-d14cc237f11d?q=80&w=1600&auto=format&fit=crop",
    headline: "Find Your Quest. Empower Your Community",
    sub: "Barangay-vouched jobs & services",
  },
  {
    id: 2,
    image:
      "https://images.unsplash.com/photo-1586880244543-8c56d1d0f6ef?q=80&w=1600&auto=format&fit=crop",
    headline: "Post Tasks That Matter",
    sub: "Get trusted help from verified members",
  },
  {
    id: 3,
    image:
      "https://images.unsplash.com/photo-1522206024047-9c9254216756?q=80&w=1600&auto=format&fit=crop",
    headline: "Earn Safely with Escrow",
    sub: "Barangay-endorsed quests, secure payouts",
  },
];

export default function HeroCarousel({ onBrowse, onPost }) {
  const [index, setIndex] = useState(0);
  const trackRef = useRef(null);
  const touch = useRef({ x: 0, startX: 0, dragging: false });

  // Auto-advance
  useEffect(() => {
    const tm = setInterval(() => setIndex((i) => (i + 1) % SLIDES.length), 5500);
    return () => clearInterval(tm);
  }, []);

  // Drag/swipe
  const onPointerDown = (e) => {
    touch.current.dragging = true;
    touch.current.startX = e.clientX ?? e.touches?.[0]?.clientX;
    touch.current.x = touch.current.startX;
  };
  const onPointerMove = (e) => {
    if (!touch.current.dragging) return;
    touch.current.x = e.clientX ?? e.touches?.[0]?.clientX;
  };
  const onPointerUp = () => {
    if (!touch.current.dragging) return;
    const delta = touch.current.x - touch.current.startX;
    if (Math.abs(delta) > 60) {
      setIndex((i) =>
        delta < 0 ? (i + 1) % SLIDES.length : (i - 1 + SLIDES.length) % SLIDES.length
      );
    }
    touch.current.dragging = false;
  };

  return (
    <div
      className="hero-carousel"
      onMouseDown={onPointerDown}
      onMouseMove={onPointerMove}
      onMouseUp={onPointerUp}
      onMouseLeave={onPointerUp}
      onTouchStart={onPointerDown}
      onTouchMove={onPointerMove}
      onTouchEnd={onPointerUp}
      role="region"
      aria-label="Featured images"
    >
      <div
        className="hero-track"
        ref={trackRef}
        style={{ transform: `translateX(-${index * 100}%)` }}
      >
        {SLIDES.map((s) => (
          <div className="hero-slide" key={s.id} aria-roledescription="slide">
            <img src={s.image} alt={s.headline} loading="eager" />
            <div className="hero-overlay">
              <h1>{s.headline}</h1>
              <p>{s.sub}</p>
              <div className="hero-actions">
                <button className="btn btn-primary" onClick={onBrowse}>Browse Quests</button>
                <button className="btn btn-outline" onClick={onPost}>Post a Quest</button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Controls */}
      <button
        className="nav prev"
        aria-label="Previous slide"
        onClick={() => setIndex((i) => (i - 1 + SLIDES.length) % SLIDES.length)}
      >
        ‹
      </button>
      <button
        className="nav next"
        aria-label="Next slide"
        onClick={() => setIndex((i) => (i + 1) % SLIDES.length)}
      >
        ›
      </button>

      <div className="dots" role="tablist" aria-label="Hero pagination">
        {SLIDES.map((s, i) => (
          <button
            key={s.id}
            className={`dot ${i === index ? "active" : ""}`}
            aria-label={`Go to slide ${i + 1}`}
            onClick={() => setIndex(i)}
            role="tab"
            aria-selected={i === index}
          />
        ))}
      </div>
    </div>
  );
}
