module ServiceObjects
  class SyncADAccount < Base
    def call
      trogdir_person = TrogdirPerson.new(change.person_uuid)
      ADAccount.new(trogdir_person.netid).create_or_update! trogdir_person
    end

    def ignore?
      !(change.has_netid? && (
        change.uuid_changed? ||
        change.first_name_changed? ||
        change.middle_name_changed? ||
        change.last_name_changed? ||
        change.preferred_name_changed? ||
        change.title_changed? ||
        change.department_changed? ||
        change.employee_type_changed? ||
        change.affiliations_changed? ||
        change.university_email_changed? ||
        change.office_phone_changed? ||
        change.biola_id_changed? ||
        change.netid_changed? ||
        change.banner_udcid_changed? ||
        change.id_photo_changed? ||
        change.profile_photo_changed?
      ))
    end
  end
end

