expect = require('chai').expect
test = require('./test')
{ pilotFields } = require('./fields')
pilotFields = pilotFields.join(', ')

test '/pilot?$orderby=name', (result) ->
	it 'should order by name desc', ->
		expect(result.query).to.equal('''
			SELECT ''' + pilotFields + '\n' + '''
			FROM "pilot"
			ORDER BY "pilot"."name" DESC
		''')


test '/pilot?$orderby=name,age', (result) ->
	it 'should order by name desc, age desc', ->
		expect(result.query).to.equal('''
			SELECT ''' + pilotFields + '\n' + '''
			FROM "pilot"
			ORDER BY "pilot"."name" DESC,
				"pilot"."age" DESC
		''')


test '/pilot?$orderby=name desc', (result) ->
	it 'should order by name desc', ->
		expect(result.query).to.equal('''
			SELECT ''' + pilotFields + '\n' + '''
			FROM "pilot"
			ORDER BY "pilot"."name" DESC
		''')


test '/pilot?$orderby=name asc', (result) ->
	it 'should order by name asc', ->
		expect(result.query).to.equal('''
			SELECT ''' + pilotFields + '\n' + '''
			FROM "pilot"
			ORDER BY "pilot"."name" ASC
		''')


test '/pilot?$orderby=name asc,age desc', (result) ->
	it 'should order by name desc, age desc', ->
		expect(result.query).to.equal('''
			SELECT ''' + pilotFields + '\n' + '''
			FROM "pilot"
			ORDER BY "pilot"."name" ASC,
				"pilot"."age" DESC
		''')


test '/pilot?$orderby=licence/id asc', (result) ->
	it 'should order by licence/id asc', ->
		expect(result.query).to.equal('''
			SELECT ''' + pilotFields + '\n' + '''
			FROM "pilot",
				"licence" AS "pilot.licence"
			WHERE "pilot"."licence" = "pilot.licence"."id"
			ORDER BY "pilot.licence"."id" ASC
		''')


test '/pilot?$orderby=can_fly__plane/plane/id asc', (result) ->
	it 'should order by pilot__can_fly__plane/plane/id asc', ->
		expect(result.query).to.equal('''
			SELECT ''' + pilotFields + '\n' + '''
			FROM "pilot",
				"pilot-can fly-plane" AS "pilot.pilot-can fly-plane",
				"plane" AS "pilot.pilot-can fly-plane.plane"
			WHERE "pilot"."id" = "pilot.pilot-can fly-plane"."pilot"
			AND "pilot.pilot-can fly-plane"."can fly-plane" = "pilot.pilot-can fly-plane.plane"."id"
			ORDER BY "pilot.pilot-can fly-plane.plane"."id" ASC
		''')


test.skip '/pilot?$orderby=favourite_colour/red', (result) ->
	it "should order by how red the pilot's favourite colour is"