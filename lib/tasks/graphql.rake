require 'graphql/rake_task'

GraphQL::RakeTask.new(schema_name: 'NabuSchema', idl_outfile: 'nabu.graphql')
