const fs = require('fs');
const path = require('path');

const dir = './admin-portal/src/pages';
const files = {
  'Dashboard.jsx': `import React from 'react';
import { Users, Server, ShieldCheck, UserCheck } from 'lucide-react';

export default function Dashboard() {
  const stats = [
    { label: 'Total Students', value: '...', icon: Users, color: 'text-blue-400', bg: 'bg-blue-500/10' },
    { label: 'Total Faculty', value: '...', icon: UserCheck, color: 'text-indigo-400', bg: 'bg-indigo-500/10' },
    { label: 'System Lock', value: '...', icon: ShieldCheck, color: 'text-emerald-400', bg: 'bg-emerald-500/10' },
    { label: 'Database', value: 'Connected', icon: Server, color: 'text-purple-400', bg: 'bg-purple-500/10' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">System Overview</h1>
          <p className="text-slate-400">Welcome to the QR Attendance Admin Portal.</p>
        </div>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <div key={index} className="glass p-6 rounded-2xl flex items-center space-x-4">
            <div className={\`p-4 rounded-xl \${stat.bg}\`}>
              <stat.icon className={\`w-6 h-6 \${stat.color}\`} />
            </div>
            <div>
              <p className="text-sm font-medium text-slate-400 mb-1">{stat.label}</p>
              <h3 className="text-2xl font-bold text-white">{stat.value}</h3>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}`,

  'DeviceManager.jsx': `import React, { useState, useEffect } from 'react';
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
      const headers = { 'Authorization': \`Bearer \${user.token}\` };
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
        headers: { 'Content-Type': 'application/json', 'Authorization': \`Bearer \${user.token}\` },
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
        headers: { 'Content-Type': 'application/json', 'Authorization': \`Bearer \${user.token}\` },
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
          className={\`flex items-center space-x-2 px-6 py-3 rounded-xl font-medium transition-all \${
            locked 
              ? 'bg-red-500/20 text-red-400 hover:bg-red-500/30 border border-red-500/50' 
              : 'bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30 border border-emerald-500/50'
          }\`}
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
}`,

  'FacultyScopeManager.jsx': `import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { Plus, Trash2, Edit2, Check, X } from 'lucide-react';

export default function FacultyScopeManager() {
  const { user } = useAuth();
  const [scopes, setScopes] = useState([]);
  const [facultyList, setFacultyList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isAdding, setIsAdding] = useState(false);
  
  const [newScope, setNewScope] = useState({ facultyId: '', subject: '', batchTarget: '', type: 'Lecture' });

  const fetchScopes = async () => {
    try {
      const headers = { 'Authorization': \`Bearer \${user.token}\` };
      const [facRes, scopeRes] = await Promise.all([
        fetch('https://qr-attendance-api-wvvs.onrender.com/api/admin/faculty', { headers }),
        fetch('https://qr-attendance-api-wvvs.onrender.com/api/admin/scopes', { headers })
      ]);
      setFacultyList(await facRes.json());
      setScopes(await scopeRes.json());
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchScopes();
  }, []);

  const addScope = async () => {
    if (!newScope.facultyId || !newScope.subject) return;
    try {
      const res = await fetch('https://qr-attendance-api-wvvs.onrender.com/api/admin/scopes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': \`Bearer \${user.token}\` },
        body: JSON.stringify(newScope)
      });
      if (res.ok) {
        setIsAdding(false);
        setNewScope({ facultyId: '', subject: '', batchTarget: '', type: 'Lecture' });
        fetchScopes();
      }
    } catch (err) {
      console.error(err);
    }
  };

  const deleteScope = async (id) => {
    try {
      const res = await fetch(\`https://qr-attendance-api-wvvs.onrender.com/api/admin/scopes/\${id}\`, {
        method: 'DELETE',
        headers: { 'Authorization': \`Bearer \${user.token}\` }
      });
      if (res.ok) fetchScopes();
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">Faculty Scopes</h1>
          <p className="text-slate-400">Dynamically assign subjects and batches to faculty.</p>
        </div>
        <button
          onClick={() => setIsAdding(true)}
          className="flex items-center space-x-2 bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2.5 rounded-xl font-medium transition-colors"
        >
          <Plus className="w-5 h-5" />
          <span>Add Scope</span>
        </button>
      </div>

      <div className="glass rounded-2xl overflow-hidden">
        <table className="w-full text-left">
          <thead>
            <tr className="bg-slate-900/50">
              <th className="px-6 py-4 font-medium text-slate-400 text-sm">Faculty Name</th>
              <th className="px-6 py-4 font-medium text-slate-400 text-sm">Subject</th>
              <th className="px-6 py-4 font-medium text-slate-400 text-sm">Target (Batch/Class)</th>
              <th className="px-6 py-4 font-medium text-slate-400 text-sm">Type</th>
              <th className="px-6 py-4 font-medium text-slate-400 text-sm text-right">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/50">
            {isAdding && (
              <tr className="bg-indigo-500/5 border-l-2 border-indigo-500">
                <td className="px-6 py-3">
                  <select 
                    value={newScope.facultyId} 
                    onChange={e => setNewScope({...newScope, facultyId: e.target.value})}
                    className="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-3 py-1.5 text-white"
                  >
                    <option value="">Select Faculty...</option>
                    {facultyList.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
                  </select>
                </td>
                <td className="px-6 py-3">
                  <input type="text" placeholder="e.g. DAA" value={newScope.subject} onChange={e => setNewScope({...newScope, subject: e.target.value})} className="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-3 py-1.5 text-white" />
                </td>
                <td className="px-6 py-3">
                  <input type="text" placeholder="e.g. Batch A" value={newScope.batchTarget} onChange={e => setNewScope({...newScope, batchTarget: e.target.value})} className="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-3 py-1.5 text-white" />
                </td>
                <td className="px-6 py-3">
                  <select value={newScope.type} onChange={e => setNewScope({...newScope, type: e.target.value})} className="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-3 py-1.5 text-white">
                    <option value="Lecture">Lecture</option>
                    <option value="Practical">Practical</option>
                  </select>
                </td>
                <td className="px-6 py-3 text-right">
                  <div className="flex justify-end space-x-2">
                    <button onClick={addScope} className="p-1.5 text-emerald-400 hover:bg-emerald-400/10 rounded-lg"><Check className="w-5 h-5" /></button>
                    <button onClick={() => setIsAdding(false)} className="p-1.5 text-slate-400 hover:bg-slate-800 rounded-lg"><X className="w-5 h-5" /></button>
                  </div>
                </td>
              </tr>
            )}
            
            {loading ? (
              <tr><td colSpan="5" className="px-6 py-8 text-center text-slate-400">Loading...</td></tr>
            ) : scopes.map(s => {
              const faculty = facultyList.find(f => f.id === s.facultyId);
              return (
                <tr key={s.id} className="hover:bg-slate-800/20 transition-colors">
                  <td className="px-6 py-4 text-white font-medium">{faculty ? faculty.name : s.facultyId}</td>
                  <td className="px-6 py-4 text-white">{s.subject}</td>
                  <td className="px-6 py-4 text-slate-300">{s.batchTarget || 'Entire Class'}</td>
                  <td className="px-6 py-4">
                    <span className={\`inline-flex items-center px-2.5 py-1 rounded-md text-xs font-medium border \${
                      s.type === 'Lecture' ? 'bg-blue-500/10 text-blue-400 border-blue-500/20' : 'bg-orange-500/10 text-orange-400 border-orange-500/20'
                    }\`}>
                      {s.type}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button onClick={() => deleteScope(s.id)} className="p-2 text-slate-400 hover:text-red-400 hover:bg-red-400/10 rounded-lg transition-colors">
                      <Trash2 className="w-5 h-5" />
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}`
};

for (const [file, content] of Object.entries(files)) {
  fs.writeFileSync(path.join(dir, file), content);
}
console.log('Pages created');
