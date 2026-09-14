class AdminMailer < ApplicationMailer
  default to: ['admin@paradisec.org.au', 'johnf@inodes.org']

  def catalog_s3_sync_report
    @s3_only = params[:s3_only]
    @db_only = params[:db_only]

    mail(subject: "[NABU Admin] Catalog S3 Sync Report: #{Date.today.strftime('%F')}")
  end

  def catalog_replication_report
    @prod_only = params[:prod_only]
    @dr_only = params[:dr_only]

    mail(subject: "[NABU Admin] Catalog Replication Report: #{Date.today.strftime('%F')}")
  end

  def catalog_mediaflux_report
    @missing = params[:missing]
    @size_mismatch = params[:size_mismatch]

    mail(subject: "[NABU Admin] Catalog Mediaflux Report: #{Date.today.strftime('%F')}", to: ['johnf@inodes.org'])
  end

  def unconfirmed_users_deleted_report
    @deleted_users = params[:deleted_users]

    mail(subject: "[NABU Admin] Unconfirmed Users Deleted: #{@deleted_users.size} accounts removed")
  end

  def doi_audit_error
    @error = params[:error]
    @failed_dois = params[:failed_dois]

    mail(subject: "[NABU Admin] DOI Audit Error: #{Date.today.strftime('%F')}")
  end
end
