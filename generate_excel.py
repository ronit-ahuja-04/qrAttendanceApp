import sqlite3
import pandas as pd

db_path = 'backend/database.sqlite'
output_path = 'emails.xlsx'

conn = sqlite3.connect(db_path)

# Query 3rd year students (Division starting with D15)
query_students = "SELECT name as Name, email as Email, role as Role, division as Division FROM users WHERE role='student' AND division LIKE 'D15%'"
df_students = pd.read_sql_query(query_students, conn)

# Query all faculty
query_faculty = "SELECT name as Name, email as Email, role as Role, division as Division FROM users WHERE role='faculty'"
df_faculty = pd.read_sql_query(query_faculty, conn)

conn.close()

# Combine both DataFrames
df_combined = pd.concat([df_students, df_faculty], ignore_index=True)

# Write to Excel
df_combined.to_excel(output_path, index=False, engine='openpyxl')

print(f"Successfully exported {len(df_students)} students and {len(df_faculty)} faculty members to {output_path}")
