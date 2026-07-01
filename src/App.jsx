import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import Dashboard from './pages/Dashboard';
import BlueprintPack from './components/dev/BlueprintPack';

function App() {
  return (
    <Router>
      <div className="app-container relative min-h-screen">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/login" element={<LoginPage />} />
          {/* Add other routes here */}
        </Routes>

        {/*
          Nuked the fixed global rendering in production.
          This dev-block will now only render in local environments,
          preventing the spatial collision over the login button.
        */}
        {process.env.NODE_ENV === 'development' && <BlueprintPack />}
      </div>
    </Router>
  );
}

export default App;
