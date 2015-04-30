class TrogdirPerson
  class TrogdirAPIError < StandardError; end

  AFFILIATION_PRECEDENCE =['faculty', 'employee', 'volunteer', 'trustee', 'faculty emeritus', 'student worker', 'student', 'alumnus', 'accepted student']

  attr_reader :uuid

  def initialize(uuid)
    @uuid = uuid
  end

  %w[first_name preferred_name middle_name last_name title department affiliations entitlements employee_type privacy].each do |meth|
    define_method(meth) do
      hash[meth]
    end
  end
  alias :privacy? :privacy

  def netid
    get_value_from_nested_record(:ids, :netid, :identifier)
  end

  def biola_id
    biola_id = get_value_from_nested_record(:ids, :biola_id, :identifier)
    biola_id.to_i unless biola_id.nil?
  end

  def university_email
    get_value_from_nested_record(:emails, :university, :address)
  end

  def office_phone
    get_value_from_nested_record(:phones, :office, :number)
  end

  def id_card_photo
    get_value_from_nested_record(:photos, :id_card, :url)
  end

  def profile_photo
    get_value_from_nested_record(:photos, :profile, :url)
  end

  def description
    # Not sure why they don't get a description if they don't have a biola_id.
    # That's the way the old system did it so I'm sticking with it.
    return nil if biola_id.blank?

    title_n_dept = [title, department].reject(&:blank?).join(', ')

    "#{title_n_dept.presence || friendly_affiliation} - #{biola_id}"
  end

  def primary_affiliation
    AFFILIATION_PRECEDENCE.find { |aff| affiliations.include? aff }
  end

  private

  def friendly_affiliation
    primary_affiliation.to_s.humanize.presence || 'No affiliations'
  end

  def hash
    @hash ||= (
      response = Trogdir::APIClient::People.new.show(uuid: uuid).perform
      raise TrogdirAPIError, response.parse['error'] unless response.success?
      response.parse
    )
  end

  def get_value_from_nested_record(collection, type, return_attr)
    record = Array(hash[collection.to_s]).find { |record| record['type'] == type.to_s }
    record[return_attr.to_s] unless record.nil?
  end
end
