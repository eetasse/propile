require 'spec_helper'

describe ReviewsController do
  it_should_behave_like "a guarded resource controller", :presenter, :maintainer


  context "when logged in" do
    login_as :presenter

    def valid_attributes
      session = FactoryGirl.create(:session_with_presenter)
      FactoryGirl.attributes_for(:review).merge :session_id => session.id
    end
    let(:review) { FactoryGirl.create :review }
    alias_method :create_review, :review

    describe "GET index" do
      it "assigns all reviews as @reviews" do
        create_review
        get :index, {}
        assigns(:reviews).should eq([review])
      end
    end

    describe "GET show" do
      it "assigns the requested review as @review" do
        get :show, {:id => review.to_param}
        assigns(:review).should eq(review)
      end
    end

    describe "GET new" do
      it "assigns a new review as @review" do
        session = FactoryGirl.create :session_with_presenter
        get :new, {:session_id => session.id}
        assigns(:review).should be_a_new(Review)
      end
    end

    describe "GET edit" do
      it "assigns the requested review as @review" do
        get :edit, {:id => review.to_param}
        assigns(:review).should eq(review)
      end
    end

    describe "POST create" do
      describe "with valid params" do
        it "creates a new Review" do
          expect {
            post :create, {:review => valid_attributes}
          }.to change(Review, :count).by(1)
        end

        it "current_presenter is newly created comments' owner" do
          post :create, {:review => valid_attributes}
          Review.last.presenter.should == current_presenter
        end

        it "redirects to the created review" do
          post :create, {:review => valid_attributes}
          response.should redirect_to(Review.last)
        end
      end

      describe "with invalid params" do
        before do
          # Trigger the behavior that occurs when invalid params are submitted
          Review.any_instance.stub(:save).and_return(false)
          post :create, {:review => {}}
        end
        it "assigns a newly created but unsaved review as @review" do
          assigns(:review).should be_a_new(Review)
        end

        it "re-renders the 'new' template" do
          response.should render_template("new")
        end
      end
    end

    describe "PUT update" do
      describe "with valid params" do
        it "updates the requested review" do
          create_review 
          # Assuming there are no other reviews in the database, this
          # specifies that the Review created on the previous line
          # receives the :update_attributes message with whatever params are
          # submitted in the request.
          Review.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
          put :update, {:id => review.to_param, :review => {'these' => 'params'}}
        end

        it "assigns the requested review as @review" do
          put :update, {:id => review.to_param, :review => valid_attributes}
          assigns(:review).should eq(review)
        end

        it "redirects to the review" do
          put :update, {:id => review.to_param, :review => valid_attributes}
          response.should redirect_to(review)
        end
      end

      describe "with invalid params" do
        before do
          # Trigger the behavior that occurs when invalid params are submitted
          Review.any_instance.stub(:save).and_return(false)
          put :update, {:id => review.to_param, :review => {}}
        end
        it "assigns the review as @review" do
          assigns(:review).should eq(review)
        end

        it "re-renders the 'edit' template" do
          response.should render_template("edit")
        end
      end
    end

    describe "DELETE destroy" do
      it "destroys the requested review" do
        create_review
        expect {
          delete :destroy, {:id => review.to_param}
        }.to change(Review, :count).by(-1)
      end

      it "redirects to the reviews list" do
        delete :destroy, {:id => review.to_param}
        response.should redirect_to(reviews_url)
      end
    end
  end

end
