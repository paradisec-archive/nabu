require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
# The validators run inside the shared jobs worker, where mutating the process
# environment on construction would change credentials for every other thread.
# The rake-only services are held to the same rule so none of them can be moved
# into a job and reintroduce it.
describe 'S3 service AWS credentials' do
  def credential_vars = %w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN]

  def aws_credentials = ENV.to_hash.slice(*credential_vars)

  around do |example|
    original = aws_credentials

    ENV['AWS_ACCESS_KEY_ID'] = 'AKIAEXAMPLE'
    ENV['AWS_SECRET_ACCESS_KEY'] = 'secret'
    ENV['AWS_SESSION_TOKEN'] = 'token'

    example.run

    credential_vars.each { |var| ENV.delete(var) }
    ENV.update(original)
  end

  it 'survives constructing the DB sync validator' do
    expect { CatalogDbSyncValidatorService.new('prod') }.not_to(change { aws_credentials })
  end

  it 'survives constructing the replication validator' do
    expect { CatalogReplicationValidatorService.new }.not_to(change { aws_credentials })
  end

  it 'survives constructing the Mediaflux validator' do
    expect { CatalogMediafluxValidatorService.new }.not_to(change { aws_credentials })
  end

  it 'survives constructing the junk service' do
    expect { JunkService.new('prod') }.not_to(change { aws_credentials })
  end

  it 'survives constructing the S3 version deletion service' do
    expect { S3VersionDeletionService.new('prod') }.not_to(change { aws_credentials })
  end
end
# rubocop:enable RSpec/DescribeClass
