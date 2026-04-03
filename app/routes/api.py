"""
API Routes
JSON API endpoints for AJAX calls from the frontend.
"""

from flask import Blueprint, jsonify, request
from flask_login import login_required, current_user
from ..models.database import (
    get_user_notifications, mark_notification_read,
    get_unread_notification_count, get_active_announcements,
    get_available_rooms, execute_procedure, get_student_by_user_id,
    get_mess_menu, get_student_compatibility_responses,
    calculate_compatibility
)
from ..utils.helpers import student_required, warden_required, admin_required

api_bp = Blueprint('api', __name__)


@api_bp.route('/notifications')
@login_required
def notifications():
    """Get user notifications as JSON."""
    unread_only = request.args.get('unread_only', 'false').lower() == 'true'
    limit = request.args.get('limit', 10, type=int)
    notifs = get_user_notifications(current_user.user_id, unread_only, limit)
    return jsonify({'notifications': notifs or [], 'count': len(notifs or [])})


@api_bp.route('/notifications/<int:notification_id>/read', methods=['POST'])
@login_required
def mark_read(notification_id):
    """Mark a notification as read."""
    mark_notification_read(notification_id, current_user.user_id)
    count = get_unread_notification_count(current_user.user_id)
    return jsonify({'success': True, 'unread_count': count})


@api_bp.route('/rooms/available')
@login_required
def available_rooms():
    """Get available rooms as JSON."""
    gender = request.args.get('gender')
    rooms = get_available_rooms(gender)
    return jsonify({'rooms': rooms or []})


@api_bp.route('/mess-menu')
@login_required
def mess_menu():
    """Get mess menu as JSON."""
    day = request.args.get('day')
    menu = get_mess_menu(day_of_week=day)
    return jsonify({'menu': menu or []})


@api_bp.route('/compatibility/<int:student2_id>')
@login_required
def compatibility_score(student2_id):
    """Get compatibility score between current student and another."""
    student = get_student_by_user_id(current_user.user_id)
    if not student:
        return jsonify({'error': 'Student not found'}), 404
    score = calculate_compatibility(student['student_id'], student2_id)
    return jsonify({'score': score})
