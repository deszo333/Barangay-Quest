import React from 'react';
import { Navigate, Outlet, useOutletContext } from 'react-router-dom'; // <-- 1. Import useOutletContext

export default function PendingRoute({ user }) {
  const context = useOutletContext(); // <-- 2. Get the context from Layout
  
  // 1. Check if user is logged in
  if (!user) {
    return <Navigate to="/login" replace />;
  }

  // 2. Check if user is "approved"
  if (user.status === 'approved') {
    return <Navigate to="/" replace />;
  }

  // 3. If pending, render the child and PASS THE CONTEXT
  return <Outlet context={context} />; // <-- 3. Pass context down
}