class ADAccount
  class ADError < StandardError; end

  ADS_UF_SCRIPT                                 = 1        # 0x1
  ADS_UF_ACCOUNTDISABLE                         = 2        # 0x2
  ADS_UF_HOMEDIR_REQUIRED                       = 8        # 0x8
  ADS_UF_LOCKOUT                                = 16       # 0x10
  ADS_UF_PASSWD_NOTREQD                         = 32       # 0x20
  ADS_UF_PASSWD_CANT_CHANGE                     = 64       # 0x40
  ADS_UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED        = 128      # 0x80
  ADS_UF_TEMP_DUPLICATE_ACCOUNT                 = 256      # 0x100
  ADS_UF_NORMAL_ACCOUNT                         = 512      # 0x200
  ADS_UF_INTERDOMAIN_TRUST_ACCOUNT              = 2048     # 0x800
  ADS_UF_WORKSTATION_TRUST_ACCOUNT              = 4096     # 0x1000
  ADS_UF_SERVER_TRUST_ACCOUNT                   = 8192     # 0x2000
  ADS_UF_DONT_EXPIRE_PASSWD                     = 65536    # 0x10000
  ADS_UF_MNS_LOGON_ACCOUNT                      = 131072   # 0x20000
  ADS_UF_SMARTCARD_REQUIRED                     = 262144   # 0x40000
  ADS_UF_TRUSTED_FOR_DELEGATION                 = 524288   # 0x80000
  ADS_UF_NOT_DELEGATED                          = 1048576  # 0x100000
  ADS_UF_USE_DES_KEY_ONLY                       = 2097152  # 0x200000
  ADS_UF_DONT_REQUIRE_PREAUTH                   = 4194304  # 0x400000
  ADS_UF_PASSWORD_EXPIRED                       = 8388608  # 0x800000
  ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION = 16777216 # 0x1000000

  # WS set the ADS_UF_PASSWD_CANT_CHANGE. Not sure why. It doesn't seem like
  # AD even allows it
  DEFAULT_ACCTCONTROL = ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_NORMAL_ACCOUNT

  PRIVACY_ENTITLEMENT = 'urn:biola:privacy'

  attr_reader :cn
  alias :netid :cn

  def initialize(cn)
    raise ArgumentError, "cn can't be blank" if cn.blank?
    @cn = cn
  end

  def exists?
    entry.present?
  end

  def attributes
    return {} if entry.nil?

    @attributes ||= (
      attrs =  {}
      entry.each do |key, val|
        attrs[key] = val
      end
      attrs
    )
  end

  def create!(person)
    ldap do |ldap|
      ldap.add(dn: dn, attributes: ldap_create_attributes(person))
    end

    ldap do |ldap|
      ADAccount.groups_for(person).each do |group|
        ldap.modify dn: group, operations: [:add, :member, dn]
      end
    end

    :create
  end

  def update!(person)
    ldap do |ldap|
      ldap.modify(dn: dn, operations: ldap_update_operations(person))
    end

    ldap do |ldap|
      old_groups = Array(attributes[:memberof])
      new_groups = ADAccount.groups_for(person)
      ADAccount.managed_groups.each do |group|
        if old_groups.exclude?(group) && new_groups.include?(group)
          ldap.modify dn: group, operations: [[:add, :member, dn]]
        elsif old_groups.include?(group) && new_groups.exclude?(group)
          ldap.modify dn: group, operations: [[:delete, :member, dn]]
        end
      end
    end

    :update
  end

  def create_or_update!(person)
    if exists?
      update! person
    else
      create! person
    end
  end

  def self.cn_to_dn(cn)
    "CN=#{cn},#{Settings.ad.users_ou}"
  end

  def self.disable?(person)
    person.affiliations.blank?
  end

  def self.encode_password(password)
    # See https://msdn.microsoft.com/en-us/library/cc223248.aspx
    %{"#{password}"}.encode('utf-16le').force_encoding('utf-8')
  end

  def self.managed_groups
    Settings.sync.groups.to_h.values.flatten
  end

  def self.groups_for(person)
    Settings.sync.groups.map { |affiliation, groups|
      groups if person.affiliations.include? affiliation.to_s
    }.flatten.compact.uniq
  end

  private

  def dn
    ADAccount.cn_to_dn(cn)
  end

  def ldap_update_attributes(person)
    display_name = [(person.preferred_name.presence || person.first_name), person.last_name].reject(&:blank?).join(' ')
    principal_name = person.university_email.to_s.split('@').first
    photo_url = person.profile_photo || person.id_card_photo
    enabled = !ADAccount.disable?(person)
    description = person.description
    user_account_control = (DEFAULT_ACCTCONTROL + (enabled ? 0 : ADS_UF_ACCOUNTDISABLE)).to_s
    affiliations = (Array(attributes[:edupersonaffiliation]) - Settings.sync.affiliations + Array(person.affiliations)).uniq.sort
    entitlements = if person.privacy?
      (Array(attributes[:edupersonentitlement]) + [PRIVACY_ENTITLEMENT]).uniq.sort
    else
      (Array(attributes[:edupersonentitlement]) - [PRIVACY_ENTITLEMENT]).sort
    end

    {
      givenname: person.first_name,
      middlename: person.middle_name,
      sn: person.last_name,
      displayname: display_name,
      edupersonnickname: person.preferred_name,
      mail: person.university_email,
      telephonenumber: person.office_phone,
      ipphone: person.office_phone,
      employeeid: person.biola_id.try(:to_s),
      edupersonprincipalname: principal_name,
      department: person.department,
      edupersonaffiliation: affiliations,
      edupersonprimaryaffiliation: person.primary_affiliation,
      edupersonentitlement: entitlements,
      employeetype: person.employee_type,
      title: person.title,
      url: photo_url,
      description: description,
      useraccountcontrol: user_account_control
    }
  end

  def ldap_create_attributes(person)
    # 30 random hexadecimal characters
    password = ADAccount.encode_password(SecureRandom.hex(15))
    entitlements = [].tap do |ent|
      ent = Array(person.entitlements)
      ent += [PRIVACY_ENTITLEMENT] if person.privacy?
    end

    additional_attributes = {
      # TODO: trogdir uuid
      cn: cn,
      samaccountname: cn,
      objectclass: ['person', 'user', 'top', 'organizationalPerson'],
      edupersonaffiliation: person.affiliations,
      edupersonentitlement: entitlements,
      unicodepwd: password
    }

    attrs = ldap_update_attributes(person).merge additional_attributes
    attrs.reject { |key, val| val.blank? }
  end

  def ldap_update_operations(person)
    old_attrs = attributes
    new_attrs = ldap_update_attributes(person)

    operations = new_attrs.each_with_object([]) do |(key, val), ops|
      # Make sure that the new value isn't the value in LDAP
      if old_attrs[key] != Array(val)
        if !old_attrs[key].nil? && val.nil?
          ops << [:delete, key.to_sym, nil]
        else
          ops << [:replace, key.to_sym, val] # This will also add a new value
        end
      end
    end
  end

  def ldap(&block)
    Net::LDAP.open(Settings.ad.connection.to_hash) do |ldap|
      val = block.call(ldap)

      result = ldap.get_operation_result
      if result.code != 0
        raise ADError, "#{result.message}: #{result.each_pair.map{|k,v| "#{k}: #{v.inspect}"}.join(', ')}"
      end

      val
    end
  end

  def entry
    @entry ||= ldap { |l| l.search(filter: Net::LDAP::Filter.eq('cn', cn), base: Settings.ad.users_ou).first }
  end
end
