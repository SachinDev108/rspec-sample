# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CallCenterSerializer do
  let(:call_center) { build(:call_center, name: 'Call Center Name') }

  subject(:json) { CallCenterSerializer.new(call_center).to_json }

  it 'returns successfully' do
    expect(JSON.parse(json)).to eq(
      'name'                              => 'Call Center Name',
      'call_center_open'                  => true,
      'cc_type'                           => 'Default',
      'trigger_call_active'               => false,
      'trigger_call_frequency_in_minutes' => nil,
      'trigger_call_phone_number'         => nil,
      'virtualq_active'                   => true
    )
  end
end
