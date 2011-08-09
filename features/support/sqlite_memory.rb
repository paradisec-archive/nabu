
load_schema = lambda do
  load "#{Rails.root}/db/schema.rb"
end

silence_stream(STDOUT, &load_schema)
