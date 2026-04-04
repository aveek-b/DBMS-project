"""
Student Routes
"""

from flask import Blueprint, render_template, redirect, url_for, flash, request, jsonify
from flask_login import login_required, current_user
from datetime import datetime

from ..models.database import (
    get_student_by_user_id,
    get_student_dashboard_data,
    get_student_complaints,
    get_student_fines,
    get_student_leave_requests,
    get_student_housekeeping_requests,
    get_mess_menu,
    get_user_notifications,
    get_active_announcements,
    get_complaint_categories,
    get_room_occupants,
    get_compatibility_questions,
    get_student_compatibility_responses,
    get_best_roommate_matches,
    create_leave_request,
    execute_procedure,
    execute_dml,
    mark_notification_read
)

from ..utils.helpers import student_required, get_day_of_week
from ..utils.compatibility import calculate_detailed_compatibility, get_compatibility_category

student_bp = Blueprint('student', __name__)


@student_bp.route('/dashboard')
@login_required
@student_required
def dashboard():
    """Student dashboard."""
    student = get_student_by_user_id(current_user.user_id)

    if not student:
        flash('Student profile not found.', 'danger')
        return redirect(url_for('auth.logout'))

    dashboard_data = get_student_dashboard_data(student['student_id'])
    announcements = get_active_announcements('STUDENTS')
    notifications = get_user_notifications(current_user.user_id, limit=5)

    # Get today's menu
    today = get_day_of_week()
    todays_menu = get_mess_menu(day_of_week=today)

    return render_template(
        'student/dashboard.html',
        student=student,
        dashboard=dashboard_data,
        announcements=announcements,
        notifications=notifications,
        todays_menu=todays_menu
    )


@student_bp.route('/profile')
@login_required
@student_required
def profile():
    """Student profile page."""
    student = get_student_by_user_id(current_user.user_id)
    return render_template('student/profile.html', student=student)


@student_bp.route('/room')
@login_required
@student_required
def room_details():
    """Room details and roommate information."""
    student = get_student_by_user_id(current_user.user_id)
    roommates = []

    if student and student.get('room_id'):
        occupants = get_room_occupants(student['room_id'])
        roommates = [
            o for o in occupants
            if o['student_id'] != student['student_id']
        ]

    return render_template(
        'student/room_details.html',
        student=student,
        roommates=roommates
    )


@student_bp.route('/complaints')
@login_required
@student_required
def complaints():
    """View and manage complaints."""
    student = get_student_by_user_id(current_user.user_id)
    status_filter = request.args.get('status')

    complaints_list = get_student_complaints(
        student['student_id'],
        status_filter
    )

    categories = get_complaint_categories()

    return render_template(
        'student/complaints.html',
        complaints=complaints_list,
        categories=categories,
        current_status=status_filter
    )


@student_bp.route('/complaints/new', methods=['POST'])
@login_required
@student_required
def new_complaint():
    """Submit a new complaint."""
    student = get_student_by_user_id(current_user.user_id)

    category_id = request.form.get('category_id', type=int)
    subject = request.form.get('subject', '').strip()
    description = request.form.get('description', '').strip()
    priority = request.form.get('priority', 'MEDIUM')

    if not all([subject, description]):
        flash('Please fill in all required fields.', 'danger')
        return redirect(url_for('student.complaints'))

    try:
        result = execute_procedure('proc_register_complaint', [
            {'name': 'p_student_id', 'value': student['student_id']},
            {'name': 'p_category_id', 'value': category_id},
            {'name': 'p_subject', 'value': subject},
            {'name': 'p_description', 'value': description},
            {'name': 'p_priority', 'value': priority},
            {'name': 'p_complaint_id', 'direction': 'OUT', 'type': 'NUMBER'},
            {'name': 'p_complaint_num', 'direction': 'OUT', 'type': 'STRING'},
            {'name': 'p_result', 'direction': 'OUT', 'type': 'STRING'},
            {'name': 'p_message', 'direction': 'OUT', 'type': 'STRING'}
        ])

        if result.get('p_result') == 'SUCCESS':
            flash(
                f"Complaint {result.get('p_complaint_num')} registered successfully!",
                'success'
            )
        else:
            flash(
                result.get('p_message', 'Failed to register complaint.'),
                'danger'
            )

    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')

    return redirect(url_for('student.complaints'))


