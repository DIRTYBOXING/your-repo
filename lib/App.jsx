import React from 'react';
import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';

const Dashboard = () => <div className="p-8"><h1 className="text-2xl font-bold">DFC Control Tower</h1><p className="text-gray-400 mt-2">Welcome to the cockpit.</p></div>;
const Fighters = () => <div className="p-8"><h2 className="text-xl font-bold">Fighters Management</h2><p className="text-gray-400 mt-2">API integration pending...</p></div>;
const Events = () => <div className="p-8"><h2 className="text-xl font-bold">Events & PPV Management</h2><p className="text-gray-400 mt-2">API integration pending...</p></div>;

export default function App() {
  return (
    <BrowserRouter>
      <div className="flex h-screen bg-gray-900 text-white">
        <nav className="w-64 bg-gray-800 p-6 space-y-6 shadow-xl">
          <h2 className="text-2xl font-black text-pink-500 tracking-widest mb-8">DFC ADMIN</h2>
          <Link to="/" className="block text-gray-300 hover:text-cyan-400 font-semibold transition-colors">Dashboard</Link>
          <Link to="/fighters" className="block text-gray-300 hover:text-cyan-400 font-semibold transition-colors">Fighters</Link>
          <Link to="/events" className="block text-gray-300 hover:text-cyan-400 font-semibold transition-colors">Events & PPV</Link>
        </nav>
        <main className="flex-1 overflow-y-auto">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/fighters" element={<Fighters />} />
            <Route path="/events" element={<Events />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}