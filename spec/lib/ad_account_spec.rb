require 'spec_helper'

describe ADAccount do
  let(:cn) { 'johnd0' }
  subject { ADAccount.new(cn) }

  describe '#cn' do
    it 'initializes with cn' do
      expect { subject.cn.to eql 'johnd0' }
    end
  end

  describe '#exists?' do
    context 'when there is no entry' do
      it 'is false hen there ' do
        expect(subject).to receive(:entry).and_return nil
        expect(subject.exists?).to be false
      end
    end

    context 'when there is an entry' do
      it 'is true' do
        expect(subject).to receive(:entry).and_return instance_double(Net::LDAP::Entry)
        expect(subject.exists?).to be true
      end
    end
  end

  describe '#attributes' do
    it 'returns a hash' do
      expect(subject).to receive(:entry).at_least(:once).and_return Net::LDAP::Entry.from_single_ldif_string(File.read('./spec/fixtures/mickeymouse.ldif'))
      expect(subject.attributes.keys.sort).to eql [:accountexpires, :badpasswordtime, :badpwdcount, :cn, :codepage, :countrycode, :department, :description, :displayname, :distinguishedname, :dn, :dscorepropagationdata, :edupersonaffiliation, :edupersonentitlement, :edupersonnickname, :edupersonprimaryaffiliation, :edupersonprincipalname, :employeeid, :givenname, :instancetype, :lastlogoff, :lastlogon, :lastlogontimestamp, :logoncount, :logonhours, :mail, :memberof, :name, :objectcategory, :objectclass, :objectguid, :objectsid, :primarygroupid, :pwdlastset, :samaccountname, :samaccounttype, :sn, :title, :url, :useraccountcontrol, :usnchanged, :usncreated, :whenchanged, :whencreated].sort
      expect(subject.attributes[:cn]).to eql ['mickeymouse']
      expect(subject.attributes[:department]).to eql ['Disneyland']
      expect(subject.attributes[:description]).to eql ['Mouse, Disneyland - 800001385']
      expect(subject.attributes[:displayname]).to eql ['Mickey Mouse']
      expect(subject.attributes[:dn]).to eql ['CN=mickeymouse,OU=Biola Users,DC=ad,DC=biola,DC=edu']
      expect(subject.attributes[:edupersonaffiliation]).to eql ["robot", "student", "alumnus"]
      expect(subject.attributes[:edupersonentitlement]).to eql ["urn:biola:library:millennium"]
      expect(subject.attributes[:edupersonnickname]).to eql ["Mickey"]
      expect(subject.attributes[:edupersonprimaryaffiliation]).to eql ["student"]
      expect(subject.attributes[:edupersonprincipalname]).to eql ["mickey.a.mouse"]
      expect(subject.attributes[:employeeid]).to eql ["800001385"]
      expect(subject.attributes[:givenname]).to eql ["Mickey"]
      expect(subject.attributes[:mail]).to eql ["mickey.a.mouse@biola.edu"]
      expect(subject.attributes[:memberof]).to eql ["CN=biolastudents,OU=Biola Security Groups,DC=ad,DC=biola,DC=edu"]
      expect(subject.attributes[:name]).to eql ["mickeymouse"]
      expect(subject.attributes[:samaccountname]).to eql ["mickeymouse"]
      expect(subject.attributes[:sn]).to eql ["Mouse"]
      expect(subject.attributes[:title]).to eql ["Mouse"]
      expect(subject.attributes[:url]).to eql ["http://dropbox.biola.edu/mickeymouse"]
      expect(subject.attributes[:useraccountcontrol]).to eql ["512"]
    end
  end

  describe '#create!' do
    pending
  end

  describe '#update!' do
    pending
  end

  describe '#create_or_update!' do
    let(:person) { TrogdirPerson.new('000000-00000-00000000') }

    context "when ldap record doesn't exist" do
      it 'calls create!' do
        expect(subject).to receive(:exists?).and_return false
        expect(subject).to receive(:create!).with person
        subject.create_or_update! person
      end
    end

    context "when ldap record doesn't exist" do
      it 'calls update!' do
        expect(subject).to receive(:exists?).and_return true
        expect(subject).to receive(:update!).with person
        subject.create_or_update! person
      end
    end
  end

  describe '.cn_to_dn' do
    it 'creates a valid distinguised name' do
      expect(ADAccount.cn_to_dn('johnd0')).to eql 'CN=johnd0,OU=Biola Users,DC=adtest,DC=biola,DC=edu'
    end
  end

  describe '.disable?' do
    context 'when a person has no affiliations' do
      let(:person) { double TrogdirPerson, affiliations: [] }

      it 'is true' do
        expect(ADAccount.disable?(person)).to be true
      end
    end

    context 'when person has affiliations' do
      let(:person) { double TrogdirPerson, affiliations: ['student'] }

      it 'is false' do
        expect(ADAccount.disable?(person)).to be false
      end
    end
  end

  describe '.encode_password' do
    it 'encodes the password' do
      expect(ADAccount.encode_password('guest')).to eql "\"\u0000g\u0000u\u0000e\u0000s\u0000t\u0000\"\u0000"
    end
  end
end
