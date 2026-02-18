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

  def unconfirmed_users_deletion_report
    @report_data = params[:report_data]

    to_delete = @report_data[:unreferenced_count]

    mail(subject: "[NABU Admin] Unconfirmed Users Deletion Preview: #{to_delete} users to be deleted")
  end

  def unconfirmed_users_deleted_report
    @report_data = params[:report_data]

    subject_line = "[NABU Admin] Unconfirmed Users Deleted: #{@report_data[:deleted_count]} accounts removed"

    subject_line += " (#{@report_data[:total_failed]} failed)" if @report_data[:total_failed] > 0

    mail(subject:)
  end

  def doi_audit_error
    @error = params[:error]
    @failed_dois = params[:failed_dois]

    mail(subject: "[NABU Admin] DOI Audit Error: #{Date.today.strftime('%F')}")
  end
end
