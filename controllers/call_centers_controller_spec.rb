# frozen_string_literal: true
require 'rails_helper'

RSpec.describe API::V2::CallCentersController, type: :controller do
  describe 'GET #index' do
    context 'with a user' do
      let(:user) { create(:user) }
      let!(:call_center) { create_manageable_call_center(user) }

      before do
        create(:call_center)

        api_key(user.token!)
        get :index
      end

      it 'returns manageable call centers successfully' do
        expect(response).to serialize_collection(
          [call_center]
        ).with(CallCenterSerializer)
      end
    end

    context 'without a user' do
      it 'return 403 forbidden' do
        get :index
        expect(response).to have_api_error_code(:unauthorized)
      end
    end
  end

  describe 'GET #show' do
    context 'with a user' do
      context 'with invalid credentials' do
        before do
          api_key('invalid-api-key')
          get :show, id: 'invalid'
        end

        it 'returns 401 unauthorized' do
          expect(response).to have_api_error_code(:unauthorized)
        end
      end

      context 'with valid credentials' do
        let(:user) { create(:user) }

        before { api_key(user.token!) }

        context 'when call center does not exist' do
          it 'returns 404 not found' do
            get :show, id: '_'
            expect(response).to have_api_error_code(:not_found)
          end
        end

        context 'when user cannot manage call center' do
          let(:call_center) { create(:call_center) }

          it 'return 403 forbidden' do
            get :show, id: call_center.id
            expect(response).to have_api_error_code(:forbidden)
          end
        end

        context 'when user can manage call center' do
          let(:call_center) { create_manageable_call_center(user) }

          it 'returns successfully' do
            get :show, id: call_center.id
            expect(response).to serialize_object(call_center).with(CallCenterSerializer)
          end
        end
      end
    end
  end

  describe 'POST #create' do
    context 'without a user' do
      it 'returns 401 unauthorized' do
        post :create
        expect(response).to have_api_error_code(:unauthorized)
      end
    end

    context 'with valid credentials' do
      let(:user) { create(:user) }

      before { api_key(user.token!) }

      context 'with an invalid type' do
        it 'returns 422 unprocessable_entity' do
          post :create, data: { type: '--' }
          expect(response).to have_api_error_code(:unprocessable_entity)
        end
      end

      context 'with invalid attributes' do
        let(:data) do
          { type: 'call_centers', attributes: { name: nil } }
        end

        it 'returns an error document' do
          post :create, data: data
          expect(response).to have_unprocessable_entity_error(name: "can't be blank")
        end
      end

      context 'with valid attributes' do
        let(:data) { { type: 'call_centers', attributes: { name: 'A Valid Name' } } }

        it 'creates the record and returns successfully' do
          expect { post :create, data: data }.to change { CallCenter.count }.by(1)
          expect(response).to serialize_object(CallCenter.last).with(CallCenterSerializer)
        end

        it 'returns a call center that is owned by the current user' do
          post :create, data: data

          call_center = CallCenter.find(JSON.parse(response.body)['data']['id'])

          expect(call_center.users).to include(user)
        end
      end
    end
  end

  describe 'PATCH #update' do
    context 'without a user' do
      it 'returns 401 unauthorized' do
        patch :update, id: 'any'
        expect(response).to have_api_error_code(:unauthorized)
      end
    end

    context 'with valid credentials' do
      let(:user) { create(:user) }
      let(:call_center) { create_manageable_call_center(user, name: 'Old name') }

      before { api_key(user.token!) }

      context 'when call center does not exist' do
        it 'returns 404 not found' do
          patch :update, id: '_'
          expect(response).to have_api_error_code(:not_found)
        end
      end

      context 'with invalid attributes' do
        let(:data) { { type: 'call_centers', attributes: { name: nil } } }

        it 'returns an error document' do
          patch :update, id: call_center.id, data: data
          expect(response).to have_unprocessable_entity_error(name: "can't be blank")
        end
      end

      context 'with valid attributes' do
        let(:data) { { type: 'call_centers', attributes: { name: 'A Valid Name' } } }

        it 'updates the record and returns successfully' do
          expect { patch :update, id: call_center.id, data: data }.to change {
            call_center.reload.name
          }.to('A Valid Name')

          expect(response).to serialize_object(call_center).with(CallCenterSerializer)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'without a user' do
      it 'returns 401 unauthorized' do
        delete :destroy, id: 'any'
        expect(response).to have_api_error_code(:unauthorized)
      end
    end

    context 'with valid credentials' do
      let(:user) { create(:user) }

      before { api_key(user.token!) }

      context 'when call center does not exist' do
        it 'returns 404 not found' do
          delete :destroy, id: '_'
          expect(response).to have_api_error_code(:not_found)
        end
      end

      context 'when user cannot manage call center' do
        let(:call_center) { create(:call_center) }

        it 'return 403 forbidden' do
          delete :destroy, id: call_center.id
          expect(response).to have_api_error_code(:forbidden)
        end
      end

      context 'when user can manage call center' do
        let(:call_center) { create_manageable_call_center(user) }

        it 'marks the record as deleted' do
          expect { delete :destroy, id: call_center.id }.to change {
            call_center.reload.deleted_at
          }.from(nil)
        end

        it 'returns successfully' do
          delete :destroy, id: call_center.id
          expect(response.code).to eq('204')
        end
      end
    end
  end
end
