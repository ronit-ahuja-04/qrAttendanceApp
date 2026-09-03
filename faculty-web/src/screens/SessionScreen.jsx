import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { QRCodeSVG } from 'qrcode.react';
import { ArrowLeft, Users, CheckCircle2, ShieldCheck } from 'lucide-react';
import api from '../api';

const SessionScreen = () => {
  const { sessionId } = useParams();
  const navigate = useNavigate();
  const [sessionData, setSessionData] = useState(null);
  const [attendance, setAttendance] = useState([]);
  const [loading, setLoading] = useState(true);

  // Poll for attendance updates every 3 seconds
  useEffect(() => {
    const fetchSession = async () => {
      try {
        const res = await api.get(`/sessions/${sessionId}/attendance/details`);
        setAttendance(res.data.attendance || []);
      } catch (err) {
        console.error(err);
      }
    };

    const fetchVerification = async () => {
      try {
        const res = await api.get(`/sessions/${sessionId}/verification`);
        setSessionData(res.data);
        setLoading(false);
      } catch (err) {
        console.error(err);
      }
    };

    fetchVerification();
    fetchSession();
    
    const interval = setInterval(() => {
      fetchSession();
      // Also occasionally refresh verification token if it rotates
      fetchVerification();
    }, 3000);

    return () => clearInterval(interval);
  }, [sessionId]);

  if (loading || !sessionData) {
    return <div className="app-container" style={{ textAlign: 'center', marginTop: '100px' }}>Loading Session Data...</div>;
  }

  // The dynamic QR code data payload as defined by the backend
  const qrData = JSON.stringify({
    sessionId: sessionData.sessionId,
    courseCode: sessionData.courseCode,
    verificationToken: sessionData.verificationToken,
    timestamp: Date.now()
  });

  return (
    <div className="app-container animate-fade-in" style={{ display: 'flex', flexDirection: 'column', height: '100vh', padding: '24px' }}>
      <header style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '40px' }}>
        <button onClick={() => navigate('/dashboard')} style={{ background: 'transparent', border: 'none', color: 'var(--text-primary)', cursor: 'pointer', display: 'flex', alignItems: 'center' }}>
          <ArrowLeft size={24} />
        </button>
        <div>
          <h1 style={{ fontSize: '24px' }}>{sessionData.courseCode}</h1>
          <p style={{ color: 'var(--success)', display: 'flex', alignItems: 'center', gap: '4px', fontSize: '14px', fontWeight: '500' }}>
            <ShieldCheck size={16} /> Live & Secure
          </p>
        </div>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '40px', flex: 1 }}>
        {/* Left Side: Massive QR Code for Projector */}
        <div className="glass-card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '24px' }}>
          <div style={{ background: 'white', padding: '24px', borderRadius: '16px', boxShadow: '0 20px 40px rgba(0,0,0,0.3)' }}>
            <QRCodeSVG 
              value={qrData} 
              size={340} 
              level="H"
              includeMargin={true}
            />
          </div>
          <p style={{ color: 'var(--text-muted)', fontSize: '16px', textAlign: 'center' }}>
            Ask students to scan this QR code using the official app.<br />
            This code regenerates dynamically to prevent proxy attendance.
          </p>
        </div>

        {/* Right Side: Live Attendance Feed */}
        <div className="glass-card" style={{ display: 'flex', flexDirection: 'column' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border-glass)', paddingBottom: '16px', marginBottom: '16px' }}>
            <h2 style={{ fontSize: '20px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Users color="var(--accent-primary)" /> Live Attendance Feed
            </h2>
            <div style={{ background: 'var(--accent-glow)', padding: '4px 12px', borderRadius: '20px', fontSize: '14px', fontWeight: '600' }}>
              {attendance.length} Present
            </div>
          </div>

          <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {attendance.length === 0 ? (
              <div style={{ textAlign: 'center', color: 'var(--text-muted)', marginTop: '40px' }}>Waiting for scans...</div>
            ) : (
              attendance.map((record, index) => (
                <div key={record.id || index} className="animate-fade-in" style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', background: 'rgba(0,0,0,0.2)', borderRadius: '8px', borderLeft: '3px solid var(--success)' }}>
                  <CheckCircle2 color="var(--success)" size={20} />
                  <div>
                    <div style={{ fontWeight: '500' }}>{record.student_name || 'Student Joined'}</div>
                    <div style={{ color: 'var(--text-muted)', fontSize: '12px' }}>{new Date(record.timestamp).toLocaleTimeString()}</div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default SessionScreen;
