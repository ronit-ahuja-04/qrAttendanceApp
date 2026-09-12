import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { Calendar, Trash2, Plus, Clock, MapPin, Users, Check, X } from 'lucide-react';

export default function TimetableManager() {
  const { user } = useAuth();
  const [slots, setSlots] = useState([]);
  const [facultyList, setFacultyList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isAdding, setIsAdding] = useState(false);
  
  const [newSlot, setNewSlot] = useState({ 
    facultyId: '', 
    day: 'Monday', 
    subject: '', 
    type: 'Lecture', 
    batchTarget: 'All',
    venue: 'Room',
    startTime: '08:00',
    endTime: '09:00'
  });

  const fetchTimetable = async () => {
    try {
      const headers = { 'Authorization': `Bearer ${user.token}` };
      const [facRes, timetableRes] = await Promise.all([
        fetch('https://qr-attendance-api-wvvs.onrender.com/api/admin/faculty', { headers }),
        fetch('https://qr-attendance-api-wvvs.onrender.com/api/admin/timetable', { headers })
      ]);
      setFacultyList(await facRes.json());
      setSlots(await timetableRes.json());
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTimetable();
  }, []);

  const addSlot = async () => {
    if (!newSlot.facultyId || !newSlot.subject || !newSlot.startTime || !newSlot.endTime) return;
    try {
      const res = await fetch('https://qr-attendance-api-wvvs.onrender.com/api/admin/timetable', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${user.token}` },
        body: JSON.stringify(newSlot)
      });
      if (res.ok) {
        setIsAdding(false);
        setNewSlot({ facultyId: '', day: 'Monday', subject: '', type: 'Lecture', batchTarget: 'All', venue: 'Room', startTime: '08:00', endTime: '09:00' });
        fetchTimetable();
      }
    } catch (err) {
      console.error(err);
    }
  };

  const deleteSlot = async (id) => {
    if (!confirm('Are you sure you want to delete this timetable slot?')) return;
    try {
      const res = await fetch(`https://qr-attendance-api-wvvs.onrender.com/api/admin/timetable/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${user.token}` }
      });
      if (res.ok) fetchTimetable();
    } catch (err) {
      console.error(err);
    }
  };

  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">Timetable Management</h1>
          <p className="text-slate-400">Schedule classes, practicals, and assign venues.</p>
        </div>
        <button
          onClick={() => setIsAdding(true)}
          className="flex items-center space-x-2 px-6 py-3 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl font-medium transition-colors"
        >
          <Plus className="w-5 h-5" />
          <span>Add Slot</span>
        </button>
      </div>

      {isAdding && (
        <div className="glass p-6 rounded-2xl border border-indigo-500/30 shadow-[0_0_30px_rgba(79,70,229,0.1)]">
          <h2 className="text-xl font-semibold text-white mb-6">New Timetable Slot</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Faculty</label>
              <select
                value={newSlot.facultyId}
                onChange={(e) => setNewSlot({...newSlot, facultyId: e.target.value})}
                className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-indigo-500"
              >
                <option value="">Select Faculty...</option>
                {facultyList.map(f => (
                  <option key={f.id} value={f.id}>{f.name}</option>
                ))}
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Day</label>
              <select
                value={newSlot.day}
                onChange={(e) => setNewSlot({...newSlot, day: e.target.value})}
                className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-indigo-500"
              >
                {days.map(d => (
                  <option key={d} value={d}>{d}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Subject</label>
              <input
                type="text"
                placeholder="e.g. Data Structures"
                value={newSlot.subject}
                onChange={(e) => setNewSlot({...newSlot, subject: e.target.value})}
                className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-indigo-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Type</label>
              <select
                value={newSlot.type}
                onChange={(e) => setNewSlot({...newSlot, type: e.target.value})}
                className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-indigo-500"
              >
                <option value="Lecture">Lecture</option>
                <option value="Prac">Practical</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Start Time</label>
              <input
                type="time"
                value={newSlot.startTime}
                onChange={(e) => setNewSlot({...newSlot, startTime: e.target.value})}
                className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-indigo-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">End Time</label>
              <input
                type="time"
                value={newSlot.endTime}
                onChange={(e) => setNewSlot({...newSlot, endTime: e.target.value})}
                className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-indigo-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Venue</label>
              <input
                type="text"
                placeholder="e.g. Room 502"
                value={newSlot.venue}
                onChange={(e) => setNewSlot({...newSlot, venue: e.target.value})}
                className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-indigo-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Batch/Class Target</label>
              <input
                type="text"
                placeholder="e.g. D15A-All or B1"
                value={newSlot.batchTarget}
                onChange={(e) => setNewSlot({...newSlot, batchTarget: e.target.value})}
                className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-indigo-500"
              />
            </div>
          </div>

          <div className="flex items-center space-x-4">
            <button
              onClick={addSlot}
              disabled={!newSlot.facultyId || !newSlot.subject}
              className="flex items-center space-x-2 px-6 py-3 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white rounded-xl font-medium transition-colors"
            >
              <Check className="w-5 h-5" />
              <span>Save Slot</span>
            </button>
            <button
              onClick={() => setIsAdding(false)}
              className="flex items-center space-x-2 px-6 py-3 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl font-medium transition-colors"
            >
              <X className="w-5 h-5" />
              <span>Cancel</span>
            </button>
          </div>
        </div>
      )}

      <div className="grid gap-6">
        {days.map(day => {
          const daySlots = slots.filter(s => s.day === day).sort((a, b) => a.startTime.localeCompare(b.startTime));
          if (daySlots.length === 0) return null;
          
          return (
            <div key={day} className="glass rounded-2xl overflow-hidden">
              <div className="px-6 py-4 bg-slate-900/50 border-b border-slate-800">
                <h3 className="text-lg font-semibold text-white flex items-center space-x-2">
                  <Calendar className="w-5 h-5 text-indigo-400" />
                  <span>{day}</span>
                </h3>
              </div>
              <div className="divide-y divide-slate-800/50">
                {daySlots.map(slot => (
                  <div key={slot.id} className="p-6 flex items-center justify-between hover:bg-slate-800/20 transition-colors">
                    <div className="flex-1 grid grid-cols-1 md:grid-cols-4 gap-4">
                      <div>
                        <p className="text-sm text-slate-400 mb-1">Time</p>
                        <div className="flex items-center space-x-2 text-white font-medium">
                          <Clock className="w-4 h-4 text-indigo-400" />
                          <span>{slot.startTime} - {slot.endTime}</span>
                        </div>
                      </div>
                      <div>
                        <p className="text-sm text-slate-400 mb-1">Subject</p>
                        <p className="text-white font-medium">{slot.subject}</p>
                        <span className="inline-block mt-1 px-2 py-0.5 rounded text-xs font-medium bg-slate-800 text-slate-300">
                          {slot.type}
                        </span>
                      </div>
                      <div>
                        <p className="text-sm text-slate-400 mb-1">Faculty</p>
                        <p className="text-white font-medium">{slot.facultyName}</p>
                      </div>
                      <div>
                        <p className="text-sm text-slate-400 mb-1">Details</p>
                        <div className="flex items-center space-x-4 text-sm text-slate-300">
                          <span className="flex items-center space-x-1">
                            <MapPin className="w-4 h-4 text-emerald-400" />
                            <span>{slot.venue}</span>
                          </span>
                          <span className="flex items-center space-x-1">
                            <Users className="w-4 h-4 text-amber-400" />
                            <span>{slot.batchTarget}</span>
                          </span>
                        </div>
                      </div>
                    </div>
                    <button
                      onClick={() => deleteSlot(slot.id)}
                      className="p-3 text-slate-400 hover:text-red-400 hover:bg-red-400/10 rounded-xl transition-colors ml-4"
                      title="Delete Slot"
                    >
                      <Trash2 className="w-5 h-5" />
                    </button>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
        {!loading && slots.length === 0 && (
          <div className="text-center py-12 text-slate-400">
            No timetable slots scheduled yet.
          </div>
        )}
      </div>
    </div>
  );
}
