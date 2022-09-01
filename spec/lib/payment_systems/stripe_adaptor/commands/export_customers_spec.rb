# frozen_string_literal: true

require 'rails_helper'
require 'stripe_mock'

describe PaymentSystems::StripeAdapter::Commands::ExportCustomers do
  let(:stripe_helper) { StripeMock.create_test_helper }
  before { StripeMock.start }
  after { StripeMock.stop }

  describe 'execute' do
    let(:file_name) { 'test-customers.csv' }
    before do
      100.times do |i|
        Stripe::Customer.create({
                                  email: "test#{i}@test.com",
                                  source: stripe_helper.generate_card_token
                                })
      end
    end
    after do
      FileUtils.rm_rf(Dir["#{Rails.root}/#{file_name}"])
    end

    context 'task run first time' do
      it 'should export customers from start' do
        expect(PaymentSystems::StripeAdapter::Commands::ExportCustomers.execute(file_name)).to eq(true)
        expect(CSV.read(file_name).count).to eq(100)
      end
    end

    context 'task run after quitting' do
      before do
        customers = Stripe::Customer.list(limit: 50)
        CSV.open(file_name, 'a+') do |csv|
          customers[:data].each do |customer|
            csv << [customer.id, customer.name, customer.email]
          end
        end
      end
      it 'should start exporting customers where it left from the last export' do
        expect(PaymentSystems::StripeAdapter::Commands::ExportCustomers.execute(file_name)).to eq(true)
        expect(CSV.read(file_name).count).to eq(100)
      end
    end
  end
end
