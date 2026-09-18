class LanguageRefreshJob < ApplicationJob
  queue_as :maintenance

  def perform
    LanguageRefreshService.new.run
  end
end
