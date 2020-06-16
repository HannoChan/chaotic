# importing the requests library 
import requests, json, argparse

def populate_chaos_recipe(items):
	chaos_recipe = {}

	for type in ['two_hand_weapon', 'one_hand_weapon', 'helmet', 'gloves', 'boots', 'body', 'belt', 'ring', 'amulet']:
		chaos_recipe[type] = []

	for item in items:
		if item['ilvl'] < 60 or item['identified'] == True or item['frameType'] != 2:
			continue
		if item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Weapons/TwoHandWeapons'):
			item['type'] = 'two_hand_weapon'
			chaos_recipe['two_hand_weapon'].append(item)
		elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Weapons/OneHandWeapons'):
			item['type'] = 'one_hand_weapon'
			chaos_recipe['one_hand_weapon'].append(item)
		elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Armours/Helmets'):
			item['type'] = 'helmet'
			chaos_recipe['helmet'].append(item)
		elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Armours/Gloves'):
			item['type'] = 'gloves'
			chaos_recipe['gloves'].append(item)
		elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Armours/Boots'):
			item['type'] = 'boots'
			chaos_recipe['boots'].append(item)
		elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Armours/BodyArmours'):
			item['type'] = 'body'
			chaos_recipe['body'].append(item)
		elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Belts'):
			item['type'] = 'belt'
			chaos_recipe['belt'].append(item)
		elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Rings'):
			item['type'] = 'ring'
			chaos_recipe['ring'].append(item)
		elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Amulets'):
			item['type'] = 'amulet'
			chaos_recipe['amulet'].append(item)


	return chaos_recipe


if __name__ == "__main__":
	
	parser = argparse.ArgumentParser()
	parser.add_argument('-t', '--tabIndex', help = 'Index of the current tab', required = False, default = 0)
	parser.add_argument('-a', '--accountName', help = 'Name of the Account', required = True)
	parser.add_argument('-p', '--poesessid', help = 'poesessid of the Account', required = True)
	parser.add_argument('-l', '--league', help = 'current league', required = True)
	parser.add_argument('-c', '--count', help = 'return the count of rare items', required = False, action = 'store_true')

	argument = parser.parse_args()

	# api-endpoint 
	URL = "https://www.pathofexile.com/character-window/get-stash-items"
	  
	PARAMS = {'league':argument.league, 'realm':'pc', 'accountName':argument.accountName, 'tabs':'1', 'tabIndex':argument.tabIndex}
	COOKIES = {'POESESSID':argument.poesessid}

	# sending get request and saving the response as response object 
	r = requests.get(url = URL, params = PARAMS, cookies = COOKIES) 
	  
	# extracting data in json format 
	data = r.json()

	if argument.count:
		count = {'weapons':0, 'helmet':0, 'gloves':0, 'boots':0, 'body':0, 'ring':0, 'belt':0, 'amulet':0}
		for tab in data['tabs']:
			if tab['type'] == 'QuadStash':
				PARAMS['tabIndex'] = tab['i']
				content = requests.get(url = URL, params = PARAMS, cookies = COOKIES).json()

				for item in content['items']:
					if item['ilvl'] < 60 or item['identified'] == True or item['frameType'] != 2:
						continue
					if item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Weapons/TwoHandWeapons'):
						count['weapons'] += 2
					elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Weapons/OneHandWeapons'):
						count['weapons'] += 1
					elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Armours/Helmets'):
						count['helmet'] += 1
					elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Armours/Gloves'):
						count['gloves'] += 1
					elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Armours/Boots'):
						count['boots'] += 1
					elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Armours/BodyArmours'):
						count['body'] += 1
					elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Belts'):
						count['belt'] += 1
					elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Rings'):
						count['ring'] += 1
					elif item['icon'].startswith('https://web.poecdn.com/image/Art/2DItems/Amulets'):
						count['amulet'] += 1

		with open('count.json', 'w') as f:
			json.dump(count, f)


	else:
		items = data['items']

		chaos_recipe = populate_chaos_recipe(items)
		chaos_recipe['quad'] = int(data['tabs'][int(argument.tabIndex)]['type'] == 'QuadStash')

		with open('chaos_recipe.json', 'w') as f:
			json.dump(chaos_recipe, f)

	with open('data.json', 'w') as f:
		json.dump(data, f)
