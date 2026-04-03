"""

Helper Utilities

"""

from functools import wraps

from flask import redirect, url_for, flash

from flask_login import current_user

def role_required(*roles):

"""Decorator to require specific user roles."""

def decorator(f):

\@wraps(f)

def decorated_function(*args, **kwargs):

if not current_user.is_authenticated:

flash('Please log in to access this page.', 'warning')

return redirect(url_for('auth.login'))

if current_user.role not in roles:

flash('You do not have permission to access this page.', 'danger')

return redirect(url_for('auth.login'))

return f(*args, **kwargs)

return decorated_function

return decorator

def admin_required(f):

"""Decorator to require admin role."""

return role_required('ADMIN')(f)

def warden_required(f):

"""Decorator to require warden role."""

return role_required('WARDEN')(f)

def student_required(f):

"""Decorator to require student role."""

return role_required('STUDENT')(f)

def format_currency(amount):

"""Format amount as Indian currency."""

if amount is None:

return '₹0.00'

return f'₹{amount:,.2f}'

def format_date(date_obj, format_str='%d %b %Y'):

"""Format date object to string."""

if date_obj is None:

return '-'

return date_obj.strftime(format_str)

def get_day_of_week():

"""Get current day of week."""

from datetime import datetime

return datetime.now().strftime('%A').upper()

def paginate(query_results, page, per_page):

"""Paginate query results."""

start = (page - 1) * per_page

end = start + per_page

items = query_results[start:end]

total = len(query_results)

pages = (total + per_page - 1) // per_page

return {

'items': items,

'page': page,

'per_page': per_page,

'total': total,

'pages': pages,

'has_prev': page > 1,

'has_next': page < pages

}

5. Flask Routes
