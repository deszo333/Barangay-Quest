import React from 'react';
import { Navigate, Outlet, useOutletContext } from 'react-router-dom';

export default function AdminRoute({ user }) {
  const context = useOutletContext();
  
  // 1. Check if user is logged in
  if (!user) {
    return <Navigate to="/login" replace />;
  }

  // 2. Check if user is an admin
  if (user.role === 'admin') {
    // They are an admin! Show the page and pass the context.
    return <Outlet context={context} />;
  }

  // 3. If they are logged in but not an admin,
  // send them to the home page.
  return <Navigate to="/" replace />;
}