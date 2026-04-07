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
    execute_dml,
    get_mess_menu,
    get_student_by_id,
    get_available_rooms,
    get_room_by_id,
    get_unallocated_students_for_room,
    get_student_compatibility_responses,
    upsert_mess_menu_item,
    update_student_cgpa,
    update_block_cgpa_cutoff,
    get_allocation_queue,
    get_all_announcements,
    get_announcement_by_id,
    create_announcement,
    update_announcement,
    delete_announcement,
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

    # GET — load available rooms filtered by student gender (and optionally by block)
    gender = student.get('gender')
    block_id_filter = request.args.get('block_id', type=int)
    all_rooms = get_available_rooms(gender=gender) or []
    available_rooms = [r for r in all_rooms if not block_id_filter or r.get('block_id') == block_id_filter]

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
            # Sort: 1) CGPA desc, 2) block preference rank asc (nulls last), 3) compatibility desc
            candidates.sort(key=lambda x: (
                -(x['cgpa'] if x['cgpa'] is not None else -1),
                x['min_pref_rank'] if x['min_pref_rank'] is not None else 999,
                -(x['compatibility_score'] if x['compatibility_score'] >= 0 else -1),
            ))

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


@admin_bp.route('/mess-menu', methods=['GET', 'POST'])
@login_required
@admin_required
def mess_menu():
    """Weekly mess menu editor — view and update all 7×4 slots."""
    DAYS   = ['MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY']
    MEALS  = ['BREAKFAST','LUNCH','SNACKS','DINNER']
    TIMES  = {
        'BREAKFAST': ('07:30', '09:30'),
        'LUNCH':     ('12:30', '14:30'),
        'SNACKS':    ('16:30', '17:30'),
        'DINNER':    ('19:30', '21:30'),
    }

    if request.method == 'POST':
        errors = []
        saved  = 0
        for day in DAYS:
            for meal in MEALS:
                key      = f"{day}_{meal}"
                items    = request.form.get(f"{key}_items", '').strip()
                t_start  = request.form.get(f"{key}_start", TIMES[meal][0]).strip()
                t_end    = request.form.get(f"{key}_end",   TIMES[meal][1]).strip()
                special  = request.form.get(f"{key}_special", '').strip()
                if not items:
                    continue
                try:
                    upsert_mess_menu_item(day, meal, items, t_start, t_end,
                                         special or None, None)
                    saved += 1
                except Exception as e:
                    errors.append(f"{day} {meal}: {e}")
        if saved:
            flash(f'Menu updated — {saved} slot(s) saved.', 'success')
        for err in errors:
            flash(err, 'danger')
        return redirect(url_for('admin.mess_menu'))

    # Build a lookup dict  {day: {meal: row}}  for the template
    raw   = get_mess_menu() or []
    menu  = {}
    for day in DAYS:
        menu[day] = {}
        for meal in MEALS:
            menu[day][meal] = None
    for row in raw:
        d = row['day_of_week']
        m = row['meal_type']
        if d in menu and m in menu[d]:
            menu[d][m] = row

    return render_template('admin/mess_menu.html',
                           menu=menu, days=DAYS, meals=MEALS, times=TIMES)


@admin_bp.route('/allocation-queue')
@login_required
@admin_required
def allocation_queue():
    """Show all PENDING students sorted by CGPA, with block preferences and eligibility."""
    queue  = get_allocation_queue() or []
    blocks = get_all_hostel_blocks() or []
    return render_template('admin/allocation_queue.html', queue=queue, blocks=blocks)


