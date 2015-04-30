module ServiceObjects
  class SyncADAccount < Base
    def call
      trogdir_person = TrogdirPerson.new(change.person_uuid)
      ADAccount.new(trogdir_person.netid).create_or_update! trogdir_person
    end

    def ignore?
      !(change.has_netid? && (
        change.first_name_changed? ||
        change.middle_name_changed? ||
        change.last_name_changed? ||
        change.preferred_name_changed? ||
        change.tile_changed? ||
        change.department_changed? ||
        change.employee_type_changed? ||
        change.university_email_changed? ||
        change.office_phone_changed? ||
        change.biola_id_changed? ||
        change.netid_changed? ||
        change.id_photo_changed? ||
        change.profile_photo_changed?
      ))
    end
  end
end

