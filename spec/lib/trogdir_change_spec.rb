require 'spec_helper'

describe TrogdirChange do
  # TODO: test other fixtures
  let(:hash) { JSON.parse(File.read('./spec/fixtures/update_person_name.json')) }
  subject { TrogdirChange.new(hash) }

  describe '#sync_log_id' do
    it { expect(subject.sync_log_id).to eql '000000000000000000000000'}
  end

  describe '#person_uuid' do
    it { expect(subject.person_uuid).to eql '00000000-0000-0000-0000-000000000000'}
  end

  describe '#preferred_name_changed?' do
    it { expect(subject.preferred_name_changed?).to be true}
  end

  describe '#first_name_changed?' do
    it { expect(subject.first_name_changed?).to be false}
  end

  describe '#middle_name_changed?' do
    it { expect(subject.middle_name_changed?).to be false}
  end

  describe '#last_name_changed' do
    it { expect(subject.last_name_changed?).to be false}
  end

  describe '#title_changed?' do
    it { expect(subject.title_changed?).to be false}
  end

  describe '#department_changed' do
    it { expect(subject.department_changed?).to be false}
  end

  describe '#employee_type_changed' do
    it { expect(subject.employee_type_changed?).to be false}
  end

  describe '#university_email_changed?' do
    it { expect(subject.university_email_changed?).to be false}
  end

  describe '#office_phone_changed?' do
    it { expect(subject.office_phone_changed?).to be false}
  end

  describe '#biola_id_changed?' do
    it { expect(subject.biola_id_changed?).to be false}
  end

  describe '#netid_changed?' do
    it { expect(subject.netid_changed?).to be false}
  end

  describe '#id_photo_changed?' do
    it { expect(subject.id_photo_changed?).to be false}
  end

  describe '#profile_photo_changed?' do
    it { expect(subject.profile_photo_changed?).to be false}
  end
end
