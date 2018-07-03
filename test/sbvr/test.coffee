_ = require 'lodash'
sbvrTypes = require '@resin/sbvr-types'

expect = require('chai').expect
AbstractSQLCompiler = require('../..')

module.exports = exports = (builtInVocab = false) ->
	SBVRParser = require('@resin/sbvr-parser').SBVRParser.createInstance()
	SBVRParser.enableReusingMemoizations(SBVRParser._sideEffectingRules)

	LF2AbstractSQL = require '@resin/lf-to-abstract-sql'
	LF2AbstractSQLTranslator = LF2AbstractSQL.createTranslator(sbvrTypes)

	if builtInVocab
		SBVRParser.AddBuiltInVocab(builtInVocab)

	seSoFar = ''

	runExpectation = (it, input, expectation) ->
		it input, ->
			try
				SBVRParser.reset()
				lf = SBVRParser.matchAll(seSoFar + input, 'Process')
				schema = LF2AbstractSQLTranslator(lf, 'Process')
				result = AbstractSQLCompiler.postgres.compileSchema(schema)
			catch e
				expectation(e)
				return
			expectation(result)

	runMigration = (it, src, dst, expectation) ->
		it 'Vocabulary: src\n' + src + '\n\nVocabulary: dst\n' + dst, ->
			SBVRParser.reset()
			srcLf = SBVRParser.matchAll(src, 'Process')
			srcSchema = LF2AbstractSQLTranslator(srcLf, 'Process')

			SBVRParser.reset()
			dstLf = SBVRParser.matchAll(dst, 'Process')
			dstSchema = LF2AbstractSQLTranslator(dstLf, 'Process')

			migration = AbstractSQLCompiler.postgres.diffSchemas(srcSchema, dstSchema)

			expect(migration).to.deep.equal(expectation)

	runSchema = (it, input, expectation) ->
		runExpectation it, input, (result) ->
			seSoFar += input + '\n'
			if _.isFunction(expectation)
				expectation(result)
			else if _.isError(result)
				throw result
			else
				expect(result).to.have.property('createSchema')
				# Individually match the statements in order to get a nicer diff if they don't match.
				for i in [0...Math.max(result.createSchema.length, expectation.length)]
					expect(result.createSchema[i]).to.equal(expectation[i])

	runRule = (it, input, expectation) ->
		runExpectation it, 'Rule: ' + input, (result) ->
			if _.isFunction(expectation)
				expectation(result)
			else if _.isError(result)
				throw result
			else
				expect(result).to.have.property('rules')
				lastRule = _.last(result.rules)
				expect(lastRule).to.have.property('structuredEnglish').that.equals(input)
				expect(lastRule).to.have.property('sql').that.equals(expectation)

	ret = runSchema.bind(null, it)
	ret.skip = runSchema.bind(null, it.skip)
	ret.only = runSchema.bind(null, it.only)
	ret.rule = runRule.bind(null, it)
	ret.rule.skip = runRule.bind(null, it.skip)
	ret.rule.only = runRule.bind(null, it.only)
	ret.migration = runMigration.bind(null, it)
	return ret