@student_bp.route('/fines')
@login_required
@student_required
def fines():
    """View fines and payments."""
    student = get_student_by_user_id(current_user.user_id)
    status_filter = request.args.get('status')

    fines_list = get_student_fines(
        student['student_id'],
        status_filter
    )

    return render_template(
        'student/fines.html',
        fines=fines_list,
        current_status=status_filter
    )

@student_bp.route('/leave-requests')
@login_required
@student_required

def leave_requests():
    student = get_student_by_user_id(current_user.user_id)

    if request.method == 'POST':
        leave_type = request.form.get('leave_type')
        from_date = request.form.get('from_date')
        to_date = request.form.get('to_date')
        reason = request.form.get('reason')

        if not all([leave_type, from_date, to_date, reason]):
            flash('All fields are required.', 'danger')
            return redirect(url_for('student.leave_requests'))

        try:
            create_leave_request(
                student['student_id'],
                leave_type,
                from_date,
                to_date,
                reason
            )
            flash('Leave request submitted successfully!', 'success')
        except Exception as e:
            flash(f'Error: {str(e)}', 'danger')

        return redirect(url_for('student.leave_requests'))

    status_filter = request.args.get('status')

    leave_list = get_student_leave_requests(
        student['student_id'],
        status_filter
    )

    return render_template(
        'student/leave_requests.html',
        leave_requests=leave_list,
        current_status=status_filter
    )

@student_bp.route('/mess-menu')
@login_required
@student_required
def mess_menu():
    day = request.args.get('day')
    menu = get_mess_menu(day_of_week=day)

    return render_template(
        'student/mess_menu.html',
        menu=menu,
        selected_day=day
    )

@student_bp.route('/compatibility-quiz', methods=['GET', 'POST'])
@login_required
@student_required
def compatibility_quiz():
    student = get_student_by_user_id(current_user.user_id)

    if request.method == 'POST':
        try:
            for key, value in request.form.items():
                if key.startswith('question_'):
                    question_id = int(key.split('_')[1])

                    execute_dml("""
                        MERGE INTO compatibility_responses cr
                        USING dual
                        ON (cr.student_id = :student_id AND cr.question_id = :question_id)
                        WHEN MATCHED THEN
                            UPDATE SET answer = :answer
                        WHEN NOT MATCHED THEN
                            INSERT (student_id, question_id, answer)
                            VALUES (:student_id, :question_id, :answer)
                    """, {
                        'student_id': student['student_id'],
                        'question_id': question_id,
                        'answer': value
                    })

            flash('Responses saved successfully!', 'success')
        except Exception as e:
            flash(f'Error: {str(e)}', 'danger')

        return redirect(url_for('student.compatibility_quiz'))

    questions = get_compatibility_questions()
    responses = get_student_compatibility_responses(student['student_id'])

    return render_template(
        'student/compatibility_quiz.html',
        questions=questions,
        responses=responses
    )

@student_bp.route('/roommate-matches')
@login_required
@student_required
def roommate_matches():
    student = get_student_by_user_id(current_user.user_id)

    matches = get_best_roommate_matches(student['student_id'])

    # Add compatibility details (optional enhancement)
    detailed_matches = []
    for m in matches:
        score = m.get('compatibility_score', 0)
        detailed_matches.append({
            **m,
            'category': get_compatibility_category(score)
        })

    return render_template(
        'student/roommate_matches.html',
        matches=detailed_matches
    )

@student_bp.route('/housekeeping')
@login_required
@student_required
def housekeeping():
    student = get_student_by_user_id(current_user.user_id)
    status_filter = request.args.get('status')

    requests_list = get_student_housekeeping_requests(
        student['student_id'],
        status_filter
    )

    return render_template(
        'student/housekeeping.html',
        requests=requests_list,
        current_status=status_filter
    )