class ItemsController < ApplicationController

  before_filter :require_login, except: [:index, :show]
  before_filter :set_item, except: [:index, :new, :create]

  def index
    @items = Item.recent.to_a

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @items }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @item }
    end
  end

  def new
    @item = Item.new

    respond_to do |format|
      format.html
      format.json { render json: @item }
    end
  end

  def edit
  end

  def create
    @item = Item.new(params[:item])
    @item.user = current_user

    respond_to do |format|
      if @item.save
        format.html { redirect_to @item, notice: 'Item was successfully created.' }
        format.json { render json: @item, status: :created, location: @item }
      else
        format.html { render action: "new" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @item.update_attributes(params[:item])
        Tag.all.select {|tag| tag.items.count <= 0 }.each(&:destroy)

        format.html { redirect_to @item, notice: 'Item was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @item.destroy
    @item.tags.select {|tag| tag.items.count <= 0 }.each(&:destroy)

    respond_to do |format|
      format.html { redirect_to user_url(@item.user), notice: %(Success to delete "#{@item.title}".) }
      format.json { head :no_content }
    end
  end

  def stock
    current_user.stock(@item)
    @target = @item.title
    if current_user.save
      render "share/action"
    else
      render "share/action_error"
    end
  end

  def unstock
    current_user.unstock(@item)
    @target = @item.title
    if current_user.save
      render "share/action"
    else
      render "share/action_error"
    end
  end

  def comment
    comment = Comment.new_with_user(params[:comment].merge(user: current_user))
    @item.comments.push comment

    if comment.save
      render partial: "share/comment", object: comment
    else
      render nothing: true, status: 400
    end
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

end
