require 'spec_helper'

describe FreshConnection do
  it 'should have a version number' do
    FreshConnection::VERSION.should_not be_nil
  end
end
