import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';

const Dashboard = () => <div className="p-8"><h1 className="text-2xl font-bold">DFC Control Tower</h1><p className="text-gray-400 mt-2">Welcome to the cockpit.</p></div>;

const Fighters = () => {
  const [fighters, setFighters] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Pointing to your local Firebase Emulator Express API
    fetch('http://127.0.0.1:5001/datafightcentral/us-central1/adminApi/fighters')
      .then((res) => res.json())
      .then((data) => {
        setFighters(data);
        setLoading(false);
      })
      .catch((err) => {
        console.error("Error fetching fighters:", err);
        setLoading(false);
      });
  }, []);

  return (
    <div className="p-8">
      <h2 className="text-xl font-bold mb-6">Fighters Management</h2>
      {loading ? (
        <p className="text-gray-400">Loading fighters...</p>
      ) : (
        <div className="overflow-hidden rounded-lg bg-gray-800 shadow">
          <table className="min-w-full text-left text-sm text-gray-300">
            <thead className="bg-gray-700 text-gray-100">
              <tr>
                <th className="p-4">Name</th>
                <th className="p-4">Weight Class</th>
                <th className="p-4">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-700">
              {fighters.map((f) => (
                <tr key={f.id} className="hover:bg-gray-700/50 transition-colors">
                  <td className="p-4 font-medium text-white">{f.first_name} {f.last_name}</td>
                  <td className="p-4 text-pink-400">{f.weight_class}</td>
                  <td className="p-4">
                    <span className={`px-2 py-1 rounded text-xs font-bold ${f.status === 'active' ? 'bg-green-900 text-green-300' : 'bg-red-900 text-red-300'}`}>
                      {(f.status || 'ACTIVE').toUpperCase()}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

const Events = () => {
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('http://127.0.0.1:5001/datafightcentral/us-central1/adminApi/events')
      .then((res) => res.json())
      .then((data) => {
        setEvents(data);
        setLoading(false);
      })
      .catch((err) => {
        console.error("Error fetching events:", err);
        setLoading(false);
      });
  }, []);

  return (
    <div className="p-8">
      <h2 className="text-xl font-bold mb-6">Events & PPV Management</h2>
      {loading ? (
        <p className="text-gray-400">Loading events...</p>
      ) : (
        <div className="overflow-hidden rounded-lg bg-gray-800 shadow">
          <table className="min-w-full text-left text-sm text-gray-300">
            <thead className="bg-gray-700 text-gray-100">
              <tr>
                <th className="p-4">Event Name</th>
                <th className="p-4">Venue & City</th>
                <th className="p-4">Date</th>
                <th className="p-4">PPV Price</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-700">
              {events.map((e) => (
                <tr key={e.id} className="hover:bg-gray-700/50 transition-colors">
                  <td className="p-4 font-medium text-white">{e.name}</td>
                  <td className="p-4 text-gray-400">{e.venue}, {e.city}</td>
                  <td className="p-4 text-cyan-400">{new Date(e.start_time).toLocaleDateString()}</td>
                  <td className="p-4 text-pink-400">${(e.ppv_price_cents / 100).toFixed(2)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

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