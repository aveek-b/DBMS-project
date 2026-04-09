"""Warden Routes"""

from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_required, current_user

from ..models.database import (
    get_warden_by_user_id,
    get_warden_dashboard_data,
    get_block_students,
    get_block_complaints,
    get_block_leave_requests,
    get_block_housekeeping_requests,
    get_all_rooms,
    execute_procedure,
    execute_query,
    get_complaint_statistics
)

from ..utils.helpers import warden_required

warden_bp = Blueprint('warden', __name__)


@warden_bp.route('/dashboard')
@login_required
@warden_required
def dashboard():
    """Warden dashboard."""
    warden = get_warden_by_user_id(current_user.user_id)

    dashboard_data = get_warden_dashboard_data(warden['warden_id'])

    recent_complaints = get_block_complaints(
        warden['assigned_block_id'],
        'PENDING'
    )

    pending_leaves = get_block_leave_requests(
        warden['assigned_block_id'],
        'PENDING'
    )

    return render_template(
        'warden/dashboard.html',
        warden=warden,
        dashboard=dashboard_data,
        recent_complaints=recent_complaints[:5],
        pending_leaves=pending_leaves[:5]
    )


@warden_bp.route('/students')
@login_required
@warden_required
def students():
    """View all students in the warden's block."""
    warden = get_warden_by_user_id(current_user.user_id)

    search = request.args.get('search', '').strip()
    status_filter = request.args.get('status')

    students_list = get_block_students(
        warden['assigned_block_id'],
        status_filter,
        search if search else None
    )

    return render_template(
        'warden/students.html',
        students=students_list,
        warden=warden
    )


@warden_bp.route('/leave/<int:leave_id>/process', methods=['POST'])
@login_required
@warden_required
def process_leave(leave_id):
    """Approve or reject a leave request."""
    action = request.form.get('action', '').upper()
    rejection_reason = request.form.get('rejection_reason', '').strip()

    try:
        result = execute_procedure('proc_process_leave_request', [
            {'name': 'p_leave_id', 'value': leave_id},
            {'name': 'p_action', 'value': action},
            {'name': 'p_processed_by', 'value': current_user.user_id},
            {'name': 'p_rejection_reason', 'value': rejection_reason or None},
            {'name': 'p_result', 'direction': 'OUT', 'type': 'STRING'},
            {'name': 'p_message', 'direction': 'OUT', 'type': 'STRING'}
        ])

        if result.get('p_result') == 'SUCCESS':
            flash(result.get('p_message'), 'success')
        else:
            flash(result.get('p_message', 'Action failed.'), 'danger')

    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')

    return redirect(url_for('warden.leave_requests'))


@warden_bp.route('/leave-requests')
@login_required
@warden_required
def leave_requests():
    """View and manage leave requests for the warden's block."""
    warden = get_warden_by_user_id(current_user.user_id)

    status_filter = request.args.get('status')

    leave_list = get_block_leave_requests(
        warden['assigned_block_id'],
        status_filter
    )

    return render_template(
        'warden/leave_requests.html',
        leave_requests=leave_list,
        current_status=status_filter,
        warden=warden
    )


@warden_bp.route('/complaints')
@login_required
@warden_required
def complaints():
    """View and manage complaints for the warden's block."""
    warden = get_warden_by_user_id(current_user.user_id)

    status_filter = request.args.get('status')

    complaints_list = get_block_complaints(
        warden['assigned_block_id'],
        status_filter
    )

    return render_template(
        'warden/complaints.html',
        complaints=complaints_list,
        current_status=status_filter,
        warden=warden
    )


@warden_bp.route('/housekeeping')
@login_required
@warden_required
def housekeeping():
    """View and manage housekeeping requests for the warden's block."""
    warden = get_warden_by_user_id(current_user.user_id)

    status_filter = request.args.get('status')

    housekeeping_list = get_block_housekeeping_requests(
        warden['assigned_block_id'],
        status_filter
    )

    # Analytics: service type breakdown
    hk_analytics = execute_query("""
        SELECT hr.service_type,
               COUNT(*) AS total,
               SUM(CASE WHEN hr.status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed,
               SUM(CASE WHEN hr.status = 'PENDING' THEN 1 ELSE 0 END) AS pending
        FROM housekeeping_requests hr
        JOIN rooms r ON hr.room_id = r.room_id
        WHERE r.block_id = :block_id
        GROUP BY hr.service_type
        ORDER BY total DESC
    """, {'block_id': warden['assigned_block_id']})

    return render_template(
        'warden/housekeeping.html',
        housekeeping_requests=housekeeping_list,
        current_status=status_filter,
        warden=warden,
        analytics=hk_analytics
    )


@warden_bp.route('/room-allocation')
@login_required
@warden_required
def room_allocation():
    """View room allocation and occupancy for the warden's block."""
    warden = get_warden_by_user_id(current_user.user_id)

    rooms_list = get_all_rooms(block_id=warden['assigned_block_id'])

    return render_template(
        'warden/room_allocation.html',
        rooms=rooms_list,
        warden=warden
    )


