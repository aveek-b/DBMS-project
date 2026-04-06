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

    return render_template(
        'warden/housekeeping.html',
        housekeeping_requests=housekeeping_list,
        current_status=status_filter,
        warden=warden
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