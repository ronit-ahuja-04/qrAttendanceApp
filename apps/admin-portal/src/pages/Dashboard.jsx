import React from 'react';
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
            <div className={`p-4 rounded-xl ${stat.bg}`}>
              <stat.icon className={`w-6 h-6 ${stat.color}`} />
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
}