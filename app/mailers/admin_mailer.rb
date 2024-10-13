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
end
