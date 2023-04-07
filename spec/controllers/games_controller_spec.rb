require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  describe '#show' do
    context 'when anonim' do
      before { get :show, id: game_w_questions.id }

      it 'return status is not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to authorization' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'return alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when authorized' do
      before do
        sign_in user
        get :show, id: game_w_questions.id
      end

      let(:game) { assigns(:game) }

      it 'return false' do
        expect(game.finished?).to be false
      end

      it 'return user' do
        expect(game.user).to eq(user)
      end

      it 'return status 200' do
        expect(response.status).to eq(200)
      end

      it 'render show' do
        expect(response).to render_template('show')
      end
    end

    context 'new game' do
      let!(:new_game) { FactoryBot.create(:game_with_questions) }
      before { get :show, id: new_game.id }

      it 'return status is not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to root path' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'return flash alert' do
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#create' do
    context 'when anonim' do
      before { post :create }

      it 'return status is not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to authorization' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'return flash alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when authorized user' do
      before { sign_in user }
      let(:game) { assigns(:game) }

      context 'creates game' do
        before do
          generate_questions(15)
          post :create
        end

        it 'game not finished' do
          expect(game.finished?).to be false
        end

        it 'return game user' do
          expect(game.user).to eq(user)
        end

        it 'redirect to game page' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'return flash notice' do
          expect(flash[:notice]).to be
        end
      end

      context 'try to create second game' do
        let!(:existing_game) { game_w_questions }

        it "continues current game" do
          expect(game_w_questions.finished?).to be false
        end

        it "does not create new records" do
          expect { post :create }.to change(Game, :count).by(0)
        end

        it "does not create a new game" do
          post :create
          game = assigns(:game)
          expect(game).to be nil
        end

        it "redirects to current game" do
          post :create
          expect(response).to redirect_to(game_path(existing_game))
        end

        it "has alert flash" do
          post :create
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#answer' do
    context 'when anonim' do
      before { put :answer, id: game_w_questions.id }

      it 'return status is not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to authorization' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'return flash alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when authorized user' do
      before { sign_in user }

      context 'correct answer' do
        before do
          put :answer, id: game_w_questions.id,
              letter: game_w_questions.current_game_question.correct_answer_key
        end

        let(:game) { assigns(:game) }

        it 'game not finished' do
          expect(game.finished?).to be false
        end

        it 'current level 1' do
          expect(game.current_level).to eq(1)
        end

        it 'redirect to game path' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'return flash empty' do
          expect(flash.empty?).to be true
        end
      end

      context 'wrong answer' do
        before do
          put :answer, id: game_w_questions.id,
              letter: ['a', 'b', 'c'].sample
        end

        let(:game) { assigns(:game) }

        it 'finish game return true' do
          expect(game.finished?).to be true
        end

        it 'return fail status' do
          expect(game.status).to eq(:fail)
        end

        it 'redirect to user path' do
          expect(response).to redirect_to(user_path(game))
        end

        it 'return flash alert' do
          expect(flash.alert).to be
        end
      end
    end
  end

  describe '#help' do
    let(:game) { assigns(:game) }

    context 'when anonim' do
      before { put :help, id: game_w_questions.id, help_type: :fifty_fifty }

      it 'return status is not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to authorization' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'it must be flash alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when authorized user' do
      before { sign_in user }

      context 'and used fifty_fifty' do
        before { put :help, id: game_w_questions.id, help_type: :fifty_fifty }

        it 'game not finished' do
          expect(game.finished?).to be false
        end

        it 'redirect to game path' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'fifty_fifty_used' do
          expect(game.fifty_fifty_used).to be true
        end

        it 'fifty_fifty return 2 answers' do
          expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq(2)
        end

        it 'fifty_fifty return an array' do
          expect(game.current_game_question.help_hash[:fifty_fifty]).to be_an(Array)
        end

        it 'contains answer key' do
          expect(game.current_game_question.help_hash[:fifty_fifty]).to include(game_w_questions.current_game_question.correct_answer_key)
        end
      end

      context 'and used audience_help' do
        before { put :help, id: game_w_questions.id, help_type: :audience_help }

        it 'game not finished' do
          expect(game.finished?).to be false
        end

        it 'audience_help_used' do
          expect(game.audience_help_used).to be true
        end

        it 'help hash includes audience help' do
          expect(game.current_game_question.help_hash[:audience_help]).to be
        end

        it 'contains correct keys' do
          expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
        end

        it 'redirects to game path' do
          expect(response).to redirect_to(game_path(game))
        end
      end

      context 'add used friend call' do
        before { put :help, id: game_w_questions.id, help_type: :friend_call }

        it 'game not finished' do
          expect(game.finished?).to be false
        end

        it 'friend_call_used' do
          expect(game.friend_call_used).to be true
        end

        it 'help hash includes friend_call' do
          expect(game.current_game_question.help_hash[:friend_call]).to be
        end

        it 'redirect to game path' do
          expect(response).to redirect_to(game_path(game))
        end
      end
    end
  end

  describe '#take_money' do
    context 'when anonim' do
      before { put :take_money, id: game_w_questions.id }

      it 'return status is not 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to authorization' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'return flash alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when authorized' do
      before do
        sign_in user
        game_w_questions.update_attribute(:current_level, 2)
        put :take_money, id: game_w_questions.id
      end
      let(:game) { assigns(:game) }

      it 'finish game return true' do
        expect(game.finished?).to be true
      end

      it 'prize return 200' do
        expect(game.prize).to eq(200)
      end

      context 'after reload' do
        before { user.reload }

        it 'balance return 200' do
          expect(user.balance).to eq(200)
        end

        it 'redirect to user path' do
          expect(response).to redirect_to(user_path(user))
        end

        it 'return flash warning' do
          expect(flash[:warning]).to be
        end
      end
    end
  end
end
