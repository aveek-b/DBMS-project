"""

Roommate Compatibility Calculation Utilities

"""

# Compatibility weight configuration

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

def get_compatibility_category(score):

"""Get compatibility category based on score."""

if score >= 85:

return {

'category': 'Excellent Match',

'color': 'success',

'description': 'You and this person have very similar preferences and
habits!'

}

elif score >= 70:

return {

'category': 'Good Match',

'color': 'primary',

'description': 'You share many common preferences with some minor
differences.'

}

elif score >= 50:

return {

'category': 'Moderate Match',

'color': 'warning',

'description': 'You have some similarities but also notable
differences.'

}

else:

return {

'category': 'Poor Match',

'color': 'danger',

'description': 'Your preferences differ significantly. Consider other
options.'

}

def calculate_detailed_compatibility(responses1, responses2):

"""Calculate detailed compatibility breakdown."""

if not responses1 or not responses2:

return None

total_weight = 0

matched_weight = 0

breakdown = []

# Convert responses to dictionaries

r1_dict = {r['question_id']: r['response_value'] for r in
responses1}

r2_dict = {r['question_id']: r['response_value'] for r in
responses2}

for r1 in responses1:

q_id = r1['question_id']

category = r1['category']

weight = COMPATIBILITY_WEIGHTS.get(category, 5)

if q_id in r2_dict:

total_weight += weight

r1_val = r1['response_value']

r2_val = r2_dict[q_id]

# Calculate match score

if r1_val == r2_val:

match_score = weight

match_status = 'Perfect Match'

elif category in ['CLEANLINESS', 'NOISE_TOLERANCE',
'PERSONALITY']:

# Scale-based partial matching

try:

diff = abs(int(r1_val) - int(r2_val))

if diff == 1:

match_score = weight * 0.6

match_status = 'Close Match'

elif diff == 2:

match_score = weight * 0.3

match_status = 'Partial Match'

else:

match_score = 0

match_status = 'No Match'

except ValueError:

match_score = 0

match_status = 'No Match'

elif category in ['SLEEP_SCHEDULE', 'WAKE_TIME']:

# Time-based partial matching

times = ['9 PM', '10 PM', '11 PM', '12 AM', '1 AM', 'After 1
AM']

try:

idx1 = times.index(r1_val) if r1_val in times else -1

idx2 = times.index(r2_val) if r2_val in times else -1

if idx1 >= 0 and idx2 >= 0:

diff = abs(idx1 - idx2)

if diff == 1:

match_score = weight * 0.7

match_status = 'Close Match'

elif diff == 2:

match_score = weight * 0.4

match_status = 'Partial Match'

else:

match_score = 0

match_status = 'No Match'

else:

match_score = 0

match_status = 'No Match'

except:

match_score = 0

match_status = 'No Match'

else:

match_score = 0

match_status = 'No Match'

matched_weight += match_score

breakdown.append({

'category': category.replace('_', ' ').title(),

'weight': weight,

'your_response': r1_val,

'their_response': r2_val,

'match_status': match_status,

'match_percentage': round(match_score / weight * 100) if weight > 0
else 0

})

overall_score = round(matched_weight / total_weight * 100, 2) if
total_weight > 0 else 0

category_info = get_compatibility_category(overall_score)

return {

'overall_score': overall_score,

'category': category_info['category'],

'color': category_info['color'],

'description': category_info['description'],

'breakdown': breakdown

}
