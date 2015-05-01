class TrogdirChange
  attr_reader :hash
  def initialize(hash)
    @hash = hash
  end

  def sync_log_id
    hash['sync_log_id']
  end

  def person_uuid
    hash['person_id']
  end

  def has_netid?
    if hash['scope'] == 'person'
      Array(hash['ids']).any? { |id| id['type'] == 'netid' }
    elsif hash['scope'] == 'id' && all_attrs['type'] == 'netid'
      true
    else
      TrogdirPerson.new(person_uuid).netid.present?
    end
  end

  [:first_name, :middle_name, :last_name, :preferred_name, :tile, :department, :employee_type].each do |meth|
    define_method "#{meth}_changed?" do
      changed_attrs.include? meth.to_s
    end
  end

  {
    university_email: [:email, :university],
    office_phone: [:phone, :office],
    biola_id: [:id, :biola_id],
    netid: [:id, :netid],
    id_photo: [:photo, :id_card],
    profile_photo: [:photo, :profile]
  }.each do |meth, (scope, type)|
    define_method "#{meth}_changed?" do
      hash['scope'] == scope.to_s && (original['type'] == type.to_s || modified['type'] == type.to_s)
    end
  end

  private

  def changed_attrs
    @changed_attrs ||= (original.keys + modified.keys).uniq
  end

  def original
    hash['original']
  end

  def modified
    hash['modified']
  end

  def all_attrs
    hash['all_attributes']
  end
end