@admin_bp.route('/students/update-cgpa', methods=['POST'])
@login_required
@admin_required
def update_cgpa():
    """Update a single student's CGPA."""
    student_id = request.form.get('student_id', type=int)
    cgpa       = request.form.get('cgpa', type=float)
    if student_id is None or cgpa is None or not (0 <= cgpa <= 10):
        flash('Invalid CGPA value.', 'danger')
    else:
        try:
            update_student_cgpa(student_id, cgpa)
            flash('CGPA updated successfully.', 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return redirect(request.referrer or url_for('admin.allocation_queue'))


@admin_bp.route('/blocks/update-cutoff', methods=['POST'])
@login_required
@admin_required
def update_block_cutoff():
    """Update the CGPA cutoff for a hostel block."""
    block_id = request.form.get('block_id', type=int)
    cutoff   = request.form.get('cgpa_cutoff', type=float)
    if block_id is None or cutoff is None or not (0 <= cutoff <= 10):
        flash('Invalid cutoff value.', 'danger')
    else:
        try:
            update_block_cgpa_cutoff(block_id, cutoff)
            flash('CGPA cutoff updated.', 'success')
        except Exception as e:
            flash(f'Error: {e}', 'danger')
    return redirect(url_for('admin.blocks'))


@admin_bp.route('/announcements', methods=['GET'])
@login_required
@admin_required
def announcements():
    """List all announcements."""
    filter_type = request.args.get('type', '')
    filter_audience = request.args.get('audience', '')
    filter_active = request.args.get('active', '')

    is_active = None
    if filter_active == 'Y':
        is_active = True
    elif filter_active == 'N':
        is_active = False

    all_announcements = get_all_announcements(
        is_active=is_active,
        announcement_type=filter_type or None,
        target_audience=filter_audience or None,
    )
    blocks = get_all_hostel_blocks()
    return render_template(
        'admin/announcements.html',
        announcements=all_announcements,
        blocks=blocks,
        filter_type=filter_type,
        filter_audience=filter_audience,
        filter_active=filter_active,
    )


@admin_bp.route('/announcements/create', methods=['POST'])
@login_required
@admin_required
def create_announcement_route():
    """Create a new announcement."""
    title = request.form.get('title', '').strip()
    content = request.form.get('content', '').strip()
    announcement_type = request.form.get('announcement_type', 'GENERAL')
    target_audience = request.form.get('target_audience', 'ALL')
    target_block_id = request.form.get('target_block_id') or None
    priority = request.form.get('priority', 'NORMAL')
    start_date = request.form.get('start_date', '')
    end_date = request.form.get('end_date', '') or None
    is_pinned = 'Y' if request.form.get('is_pinned') else 'N'

    if not title or not content or not start_date:
        flash('Title, content, and start date are required.', 'danger')
        return redirect(url_for('admin.announcements'))

    try:
        create_announcement(
            title=title,
            content=content,
            announcement_type=announcement_type,
            target_audience=target_audience,
            priority=priority,
            start_date=start_date,
            end_date=end_date,
            is_pinned=is_pinned,
            created_by=current_user.user_id,
            target_block_id=int(target_block_id) if target_block_id else None,
        )
        flash('Announcement created successfully.', 'success')
    except Exception as e:
        flash(f'Error creating announcement: {e}', 'danger')

    return redirect(url_for('admin.announcements'))


@admin_bp.route('/announcements/<int:announcement_id>/edit', methods=['POST'])
@login_required
@admin_required
def edit_announcement(announcement_id):
    """Update an existing announcement."""
    title = request.form.get('title', '').strip()
    content = request.form.get('content', '').strip()
    announcement_type = request.form.get('announcement_type', 'GENERAL')
    target_audience = request.form.get('target_audience', 'ALL')
    target_block_id = request.form.get('target_block_id') or None
    priority = request.form.get('priority', 'NORMAL')
    start_date = request.form.get('start_date', '')
    end_date = request.form.get('end_date', '') or None
    is_pinned = 'Y' if request.form.get('is_pinned') else 'N'
    is_active = request.form.get('is_active', 'Y')

    if not title or not content or not start_date:
        flash('Title, content, and start date are required.', 'danger')
        return redirect(url_for('admin.announcements'))

    try:
        update_announcement(
            announcement_id=announcement_id,
            title=title,
            content=content,
            announcement_type=announcement_type,
            target_audience=target_audience,
            priority=priority,
            start_date=start_date,
            end_date=end_date,
            is_pinned=is_pinned,
            is_active=is_active,
            target_block_id=int(target_block_id) if target_block_id else None,
        )
        flash('Announcement updated successfully.', 'success')
    except Exception as e:
        flash(f'Error updating announcement: {e}', 'danger')

    return redirect(url_for('admin.announcements'))


@admin_bp.route('/announcements/<int:announcement_id>/delete', methods=['POST'])
@login_required
@admin_required
def delete_announcement_route(announcement_id):
    """Soft-delete an announcement."""
    try:
        delete_announcement(announcement_id)
        flash('Announcement deleted.', 'success')
    except Exception as e:
        flash(f'Error deleting announcement: {e}', 'danger')
    return redirect(url_for('admin.announcements'))


@admin_bp.route('/analytics')
@login_required
@admin_required
def analytics():
    """View system analytics."""
    # For now, redirect to dashboard
    flash('Advanced analytics coming soon.', 'info')
    return redirect(url_for('admin.dashboard'))