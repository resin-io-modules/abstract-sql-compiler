expect = require('chai').expect
test = require('./test')
{pilotFields, pilotCanFlyPlaneFields} = require('./fields')

postgresAgg = (field) -> 'array_to_json(array_agg(' + field + '))'
mysqlAgg = websqlAgg = (field) -> "'[' || group_concat(" + field + ", ',') || ']'"
(field) -> "'[' || group_concat(" + field + ", ',') || ']'"
do ->
	remainingPilotFields = _.reject(pilotFields, (field) -> field is '"pilot"."licence"').join(', ')
	testFunc = (aggFunc) -> (result) ->
		it 'should select from pilot.*, aggregated licence', ->
			expect(result.query).to.equal '''
				SELECT (
					SELECT ''' + aggFunc('"licence".*') + ''' AS "licence"
					FROM "licence"
					WHERE "licence"."id" = "pilot"."licence"
				) AS "licence", ''' +  remainingPilotFields + '\n' + '''
				FROM "pilot"'''
	test.postgres '/pilot?$expand=licence', testFunc(postgresAgg)
	test.mysql.skip '/pilot?$expand=licence', testFunc(mysqlAgg)
	test.websql.skip '/pilot?$expand=licence', testFunc(websqlAgg)


do ->
	remainingPilotCanFlyFields = _.reject(pilotCanFlyPlaneFields, (field) -> field is '"pilot-can_fly-plane"."plane"').join(', ')
	testFunc = (aggFunc) -> (result) ->
		it 'should select from pilot.*, aggregated(pilot-can_fly-plane, aggregated plane)', ->
			expect(result.query).to.equal """
				SELECT (
					SELECT #{aggFunc('"pilot-can_fly-plane".*')} AS "pilot-can_fly-plane"
					FROM (
						SELECT (
							SELECT #{aggFunc('"plane".*')} AS "plane"
							FROM "plane"
							WHERE "plane"."id" = "pilot-can_fly-plane"."plane"
						) AS "plane", #{remainingPilotCanFlyFields}
						FROM "pilot-can_fly-plane"
					) AS "pilot-can_fly-plane"
					WHERE "pilot"."id" = "pilot-can_fly-plane"."pilot"
				) AS "pilot-can_fly-plane", #{pilotFields.join(', ')}
				FROM "pilot"
				"""
	test.postgres '/pilot?$expand=pilot__can_fly__plane/plane', testFunc(postgresAgg)
	test.mysql.skip '/pilot?$expand=pilot__can_fly__plane/plane', testFunc(mysqlAgg)
	test.websql.skip '/pilot?$expand=pilot__can_fly__plane/plane', testFunc(websqlAgg)
###
					(	SELECT ''' + aggFunc('"plane".*') + ' AS "plane", ' + _.reject(pilotCanFlyPlaneFields, (field) -> field is '"pilot-can_fly-plane"."plane"').join(', ') + '\n' + '''
						FROM "pilot-can_fly-plane",
							"plane"
						WHERE "plane"."id" = "pilot-can_fly-plane"."plane"
						GROUP BY "pilot-can_fly-plane"."id"
					) AS "pilot-can_fly-plane"
				WHERE "pilot"."id" = "pilot-can_fly-plane"."pilot"
				GROUP BY "pilot"."id"
				###
do ->
	remainingPilotCanFlyFields = _.reject(pilotCanFlyPlaneFields, (field) -> field is '"pilot-can_fly-plane"."plane"').join(', ')
	remainingPilotFields = _.reject(pilotFields, (field) -> field is '"pilot"."licence"').join(', ')
	testFunc = (aggFunc) -> (result) ->
		it 'should select from pilot.*, aggregated(pilot-can_fly-plane, aggregated plane), aggregated licence', ->
			expect(result.query).to.equal """
				SELECT (
					SELECT #{aggFunc('"pilot-can_fly-plane".*')} AS "pilot-can_fly-plane"
					FROM (
						SELECT (
							SELECT #{aggFunc('"plane".*')} AS "plane"
							FROM "plane"
							WHERE "plane"."id" = "pilot-can_fly-plane"."plane"
						) AS "plane", #{remainingPilotCanFlyFields}
						FROM "pilot-can_fly-plane"
					) AS "pilot-can_fly-plane"
					WHERE "pilot"."id" = "pilot-can_fly-plane"."pilot"
				) AS "pilot-can_fly-plane", (
					SELECT """ + aggFunc('"licence".*') + """ AS "licence"
					FROM "licence"
					WHERE "licence"."id" = "pilot"."licence"
				) AS "licence", #{remainingPilotFields}
				FROM "pilot"
				"""
	test.postgres '/pilot?$expand=pilot__can_fly__plane/plane,licence', testFunc(postgresAgg)
	test.mysql.skip '/pilot?$expand=pilot__can_fly__plane/plane,licence', testFunc(mysqlAgg)
	test.websql.skip '/pilot?$expand=pilot__can_fly__plane/plane,licence', testFunc(websqlAgg)
