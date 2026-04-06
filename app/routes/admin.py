"""Admin Routes"""

from flask import Blueprint, render_template, redirect, url_for, flash, request, jsonify
from flask_login import login_required, current_user

from ..models.database import (
    get_all_students,
    get_all_hostel_blocks,
    get_all_rooms,
    get_all_wardens,
    get_all_staff,
    get_occupancy_stats,
    get_complaint_statistics,
    get_monthly_stats,
    execute_procedure,
    get_mess_menu,
    get_student_by_id,
    get_available_rooms,
    get_room_by_id,
    get_unallocated_students_for_room,
    get_student_compatibility_responses,
)
from ..utils.compatibility import calculate_compatibility_python, get_compatibility_category

from ..utils.helpers import admin_required

admin_bp = Blueprint('admin', __name__)


@admin_bp.route('/dashboard')
@login_required
@admin_required
def dashboard():
    """Admin dashboard with system-wide statistics."""
    occupancy = get_occupancy_stats()
    monthly = get_monthly_stats()
    complaint_stats = get_complaint_statistics()
    blocks = get_all_hostel_blocks()

    return render_template(
        'admin/dashboard.html',
        occupancy=occupancy,
        monthly=monthly,
        complaint_stats=complaint_stats,
        blocks=blocks
    )


@admin_bp.route('/allocate/<int:student_id>', methods=['GET', 'POST'])
@login_required
@admin_required
def allocate_student(student_id):
    """Dedicated allocation page: pick a room, see compatibility scores, optionally co-allocate roommates."""
    student = get_student_by_id(student_id)
    if not student:
        flash('Student not found.', 'danger')
        return redirect(url_for('admin.students'))

    if student['hostel_status'] == 'ALLOCATED':
        flash('Student is already allocated to a room.', 'warning')
        return redirect(url_for('admin.students'))

    if request.method == 'POST':
        room_id = request.form.get('room_id', type=int)
        roommate_ids = request.form.getlist('roommate_ids')
        roommate_ids = [int(x) for x in roommate_ids if x]
        remarks = request.form.get('remarks', '').strip()

        if not room_id:
            flash('Please select a room.', 'danger')
            return redirect(url_for('admin.allocate_student', student_id=student_id))

        errors = []
        success_count = 0
        for sid in [student_id] + roommate_ids:
            try:
                result = execute_procedure('proc_allocate_room', [
                    {'name': 'p_student_id', 'value': sid},
                    {'name': 'p_room_id', 'value': room_id},
                    {'name': 'p_allocated_by', 'value': current_user.user_id},
                    {'name': 'p_remarks', 'value': remarks or None},
                    {'name': 'p_result', 'direction': 'OUT', 'type': 'STRING'},
                    {'name': 'p_message', 'direction': 'OUT', 'type': 'STRING'}
                ])
                if result.get('p_result') == 'SUCCESS':
                    success_count += 1
                else:
                    errors.append(result.get('p_message', 'Allocation failed.'))
            except Exception as e:
                errors.append(str(e))

        if success_count:
            flash(f'Successfully allocated {success_count} student(s) to the room.', 'success')
        for err in errors:
            flash(err, 'danger')
        return redirect(url_for('admin.students'))

    # GET — load available rooms filtered by student gender
    gender = student.get('gender')
    available_rooms = get_available_rooms(gender=gender) or []

    selected_room_id = request.args.get('room_id', type=int)
    selected_room = None
    candidates = []

    if selected_room_id:
        selected_room = get_room_by_id(selected_room_id)
        if selected_room and selected_room['available_beds'] > 0:
            my_responses = get_student_compatibility_responses(student_id)
            raw_candidates = get_unallocated_students_for_room(selected_room_id, student_id) or []
            for c in raw_candidates:
                their_responses = get_student_compatibility_responses(c['student_id'])
                score = calculate_compatibility_python(my_responses, their_responses)
                cat = get_compatibility_category(score if score >= 0 else None)
                candidates.append({
                    **c,
                    'compatibility_score': score,
                    'category_info': cat,
                })
            candidates.sort(key=lambda x: -(x['compatibility_score'] if x['compatibility_score'] >= 0 else -1))

    return render_template(
        'admin/allocate.html',
        student=student,
        available_rooms=available_rooms,
        selected_room=selected_room,
        selected_room_id=selected_room_id,
        candidates=candidates,
    )