@warden_bp.route('/complaints/<int:complaint_id>/update', methods=['POST'])
@login_required
@warden_required
def update_complaint(complaint_id):
    """Update complaint status."""
    new_status = request.form.get('new_status', '').strip()
    resolution_notes = request.form.get('resolution_notes', '').strip()

    try:
        result = execute_procedure('proc_update_complaint_status', [
            {'name': 'p_complaint_id', 'value': complaint_id},
            {'name': 'p_new_status', 'value': new_status},
            {'name': 'p_assigned_to', 'value': None},
            {'name': 'p_resolution_notes', 'value': resolution_notes or None},
            {'name': 'p_updated_by', 'value': current_user.user_id},
            {'name': 'p_result', 'direction': 'OUT', 'type': 'STRING'},
            {'name': 'p_message', 'direction': 'OUT', 'type': 'STRING'}
        ])
        if result.get('p_result') == 'SUCCESS':
            flash('Complaint status updated successfully.', 'success')
        else:
            flash(result.get('p_message', 'Update failed.'), 'danger')
    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')

    return redirect(url_for('warden.complaints'))


@warden_bp.route('/fines')
@login_required
@warden_required
def fines():
    """View and impose fines for the warden's block."""
    warden = get_warden_by_user_id(current_user.user_id)
    status_filter = request.args.get('status')

    fines_list = execute_query("""
        SELECT f.*, f.amount - f.paid_amount AS balance,
               u.first_name || ' ' || NVL(u.last_name, '') AS student_name,
               s.roll_number, r.room_number,
               ui.first_name || ' ' || NVL(ui.last_name, '') AS imposed_by_name
        FROM fines f
        JOIN students s ON f.student_id = s.student_id
        JOIN users u ON s.user_id = u.user_id
        JOIN rooms r ON s.room_id = r.room_id
        LEFT JOIN users ui ON f.imposed_by = ui.user_id
        WHERE r.block_id = :block_id
        """ + (" AND f.status = :status" if status_filter else "") + """
        ORDER BY f.created_at DESC
    """, {'block_id': warden['assigned_block_id'], **(({'status': status_filter}) if status_filter else {})})

    # Analytics: fine counts by type
    analytics = execute_query("""
        SELECT f.fine_type,
               COUNT(*) AS total,
               SUM(f.amount) AS total_amount,
               SUM(CASE WHEN f.status = 'PAID' THEN 1 ELSE 0 END) AS paid_count,
               SUM(CASE WHEN f.status = 'PENDING' THEN 1 ELSE 0 END) AS pending_count
        FROM fines f
        JOIN students s ON f.student_id = s.student_id
        JOIN rooms r ON s.room_id = r.room_id
        WHERE r.block_id = :block_id
        GROUP BY f.fine_type
        ORDER BY total DESC
    """, {'block_id': warden['assigned_block_id']})

    # Students in this block for the impose-fine form
    block_students = execute_query("""
        SELECT s.student_id, s.roll_number,
               u.first_name || ' ' || NVL(u.last_name, '') AS full_name,
               r.room_number
        FROM students s
        JOIN users u ON s.user_id = u.user_id
        JOIN rooms r ON s.room_id = r.room_id
        WHERE r.block_id = :block_id AND s.hostel_status = 'ALLOCATED'
        ORDER BY r.room_number, s.roll_number
    """, {'block_id': warden['assigned_block_id']})

    return render_template(
        'warden/fines.html',
        fines=fines_list,
        analytics=analytics,
        block_students=block_students,
        current_status=status_filter,
        warden=warden
    )


@warden_bp.route('/fines/impose', methods=['POST'])
@login_required
@warden_required
def impose_fine():
    """Impose a fine on a student."""
    student_id = request.form.get('student_id', type=int)
    fine_type = request.form.get('fine_type', '').strip()
    amount = request.form.get('amount', type=float)
    description = request.form.get('description', '').strip()
    due_days = request.form.get('due_days', 30, type=int)

    if not all([student_id, fine_type, amount]):
        flash('Student, fine type, and amount are required.', 'danger')
        return redirect(url_for('warden.fines'))

    try:
        result = execute_procedure('proc_impose_fine', [
            {'name': 'p_student_id', 'value': student_id},
            {'name': 'p_fine_type', 'value': fine_type},
            {'name': 'p_amount', 'value': amount},
            {'name': 'p_description', 'value': description or None},
            {'name': 'p_imposed_by', 'value': current_user.user_id},
            {'name': 'p_due_days', 'value': due_days},
            {'name': 'p_fine_id', 'direction': 'OUT', 'type': 'NUMBER'},
            {'name': 'p_fine_num', 'direction': 'OUT', 'type': 'STRING'},
            {'name': 'p_result', 'direction': 'OUT', 'type': 'STRING'},
            {'name': 'p_message', 'direction': 'OUT', 'type': 'STRING'}
        ])
        if result.get('p_result') == 'SUCCESS':
            flash(f"Fine {result.get('p_fine_num')} imposed successfully. Student has been notified.", 'success')
        else:
            flash(result.get('p_message', 'Failed to impose fine.'), 'danger')
    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')

    return redirect(url_for('warden.fines'))