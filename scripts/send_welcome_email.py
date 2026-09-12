import smtplib
from email.message import EmailMessage
import os

def send_welcome_email():
    user = None
    password = None
    
    try:
        with open('services/backend/.env', 'r') as f:
            for line in f:
                if line.startswith('MAIL_USER='):
                    user = line.strip().split('=', 1)[1]
                elif line.startswith('MAIL_PASS='):
                    password = line.strip().split('=', 1)[1]
    except FileNotFoundError:
        print("Error: services/backend/.env file not found")
        return

    if not user or not password:
        print("Error: SMTP credentials not found in services/backend/.env")
        return

    recipient = "2024.ronit.ahuja@ves.ac.in"
    
    msg = EmailMessage()
    msg.set_content(f"Hi Ronit,\n\nWelcome to the Magic Attendance System! We're thrilled to have you onboard.\n\nBest regards,\nThe AMS Team")
    msg['Subject'] = 'Welcome to Magic Attendance System!'
    msg['From'] = user
    msg['To'] = recipient

    try:
        print(f"Connecting to SMTP server to send email to {recipient}...")
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(user, password)
        server.send_message(msg)
        server.quit()
        print("SUCCESS: Welcome email sent successfully to Ronit Ahuja!")
    except Exception as e:
        print(f"FAILED to send email: {e}")

if __name__ == "__main__":
    send_welcome_email()
