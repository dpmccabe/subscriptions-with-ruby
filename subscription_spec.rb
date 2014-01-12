require 'rspec'
require_relative ('subscription')

module SubscriptionSpecHelpers
  def residues(subscriptions)
    subscriptions.map(&:residue)
  end

  def unique_residues(subscriptions)
    subscriptions.map(&:residue).uniq
  end

  def beginning
    Subscription.beginning
  end
end

describe Subscription do
  include SubscriptionSpecHelpers

  describe '.initialize' do
    context 'daily frequency' do
      subject { Subscription.new(interval: 14, start_date: Date.tomorrow) }

      its(:interval) { should eq(14) }
      its(:start_date) { should eq(Date.tomorrow) }
      its(:frequency) { should eq(:daily) }
    end

    context 'monthly frequency' do
      subject { Subscription.new(interval: 14, start_date: Date.tomorrow, frequency: :monthly) }

      its(:interval) { should eq(14) }
      its(:start_date) { should eq(Date.tomorrow) }
      its(:frequency) { should eq(:monthly) }
    end
  end

  describe '#residue' do
    context 'when the frequency is daily' do
      context 'when interval is weekly' do
        it 'computes members of the residue class 0' do
          subscriptions = [
            Subscription.new(interval: 7, start_date: beginning),
            Subscription.new(interval: 7, start_date: beginning + 7.days),
            Subscription.new(interval: 7, start_date: beginning + 70.days)
          ]

          expect(unique_residues(subscriptions)).to eq([0])
        end

        it 'computes members of the residue class 1' do
          subscriptions = [
            Subscription.new(interval: 7, start_date: beginning + 1.day),
            Subscription.new(interval: 7, start_date: beginning + 8.days),
            Subscription.new(interval: 7, start_date: beginning + 71.days)
          ]

          expect(unique_residues(subscriptions)).to eq([1])
        end

        it 'computes members of all possible residue classes' do
          subscriptions = [
            Subscription.new(interval: 7, start_date: beginning),
            Subscription.new(interval: 7, start_date: beginning + 1.day),
            Subscription.new(interval: 7, start_date: beginning + 2.days),
            Subscription.new(interval: 7, start_date: beginning + 3.days),
            Subscription.new(interval: 7, start_date: beginning + 4.days),
            Subscription.new(interval: 7, start_date: beginning + 5.days),
            Subscription.new(interval: 7, start_date: beginning + 6.days),
            Subscription.new(interval: 7, start_date: beginning + 7.days)
          ]

          expect(residues(subscriptions)).to eq([0, 1, 2, 3, 4, 5, 6, 0])
        end
      end

      context 'when interval is every 100 days' do
        it 'computes members of the residue class 0' do
          subscriptions = [
            Subscription.new(interval: 100, start_date: beginning),
            Subscription.new(interval: 100, start_date: beginning + 100.days),
            Subscription.new(interval: 100, start_date: beginning + 500.days)
          ]

          expect(unique_residues(subscriptions)).to eq([0])
        end

        it 'computes members of the residue class 1' do
          subscriptions = [
            Subscription.new(interval: 100, start_date: beginning + 1.day),
            Subscription.new(interval: 100, start_date: beginning + 101.days),
            Subscription.new(interval: 100, start_date: beginning + 501.days)
          ]

          expect(unique_residues(subscriptions)).to eq([1])
        end
      end
    end

    context 'when the frequency is monthly' do
      context 'when interval is every 5 months' do
        it 'computes members of the residue class 0' do
          subscriptions = [
            Subscription.new(frequency: :monthly, interval: 5, start_date: beginning),
            Subscription.new(frequency: :monthly, interval: 5, start_date: beginning + 5.months),
            Subscription.new(frequency: :monthly, interval: 5, start_date: beginning + 20.months)
          ]

          expect(unique_residues(subscriptions)).to eq([0])
        end

        it 'computes members of the residue class 1' do
          subscriptions = [
            Subscription.new(frequency: :monthly, interval: 5, start_date: beginning + 1.month),
            Subscription.new(frequency: :monthly, interval: 5, start_date: beginning + 6.months),
            Subscription.new(frequency: :monthly, interval: 5, start_date: beginning + 51.months)
          ]

          expect(unique_residues(subscriptions)).to eq([1])
        end

        it 'computes members of all possible residue classes' do
          subscriptions = [
            Subscription.new(frequency: :monthly, interval: 5, start_date: beginning),
            Subscription.new(frequency: :monthly, interval: 5, start_date: beginning + 1.month),
            Subscription.new(frequency: :monthly, interval: 5, start_date: beginning + 2.months),
            Subscription.new(frequency: :monthly, interval: 5, start_date: beginning + 3.months),
            Subscription.new(frequency: :monthly, interval: 5, start_date: beginning + 4.months),
            Subscription.new(frequency: :monthly, interval: 5, start_date: beginning + 5.months)
          ]

          expect(residues(subscriptions)).to eq([0, 1, 2, 3, 4, 0])
        end
      end
    end
  end

  describe '#interval=' do
    it 'updates the residue when the interval changes' do
      subscription = Subscription.new(interval: 30, start_date: beginning + 10.days)
      subscription.interval = 9

      expect(subscription.residue).to eq(1)
    end
  end

  describe '#start_date=' do
    it 'updates the residue when the start_date changes' do
      subscription = Subscription.new(interval: 30, start_date: beginning + 10.days)
      subscription.start_date = beginning + 5.days

      expect(subscription.residue).to eq(5)
    end
  end

  describe '#process_on?' do
    context 'when the frequency is daily' do
      context 'when the subscription is biweekly and starts 5 days after the beginning' do
        let(:subscription) { Subscription.new(interval: 14, start_date: beginning + 5.days) }

        it 'processes it on its start date' do
          expect(subscription.process_on?(beginning + 5.days)).to be_true
        end

        it 'processes it on its next processing date' do
          expect(subscription.process_on?(beginning + 5.days + 14.days)).to be_true
        end

        it 'does not process it on the day after its next processing date' do
          expect(subscription.process_on?(beginning + 5.days + 15.days)).to be_false
        end
      end

      context 'when the subscription is every 30 days and starts 11 days after the beginning' do
        let(:subscription) { Subscription.new(interval: 30, start_date: beginning + 11.days) }

        it 'processes it on its start date' do
          expect(subscription.process_on?(beginning + 11.days)).to be_true
        end

        it 'processes it on its next processing date' do
          expect(subscription.process_on?(beginning + 11.days + 30.days)).to be_true
        end

        it 'does not process it on the day before its next processing date' do
          expect(subscription.process_on?(beginning + 11.days + 29.days)).to be_false
        end
      end
    end

    context 'when the frequency is monthly' do
      context 'when the subscription is every 3 months and starts 2 months after the beginning' do
        let(:subscription) { Subscription.new(frequency: :monthly, interval: 3, start_date: beginning + 2.months) }

        it 'processes it on its start date' do
          expect(subscription.process_on?(beginning + 2.months)).to be_true
        end

        it 'processes it on its next processing date' do
          expect(subscription.process_on?(beginning + 2.months + 3.months)).to be_true
        end

        it 'does not process it on the month after its next processing date' do
          expect(subscription.process_on?(beginning + 2.months + 4.months)).to be_false
        end
      end
    end
  end

  describe '#next_processing_date' do
    context 'when the frequency is daily' do
      context 'when the subscription is every 21 days and starts at the beginning' do
        let(:subscription) { Subscription.new(interval: 21, start_date: beginning) }

        it 'calculates the first processing date' do
          expect(subscription.next_processing_date(beginning)).to eq(beginning)
        end

        it 'calculates the next processing date 1 day later' do
          expect(subscription.next_processing_date(beginning + 1.day)).to eq(beginning + 21.days)
        end

        it 'calculates the next processing date 10 days later' do
          expect(subscription.next_processing_date(beginning + 10.days)).to eq(beginning + 21.days)
        end

        it 'calculates the next processing date 21 days later' do
          expect(subscription.next_processing_date(beginning + 21.days)).to eq(beginning + 21.days)
        end

        it 'calculates the third processing date 25 days later' do
          expect(subscription.next_processing_date(beginning + 25.days)).to eq(beginning + 42.days)
        end
      end

      context 'when the subscription is every 10 days and starts 4 days after the beginning' do
        let(:subscription) { Subscription.new(interval: 10, start_date: beginning + 4.days) }

        it 'calculates the first processing date' do
          expect(subscription.next_processing_date(beginning + 4.days)).to eq(beginning + 4.days)
        end

        it 'calculates the next processing date 1 day later' do
          expect(subscription.next_processing_date(beginning + 5.days)).to eq(beginning + 14.days)
        end

        it 'calculates the next processing date 9 days later' do
          expect(subscription.next_processing_date(beginning + 13.days)).to eq(beginning + 14.days)
        end

        it 'calculates the next processing date 10 days later' do
          expect(subscription.next_processing_date(beginning + 14.days)).to eq(beginning + 14.days)
        end

        it 'calculates the third processing date 17 days later' do
          expect(subscription.next_processing_date(beginning + 21.days)).to eq(beginning + 24.days)
        end
      end
    end

    context 'when the frequency is monthly' do
      context 'when the subscription is every 4 months and starts at the beginning' do
        let(:subscription) { Subscription.new(frequency: :monthly, interval: 4, start_date: beginning) }

        it 'calculates the first processing date' do
          expect(subscription.next_processing_date(beginning)).to eq(beginning)
        end

        it 'calculates the next processing date 1 month later' do
          expect(subscription.next_processing_date(beginning + 1.month)).to eq(beginning + 4.months)
        end

        it 'calculates the next processing date 4 months later' do
          expect(subscription.next_processing_date(beginning + 4.months)).to eq(beginning + 4.months)
        end

        it 'calculates the next processing date 5 months later' do
          expect(subscription.next_processing_date(beginning + 5.months)).to eq(beginning + 8.months)
        end

        it 'calculates the processing date 25 months later' do
          expect(subscription.next_processing_date(beginning + 25.months)).to eq(beginning + 28.months)
        end
      end
    end
  end

  describe '#next_n_processing_dates' do
    context 'when the frequency is daily' do
      context 'when the subscription is every 7 days and starts 31 days after the beginning' do
        let(:subscription) { Subscription.new(interval: 7, start_date: beginning + 31.days) }

        it 'calculates the next 5 processing dates 1 day after the first processing' do
          expect(subscription.next_n_processing_dates(5, beginning + 32.days)).to eq([
            beginning + 38.days,
            beginning + 45.days,
            beginning + 52.days,
            beginning + 59.days,
            beginning + 66.days
          ])
        end
      end

      context 'when the subscription is every 40 days and starts 11 days after the beginning' do
        let(:subscription) { Subscription.new(interval: 40, start_date: beginning + 11.days) }

        it 'calculates the next 3 processing dates 100 days after the first processing' do
          expect(subscription.next_n_processing_dates(3, beginning + 111.days)).to eq([
            beginning + 131.days,
            beginning + 171.days,
            beginning + 211.days
          ])
        end
      end
    end

    context 'when the frequency is monthly' do
      context 'when the subscription is every 7 months and starts 3 months after the beginning' do
        let(:subscription) { Subscription.new(frequency: :monthly, interval: 7, start_date: beginning + 3.months) }

        it 'calculates the next 5 processing dates 1 month after the first processing' do
          expect(subscription.next_n_processing_dates(5, beginning + 4.months)).to eq([
            beginning + 10.months,
            beginning + 17.months,
            beginning + 24.months,
            beginning + 31.months,
            beginning + 38.months
          ])
        end
      end
    end
  end
end
