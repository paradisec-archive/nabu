class MergeUser
  attr_accessor :first_name, :last_name, :email, :address, :address2,
                :country, :phone, :admin, :contact_only

  def initialize(users)
    @first_name = Set.new
    @last_name = Set.new
    @email = Set.new
    @address = Set.new
    @address2 = Set.new
    @country = Set.new
    @phone = Set.new
    @admin = Set.new
    @contact_only = Set.new
    
    users.each do |user|
      @first_name.add user.try(:first_name)
      @last_name.add user.try(:last_name)
      @email.add user.try(:email)
      @address.add user.try(:address)
      @address2.add user.try(:address2)
      @country.add user.try(:country)
      @phone.add user.try(:phone)
      @admin.add user.try(:admin)
      @contact_only.add user.try(:contact_only)
    end
    
    # @rights_transferred_to = Set.new
    # @rights_transfer_reason = Set.new
    # @nla_persistent_identifier = Set.new
  end
end