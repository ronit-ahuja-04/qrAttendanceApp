import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { LogOut, Calendar, Clock, Users, Play, AlertCircle } from 'lucide-react';
import api from '../api';

const DashboardScreen = () => {
  const navigate = useNavigate();
  const [sessions, setSessions] = useState([]);
  const [loading, setLoading] = useState(true);
  const user = JSON.parse(localStorage.getItem('user') || '{}');

  useEffect(() => {
    const fetchTimetable = async () => {
      try {
        // According to API routes, faculty can fetch their sessions 
        // using /api/sessions/faculty/:facultyId (active) or generic fetching.
        // Assuming we fetch all sessions for today for this faculty
        const response = await api.get(`/sessions/faculty/${user.id}`);
        setSessions(response.data.sessions || []);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    if (user.id) fetchTimetable();
  }, [user.id]);

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/login');
  };

  const startSession = async (courseCode) => {
    try {
      const res = await api.post('/sessions', {
        courseCode,
        facultyId: user.id
      });
      navigate(`/session/${res.data.session.id}`);
    } catch (err) {
      alert("Failed to start session. Is one already active?");
    }
  };

  return (
    <div className="app-container animate-fade-in">
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '40px' }}>
        <div>
          <h1 style={{ fontSize: '28px', marginBottom: '4px' }}>Welcome back, Prof. {user.name?.split(' ')[0]}</h1>
          <p style={{ color: 'var(--text-secondary)' }}>Manage your classes and live attendance.</p>
        </div>
        <button onClick={handleLogout} className="btn-primary" style={{ background: 'transparent', border: '1px solid var(--border-glass)', boxShadow: 'none' }}>
          <LogOut size={18} style={{ display: 'inline', marginRight: '8px', verticalAlign: 'middle' }} />
          Logout
        </button>
      </header>

      <h2 style={{ fontSize: '20px', marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
        <Calendar color="var(--accent-primary)" /> Today's Schedule
      </h2>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>Loading timetable...</div>
      ) : sessions.length === 0 ? (
        <div className="glass-card" style={{ textAlign: 'center', padding: '40px' }}>
          <AlertCircle size={48} color="var(--text-muted)" style={{ margin: '0 auto 16px' }} />
          <h3 style={{ fontSize: '18px', color: 'var(--text-secondary)' }}>No active sessions found for today.</h3>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '20px' }}>
          {sessions.map((session) => (
            <div key={session.id} className="glass-card" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <h3 style={{ fontSize: '18px', marginBottom: '4px' }}>{session.course_code}</h3>
                  <p style={{ color: 'var(--text-muted)', fontSize: '14px', display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <Clock size={14} /> {new Date(session.start_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </p>
                </div>
                <div style={{ background: 'var(--success-bg)', color: 'var(--success)', padding: '4px 12px', borderRadius: '20px', fontSize: '12px', fontWeight: '600' }}>
                  {session.status.toUpperCase()}
                </div>
              </div>
              
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: 'var(--text-secondary)', fontSize: '14px' }}>
                <Users size={16} />
                <span>Attendance Active</span>
              </div>

              <button onClick={() => navigate(`/session/${session.id}`)} className="btn-primary" style={{ width: '100%', marginTop: 'auto', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px' }}>
                <Play size={16} /> View Live Session
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default DashboardScreen;
