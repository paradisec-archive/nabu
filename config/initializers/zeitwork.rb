Rails.autoloaders.each do |autoloader|
  autoloader.ignore(Rails.root.join('lib/monkeypatch'))
end
