import React, { useState } from 'react';

// Simple CSS for the stars within the component
const styles = {
  container: {
    display: 'flex',
    gap: '4px',
    fontSize: '1.8rem', // Adjust size as needed
    color: 'var(--muted)', // Default star color
    cursor: 'pointer',
  },
  starActive: {
    color: '#ffd166', // Active star color (yellow)
  }
};

export default function StarRatingInput({ rating, setRating }) {
  const [hoverRating, setHoverRating] = useState(0);

  return (
    <div style={styles.container}>
      {[1, 2, 3, 4, 5].map((star) => (
        <span
          key={star}
          style={ (hoverRating || rating) >= star ? styles.starActive : {}}
          onMouseEnter={() => setHoverRating(star)}
          onMouseLeave={() => setHoverRating(0)}
          onClick={() => setRating(star)}
        >
          ★
        </span>
      ))}
    </div>
  );
}