@admin_bp.route('/rooms/deallocate', methods=['POST'])
@login_required
@admin_required
def deallocate_room():
    """Remove a student's room allocation."""
    student_id = request.form.get('student_id', type=int)
    remarks = request.form.get('remarks', '').strip()
    try:
        result = execute_procedure('proc_deallocate_room', [
            {'name': 'p_student_id', 'value': student_id},
            {'name': 'p_remarks', 'value': remarks or None},
            {'name': 'p_result', 'direction': 'OUT', 'type': 'STRING'},
            {'name': 'p_message', 'direction': 'OUT', 'type': 'STRING'}
        ])
        if result.get('p_result') == 'SUCCESS':
            flash(result.get('p_message'), 'success')
        else:
            flash(result.get('p_message', 'Deallocation failed.'), 'danger')
    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')
    return redirect(url_for('admin.students'))


@admin_bp.route('/students')
@login_required
@admin_required
def students():
    """View all students in the system."""
    search = request.args.get('search', '').strip()
    status_filter = request.args.get('status')
    page = request.args.get('page', 1, type=int)

    students_list = get_all_students(
        status=status_filter,
        search=search if search else None,
        page=page
    )

    return render_template(
        'admin/students.html',
        students=students_list
    )


@admin_bp.route('/rooms')
@login_required
@admin_required
def rooms():
    """View all rooms in the system."""
    block_filter = request.args.get('block')
    status_filter = request.args.get('status')

    rooms_list = get_all_rooms(
        block_id=block_filter,
        status=status_filter
    )

    blocks = get_all_hostel_blocks()

    return render_template(
        'admin/rooms.html',
        rooms=rooms_list,
        blocks=blocks
    )


@admin_bp.route('/blocks')
@login_required
@admin_required
def blocks():
    """View all hostel blocks."""
    blocks_list = get_all_hostel_blocks()

    return render_template(
        'admin/blocks.html',
        blocks=blocks_list
    )


@admin_bp.route('/wardens')
@login_required
@admin_required
def wardens():
    """View all wardens."""
    wardens_list = get_all_wardens()

    return render_template(
        'admin/wardens.html',
        wardens=wardens_list
    )


@admin_bp.route('/staff')
@login_required
@admin_required
def staff():
    """View all staff members."""
    type_filter = request.args.get('type')

    staff_list = get_all_staff(staff_type=type_filter)

    return render_template(
        'admin/staff.html',
        staff=staff_list
    )


@admin_bp.route('/complaints')
@login_required
@admin_required
def complaints():
    """View all complaints in the system."""
    # For now, redirect to dashboard or create a simple view
    flash('Complaints management coming soon.', 'info')
    return redirect(url_for('admin.dashboard'))


@admin_bp.route('/mess-menu')
@login_required
@admin_required
def mess_menu():
    """Manage mess menu."""
    # For now, redirect to dashboard
    flash('Mess menu management coming soon.', 'info')
    return redirect(url_for('admin.dashboard'))


@admin_bp.route('/announcements')
@login_required
@admin_required
def announcements():
    """Manage announcements."""
    # For now, redirect to dashboard
    flash('Announcements management coming soon.', 'info')
    return redirect(url_for('admin.dashboard'))


@admin_bp.route('/analytics')
@login_required
@admin_required
def analytics():
    """View system analytics."""
    # For now, redirect to dashboard
    flash('Advanced analytics coming soon.', 'info')
    return redirect(url_for('admin.dashboard'))