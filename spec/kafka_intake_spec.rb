# frozen_string_literal: true

RSpec.describe KafkaIntake do
  it "has a version number" do
    expect(KafkaIntake::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
