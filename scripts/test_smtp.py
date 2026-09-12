import smtplib
from email.message import EmailMessage
import os

try:
    with open('backend/.env', 'r') as f:
        for line in f:
            if line.startswith('MAIL_USER='):
                user = line.strip().split('=')[1]
            elif line.startswith('MAIL_PASS='):
                password = line.strip().split('=')[1]
                
    msg = EmailMessage()
    msg.set_content('Test email from python')
    msg['Subject'] = 'Test'
    msg['From'] = user
    msg['To'] = user

    server = smtplib.SMTP('smtp.gmail.com', 587)
    server.starttls()
    server.login(user, password)
    server.send_message(msg)
    server.quit()
    print("SUCCESS: SMTP login worked and email sent!")
except Exception as e:
    print(f"FAILED: {e}")
