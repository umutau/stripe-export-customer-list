# frozen_string_literal: true

require 'rubygems'
require 'stripe'
require 'csv'

# Connect payment system to call APIs
module PaymentSystems
  module StripeAdapter
    module Commands
      # export list of customer into csv file
      class ExportCustomers
        class << self
          READ_OPERATION_PER_SECOND = 25 # TODO: this is 100 for live mode, it should set as env variable
          MIN_INTERVAL = 1 / READ_OPERATION_PER_SECOND.to_f
          Stripe.api_key = Rails.application.credentials[:STRIPE_API_KEY]

          def execute(file_name = 'customers.csv')
            @last_operation_time = Time.now
            last_customer_id = last_customer_id_from_file(file_name)
            CSV.open(file_name, 'a+') do |csv|
              loop do
                customers = customer_list(last_customer_id)
                return false unless customers.present?

                @tried_rate_limit = 0
                customers[:data].each do |customer|
                  last_customer_id = customer.id
                  csv << [customer.id, customer.name, customer.email]
                end
                break unless customers[:has_more]
              end
            end
            true
          end

          private

          # call stripe and return list of customers
          def customer_list(last_customer_id)
            rate_limited
            Stripe::Customer.list(limit: 50, starting_after: last_customer_id)
          rescue Stripe::RateLimitError
            retry if (@tried_rate_limited += 1) < 3
            false
          rescue StandardError
            false
          end

          # sleep if last operation time is less than MIN_INTERVAL
          def rate_limited
            elapsed = Time.now - @last_operation_time
            left_to_wait = MIN_INTERVAL - elapsed
            sleep(left_to_wait) if left_to_wait.positive?
            @last_operation_time = Time.now
          end

          # return last customer id from file
          def last_customer_id_from_file(file_name = 'customers.csv')
            return unless File.exist?(file_name)

            CSV.read(file_name).last[0] if CSV.read(file_name).last
          end
        end
      end
    end
  end
end
