require 'spec_helper'

describe ServiceObjects::SyncADAccount do
  let(:hash) { JSON.parse(File.read('./spec/fixtures/update_person_name.json')) }
  let(:trogdir_change) { TrogdirChange.new(hash) }
  subject { ServiceObjects::SyncADAccount.new(trogdir_change) }

  describe '#ignore?' do
    context 'when updating a preferred_name' do
      it 'is false' do
        expect(subject.ignore?).to be false
      end
    end
  end
end
