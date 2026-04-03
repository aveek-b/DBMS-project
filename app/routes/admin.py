"""Admin Routes"""

from flask import Blueprint, render_template, redirect, url_for, flash,
request, jsonify

from flask_login import login_required, current_user

from ..models.database import (

get_all_students, get_all_hostel_blocks, get_all_rooms, get_all_wardens,

get_all_staff, get_occupancy_stats, get_complaint_statistics,

get_monthly_stats, execute_procedure, get_mess_menu

)

from ..utils.helpers import admin_required

admin_bp = Blueprint('admin', __name__)

\@admin_bp.route('/dashboard')

\@login_required

\@admin_required

def dashboard():

"""Admin dashboard with system-wide statistics."""

occupancy = get_occupancy_stats()

monthly = get_monthly_stats()

complaint_stats = get_complaint_statistics()

blocks = get_all_hostel_blocks()

return render_template('admin/dashboard.html',

occupancy=occupancy, monthly=monthly,

complaint_stats=complaint_stats, blocks=blocks)

\@admin_bp.route('/rooms/allocate', methods=['POST'])

\@login_required

\@admin_required

def allocate_room():

"""Allocate a room to a student."""

student_id = request.form.get('student_id', type=int)

room_id = request.form.get('room_id', type=int)

remarks = request.form.get('remarks', '').strip()

try:

result = execute_procedure('proc_allocate_room', [

{'name': 'p_student_id', 'value': student_id},

{'name': 'p_room_id', 'value': room_id},

{'name': 'p_allocated_by', 'value': current_user.user_id},

{'name': 'p_remarks', 'value': remarks or None},

{'name': 'p_result', 'direction': 'OUT', 'type': 'STRING'},

{'name': 'p_message', 'direction': 'OUT', 'type': 'STRING'}

])

if result.get('p_result') == 'SUCCESS':

flash(result.get('p_message'), 'success')

else:

flash(result.get('p_message', 'Allocation failed.'), 'danger')

except Exception as e:

flash(f'Error: {str(e)}', 'danger')

return redirect(url_for('admin.rooms'))

This completes the Hostel Management System. Here is a summary of
everything included:

1\. Oracle SQL: 18 tables, 4 schema files (tables, sequences, views,
indexes)

2\. PL/SQL: 8 procedures, 8 functions, 12 triggers, 4 packages, 5
cursor-based procedures

3\. Flask Backend: authentication, student/warden/admin routes, database
module, helpers

4\. Sample Data: 4 blocks, 18 rooms, 10 students, 4 wardens, full mess
menu, compatibility questions
