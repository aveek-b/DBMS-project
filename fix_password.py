from app import create_app
from app.models.database import get_db_connection

app = create_app()

with app.app_context():
    from werkzeug.security import generate_password_hash
    conn = get_db_connection()
    cursor = conn.cursor()
    
    real_hash = generate_password_hash('password123')
    
    cursor.execute("""
        UPDATE users SET password_hash = :hash
        WHERE username IN (
            'admin', 'warden_a', 'warden_b', 'warden_c', 'warden_d',
            'student001', 'student002', 'student003', 'student004',
            'student005', 'student006', 'student007', 'student008',
            'student009', 'student010'
        )
    """, {'hash': real_hash})
    
    conn.commit()
    print(f"Updated {cursor.rowcount} users")
    cursor.close()