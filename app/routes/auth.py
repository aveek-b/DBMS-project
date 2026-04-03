"""
Authentication Routes
"""

from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_user, logout_user, login_required, current_user

from ..models.database import (
    verify_user,
    create_user,
    create_student_profile,
    get_user_by_username,
    get_user_by_email,
    update_last_login
)

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/')
def index():
    """Landing page - redirect to appropriate dashboard."""
    if current_user.is_authenticated:
        if current_user.is_admin():
            return redirect(url_for('admin.dashboard'))
        elif current_user.is_warden():
            return redirect(url_for('warden.dashboard'))
        else:
            return redirect(url_for('student.dashboard'))
    return redirect(url_for('auth.login'))


@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    """User login page."""
    if current_user.is_authenticated:
        return redirect(url_for('auth.index'))

    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '')
        remember = request.form.get('remember') == 'on'

        if not username or not password:
            flash('Please enter both username and password.', 'danger')
            return render_template('auth/login.html')

        user = verify_user(username, password)

        if user:
            login_user(user, remember=remember)
            update_last_login(user.user_id)

            flash(f'Welcome back, {user.first_name}!', 'success')

            next_page = request.args.get('next')
            if next_page:
                return redirect(next_page)

            if user.is_admin():
                return redirect(url_for('admin.dashboard'))
            elif user.is_warden():
                return redirect(url_for('warden.dashboard'))
            else:
                return redirect(url_for('student.dashboard'))
        else:
            flash('Invalid username or password.', 'danger')

    return render_template('auth/login.html')


@auth_bp.route('/register', methods=['GET', 'POST'])
def register():
    """Student registration page."""
    if current_user.is_authenticated:
        return redirect(url_for('auth.index'))

    if request.method == 'POST':
        # Get form data
        username = request.form.get('username', '').strip()
        email = request.form.get('email', '').strip()
        password = request.form.get('password', '')
        confirm_password = request.form.get('confirm_password', '')
        first_name = request.form.get('first_name', '').strip()
        last_name = request.form.get('last_name', '').strip()
        phone = request.form.get('phone', '').strip()

        # Student-specific fields
        roll_number = request.form.get('roll_number', '').strip()
        registration_number = request.form.get('registration_number', '').strip()
        course = request.form.get('course', '').strip()
        branch = request.form.get('branch', '').strip()
        year_of_study = request.form.get('year_of_study', type=int)
        semester = request.form.get('semester', type=int)
        batch_year = request.form.get('batch_year', type=int)
        date_of_birth = request.form.get('date_of_birth')
        gender = request.form.get('gender')
        blood_group = request.form.get('blood_group')
        permanent_address = request.form.get('permanent_address')
        city = request.form.get('city')
        state = request.form.get('state')
        pincode = request.form.get('pincode')
        parent_name = request.form.get('parent_name')
        parent_phone = request.form.get('parent_phone')

        # Validation
        errors = []

        if not all([
            username, email, password, first_name,
            roll_number, course, branch, year_of_study, gender
        ]):
            errors.append('Please fill in all required fields.')

        if password != confirm_password:
            errors.append('Passwords do not match.')

        if len(password) < 8:
            errors.append('Password must be at least 8 characters long.')

        if get_user_by_username(username):
            errors.append('Username already exists.')

        if get_user_by_email(email):
            errors.append('Email already registered.')

        if errors:
            for error in errors:
                flash(error, 'danger')
            return render_template('auth/register.html')

        try:
            # Create user account
            user_id = create_user(
                username=username,
                email=email,
                password=password,
                role='STUDENT',
                first_name=first_name,
                last_name=last_name,
                phone_number=phone
            )

            # Create student profile
            from datetime import datetime
            dob = (
                datetime.strptime(date_of_birth, '%Y-%m-%d').date()
                if date_of_birth else None
            )

            create_student_profile(
                user_id=user_id,
                roll_number=roll_number,
                registration_number=registration_number,
                course=course,
                branch=branch,
                year_of_study=year_of_study,
                semester=semester,
                batch_year=batch_year,
                date_of_birth=dob,
                gender=gender,
                blood_group=blood_group,
                permanent_address=permanent_address,
                city=city,
                state=state,
                pincode=pincode,
                parent_name=parent_name,
                parent_phone=parent_phone
            )

            flash('Registration successful! Please log in.', 'success')
            return redirect(url_for('auth.login'))

        except Exception as e:
            flash(f'Registration failed: {str(e)}', 'danger')

    return render_template('auth/register.html')


@auth_bp.route('/logout')
@login_required
def logout():
    """User logout."""
    logout_user()
    flash('You have been logged out.', 'info')
    return redirect(url_for('auth.login'))


@auth_bp.route('/forgot-password', methods=['GET', 'POST'])
def forgot_password():
    """Forgot password page."""
    if request.method == 'POST':
        email = request.form.get('email', '').strip()

        if not email:
            flash('Please enter your email address.', 'danger')
        else:
            user = get_user_by_email(email)

            if user:
                # In production, send password reset email
                flash('Password reset instructions have been sent to your email.', 'success')
            else:
                flash('No account found with that email address.', 'danger')

    return render_template('auth/forgot_password.html')