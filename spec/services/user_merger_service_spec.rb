require 'spec_helper'

describe UserMergerService do
  let(:user) {create(:user)}
  let(:duplicates) {create_list(:user, 3)}
  let(:duplicate_ids) { duplicates.collect(&:id) }

  context 'when merging a user' do
    context ' with itself' do
      it 'should not perform any actions' do
        Item.should_not_receive(:update_all)
        Item.should_not_receive(:update_all)
        ItemUser.should_not_receive(:update_all)
        ItemAdmin.should_not_receive(:update_all)
        ItemAgent.should_not_receive(:update_all)

        user.should_not_receive(:destroy)
        user.should_not_receive(:save)

        UserMergerService.new(user, [user]).call
      end
    end

    context 'with empty array' do
      it 'should not perform any actions' do
        Item.should_not_receive(:update_all)
        Item.should_not_receive(:update_all)
        ItemUser.should_not_receive(:update_all)
        ItemAdmin.should_not_receive(:update_all)
        ItemAgent.should_not_receive(:update_all)

        user.should_not_receive(:destroy)
        user.should_not_receive(:save)

        UserMergerService.new(user, []).call
      end
    end
    context 'with nil' do
      it 'should not perform any actions' do
        Item.should_not_receive(:update_all)
        Item.should_not_receive(:update_all)
        ItemUser.should_not_receive(:update_all)
        ItemAdmin.should_not_receive(:update_all)
        ItemAgent.should_not_receive(:update_all)

        user.should_not_receive(:destroy)
        user.should_not_receive(:save)

        UserMergerService.new(user, nil).call
      end
    end

    context 'with other users' do
      context 'including the primary user' do
        it 'should only merge other users, not the primary' do
          Item.should_receive(:update_all).with({collector_id: user.id}, {collector_id: duplicate_ids})
          Item.should_receive(:update_all).with({operator_id: user.id}, {operator_id: duplicate_ids})
          ItemUser.should_receive(:update_all).with({user_id: user.id}, {user_id: duplicate_ids})
          ItemAdmin.should_receive(:update_all).with({user_id: user.id}, {user_id: duplicate_ids})
          ItemAgent.should_receive(:update_all).with({user_id: user.id}, {user_id: duplicate_ids})

          user.should_not_receive(:destroy)
          user.should_receive(:save)

          duplicates.each do |dup|
            dup.should_receive(:destroy)
          end

          UserMergerService.new(user, [user] + duplicates).call
        end
      end
      context 'not including the primary user' do
        it 'should merge other users' do
          Item.should_receive(:update_all).with({collector_id: user.id}, {collector_id: duplicate_ids})
          Item.should_receive(:update_all).with({operator_id: user.id}, {operator_id: duplicate_ids})
          ItemUser.should_receive(:update_all).with({user_id: user.id}, {user_id: duplicate_ids})
          ItemAdmin.should_receive(:update_all).with({user_id: user.id}, {user_id: duplicate_ids})
          ItemAgent.should_receive(:update_all).with({user_id: user.id}, {user_id: duplicate_ids})

          user.should_not_receive(:destroy)
          user.should_receive(:save)

          duplicates.each do |dup|
            dup.should_receive(:destroy)
          end

          UserMergerService.new(user, duplicates).call
        end
      end
    end
  end
end