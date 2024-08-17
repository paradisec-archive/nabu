require 'spec_helper'

describe UserMergerService do
  let(:user) { create(:user) }
  let(:duplicates) { create_list(:user, 3) }
  let(:duplicate_ids) { duplicates.collect(&:id) }

  context 'when merging a user' do
    context ' with itself' do
      it 'should not perform any actions' do
        expect(Item).not_to receive(:update_all)
        expect(Item).not_to receive(:update_all)
        expect(ItemUser).not_to receive(:update_all)
        expect(ItemAdmin).not_to receive(:update_all)
        expect(ItemAgent).not_to receive(:update_all)

        expect(user).not_to receive(:destroy)
        expect(user).not_to receive(:save)

        UserMergerService.new(user, [user]).call
      end
    end

    context 'with empty array' do
      it 'should not perform any actions' do
        expect(Item).not_to receive(:update_all)
        expect(Item).not_to receive(:update_all)
        expect(ItemUser).not_to receive(:update_all)
        expect(ItemAdmin).not_to receive(:update_all)
        expect(ItemAgent).not_to receive(:update_all)

        expect(user).not_to receive(:destroy)
        expect(user).not_to receive(:save)

        UserMergerService.new(user, []).call
      end
    end
    context 'with nil' do
      it 'should not perform any actions' do
        expect(Item).not_to receive(:update_all)
        expect(Item).not_to receive(:update_all)
        expect(ItemUser).not_to receive(:update_all)
        expect(ItemAdmin).not_to receive(:update_all)
        expect(ItemAgent).not_to receive(:update_all)

        expect(user).not_to receive(:destroy)
        expect(user).not_to receive(:save)

        UserMergerService.new(user, nil).call
      end
    end

    context 'with other users' do
      context 'including the primary user' do
        it 'should only merge other users, not the primary' do
          expect(Item).to receive(:update_all).with({ collector_id: user.id }, { collector_id: duplicate_ids })
          expect(Item).to receive(:update_all).with({ operator_id: user.id }, { operator_id: duplicate_ids })
          expect(ItemUser).to receive(:update_all).with({ user_id: user.id }, { user_id: duplicate_ids })
          expect(ItemAdmin).to receive(:update_all).with({ user_id: user.id }, { user_id: duplicate_ids })
          expect(ItemAgent).to receive(:update_all).with({ user_id: user.id }, { user_id: duplicate_ids })

          expect(user).not_to receive(:destroy)
          expect(user).to receive(:save)

          duplicates.each do |dup|
            expect(dup).to receive(:destroy)
          end

          UserMergerService.new(user, [user] + duplicates).call
        end
      end
      context 'not including the primary user' do
        it 'should merge other users' do
          expect(Item).to receive(:update_all).with({ collector_id: user.id }, { collector_id: duplicate_ids })
          expect(Item).to receive(:update_all).with({ operator_id: user.id }, { operator_id: duplicate_ids })
          expect(ItemUser).to receive(:update_all).with({ user_id: user.id }, { user_id: duplicate_ids })
          expect(ItemAdmin).to receive(:update_all).with({ user_id: user.id }, { user_id: duplicate_ids })
          expect(ItemAgent).to receive(:update_all).with({ user_id: user.id }, { user_id: duplicate_ids })

          expect(user).not_to receive(:destroy)
          expect(user).to receive(:save)

          duplicates.each do |dup|
            expect(dup).to receive(:destroy)
          end

          UserMergerService.new(user, duplicates).call
        end
      end
    end
  end
end
