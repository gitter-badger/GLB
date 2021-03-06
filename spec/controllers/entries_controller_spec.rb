require 'spec_helper'

# I'm a public user No ability to create
# I'm an editor
# I'm an admin
# I create an Entry for myself
# I create an Entry for other person


describe EntriesController, :type => :controller do

  let(:unpublished_entry) { FactoryGirl.create(:entry) }
  let(:published_entry) { FactoryGirl.create(:published_entry) }

  before :each do
    @editor = FactoryGirl.create(:editor)
    @admin = FactoryGirl.create(:admin)
  end

  describe "GET index" do
    it "returns published entries" do
      unpublished_entry && published_entry
      get :index
      assigns(:entries).tap do |entries|
        expect(entries).to include(published_entry)
        expect(entries).to_not include(unpublished_entry)
      end
    end
  end

  describe "GET show" do
    before :each do
      unpublished_entry && published_entry
    end

    it "doesn't show only published entries" do
      get :show, {:id => unpublished_entry.to_param}
      expect(response).to redirect_to(entries_url)
    end

    it "shows published entries" do
      get :show, {:id => published_entry.to_param}
      assigns(:entry).should eq(published_entry)
    end
  end

  describe "GET new" do
    it "assigns a new entry as @entry" do
      sign_in @admin
      get :new
      assigns(:entry).should be_a_new(Entry)
      sign_out @admin
    end
  end

  describe "GET edit" do
    before :each do
      unpublished_entry
    end
    it "assigns the requested entry as @entry" do
      sign_in @editor
      unpublished_entry.user = @editor
      unpublished_entry.reload
      get :edit, {:id => unpublished_entry.to_param}
      assigns(:entry).should eq(unpublished_entry)
      sign_out @editor
    end
  end

  describe "POST create" do
    describe "Admin creates an entry" do
      before :each do
        sign_in @admin
      end

      it "creates a new Entry for herself" do
        attributes = FactoryGirl.attributes_for(:entry)
        attributes.delete(:user_id)
        expect {
          post :create, :entry => attributes
        }.to change(Entry, :count).by(1)

        assigns(:entry).tap do |entry|
          expect(entry.user).to eq(@admin)
        end
      end

      context "creates an entry for another user" do
        it "creates an entry for another editor" do
          editor = FactoryGirl.create(:editor)
          expect {
            post :create, :entry => FactoryGirl.attributes_for(:entry).merge({user_id: editor.id })
          }.to change(Entry, :count).by(1)

          assigns(:entry).tap do |entry|
            expect(entry.user).to eq(editor)
          end
        end

        it "creates an entry for another admin" do
          admin = FactoryGirl.create(:admin)
          expect {
            post :create, :entry => FactoryGirl.attributes_for(:entry).merge({user_id: admin.id })
          }.to change(Entry, :count).by(1)

          assigns(:entry).tap do |entry|
            expect(entry.user).to eq(admin)
          end
        end

        it "doesn't create an entry for a non admin or editor user" do
          user = FactoryGirl.create(:user)

          post :create, :entry => FactoryGirl.attributes_for(:entry).merge({user_id: user.id })
          expect(response.code).to eq(200.to_s)
        end
      end


      it "redirects to the created entry" do
        post :create, :entry => FactoryGirl.attributes_for(:entry)
        expect(response).to redirect_to(Entry.last)
      end
    end

    describe "Editor creates an entry" do
      before :each do
        sign_in @editor
      end

      it "creates a new Entry for herself" do
        attributes = FactoryGirl.attributes_for(:entry)
        attributes.delete(:user_id)
        expect {
          post :create, :entry => attributes
        }.to change(Entry, :count).by(1)

        assigns(:entry).tap do |entry|
          expect(entry.user).to eq(@editor)
        end
      end
    end

    describe "User tries to creates an entry" do
      it "creates a new Entry for herself" do
        attributes = FactoryGirl.attributes_for(:entry)
        attributes.delete(:user_id)
        post :create, :entry => attributes
        expect(response.code).to eq(302.to_s)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      pending
      it "updates the requested entry" do
        entry = Entry.create! FactoryGirl.attributes_for(:entry)
        # Assuming there are no other entries in the database, this
        # specifies that the Entry created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Entry.any_instance.should_receive(:update_attributes).with({ "verfasser" => "MyString" })
        put :update, {:id => entry.to_param, :entry => { "verfasser" => "MyString" }}
      end

      it "assigns the requested entry as @entry" do
        entry = Entry.create! FactoryGirl.attributes_for(:entry)
        put :update, {:id => entry.to_param, :entry => FactoryGirl.attributes_for(:entry)}
        subject { assigns(:entry) }
        it {is_expected.to eq(entry) }
      end

      it "redirects to the entry" do
        entry = Entry.create! FactoryGirl.attributes_for(:entry)
        put :update, {:id => entry.to_param, :entry => FactoryGirl.attributes_for(:entry)}
        expect(response).to redirect_to(entry)
      end
    end

    describe "with invalid params" do
      it "assigns the entry as @entry" do
        sign_in @admin
        # Trigger the behavior that occurs when invalid params are submitted
        Entry.any_instance.stub(:save).and_return(false)
        put :update, {:id => @entry.to_param, :entry => { "namenskuerzel" => "invalid value" }}
        assigns(:entry).should eq(@entry)
        sign_out @admin
      end

      it "re-renders the 'edit' template" do
        sign_in @admin
        # Trigger the behavior that occurs when invalid params are submitted
        Entry.any_instance.stub(:save).and_return(false)
        put :update, {:id => @entry.to_param, :entry => { "namenskuerzel" => "invalid value" }}
        response.should render_template("edit")
        sign_out @admin
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested entry" do
      sign_in @admin
      expect {
        delete :destroy, {:id => @entry.to_param}
      }.to change(Entry, :count).by(-1)
      sign_out @admin
    end

    it "redirects to the entries list" do
      sign_in @admin
      delete :destroy, {:id => @entry.to_param}
      response.should redirect_to(entries_url)
      sign_out @admin
    end
  end

end
