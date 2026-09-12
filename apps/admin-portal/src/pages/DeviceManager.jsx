import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { Search, ShieldAlert, ShieldCheck, Smartphone, Trash2 } from 'lucide-react';

export default function DeviceManager() {
  const { user } = useAuth();
  const [locked, setLocked] = useState(false);
  const [students, setStudents] = useState([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  const fetchState = async () => {
    try {
      const headers = { 'Authorization': `Bearer ${user.token}` };
      const [lockRes, studentsRes] = await Promise.all([
        fetch('https://qr-attendance-api-wvvs.onrender.com/api/admin/device-lock', { headers }),
        fetch('https://qr-attendance-api-wvvs.onrender.com/api/admin/students', { headers })
      ]);
      const lockData = await lockRes.json();
      const studentsData = await studentsRes.json();
      setLocked(lockData.locked);
      setStudents(studentsData);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchState();
  }, []);

  const toggleLock = async () => {
    try {
      const res = await fetch('https://qr-attendance-api-wvvs.onrender.com/api/admin/device-lock', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${user.token}` },
        body: JSON.stringify({ locked: !locked })
      });
      if (res.ok) setLocked(!locked);
    } catch (err) {
      console.error(err);
    }
  };

  const unbindStudent = async (studentId) => {
    if (!confirm('Are you sure you want to unbind this device? The student will be logged out instantly.')) return;
    try {
      const res = await fetch('https://qr-attendance-api-wvvs.onrender.com/api/admin/unbind-student', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${user.token}` },
        body: JSON.stringify({ studentId })
      });
      if (res.ok) fetchState();
    } catch (err) {
      console.error(err);
    }
  };

  const filtered = students.filter(s => 
    s.name.toLowerCase().includes(search.toLowerCase()) || 
    s.rollNo.includes(search)
  );

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">Device Security</h1>
          <p className="text-slate-400">Manage global locks and student device bindings.</p>
        </div>
        <button
          onClick={toggleLock}
          className={`flex items-center space-x-2 px-6 py-3 rounded-xl font-medium transition-all ${
            locked 
              ? 'bg-red-500/20 text-red-400 hover:bg-red-500/30 border border-red-500/50' 
              : 'bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30 border border-emerald-500/50'
          }`}
        >
          {locked ? <ShieldAlert className="w-5 h-5" /> : <ShieldCheck className="w-5 h-5" />}
          <span>{locked ? 'Global Lock ON' : 'Global Lock OFF'}</span>
        </button>
      </div>

      <div className="glass rounded-2xl overflow-hidden">
        <div className="p-6 border-b border-slate-800 flex items-center space-x-4">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-500" />
            <input
              type="text"
              placeholder="Search by name or roll number..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full bg-slate-900/50 border border-slate-700 rounded-lg pl-10 pr-4 py-2 text-white focus:outline-none focus:border-indigo-500"
            />
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-900/50">
                <th className="px-6 py-4 font-medium text-slate-400 text-sm">Roll No</th>
                <th className="px-6 py-4 font-medium text-slate-400 text-sm">Name</th>
                <th className="px-6 py-4 font-medium text-slate-400 text-sm">Email</th>
                <th className="px-6 py-4 font-medium text-slate-400 text-sm">Device Status</th>
                <th className="px-6 py-4 font-medium text-slate-400 text-sm text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/50">
              {loading ? (
                <tr><td colSpan="5" className="px-6 py-8 text-center text-slate-400">Loading...</td></tr>
              ) : filtered.map(s => (
                <tr key={s.id} className="hover:bg-slate-800/20 transition-colors">
                  <td className="px-6 py-4 text-white font-medium">{s.rollNo}</td>
                  <td className="px-6 py-4 text-white">{s.name}</td>
                  <td className="px-6 py-4 text-slate-400">{s.email}</td>
                  <td className="px-6 py-4">
                    {s.deviceId ? (
                      <span className="inline-flex items-center space-x-1.5 px-2.5 py-1 rounded-md bg-indigo-500/10 text-indigo-400 text-xs font-medium border border-indigo-500/20">
                        <Smartphone className="w-3.5 h-3.5" />
                        <span>Bound</span>
                      </span>
                    ) : (
                      <span className="inline-flex items-center space-x-1.5 px-2.5 py-1 rounded-md bg-slate-800 text-slate-400 text-xs font-medium border border-slate-700">
                        <span>Unbound</span>
                      </span>
                    )}
                  </td>
                  <td className="px-6 py-4 text-right">
                    {s.deviceId && (
                      <button
                        onClick={() => unbindStudent(s.id)}
                        className="p-2 text-slate-400 hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-colors"
                        title="Unbind Device"
                      >
                        <Trash2 className="w-5 h-5" />
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}