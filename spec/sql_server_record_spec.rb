require "spec_helper"

RSpec.describe SqlServerRecord do
  it "has a version number" do
    expect(SqlServerRecord::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
