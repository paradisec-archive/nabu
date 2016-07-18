# == Schema Information
#
# Table name: data_types
#
#  id   :integer          not null, primary key
#  name :string(255)      not null
#

class DataType < ActiveRecord::Base
  attr_accessible :name
end
