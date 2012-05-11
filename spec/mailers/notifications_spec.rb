require "spec_helper"

describe Notifications do

  def containsGuid(s)
    (s =~ /(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}/) != nil
  end

  describe "session_submit" do
    let(:presenter_email) { "presenter@company.nl" }
    let(:presenter_login_guid) { "b93e5a88-acf7-be64-af0b-6de00bd83fd3" }
    let(:session) { FactoryGirl.build(:session) } 
    let(:mail) { Notifications.session_submit(presenter_email,presenter_login_guid,session) }

    it "renders the headers" do
      mail.subject.should eq(I18n.t('notifications.session_submit.subject'))
      mail.to.should eq([presenter_email])
      mail.from.should eq([Notifications::FromAddress])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
      mail.body.encoded.should match session.title
      (containsGuid mail.body.encoded).should eq(true) 
    end
  end

end