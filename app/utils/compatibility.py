"""
Roommate Compatibility Calculation Utilities - FIXED
"""

COMPATIBILITY_WEIGHTS = {
    'SLEEP_SCHEDULE': 10,
    'WAKE_TIME': 10,
    'CLEANLINESS': 15,
    'STUDY_HABITS': 15,
    'NOISE_TOLERANCE': 15,
    'MUSIC_PREFERENCE': 10,
    'SOCIAL_HABITS': 10,
    'TEMPERATURE': 3,
    'SHARING': 1,
    'PERSONALITY': 5,
    'SMOKING': 3,
    'FOOD_HABITS': 3
}

SCALE_CATEGORIES = {'CLEANLINESS', 'NOISE_TOLERANCE', 'PERSONALITY'}
TIME_CATEGORIES = {'SLEEP_SCHEDULE', 'WAKE_TIME'}

TIME_OPTIONS = ['9 PM', '10 PM', '11 PM', '12 AM', '1 AM', 'After 1 AM',
                '5 AM', '6 AM', '7 AM', '8 AM', '9 AM', 'After 9 AM']


def get_compatibility_category(score):
    """Return category dict based on score."""
    if score is None or score < 0:
        return {'category': 'Unknown', 'color': 'muted', 'description': 'Quiz not completed.'}
    if score >= 85:
        return {
            'category': 'Excellent Match',
            'color': 'success',
            'description': 'You and this person have very similar preferences and habits!'
        }
    elif score >= 70:
        return {
            'category': 'Good Match',
            'color': 'primary',
            'description': 'You share many common preferences with some minor differences.'
        }
    elif score >= 50:
        return {
            'category': 'Moderate Match',
            'color': 'warning',
            'description': 'You have some similarities but also notable differences.'
        }
    else:
        return {
            'category': 'Poor Match',
            'color': 'danger',
            'description': 'Your preferences differ significantly. Consider other options.'
        }


def _match_score(category, r1_val, r2_val, weight):
    """Calculate match score for two response values."""
    r1_val = str(r1_val).strip()
    r2_val = str(r2_val).strip()

    # Exact match
    if r1_val == r2_val:
        return weight, 'Perfect Match'

    # Scale-based partial match (1-5 scales)
    if category in SCALE_CATEGORIES:
        try:
            diff = abs(int(r1_val) - int(r2_val))
            if diff == 1:
                return weight * 0.6, 'Close Match'
            elif diff == 2:
                return weight * 0.3, 'Partial Match'
            else:
                return 0, 'No Match'
        except ValueError:
            return 0, 'No Match'

    # Time-based partial match
    if category in TIME_CATEGORIES:
        try:
            idx1 = TIME_OPTIONS.index(r1_val) if r1_val in TIME_OPTIONS else -1
            idx2 = TIME_OPTIONS.index(r2_val) if r2_val in TIME_OPTIONS else -1
            if idx1 >= 0 and idx2 >= 0:
                diff = abs(idx1 - idx2)
                if diff == 1:
                    return weight * 0.7, 'Close Match'
                elif diff == 2:
                    return weight * 0.4, 'Partial Match'
                else:
                    return 0, 'No Match'
        except Exception:
            pass
        return 0, 'No Match'

    return 0, 'No Match'


def calculate_compatibility_python(responses1, responses2):
    """
    Pure Python compatibility calculation.
    responses1, responses2: lists of dicts with keys question_id, category, response_value, weight_percentage
    Returns score 0-100, or -1 if either has no responses.
    """
    if not responses1 or not responses2:
        return -1

    # Build maps: question_id -> response dict
    map1 = {r['question_id']: r for r in responses1}
    map2 = {r['question_id']: r for r in responses2}

    total_weight = 0.0
    matched_weight = 0.0

    # Only score questions answered by BOTH
    common_ids = set(map1.keys()) & set(map2.keys())
    if not common_ids:
        return 0

    for qid in common_ids:
        r1 = map1[qid]
        r2 = map2[qid]
        category = r1.get('category', '')
        weight = float(COMPATIBILITY_WEIGHTS.get(category, r1.get('weight_percentage', 5)))

        total_weight += weight
        score, _ = _match_score(category, r1['response_value'], r2['response_value'], weight)
        matched_weight += score

    if total_weight == 0:
        return 0

    return round((matched_weight / total_weight) * 100, 1)


def calculate_detailed_compatibility(responses1, responses2):
    """Full breakdown for display on roommate detail view."""
    if not responses1 or not responses2:
        return None

    map1 = {r['question_id']: r for r in responses1}
    map2 = {r['question_id']: r for r in responses2}

    total_weight = 0.0
    matched_weight = 0.0
    breakdown = []

    common_ids = set(map1.keys()) & set(map2.keys())

    for qid in common_ids:
        r1 = map1[qid]
        r2 = map2[qid]
        category = r1.get('category', '')
        weight = float(COMPATIBILITY_WEIGHTS.get(category, r1.get('weight_percentage', 5)))
        total_weight += weight

        r1_val = str(r1['response_value']).strip()
        r2_val = str(r2['response_value']).strip()
        score, status = _match_score(category, r1_val, r2_val, weight)
        matched_weight += score

        breakdown.append({
            'category': category.replace('_', ' ').title(),
            'question': r1.get('question_text', ''),
            'weight': weight,
            'your_response': r1_val,
            'their_response': r2_val,
            'match_status': status,
            'match_percentage': round(score / weight * 100) if weight > 0 else 0
        })

    overall = round((matched_weight / total_weight) * 100, 1) if total_weight > 0 else 0
    info = get_compatibility_category(overall)

    return {
        'overall_score': overall,
        'category': info['category'],
        'color': info['color'],
        'description': info['description'],
        'breakdown': sorted(breakdown, key=lambda x: -x['weight'])
    }